`timescale 1ns / 1ps

module core_axi_adapter #
(
    parameter C_AXI_ID_WIDTH    = 4,
    parameter C_AXI_ADDR_WIDTH  = 32,
    parameter C_AXI_DATA_WIDTH  = 32,
    parameter WR_BUFFER_DEPTH   = 16
)
(
    input  wire                         clk,
    input  wire                         rst_n,
    
    // Core Interface
    input  wire                         core_req,
    input  wire                         core_wen,
    input  wire [C_AXI_ADDR_WIDTH-1:0]  core_addr,
    input  wire [C_AXI_DATA_WIDTH-1:0]  core_wdata, 
    input  wire [(C_AXI_DATA_WIDTH/8)-1:0] core_wmask,
    output wire [C_AXI_DATA_WIDTH-1:0]  core_rdata,
    output wire                         core_stall,
    output reg                          core_err,
    
    // AXI Master Interface
    output reg  [C_AXI_ID_WIDTH-1:0]    m_axi_awid,
    output reg  [C_AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
    output reg  [7:0]                   m_axi_awlen,
    output reg  [2:0]                   m_axi_awsize,
    output reg  [1:0]                   m_axi_awburst,
    output reg                          m_axi_awlock,
    output reg  [3:0]                   m_axi_awcache,
    output reg  [2:0]                   m_axi_awprot,
    output reg                          m_axi_awvalid,
    input  wire                         m_axi_awready,
    
    output reg  [C_AXI_DATA_WIDTH-1:0]  m_axi_wdata,
    output reg  [(C_AXI_DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output reg                          m_axi_wlast,
    output reg                          m_axi_wvalid,
    input  wire                         m_axi_wready,
    
    input  wire [C_AXI_ID_WIDTH-1:0]    m_axi_bid,
    input  wire [1:0]                   m_axi_bresp,
    input  wire                         m_axi_bvalid,
    output reg                          m_axi_bready,
    
    output reg  [C_AXI_ID_WIDTH-1:0]    m_axi_arid,
    output reg  [C_AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
    output reg  [7:0]                   m_axi_arlen,
    output reg  [2:0]                   m_axi_arsize,
    output reg  [1:0]                   m_axi_arburst,
    output reg                          m_axi_arlock,
    output reg  [3:0]                   m_axi_arcache,
    output reg  [2:0]                   m_axi_arprot,
    output reg                          m_axi_arvalid,
    input  wire                         m_axi_arready,
    
    input  wire [C_AXI_ID_WIDTH-1:0]    m_axi_rid,
    input  wire [C_AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]                   m_axi_rresp,
    input  wire                         m_axi_rlast,
    input  wire                         m_axi_rvalid,
    output reg                          m_axi_rready
);

    localparam STRB_WIDTH   = C_AXI_DATA_WIDTH / 8;
    localparam ADDR_LSB     = $clog2(STRB_WIDTH); 
    localparam CNT_WIDTH    = $clog2(WR_BUFFER_DEPTH) + 1;
    localparam BUF_IDX_WIDTH = $clog2(WR_BUFFER_DEPTH);  // Exact bits for buffer index
    localparam [2:0] AXI_SIZE_VAL = ADDR_LSB[2:0]; 

    reg [C_AXI_DATA_WIDTH-1:0] core_rdata_reg;
    assign core_rdata = core_rdata_reg;

    // CRITICAL FIX: Separate busy flag that goes high IMMEDIATELY when request seen
    reg busy;
    assign core_stall = busy;

    localparam [3:0] IDLE        = 0, 
                     PROCESS_REQ = 1,
                     PRE_FLUSH   = 2, 
                     FLUSH_AW    = 3, 
                     FLUSH_W     = 4, 
                     FLUSH_B     = 5, 
                     READ_ADDR   = 6, 
                     READ_DATA   = 7;

    reg [3:0] state;

    reg [C_AXI_ADDR_WIDTH-1:0] r_req_addr;
    reg [C_AXI_DATA_WIDTH-1:0] r_req_wdata;
    reg [STRB_WIDTH-1:0]       r_req_wmask;
    reg                        r_req_wen;
    
    reg flush_and_retry;

    reg [C_AXI_ADDR_WIDTH-1:0]     buf_base_addr;
    reg [CNT_WIDTH-1:0]            buf_count;
    reg [5:0]                      timeout_ctr; 
    localparam TIMEOUT_LIMIT = 6'd32; 

    reg [C_AXI_DATA_WIDTH-1:0]     data_buffer [0:WR_BUFFER_DEPTH-1];
    reg [STRB_WIDTH-1:0]           strb_buffer [0:WR_BUFFER_DEPTH-1];
    reg [CNT_WIDTH-1:0]            flush_idx;

    // Forwarding Logic
    wire [C_AXI_ADDR_WIDTH-1:0] diff_addr = r_req_addr - buf_base_addr;
    wire [C_AXI_ADDR_WIDTH-1:0] index_raw = diff_addr >> ADDR_LSB; 
    
    // CRITICAL FIX: Use proper bit width for buffer indexing
    wire [BUF_IDX_WIDTH-1:0] buf_idx = index_raw[BUF_IDX_WIDTH-1:0];
    
    // Check if index is within valid buffer range
    wire index_in_bounds = (index_raw < WR_BUFFER_DEPTH);
    
    wire addr_match = (buf_count > 0) && 
                      (r_req_addr >= buf_base_addr) && 
                      (index_raw < buf_count) &&          // Within current valid entries
                      index_in_bounds &&                   // Within physical buffer size
                      (diff_addr[ADDR_LSB-1:0] == 0);     // Word-aligned

    wire is_full_width_entry = &strb_buffer[buf_idx];
    wire is_forwardable_hit = addr_match && is_full_width_entry;

    // Sequential write logic
    wire [C_AXI_ADDR_WIDTH-1:0] next_seq_addr = buf_base_addr + (buf_count << ADDR_LSB); 
    wire is_seq = (r_req_addr == next_seq_addr);
    wire buf_full = (buf_count >= WR_BUFFER_DEPTH);

    // 4KB boundary check
    wire [12:0] current_bytes = buf_count << ADDR_LSB;
    wire [12:0] next_bytes    = current_bytes + STRB_WIDTH;
    wire will_cross_4k = ({1'b0, buf_base_addr[11:0]} + next_bytes) > 13'd4096;

    wire accepting_write = (buf_count == 0) || (is_seq && !buf_full && !will_cross_4k);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            buf_count <= 0;
            timeout_ctr <= 0;
            core_err <= 0;
            flush_idx <= 0;
            core_rdata_reg <= 0;
            flush_and_retry <= 0;
            
            r_req_addr    <= 0;
            r_req_wdata   <= 0;
            r_req_wen     <= 0;
            r_req_wmask   <= 0;

            m_axi_awvalid <= 0; m_axi_wvalid <= 0; m_axi_arvalid <= 0;
            m_axi_awaddr <= 0; m_axi_awlen <= 0; m_axi_awburst <= 0;
            m_axi_wdata <= 0; m_axi_wstrb <= 0; m_axi_wlast <= 0;
            m_axi_bready <= 0; m_axi_rready <= 0; 
            m_axi_araddr <= 0; m_axi_arlen <= 0;
            
            m_axi_awsize <= AXI_SIZE_VAL; 
            m_axi_arsize <= AXI_SIZE_VAL;
            
            m_axi_awid <= 0; m_axi_arid <= 0; 
            m_axi_awlock <= 0; m_axi_arlock <= 0;
            m_axi_awcache <= 0; m_axi_arcache <= 0;
            m_axi_awprot <= 0; m_axi_arprot <= 0;

        end else begin
            
            if (buf_count > 0 && state == IDLE && !core_req) 
                timeout_ctr <= timeout_ctr + 1;
            else 
                timeout_ctr <= 0;

            case (state)
                IDLE: begin
                    m_axi_bready <= 0; 
                    m_axi_rready <= 0;
                    m_axi_awvalid <= 0; 
                    m_axi_wvalid <= 0; 
                    m_axi_arvalid <= 0;
                    
                    if (buf_count > 0 && timeout_ctr >= TIMEOUT_LIMIT) begin
                        state <= PRE_FLUSH;
                    end
                    else if (core_req && !busy) begin
                        // CRITICAL: Set busy IMMEDIATELY in same cycle as request
                        busy <= 1;
                        
                        // Latch inputs
                        r_req_addr  <= core_addr;
                        r_req_wdata <= core_wdata;
                        r_req_wen   <= core_wen;
                        r_req_wmask <= core_wmask;  // FIXED: Use actual mask
                        
                        core_err <= 0;
                        state    <= PROCESS_REQ;
                    end
                end

                PROCESS_REQ: begin
                    flush_and_retry  <= 0;
                    
                    if (r_req_wen) begin
                        // WRITE
                        if (!accepting_write) begin
                            flush_and_retry <= 1;
                            state <= PRE_FLUSH;
                        end else begin
                            if (buf_count == 0) begin
                                buf_base_addr  <= r_req_addr;
                                data_buffer[0] <= r_req_wdata;
                                strb_buffer[0] <= r_req_wmask; 
                                buf_count      <= 1;
                            end else begin
                                data_buffer[buf_count] <= r_req_wdata;
                                strb_buffer[buf_count] <= r_req_wmask; 
                                buf_count      <= buf_count + 1;
                            end
                            busy  <= 0;  // Release stall
                            state <= IDLE; 
                        end
                    end else begin
                        // READ
                        if (is_forwardable_hit) begin
                            // Use buf_idx instead of index_raw to prevent out-of-bounds
                            core_rdata_reg <= data_buffer[buf_idx];
                            busy  <= 0;
                            state <= IDLE; 
                        end else if (buf_count > 0) begin
                            flush_and_retry <= 1;
                            state <= PRE_FLUSH;
                        end else begin
                            state <= READ_ADDR;
                        end
                    end
                end

                PRE_FLUSH: begin
                    flush_idx <= 0; 
                    state <= FLUSH_AW;
                end

                FLUSH_AW: begin
                    m_axi_awaddr  <= buf_base_addr;
                    m_axi_awlen   <= buf_count - 1;
                    m_axi_awburst <= 2'b01;
                    m_axi_awvalid <= 1;
                    
                    if (m_axi_awready && m_axi_awvalid) begin
                        m_axi_awvalid <= 0;
                        m_axi_wdata  <= data_buffer[0];
                        m_axi_wstrb  <= strb_buffer[0]; 
                        m_axi_wlast  <= (buf_count == 1);
                        m_axi_wvalid <= 1; 
                        flush_idx    <= 0; 
                        state        <= FLUSH_W;
                    end
                end

                FLUSH_W: begin
                    if (m_axi_wready && m_axi_wvalid) begin
                        if (flush_idx == buf_count - 1) begin
                            m_axi_wvalid <= 0; 
                            m_axi_wlast  <= 0;
                            m_axi_bready <= 1; 
                            state        <= FLUSH_B;
                        end else begin
                            flush_idx    <= flush_idx + 1;
                            m_axi_wdata  <= data_buffer[flush_idx + 1];
                            m_axi_wstrb  <= strb_buffer[flush_idx + 1]; 
                            m_axi_wlast  <= ((flush_idx + 1) == (buf_count - 1));
                        end
                    end
                end

                FLUSH_B: begin
                    m_axi_bready <= 1; 
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 0; 
                        buf_count <= 0; 
                        
                        if (m_axi_bid != 0) core_err <= 1; 
                        if (m_axi_bresp[1]) core_err <= 1; 
                        
                        if (flush_and_retry) begin
                            flush_and_retry <= 0;
                            state <= PROCESS_REQ;
                        end else begin
                            busy <= 0;  // Release if timeout flush
                            state <= IDLE;
                        end
                    end
                end

                READ_ADDR: begin
                    m_axi_araddr  <= r_req_addr; 
                    m_axi_arlen   <= 0;       
                    m_axi_arburst <= 2'b01;     
                    m_axi_arvalid <= 1;
                    m_axi_rready  <= 0;        

                    if (m_axi_arready && m_axi_arvalid) begin
                        m_axi_arvalid <= 0;
                        m_axi_rready  <= 1;     
                        state <= READ_DATA;        
                    end
                end

                READ_DATA: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        core_rdata_reg <= m_axi_rdata; 
                        
                        if (m_axi_rid != 0) core_err <= 1; 
                        if (m_axi_rresp[1]) core_err <= 1; 

                        if (m_axi_rlast) begin
                            m_axi_rready <= 0;
                            busy <= 0;  // Release stall
                            state <= IDLE;
                        end else begin
                            core_err <= 1; 
                            m_axi_rready <= 0;
                            busy <= 0;
                            state <= IDLE;
                        end
                    end
                end
                
            endcase
        end
    end
endmodule