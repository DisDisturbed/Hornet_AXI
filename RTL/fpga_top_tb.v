`timescale 1ns / 1ps

module tb_system_top;

    // =================================================================
    // SIGNAL DECLARATIONS
    // =================================================================
    reg        clk_in;
    reg        rst_n;
    
    wire [7:0] gpio_leds;

    // Simulation parameters
    localparam CLK_PERIOD = 10; // 10ns = 100 MHz

    // =================================================================
    // DUT INSTANTIATION
    // =================================================================
    system_top u_dut (
        .clk_in        (clk_in),
        .rst_n      (rst_n),
        .gpio_leds  (gpio_leds),
        .uart_tx_o    (uart_tx),
        .uart_rx_i    (uart_rx)
    );

    // =================================================================
    // CLOCK GENERATION
    // =================================================================
    initial begin
        clk_in = 0;
        forever #(CLK_PERIOD/2) clk_in = ~clk_in;
    end

    // =================================================================
    // MAIN STIMULUS
    // =================================================================
    initial begin
        // 1. Initialization
        rst_n   = 0;    // Assert Reset (Active Low)
         
        $display("Simulation Start: Asserting Reset...");

        // 2. Hold Reset for 100ns
        repeat (10) @(posedge clk_in); 
        #5; 
        
        // 3. Release Reset
        rst_n = 1;
        $display("Time: %0t | Reset Released. CPU should boot now.", $time);

        // 4. Run Simulation
        // Adjust this duration based on how long your firmware takes to run.
        // For a bootloader, you might need 100,000ns or more.
        #50000; 
        
        $display("Simulation Finished.");
        
    end

  

    // =================================================================
    // WAVEFORM DUMPING (For GTKWave / Vivado)
    // =================================================================
    initial begin
        // The filename for the output waveform
        $dumpfile("tb_system_top.vcd");
        
        // Dump all signals in this module and sub-modules (0 implies all levels)
        $dumpvars(0, tb_system_top);
    end

endmodule