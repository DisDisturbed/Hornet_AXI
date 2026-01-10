`timescale 1ns / 1ps

module Core_Axi_Wrapper #
(
    parameter C_AXI_ID_WIDTH    = 4,
    parameter C_AXI_ADDR_WIDTH  = 32,
    parameter C_AXI_DATA_WIDTH  = 32,
    parameter RESET_VECTOR      = 32'h0000_0000
)
(
    input  wire                         clk,
    input  wire                         rst, 
    input  wire [31:0]                  instr_i,
    output wire [31:0]                  instr_addr_o,
    input  wire                         instr_access_fault_i,

    output wire [C_AXI_ID_WIDTH-1:0]    m_axi_awid,
    output wire [C_AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
    output wire [7:0]                   m_axi_awlen,
    output wire [2:0]                   m_axi_awsize,
    output wire [1:0]                   m_axi_awburst,
    output wire                         m_axi_awlock,
    output wire [3:0]                   m_axi_awcache,
    output wire [2:0]                   m_axi_awprot,
    output wire                         m_axi_awvalid,
    input  wire                         m_axi_awready,

    output wire [C_AXI_DATA_WIDTH-1:0]  m_axi_wdata,
    output wire [C_AXI_DATA_WIDTH/8-1:0] m_axi_wstrb,
    output wire                         m_axi_wlast,
    output wire                         m_axi_wvalid,
    input  wire                         m_axi_wready,

    input  wire [C_AXI_ID_WIDTH-1:0]    m_axi_bid,
    input  wire [1:0]                   m_axi_bresp,
    input  wire                         m_axi_bvalid,
    output wire                         m_axi_bready,

    output wire [C_AXI_ID_WIDTH-1:0]    m_axi_arid,
    output wire [C_AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
    output wire [7:0]                   m_axi_arlen,
    output wire [2:0]                   m_axi_arsize,
    output wire [1:0]                   m_axi_arburst,
    output wire                         m_axi_arlock,
    output wire [3:0]                   m_axi_arcache,
    output wire [2:0]                   m_axi_arprot,
    output wire                         m_axi_arvalid,
    input  wire                         m_axi_arready,

    input  wire [C_AXI_ID_WIDTH-1:0]    m_axi_rid,
    input  wire [C_AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]                   m_axi_rresp,
    input  wire                         m_axi_rlast,
    input  wire                         m_axi_rvalid,
    output wire                         m_axi_rready,

    input  wire                         meip_i,
    input  wire                         mtip_i,
    input  wire                         msip_i,
    input  wire [15:0]                  fast_irq_i,
    output wire                         irq_ack_o,

    output wire [31:0]                  tr_mem_data,
    output wire [31:0]                  tr_mem_addr,
    output wire [31:0]                  tr_reg_data,
    output wire [31:0]                  tr_pc,
    output wire [31:0]                  tr_instr
);

    wire [31:0] int_data_i;
    wire [31:0] int_data_o;
    wire [31:0] int_data_addr;
    wire [3:0]  int_data_wmask;
    wire        int_data_wen;
    wire        int_data_req;
    wire        int_data_stall;
    wire        int_data_err;
    wire rst_n = rst;

    core #(
        .reset_vector(RESET_VECTOR)
    ) u_core (
        .clk_i(clk),
        .reset_i(~rst_n),
        .instr_i(instr_i),
        .instr_addr_o(instr_addr_o),
        .instr_access_fault_i(instr_access_fault_i),
        .data_i(int_data_i),
        .data_wmask_o(int_data_wmask),
        .data_wen_o(int_data_wen),
        .data_addr_o(int_data_addr),
        .data_o(int_data_o),
        .data_req_o(int_data_req),
        .data_stall_i(int_data_stall),
        .data_err_i(int_data_err),
        .meip_i(meip_i),
        .mtip_i(mtip_i),
        .msip_i(msip_i),
        .fast_irq_i(fast_irq_i),
        .irq_ack_o(irq_ack_o),

        .tr_mem_data(tr_mem_data),
        .tr_mem_addr(tr_mem_addr),
        .tr_reg_data(tr_reg_data),
        .tr_pc(tr_pc),
        .tr_instr(tr_instr)
    );

    core_axi_adapter #(
        .C_AXI_ID_WIDTH(C_AXI_ID_WIDTH),
        .C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
        .C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH)
    ) adapter (
        .clk(clk),
        .rst_n(~rst_n),

        .core_req(int_data_req),
        .core_wen(~int_data_wen), 
        .core_addr(int_data_addr),
        .core_wdata(int_data_o),
        .core_wmask(int_data_wmask),
        .core_rdata(int_data_i),
        .core_stall(int_data_stall),
        .core_err(int_data_err),

        .m_axi_awid(m_axi_awid),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awlen(m_axi_awlen),
        .m_axi_awsize(m_axi_awsize),
        .m_axi_awburst(m_axi_awburst),
        .m_axi_awlock(m_axi_awlock),
        .m_axi_awcache(m_axi_awcache),
        .m_axi_awprot(m_axi_awprot),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        .m_axi_bid(m_axi_bid),
        .m_axi_bresp(m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready),
        .m_axi_arid(m_axi_arid),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen),
        .m_axi_arsize(m_axi_arsize),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arlock(m_axi_arlock),
        .m_axi_arcache(m_axi_arcache),
        .m_axi_arprot(m_axi_arprot),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rid(m_axi_rid),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready)
    );

endmodule