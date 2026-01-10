`timescale 1ns / 1ps

module peripheral_subsystem # (
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8
)(
    input  wire                   clk,
    input  wire                   rst,
    
    input  wire  [31:0]                 core_instr_addr,
    output wire  [31:0]                 core_instr_data,
    input  wire [ID_WIDTH-1:0]    s_axi_awid,
    input  wire [31:0]            s_axi_awaddr,
    input  wire [7:0]             s_axi_awlen,
    input  wire [2:0]             s_axi_awsize,
    input  wire [1:0]             s_axi_awburst,
    input  wire                   s_axi_awlock,
    input  wire [3:0]             s_axi_awcache,
    input  wire [2:0]             s_axi_awprot,
    input  wire                   s_axi_awvalid,
    output wire                   s_axi_awready, 
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0]s_axi_wstrb,
    input  wire                   s_axi_wlast,
    input  wire                   s_axi_wvalid,
    output wire                   s_axi_wready,
    output wire [ID_WIDTH-1:0]    s_axi_bid,
    output wire [1:0]             s_axi_bresp,
    output wire                   s_axi_bvalid,
    input  wire                   s_axi_bready,
    input  wire [ID_WIDTH-1:0]    s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire [7:0]             s_axi_arlen,
    input  wire [2:0]             s_axi_arsize,
    input  wire [1:0]             s_axi_arburst,
    input  wire                   s_axi_arlock,
    input  wire [3:0]             s_axi_arcache,
    input  wire [2:0]             s_axi_arprot,
    input  wire                   s_axi_arvalid,
    output wire                   s_axi_arready,
    output wire [ID_WIDTH-1:0]    s_axi_rid,
    output wire [DATA_WIDTH-1:0]  s_axi_rdata,
    output wire [1:0]             s_axi_rresp,
    output wire                   s_axi_rlast,
    output wire                   s_axi_rvalid,
    input  wire                   s_axi_rready,

    // External Pins
    input  wire                   uart_rx,
    output wire                   uart_tx,
    output wire [7:0]             led_gpio_out
);

    localparam M_COUNT = 3;
    parameter [M_COUNT*ADDR_WIDTH-1:0] M_BASE_ADDR  = {32'h1000_1000, 32'h1000_0000, 32'h0000_0000};
    
    parameter [M_COUNT*32-1:0]         M_ADDR_WIDTH = {32'd12,        32'd12,        32'd16};
    
    parameter [M_COUNT-1:0]            M_CONNECT    = 3'b111;

    // Internal AXI Connections
    wire [M_COUNT*ID_WIDTH-1:0]    m_axi_awid;
    wire [M_COUNT*ADDR_WIDTH-1:0]  m_axi_awaddr;
    wire [M_COUNT*8-1:0]           m_axi_awlen;
    wire [M_COUNT*3-1:0]           m_axi_awsize;
    wire [M_COUNT*2-1:0]           m_axi_awburst;
    wire [M_COUNT-1:0]             m_axi_awlock;
    wire [M_COUNT*4-1:0]           m_axi_awcache; 
    wire [M_COUNT*3-1:0]           m_axi_awprot;
    wire [M_COUNT-1:0]             m_axi_awvalid;
    wire [M_COUNT-1:0]             m_axi_awready; 
    wire [M_COUNT*DATA_WIDTH-1:0]  m_axi_wdata;
    wire [M_COUNT*DATA_WIDTH/8-1:0]m_axi_wstrb;
    wire [M_COUNT-1:0]             m_axi_wlast;
    wire [M_COUNT-1:0]             m_axi_wvalid;
    wire [M_COUNT-1:0]             m_axi_wready;
    wire [M_COUNT*ID_WIDTH-1:0]    m_axi_bid;
    wire [M_COUNT*2-1:0]           m_axi_bresp;
    wire [M_COUNT-1:0]             m_axi_bvalid;
    wire [M_COUNT-1:0]             m_axi_bready;
    wire [M_COUNT*ID_WIDTH-1:0]    m_axi_arid;
    wire [M_COUNT*ADDR_WIDTH-1:0]  m_axi_araddr;
    wire [M_COUNT*8-1:0]           m_axi_arlen;
    wire [M_COUNT*3-1:0]           m_axi_arsize;
    wire [M_COUNT*2-1:0]           m_axi_arburst;
    wire [M_COUNT-1:0]             m_axi_arlock;
    wire [M_COUNT*4-1:0]           m_axi_arcache;
    wire [M_COUNT*3-1:0]           m_axi_arprot;
    wire [M_COUNT-1:0]             m_axi_arvalid;
    wire [M_COUNT-1:0]             m_axi_arready;
    wire [M_COUNT*ID_WIDTH-1:0]    m_axi_rid;
    wire [M_COUNT*DATA_WIDTH-1:0]  m_axi_rdata;
    wire [M_COUNT*2-1:0]           m_axi_rresp;
    wire [M_COUNT-1:0]             m_axi_rlast;
    wire [M_COUNT-1:0]             m_axi_rvalid;
    wire [M_COUNT-1:0]             m_axi_rready;


      boot_rom ins_mem (
        .clk(clk),
        .en(1'b1),
        .addr(core_instr_addr),
        .data(core_instr_data)     
    );
    axi_crossbar #(
        .S_COUNT(1),
        .M_COUNT(M_COUNT),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .S_ID_WIDTH(ID_WIDTH),
        .M_BASE_ADDR(M_BASE_ADDR),
        .M_ADDR_WIDTH(M_ADDR_WIDTH),
        .M_CONNECT_READ(M_CONNECT),
        .M_CONNECT_WRITE(M_CONNECT) 
    ) u_crossbar (
        .clk(clk),
        .rst(rst),
        .s_axi_awid(s_axi_awid), .s_axi_awaddr(s_axi_awaddr), .s_axi_awlen(s_axi_awlen), .s_axi_awsize(s_axi_awsize), .s_axi_awburst(s_axi_awburst), .s_axi_awlock(s_axi_awlock), .s_axi_awcache(s_axi_awcache), .s_axi_awprot(s_axi_awprot), .s_axi_awvalid(s_axi_awvalid), 
        .s_axi_awready(s_axi_awready), 
        .s_axi_wdata(s_axi_wdata), .s_axi_wstrb(s_axi_wstrb), .s_axi_wlast(s_axi_wlast), .s_axi_wvalid(s_axi_wvalid), .s_axi_wready(s_axi_wready),
        .s_axi_bid(s_axi_bid), .s_axi_bresp(s_axi_bresp), .s_axi_bvalid(s_axi_bvalid), .s_axi_bready(s_axi_bready),
        .s_axi_arid(s_axi_arid), .s_axi_araddr(s_axi_araddr), .s_axi_arlen(s_axi_arlen), .s_axi_arsize(s_axi_arsize), .s_axi_arburst(s_axi_arburst), .s_axi_arlock(s_axi_arlock), .s_axi_arcache(s_axi_arcache), .s_axi_arprot(s_axi_arprot), .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
        .s_axi_rid(s_axi_rid), .s_axi_rdata(s_axi_rdata), .s_axi_rresp(s_axi_rresp), .s_axi_rlast(s_axi_rlast), .s_axi_rvalid(s_axi_rvalid), .s_axi_rready(s_axi_rready),

        .m_axi_awid(m_axi_awid), .m_axi_awaddr(m_axi_awaddr), .m_axi_awlen(m_axi_awlen), .m_axi_awsize(m_axi_awsize), .m_axi_awburst(m_axi_awburst), .m_axi_awlock(m_axi_awlock), .m_axi_awcache(m_axi_awcache), .m_axi_awprot(m_axi_awprot), .m_axi_awvalid(m_axi_awvalid), 
        .m_axi_awready(m_axi_awready), 
        .m_axi_wdata(m_axi_wdata), .m_axi_wstrb(m_axi_wstrb), .m_axi_wlast(m_axi_wlast), .m_axi_wvalid(m_axi_wvalid), .m_axi_wready(m_axi_wready),
        .m_axi_bid(m_axi_bid), .m_axi_bresp(m_axi_bresp), .m_axi_bvalid(m_axi_bvalid), .m_axi_bready(m_axi_bready),
        .m_axi_arid(m_axi_arid), .m_axi_araddr(m_axi_araddr), .m_axi_arlen(m_axi_arlen), .m_axi_arsize(m_axi_arsize), .m_axi_arburst(m_axi_arburst), .m_axi_arlock(m_axi_arlock), .m_axi_arcache(m_axi_arcache), .m_axi_arprot(m_axi_arprot), .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
        .m_axi_rid(m_axi_rid), .m_axi_rdata(m_axi_rdata), .m_axi_rresp(m_axi_rresp), .m_axi_rlast(m_axi_rlast), .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready)
    );

    axi_ram #(
        .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(M_ADDR_WIDTH[0*32 +: 32]), .ID_WIDTH(ID_WIDTH)
    ) u_main_ram (
        .clk(clk), .rst(rst),
        .s_axi_awid(m_axi_awid[0*ID_WIDTH +: ID_WIDTH]), .s_axi_awaddr(m_axi_awaddr[0*ADDR_WIDTH +: ADDR_WIDTH]), .s_axi_awlen(m_axi_awlen[0*8 +: 8]), .s_axi_awsize(m_axi_awsize[0*3 +: 3]), .s_axi_awburst(m_axi_awburst[0*2 +: 2]), .s_axi_awlock(m_axi_awlock[0]), .s_axi_awcache(m_axi_awcache[0*4 +: 4]), .s_axi_awprot(m_axi_awprot[0*3 +: 3]), .s_axi_awvalid(m_axi_awvalid[0]), 
        .s_axi_awready(m_axi_awready[0]),
        .s_axi_wdata(m_axi_wdata[0*DATA_WIDTH +: DATA_WIDTH]), .s_axi_wstrb(m_axi_wstrb[0*(DATA_WIDTH/8) +: (DATA_WIDTH/8)]), .s_axi_wlast(m_axi_wlast[0]), .s_axi_wvalid(m_axi_wvalid[0]), .s_axi_wready(m_axi_wready[0]),
        .s_axi_bid(m_axi_bid[0*ID_WIDTH +: ID_WIDTH]), .s_axi_bresp(m_axi_bresp[0*2 +: 2]), .s_axi_bvalid(m_axi_bvalid[0]), .s_axi_bready(m_axi_bready[0]),
        .s_axi_arid(m_axi_arid[0*ID_WIDTH +: ID_WIDTH]), .s_axi_araddr(m_axi_araddr[0*ADDR_WIDTH +: ADDR_WIDTH]), .s_axi_arlen(m_axi_arlen[0*8 +: 8]), .s_axi_arsize(m_axi_arsize[0*3 +: 3]), .s_axi_arburst(m_axi_arburst[0*2 +: 2]), .s_axi_arlock(m_axi_arlock[0]), .s_axi_arcache(m_axi_arcache[0*4 +: 4]), .s_axi_arprot(m_axi_arprot[0*3 +: 3]), .s_axi_arvalid(m_axi_arvalid[0]), .s_axi_arready(m_axi_arready[0]),
        .s_axi_rid(m_axi_rid[0*ID_WIDTH +: ID_WIDTH]), .s_axi_rdata(m_axi_rdata[0*DATA_WIDTH +: DATA_WIDTH]), .s_axi_rresp(m_axi_rresp[0*2 +: 2]), .s_axi_rlast(m_axi_rlast[0]), .s_axi_rvalid(m_axi_rvalid[0]), .s_axi_rready(m_axi_rready[0])
    );

    axi_uart #(
        .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(M_ADDR_WIDTH[1*32 +: 32]) 
    ) u_uart (
        .clk(clk), .rst(rst),
        .s_axi_awaddr(m_axi_awaddr[1*ADDR_WIDTH +: ADDR_WIDTH]), 
        .s_axi_awvalid(m_axi_awvalid[1]), .s_axi_awready(m_axi_awready[1]),
        .s_axi_wdata(m_axi_wdata[1*DATA_WIDTH +: DATA_WIDTH]), .s_axi_wstrb(m_axi_wstrb[1*(DATA_WIDTH/8) +: (DATA_WIDTH/8)]), .s_axi_wvalid(m_axi_wvalid[1]), .s_axi_wready(m_axi_wready[1]),
        .s_axi_bresp(m_axi_bresp[1*2 +: 2]), .s_axi_bvalid(m_axi_bvalid[1]), .s_axi_bready(m_axi_bready[1]),
        
        .s_axi_araddr(m_axi_araddr[1*ADDR_WIDTH +: ADDR_WIDTH]), 
        .s_axi_arvalid(m_axi_arvalid[1]), .s_axi_arready(m_axi_arready[1]),
        .s_axi_rdata(m_axi_rdata[1*DATA_WIDTH +: DATA_WIDTH]), .s_axi_rresp(m_axi_rresp[1*2 +: 2]), .s_axi_rvalid(m_axi_rvalid[1]), .s_axi_rready(m_axi_rready[1]),
        .rx(uart_rx), .tx(uart_tx), .gpio_out(led_gpio_out)
    );
    assign m_axi_bid[1*ID_WIDTH +: ID_WIDTH] = m_axi_awid[1*ID_WIDTH +: ID_WIDTH];
    assign m_axi_rid[1*ID_WIDTH +: ID_WIDTH] = m_axi_arid[1*ID_WIDTH +: ID_WIDTH];
    assign m_axi_rlast[1] = 1'b1;
    axi_ram_dummy #(
        .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(12), .ID_WIDTH(ID_WIDTH)
    ) u_burst_ram (
        .clk(clk), .rst(rst),
        .s_axi_awid(m_axi_awid[2*ID_WIDTH +: ID_WIDTH]), 
        .s_axi_awaddr(m_axi_awaddr[2*ADDR_WIDTH +: ADDR_WIDTH]), 
        .s_axi_awlen(m_axi_awlen[2*8 +: 8]), .s_axi_awsize(m_axi_awsize[2*3 +: 3]), .s_axi_awburst(m_axi_awburst[2*2 +: 2]), .s_axi_awlock(m_axi_awlock[2]), .s_axi_awcache(m_axi_awcache[2*4 +: 4]), .s_axi_awprot(m_axi_awprot[2*3 +: 3]), .s_axi_awvalid(m_axi_awvalid[2]), 
        .s_axi_awready(m_axi_awready[2]),
        .s_axi_wdata(m_axi_wdata[2*DATA_WIDTH +: DATA_WIDTH]), .s_axi_wstrb(m_axi_wstrb[2*(DATA_WIDTH/8) +: (DATA_WIDTH/8)]), .s_axi_wlast(m_axi_wlast[2]), .s_axi_wvalid(m_axi_wvalid[2]), .s_axi_wready(m_axi_wready[2]),
        .s_axi_bid(m_axi_bid[2*ID_WIDTH +: ID_WIDTH]), .s_axi_bresp(m_axi_bresp[2*2 +: 2]), .s_axi_bvalid(m_axi_bvalid[2]), .s_axi_bready(m_axi_bready[2]),
        .s_axi_arid(m_axi_arid[2*ID_WIDTH +: ID_WIDTH]), .s_axi_araddr(m_axi_araddr[2*ADDR_WIDTH +: ADDR_WIDTH]), .s_axi_arlen(m_axi_arlen[2*8 +: 8]), .s_axi_arsize(m_axi_arsize[2*3 +: 3]), .s_axi_arburst(m_axi_arburst[2*2 +: 2]), .s_axi_arlock(m_axi_arlock[2]), .s_axi_arcache(m_axi_arcache[2*4 +: 4]), .s_axi_arprot(m_axi_arprot[2*3 +: 3]), .s_axi_arvalid(m_axi_arvalid[2]), .s_axi_arready(m_axi_arready[2]),
        .s_axi_rid(m_axi_rid[2*ID_WIDTH +: ID_WIDTH]), .s_axi_rdata(m_axi_rdata[2*DATA_WIDTH +: DATA_WIDTH]), .s_axi_rresp(m_axi_rresp[2*2 +: 2]), .s_axi_rlast(m_axi_rlast[2]), .s_axi_rvalid(m_axi_rvalid[2]), .s_axi_rready(m_axi_rready[2])
    );

endmodule