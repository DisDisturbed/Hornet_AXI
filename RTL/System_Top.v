`timescale 1ns / 1ps

module system_top (
    input  wire         clk_in,      
    input  wire         rst_n,    
    output wire [7:0]   gpio_leds,
    output wire         uart_tx_o,
    input  wire         uart_rx_i
);
    wire sys_clk;
    wire sys_rst;
    wire clk;

    assign sys_clk = clk;
    assign sys_rst = ~rst_n; 
    wire [3:0]  core_awid;
    wire [31:0] core_awaddr;
    wire [7:0]  core_awlen;
    wire [2:0]  core_awsize;
    wire [1:0]  core_awburst;
    wire        core_awvalid;
    wire        core_awready;
    
    wire [31:0] core_wdata;
    wire [3:0]  core_wstrb;
    wire        core_wlast;
    wire        core_wvalid;
    wire        core_wready;
    
    wire [3:0]  core_bid;
    wire [1:0]  core_bresp;
    wire        core_bvalid;
    wire        core_bready;
    
    wire [3:0]  core_arid;
    wire [31:0] core_araddr;
    wire [7:0]  core_arlen;
    wire [2:0]  core_arsize;
    wire [1:0]  core_arburst;
    wire        core_arvalid;
    wire        core_arready;
    
    wire [3:0]  core_rid;
    wire [31:0] core_rdata;
    wire [1:0]  core_rresp;
    wire        core_rlast;
    wire        core_rvalid;
    wire        core_rready;
    
    wire [31:0] core_instr_addr;
    wire [31:0] core_instr_data;
    wire locked ;
    clk_wiz_1 clkwiz1
(
       .clk_out1(clk),
       .reset(1'b0),
       .locked(locked),
       .clk_in1(clk_in)
);
    
  
    
    Core_Axi_Wrapper core_inst (
        .clk(sys_clk),
        .rst(sys_rst),
        
        .instr_addr_o(core_instr_addr), 
        .instr_i(core_instr_data),      
        .instr_access_fault_i(1'b0),
        .m_axi_awid(core_awid),
        .m_axi_awaddr(core_awaddr),
        .m_axi_awlen(core_awlen),
        .m_axi_awsize(core_awsize),
        .m_axi_awburst(core_awburst),
        .m_axi_awvalid(core_awvalid),
        .m_axi_awready(core_awready),
        
        .m_axi_wdata(core_wdata),
        .m_axi_wstrb(core_wstrb),
        .m_axi_wlast(core_wlast),
        .m_axi_wvalid(core_wvalid),
        .m_axi_wready(core_wready),
        
        .m_axi_bid(core_bid),
        .m_axi_bresp(core_bresp),
        .m_axi_bvalid(core_bvalid),
        .m_axi_bready(core_bready),
        
        .m_axi_arid(core_arid),
        .m_axi_araddr(core_araddr),
        .m_axi_arlen(core_arlen),
        .m_axi_arsize(core_arsize),
        .m_axi_arburst(core_arburst),
        .m_axi_arvalid(core_arvalid),
        .m_axi_arready(core_arready),
        
        .m_axi_rid(core_rid),
        .m_axi_rdata(core_rdata),
        .m_axi_rresp(core_rresp),
        .m_axi_rlast(core_rlast),
        .m_axi_rvalid(core_rvalid),
        .m_axi_rready(core_rready)
    );

    // SUBSYSTEM INTEGRATION 
    
    peripheral_subsystem peripherals (
        .clk(sys_clk),
        .rst(sys_rst),
        .core_instr_addr(core_instr_addr),
        .core_instr_data(core_instr_data), 
        .s_axi_awid    ( {4'b0000, core_awid} ),
        .s_axi_awaddr  ( core_awaddr ),
        .s_axi_awlen   ( core_awlen ),
        .s_axi_awsize  ( core_awsize ),
        .s_axi_awburst ( core_awburst ),
        .s_axi_awvalid ( core_awvalid ),
        .s_axi_awready ( core_awready ),

        .s_axi_wdata   ( core_wdata ),
        .s_axi_wstrb   ( core_wstrb ),
        .s_axi_wlast   ( core_wlast ),
        .s_axi_wvalid  ( core_wvalid ),
        .s_axi_wready  ( core_wready ),

        .s_axi_bid     ( core_bid ),
        .s_axi_bresp   ( core_bresp ),
        .s_axi_bvalid  ( core_bvalid ),
        .s_axi_bready  ( core_bready ),

        .s_axi_arid    ( {4'b0000, core_arid} ),
        .s_axi_araddr  ( core_araddr ),
        .s_axi_arlen   ( core_arlen ),
        .s_axi_arsize  ( core_arsize ),
        .s_axi_arburst ( core_arburst ),
        .s_axi_arvalid ( core_arvalid ),
        .s_axi_arready ( core_arready ),

        .s_axi_rid     ( core_rid ),
        .s_axi_rdata   ( core_rdata ),
        .s_axi_rresp   ( core_rresp ),
        .s_axi_rlast   ( core_rlast ),
        .s_axi_rvalid  ( core_rvalid ),
        .s_axi_rready  ( core_rready ),
        .led_gpio_out(gpio_leds),
        .uart_tx(uart_tx_o),
        .uart_rx(uart_rx_i)
    );

endmodule