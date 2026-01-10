`timescale 1ns / 1ps

module boot_rom #(
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 4096,         
    parameter MEM_FILE   = "ins_mem.mem"
)(
    input  wire                  clk,
    input  wire                  en,
    input  wire [31:0]           addr,     
    output reg  [DATA_WIDTH-1:0] data
);

    localparam ADDR_BITS = $clog2(MEM_DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1]; 

    initial begin
        $readmemh(MEM_FILE, mem); 
    end

    always @(posedge clk) begin 
        if(en) begin
            data <= mem[addr[ADDR_BITS+1 : 2]];
        end 
    end

endmodule