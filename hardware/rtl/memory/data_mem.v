/*
 * Data Memory Module (SRAM)
 * Main data memory for stack, heap, and variables
 * Size: 64KB (16384 x 32-bit words)
 * Address Range: 0x10000000 - 0x1000FFFF
 */

`timescale 1ns / 1ps

module data_mem (
    input  wire        clk,
    input  wire        we,           // Write enable
    input  wire [13:0] addr,         // 14-bit address for 16K words
    input  wire [31:0] wdata,        // Write data
    input  wire [3:0]  wstrb,        // Write strobe (byte enables)
    output wire [31:0] rdata         // Read data (combinational)
);

    // Data memory storage - 64KB
    reg [31:0] mem [0:16383];
    
    // Initialize to zero (optional: can load from file)
    integer i;
    initial begin
        for (i = 0; i < 16384; i = i + 1) begin
            mem[i] = 32'h00000000;
        end
    end
    
    // Combinational read - CPU needs immediate response
    assign rdata = mem[addr];
    
    // Synchronous write with byte enables
    always @(posedge clk) begin
        if (we) begin
            if (wstrb[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
            if (wstrb[1]) mem[addr][15: 8] <= wdata[15: 8];
            if (wstrb[2]) mem[addr][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[addr][31:24] <= wdata[31:24];
        end
    end

endmodule

