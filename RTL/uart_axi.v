`timescale 1ns / 1ps

module axi_uart # (
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input  wire                   clk,
    input  wire                   rst, // Active High (Standard for AXI)

    // AXI4-Lite Slave Interface
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0]s_axi_wstrb,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,
    output wire [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,
    output reg  [DATA_WIDTH-1:0]  s_axi_rdata,
    output wire [1:0]             s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready,

    // Physical Ports
    input  wire                   rx,
    output wire                   tx,
    output reg  [7:0]             gpio_out
);

    // -------------------------------------------------------------------------
    // UART INSTANTIATION
    // -------------------------------------------------------------------------
    wire tx_active, tx_done;
    reg  tx_start;
    reg  [7:0] tx_byte;
    
    wire rx_ready;
    wire [7:0] rx_byte;
    reg [7:0] rx_buffer;
    reg       rx_valid_latch;

    // Create Active Low Reset for the NANDLAND modules
    wire rst_n = ~rst; 

    // Adjust CLKS_PER_BIT based on your clock frequency (e.g. 100MHz / 115200 = 868)
    // NOTE: Ensure port names match the sub-module EXACTLY (Case Sensitive)
    AXI_UART_TX #(.CLKS_PER_BIT(868)) u_tx (
        .i_Rst_L(rst_n),          // Added: Connected active low reset
        .i_Clock(clk),
        .i_TX_DV(tx_start),       // Fixed: i_Tx_DV -> i_TX_DV
        .i_TX_Byte(tx_byte),      // Fixed: i_Tx_Byte -> i_TX_Byte
        .o_TX_Active(tx_active),  // Fixed: o_Tx_Active -> o_TX_Active
        .o_TX_Serial(tx),         // Fixed: o_Tx_Serial -> o_TX_Serial
        .o_TX_Done(tx_done)       // Fixed: o_Tx_Done -> o_TX_Done
    );
    
    AXI_UART_RX #(.CLKS_PER_BIT(868)) u_rx (
        .i_Rst_L(rst_n),          // Added: Connected active low reset
        .i_Clock(clk),
        .i_RX_Serial(rx),         // Fixed: i_Rx_Serial -> i_RX_Serial
        .o_RX_DV(rx_ready),       // Fixed: o_Rx_DV -> o_RX_DV
        .o_RX_Byte(rx_byte)       // Fixed: o_Rx_Byte -> o_RX_Byte
    );

    // -------------------------------------------------------------------------
    // AXI WRITE STATE MACHINE
    // -------------------------------------------------------------------------
    reg aw_en;
    reg [ADDR_WIDTH-1:0] axi_awaddr;

    // 1. Handle Write Address Ready (AWREADY)
    always @(posedge clk) begin
        if (rst) begin
            s_axi_awready <= 1'b0;
            aw_en <= 1'b1;
            axi_awaddr <= 0;
        end else begin
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                aw_en <= 1'b0;
                axi_awaddr <= s_axi_awaddr;
            end else if (~s_axi_awready && s_axi_awvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                aw_en <= 1'b0;
                axi_awaddr <= s_axi_awaddr;
            end else begin
                s_axi_awready <= 1'b0;
            end
            
            if (s_axi_bready && s_axi_bvalid) begin
                aw_en <= 1'b1;
            end 
        end
    end

    // 2. Handle Write Data Ready (WREADY)
    always @(posedge clk) begin
        if (rst) begin
            s_axi_wready <= 1'b0;
        end else begin
            if (~s_axi_wready && s_axi_wvalid && s_axi_awvalid && aw_en) begin
                s_axi_wready <= 1'b1;
            end else if (~s_axi_wready && s_axi_wvalid) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end

    // 3. Handle Write Response (BVALID) and Register Logic
    always @(posedge clk) begin
        if (rst) begin
            s_axi_bvalid <= 1'b0;
            tx_start     <= 1'b0;
            gpio_out     <= 8'h00;
        end else begin
            tx_start <= 1'b0; // Default pulse low

            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                // --- WRITE LOGIC ---
                if (s_axi_awaddr[7:0] == 8'h00) begin
                    if (!tx_active) begin
                        tx_byte  <= s_axi_wdata[7:0];
                        tx_start <= 1'b1;
                    end
                end else if (s_axi_awaddr[7:0] == 8'h0C) begin
                    gpio_out <= s_axi_wdata[7:0];
                end
                // -------------------
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end else if (~s_axi_bvalid && s_axi_wready && s_axi_wvalid && ~aw_en) begin
                s_axi_bvalid <= 1'b1;
                // --- WRITE LOGIC ---
                if (axi_awaddr[7:0] == 8'h00) begin
                    if (!tx_active) begin
                        tx_byte  <= s_axi_wdata[7:0];
                        tx_start <= 1'b1;
                    end
                end else if (axi_awaddr[7:0] == 8'h0C) begin
                    gpio_out <= s_axi_wdata[7:0];
                end
                // -------------------
            end
        end
    end
    
    assign s_axi_bresp = 2'b00; // OKAY

    // -------------------------------------------------------------------------
    // AXI READ LOGIC
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            rx_valid_latch <= 1'b0;
            rx_buffer      <= 0;
            s_axi_arready  <= 1'b0;
            s_axi_rvalid   <= 1'b0;
            s_axi_rdata    <= 0;
        end else begin
            // RX Buffer Latching
            if (rx_ready) begin
                rx_buffer <= rx_byte;
                rx_valid_latch <= 1'b1;
            end

            // Read Address Ready
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            // Read Data Valid
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                case(s_axi_araddr[7:0])
                    8'h00: begin 
                        s_axi_rdata <= {24'b0, rx_buffer};
                        rx_valid_latch <= 1'b0; // Clear valid on read
                    end
                    8'h04: s_axi_rdata <= {30'b0, tx_active, rx_valid_latch};
                    8'h0C: s_axi_rdata <= {24'b0, gpio_out};
                    default: s_axi_rdata <= 32'h0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
    assign s_axi_rresp = 2'b00;

endmodule