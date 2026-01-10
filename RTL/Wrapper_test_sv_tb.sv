`timescale 1ns / 1ps

module tb_core_axi_adapter;

    // Parameters
    parameter C_AXI_ID_WIDTH    = 4;
    parameter C_AXI_ADDR_WIDTH  = 32;
    parameter C_AXI_DATA_WIDTH  = 32;
    parameter WR_BUFFER_DEPTH   = 16;

    // Clock and Reset
    reg clk;
    reg rst_n;

    // Core Interface Signals (We will drive these like the CPU)
    reg                         core_req;
    reg                         core_wen;
    reg [C_AXI_ADDR_WIDTH-1:0]  core_addr;
    reg [C_AXI_DATA_WIDTH-1:0]  core_wdata;
    reg [3:0]                   core_wmask;
    wire [C_AXI_DATA_WIDTH-1:0] core_rdata;
    wire                        core_stall;
    wire                        core_err;

    // AXI Master Interface Signals (We will monitor these)
    wire [C_AXI_ID_WIDTH-1:0]   m_axi_awid;
    wire [C_AXI_ADDR_WIDTH-1:0] m_axi_awaddr;
    wire [7:0]                  m_axi_awlen;
    wire [2:0]                  m_axi_awsize;
    wire [1:0]                  m_axi_awburst;
    wire                        m_axi_awvalid;
    reg                         m_axi_awready; // Slave input

    wire [C_AXI_DATA_WIDTH-1:0] m_axi_wdata;
    wire                        m_axi_wlast;
    wire                        m_axi_wvalid;
    reg                         m_axi_wready; // Slave input

    wire                        m_axi_bready;
    reg                         m_axi_bvalid; // Slave input
    reg [1:0]                   m_axi_bresp;  // Slave input

    // DUT Instantiation
    core_axi_adapter #(
        .C_AXI_ID_WIDTH(C_AXI_ID_WIDTH),
        .C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
        .C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
        .WR_BUFFER_DEPTH(WR_BUFFER_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .core_req(core_req),
        .core_wen(core_wen),
        .core_addr(core_addr),
        .core_wdata(core_wdata),
        .core_wmask(core_wmask),
        .core_rdata(core_rdata),
        .core_stall(core_stall),
        .core_err(core_err),
        
        // AXI Write Address
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awlen(m_axi_awlen),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axi_awburst(m_axi_awburst),
        
        // AXI Write Data
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wlast(m_axi_wlast),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        
        // AXI Write Response
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready),
        .m_axi_bresp(m_axi_bresp),
        
        // Unused Read signals for this test
        .m_axi_arready(1'b1),
        .m_axi_rvalid(1'b0),
        .m_axi_rdata(32'b0)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    // -------------------------------------------------------------------------
    // Dummy AXI Slave Logic (Responds to the Adapter)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axi_awready <= 0;
            m_axi_wready  <= 0;
            m_axi_bvalid  <= 0;
        end else begin
            // 1. Address Handshake: Always ready to accept address
            m_axi_awready <= 1;

            // 2. Data Handshake: Always ready to accept data
            m_axi_wready <= 1;

            // 3. Write Response: Send valid response 1 cycle after WLAST
            if (m_axi_wvalid && m_axi_wready && m_axi_wlast) begin
                m_axi_bvalid <= 1;
            end else if (m_axi_bvalid && m_axi_bready) begin
                m_axi_bvalid <= 0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Main Stimulus (Mimics the C Code)
    // -------------------------------------------------------------------------
    integer i;
    
    initial begin
        // Initialize
        rst_n = 0;
        core_req = 0;
        core_wen = 0;
        core_addr = 0;
        core_wdata = 0;
        core_wmask = 4'b1111;
        
        // Apply Reset
        #20;
        rst_n = 1;
        #20;

        $display("Starting C-Code Simulation: Writing 1..16 to 0x9000...");

        // Loop 16 times (simulating the array filling)
        for (i = 0; i < 16; i = i + 1) begin
            
            // Wait if the core is stalled (Adapter buffer might be full)
            wait(core_stall == 0);
            
            @(posedge clk);
            core_req   <= 1;
            core_wen   <= 1; // Write
            // Address increments by 4 bytes (32-bit architecture)
            core_addr  <= 32'h0000_9000 + (i * 4); 
            core_wdata <= i + 1; // Value 1, 2, 3...
            
            @(posedge clk);
            // Deassert req after one cycle (simple valid/ready mimic)
            core_req <= 0;
            core_wen <= 0;
            
            // Small delay between CPU instructions
            #10; 
        end

        $display("CPU Writes Complete. Waiting for Adapter to Flush Burst...");

        // The adapter waits for buffer full OR timeout. 
        // Since we wrote exactly 16 (WR_BUFFER_DEPTH), it should trigger immediately.
        
        wait(m_axi_awvalid);
        $display("BURST DETECTED! AWLEN = %d (Should be 15)", m_axi_awlen);
        
        wait(m_axi_wlast);
        $display("WLAST Detected. Burst Complete.");

        #100;
        $finish;
    end

endmodule