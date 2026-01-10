//`timescale 1ns / 1ps

//module core_axi_adapter #
//(
//    parameter C_AXI_ID_WIDTH    = 4,
//    parameter C_AXI_ADDR_WIDTH  = 32,
//    parameter C_AXI_DATA_WIDTH  = 32,
//    parameter WR_BUFFER_DEPTH   = 16
//)
//(
//    input  wire                         clk,
//    input  wire                         rst_n,

//    // CORE INTERFACE
//    input  wire                         core_req,
//    input  wire                         core_wen,
//    input  wire [C_AXI_ADDR_WIDTH-1:0]  core_addr,
//    input  wire [C_AXI_DATA_WIDTH-1:0]  core_wdata, 
//    input  wire [3:0]                   core_wmask,
    
//    // Output is Reg again (Driven by FSM)
//    output reg  [C_AXI_DATA_WIDTH-1:0]  core_rdata,
    
//    output wire                         core_stall,
//    output reg                          core_err,

//    // AXI MASTER INTERFACE
//    output reg  [C_AXI_ID_WIDTH-1:0]    m_axi_awid,
//    output reg  [C_AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
//    output reg  [7:0]                   m_axi_awlen,
//    output reg  [2:0]                   m_axi_awsize,
//    output reg  [1:0]                   m_axi_awburst,
//    output reg                          m_axi_awlock,
//    output reg  [3:0]                   m_axi_awcache,
//    output reg  [2:0]                   m_axi_awprot,
//    output reg                          m_axi_awvalid,
//    input  wire                         m_axi_awready,
 
//    output reg  [C_AXI_DATA_WIDTH-1:0]  m_axi_wdata,
//    output reg  [C_AXI_DATA_WIDTH/8-1:0]m_axi_wstrb,
//    output reg                          m_axi_wlast,
//    output reg                          m_axi_wvalid,
//    input  wire                         m_axi_wready,

//    input  wire [C_AXI_ID_WIDTH-1:0]    m_axi_bid,
//    input  wire [1:0]                   m_axi_bresp,
//    input  wire                         m_axi_bvalid,
//    output reg                          m_axi_bready,

//    output reg  [C_AXI_ID_WIDTH-1:0]    m_axi_arid,
//    output reg  [C_AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
//    output reg  [7:0]                   m_axi_arlen,
//    output reg  [2:0]                   m_axi_arsize,
//    output reg  [1:0]                   m_axi_arburst,
//    output reg                          m_axi_arlock,
//    output reg  [3:0]                   m_axi_arcache,
//    output reg  [2:0]                   m_axi_arprot,
//    output reg                          m_axi_arvalid,
//    input  wire                         m_axi_arready,

//    input  wire [C_AXI_ID_WIDTH-1:0]    m_axi_rid,
//    input  wire [C_AXI_DATA_WIDTH-1:0]  m_axi_rdata,
//    input  wire [1:0]                   m_axi_rresp,
//    input  wire                         m_axi_rlast,
//    input  wire                         m_axi_rvalid,
//    output reg                          m_axi_rready
//);

//    // ----------------------------------------------------------------------
//    // WRITE BUFFERING LOGIC (KEPT INTACT)
//    // ----------------------------------------------------------------------
//    reg [C_AXI_ADDR_WIDTH-1:0]   buf_base_addr;
//    reg [4:0]                    buf_count;
//    reg [5:0]                    timeout_ctr; 
//    reg                          ignore_next; 
//    localparam TIMEOUT_LIMIT = 6'd32; 

//    reg [C_AXI_DATA_WIDTH-1:0]   data_buffer [0:WR_BUFFER_DEPTH-1];

//    wire [C_AXI_ADDR_WIDTH-1:0] next_seq_addr;
//    assign next_seq_addr = buf_base_addr + {28'b0, buf_count, 2'b00}; 
    
//    wire is_seq;
//    assign is_seq = (core_addr == next_seq_addr);
    
//    wire buf_full;
//    assign buf_full = (buf_count >= WR_BUFFER_DEPTH[4:0]);

//    // ----------------------------------------------------------------------
//    // FSM
//    // ----------------------------------------------------------------------
//    localparam [3:0] IDLE      = 0, 
//                     PRE_FLUSH = 1, 
//                     FLUSH_AW  = 2, 
//                     FLUSH_W   = 3, 
//                     FLUSH_B   = 4, 
//                     READ_ADDR = 5, // Simple Read Address
//                     READ_DATA = 6, // Simple Read Data
//                     READ_DONE = 7; // Handshake Wait

//    reg [3:0] state;
//    reg [4:0] flush_idx;

//    // Stall Logic:
//    // 1. Stall if NOT IDLE and NOT READ_DONE (Processing)
//    // 2. Stall if IDLE but Write Buffer is Full
//    // 3. Stall if IDLE but Timeout reached (Flushing)
//    assign core_stall = (state != IDLE && state != READ_DONE) || 
//                        (state == IDLE && core_req && core_wen && buf_full) ||
//                        (state == IDLE && core_req && !core_wen && buf_count > 0) || // Flush before Read
//                        (state == IDLE && buf_count > 0 && timeout_ctr >= TIMEOUT_LIMIT);


//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            state <= IDLE;
//            buf_count <= 0;
//            timeout_ctr <= 0;
//            core_err <= 0;
//            flush_idx <= 0;
//            ignore_next <= 0; 
//            core_rdata <= 0;
            
//            m_axi_awvalid <= 0; m_axi_wvalid <= 0; m_axi_arvalid <= 0;
//            m_axi_awaddr <= 0; m_axi_awlen <= 0; m_axi_awburst <= 0;
//            m_axi_wdata <= 0; m_axi_wstrb <= 0; m_axi_wlast <= 0;
//            m_axi_bready <= 0; m_axi_rready <= 0; m_axi_araddr <= 0;
            
//            m_axi_awsize <= 3'b010; m_axi_arsize <= 3'b010;
//            m_axi_awid <= 0; m_axi_arid <= 0; 
//            m_axi_awlock <= 0; m_axi_arlock <= 0;
//            m_axi_awcache <= 0; m_axi_arcache <= 0;
//            m_axi_awprot <= 0; m_axi_arprot <= 0;

//        end else begin
//            // Timeout Logic (Only for Writes)
//            if (!ignore_next && buf_count > 0 && state == IDLE && !core_req) 
//                timeout_ctr <= timeout_ctr + 1;
//            else 
//                timeout_ctr <= 0;

//            case (state)
//                IDLE: begin
//                    m_axi_bready <= 0; 
//                    m_axi_rready <= 0;
//                    m_axi_awvalid <= 0; m_axi_wvalid <= 0; m_axi_arvalid <= 0;
//                    m_axi_wlast <= 0;

//                    if (ignore_next) begin
//                        ignore_next <= 0;
//                    end
//                    else if (buf_count > 0 && timeout_ctr >= TIMEOUT_LIMIT) begin
//                        state <= PRE_FLUSH;
//                    end
//                    else if (core_req) begin
//                        if (core_wen) begin
//                            // --------------------------------------------------
//                            // WRITE LOGIC (Burst Buffering) - KEPT ORIGINAL
//                            // --------------------------------------------------
//                            if (buf_count == 0) begin
//                                buf_base_addr <= core_addr;
//                                data_buffer[0] <= core_wdata;
//                                buf_count <= 1;
//                            end else if (is_seq && !buf_full) begin
//                                data_buffer[buf_count] <= core_wdata;
//                                buf_count <= buf_count + 1;
//                            end else begin
//                                state <= PRE_FLUSH;
//                            end
//                        end else begin
//                            // --------------------------------------------------
//                            // READ LOGIC - CHANGED TO SIMPLE
//                            // --------------------------------------------------
//                            if (buf_count > 0) state <= PRE_FLUSH; // Must flush writes first
//                            else state <= READ_ADDR; // Go to simple read
//                        end
//                    end
//                end

//                // --------------------------------------------------------------
//                // BURST WRITE STATES (Original Logic)
//                // --------------------------------------------------------------
//                PRE_FLUSH: begin
//                    flush_idx <= 0; 
//                    state <= FLUSH_AW;
//                end

//                FLUSH_AW: begin
//                    m_axi_awaddr  <= buf_base_addr;
//                    m_axi_awlen   <= buf_count - 1;
//                    m_axi_awburst <= 2'b01; 
//                    m_axi_awvalid <= 1;
//                    m_axi_wvalid  <= 0; 

//                    if (m_axi_awready && m_axi_awvalid) begin
//                        m_axi_awvalid <= 0;
//                        m_axi_wdata  <= data_buffer[0];
//                        m_axi_wstrb  <= 4'b1111; 
//                        m_axi_wlast  <= (buf_count == 1);
//                        m_axi_wvalid <= 1;
//                        flush_idx    <= 0; 
//                        state        <= FLUSH_W;
//                    end
//                end

//                FLUSH_W: begin
//                    if (m_axi_wready && m_axi_wvalid) begin
//                        if (flush_idx == buf_count - 1) begin
//                            m_axi_wvalid <= 0;
//                            m_axi_wlast  <= 0;
//                            state        <= FLUSH_B;
//                        end else begin
//                            flush_idx    <= flush_idx + 1;
//                            m_axi_wdata  <= data_buffer[flush_idx + 1];
//                            m_axi_wstrb  <= 4'b1111; 
//                            if ((flush_idx + 1) == (buf_count - 1))
//                                m_axi_wlast <= 1;
//                            else
//                                m_axi_wlast <= 0;
//                        end
//                    end
//                end

//                FLUSH_B: begin
//                    m_axi_bready <= 1; 
//                    if (m_axi_bvalid) begin
//                        m_axi_bready <= 0; 
//                        buf_count <= 0;
                        
//                        if (core_req && core_wen) begin
//                            buf_base_addr <= core_addr;
//                            data_buffer[0] <= core_wdata;
//                            buf_count <= 1;
//                            ignore_next <= 1;
//                            state <= IDLE; 
//                        end else begin
//                            if (core_req && !core_wen) state <= READ_ADDR;
//                            else state <= IDLE;
//                        end
//                    end
//                end

//                // --------------------------------------------------------------
//                // SIMPLE READ STATES (Single Beat, No Burst, Handshake Safe)
//                // --------------------------------------------------------------
//                READ_ADDR: begin
//                    m_axi_araddr  <= core_addr;
//                    m_axi_arlen   <= 0;       // Always 1 word
//                    m_axi_arburst <= 2'b01;   
//                    m_axi_arvalid <= 1;
//                    m_axi_rready  <= 0;       

//                    if (m_axi_arready && m_axi_arvalid) begin
//                        m_axi_arvalid <= 0;
//                        m_axi_rready  <= 1;   // Ready to accept data immediately
//                        state <= READ_DATA;      
//                    end
//                end

//                READ_DATA: begin
//                    if (m_axi_rvalid && m_axi_rready) begin
//                        core_rdata   <= m_axi_rdata; // Capture Data
//                        m_axi_rready <= 0;
                        
//                        if (m_axi_rresp != 2'b00) core_err <= 1;

//                        // Go to DONE to hold data until Core releases Request
//                        state <= READ_DONE; 
//                    end
//                end

//                READ_DONE: begin
//                    // Wait for Core to drop 'req'. 
//                    // This prevents the "Double Read" bug.
//                    if (!core_req || (core_req && core_wen)) begin
//                        state <= IDLE;
//                    end
//                end

//            endcase
//        end
//    end
//endmodule