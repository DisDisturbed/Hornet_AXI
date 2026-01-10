/*
 * Simple AXI4 Master Interface
 * converts Core commands into AXI4 Bursts.
 */
/*module axi_master #
(
    parameter AXI_ID_WIDTH    = 4,
    parameter AXI_ADDR_WIDTH  = 32,
    parameter AXI_DATA_WIDTH  = 32
)
(
    input  wire                      clk,
    input  wire                      rst,

    // --- User Interface (Connect to Core) ---
    input  wire                      cmd_wr_start,
    input  wire [AXI_ADDR_WIDTH-1:0] cmd_wr_addr,
    input  wire [7:0]                cmd_wr_len,
    output wire                      cmd_wr_ready,
    input  wire [AXI_DATA_WIDTH-1:0] s_wr_data,
    input  wire                      s_wr_valid,
    output wire                      s_wr_ready,

    input  wire                      cmd_rd_start,
    input  wire [AXI_ADDR_WIDTH-1:0] cmd_rd_addr,
    input  wire [7:0]                cmd_rd_len,
    output wire                      cmd_rd_ready,
    output wire [AXI_DATA_WIDTH-1:0] m_rd_data,
    output wire                      m_rd_valid,
    output wire                      m_rd_last,
    input  wire                      m_rd_ready,

    // --- AXI4 Interface (Connect to Crossbar) ---
    output wire [AXI_ID_WIDTH-1:0]   m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0] m_axi_awaddr,
    output wire [7:0]                m_axi_awlen,
    output wire [2:0]                m_axi_awsize,
    output wire [1:0]                m_axi_awburst,
    output wire                      m_axi_awlock,
    output wire [3:0]                m_axi_awcache,
    output wire [2:0]                m_axi_awprot,
    output wire                      m_axi_awvalid,
    input  wire                      m_axi_awready,

    output wire [AXI_DATA_WIDTH-1:0] m_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0] m_axi_wstrb,
    output wire                      m_axi_wlast,
    output wire                      m_axi_wvalid,
    input  wire                      m_axi_wready,

    input  wire [AXI_ID_WIDTH-1:0]   m_axi_bid,
    input  wire [1:0]                m_axi_bresp,
    input  wire                      m_axi_bvalid,
    output wire                      m_axi_bready,

    output wire [AXI_ID_WIDTH-1:0]   m_axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0] m_axi_araddr,
    output wire [7:0]                m_axi_arlen,
    output wire [2:0]                m_axi_arsize,
    output wire [1:0]                m_axi_arburst,
    output wire                      m_axi_arlock,
    output wire [3:0]                m_axi_arcache,
    output wire [2:0]                m_axi_arprot,
    output wire                      m_axi_arvalid,
    input  wire                      m_axi_arready,

    input  wire [AXI_ID_WIDTH-1:0]   m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0] m_axi_rdata,
    input  wire [1:0]                m_axi_rresp,
    input  wire                      m_axi_rlast,
    input  wire                      m_axi_rvalid,
    output wire                      m_axi_rready
);

    localparam [2:0] AXI_SIZE = $clog2(AXI_DATA_WIDTH/8);
    localparam [1:0] AXI_BURST_INCR = 2'b01;

    // --- Write Logic ---
    reg [1:0] wr_state;
    reg [AXI_ADDR_WIDTH-1:0] reg_wr_addr;
    reg [7:0] reg_wr_len, wr_beat_cnt;

    localparam S_WR_IDLE=0, S_WR_ADDR=1, S_WR_DATA=2, S_WR_RESP=3;

    always @(posedge clk) begin
        if (rst) begin
            wr_state <= S_WR_IDLE;
            wr_beat_cnt <= 0;
        end else begin
            case (wr_state)
                S_WR_IDLE: if (cmd_wr_start) begin
                    reg_wr_addr <= cmd_wr_addr;
                    reg_wr_len <= cmd_wr_len;
                    wr_state <= S_WR_ADDR;
                end
                S_WR_ADDR: if (m_axi_awready) wr_state <= S_WR_DATA;
                S_WR_DATA: if (s_wr_valid && m_axi_wready) begin
                    if (wr_beat_cnt == reg_wr_len) begin
                        wr_state <= S_WR_RESP;
                        wr_beat_cnt <= 0;
                    end else begin
                        wr_beat_cnt <= wr_beat_cnt + 1;
                    end
                end
                S_WR_RESP: if (m_axi_bvalid) wr_state <= S_WR_IDLE;
            endcase
        end
    end

    assign m_axi_awid = 0; assign m_axi_awaddr = reg_wr_addr; assign m_axi_awlen = reg_wr_len;
    assign m_axi_awsize = AXI_SIZE; assign m_axi_awburst = AXI_BURST_INCR;
    assign m_axi_awlock = 0; assign m_axi_awcache = 3; assign m_axi_awprot = 0;
    assign m_axi_awvalid = (wr_state == S_WR_ADDR);

    assign m_axi_wdata = s_wr_data;
    assign m_axi_wstrb = {(AXI_DATA_WIDTH/8){1'b1}};
    assign m_axi_wlast = (wr_beat_cnt == reg_wr_len);
    assign m_axi_wvalid = (wr_state == S_WR_DATA) && s_wr_valid;
    assign s_wr_ready = (wr_state == S_WR_DATA) && m_axi_wready;
    assign m_axi_bready = (wr_state == S_WR_RESP);
    assign cmd_wr_ready = (wr_state == S_WR_IDLE);

    // --- Read Logic ---
    reg [1:0] rd_state;
    reg [AXI_ADDR_WIDTH-1:0] reg_rd_addr;
    reg [7:0] reg_rd_len;

    localparam S_RD_IDLE=0, S_RD_ADDR=1, S_RD_DATA=2;

    always @(posedge clk) begin
        if (rst) begin
            rd_state <= S_RD_IDLE;
        end else begin
            case (rd_state)
                S_RD_IDLE: if (cmd_rd_start) begin
                    reg_rd_addr <= cmd_rd_addr;
                    reg_rd_len <= cmd_rd_len;
                    rd_state <= S_RD_ADDR;
                end
                S_RD_ADDR: if (m_axi_arready) rd_state <= S_RD_DATA;
                S_RD_DATA: if (m_axi_rvalid && m_axi_rready && m_axi_rlast) rd_state <= S_RD_IDLE;
            endcase
        end
    end

    assign m_axi_arid = 0; assign m_axi_araddr = reg_rd_addr; assign m_axi_arlen = reg_rd_len;
    assign m_axi_arsize = AXI_SIZE; assign m_axi_arburst = AXI_BURST_INCR;
    assign m_axi_arlock = 0; assign m_axi_arcache = 3; assign m_axi_arprot = 0;
    assign m_axi_arvalid = (rd_state == S_RD_ADDR);

    assign m_rd_data = m_axi_rdata;
    assign m_rd_valid = (rd_state == S_RD_DATA) && m_axi_rvalid;
    assign m_rd_last = m_axi_rlast;
    assign m_axi_rready = (rd_state == S_RD_DATA) && m_rd_ready;
    assign cmd_rd_ready = (rd_state == S_RD_IDLE);

endmodule