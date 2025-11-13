/*
 * Boot ROM Module
 * Immutable read-only memory containing the secure bootloader
 * Size: 4KB (1024 x 32-bit words)
 * Address Range: 0x00000000 - 0x00000FFF
 */

`timescale 1ns / 1ps

module boot_rom (
    input  wire        clk,
    input  wire [9:0]  addr,      // 10-bit address for 1024 words
    output wire [31:0] rdata      // Changed to wire for combinational read
);

    // Boot ROM storage - 4KB
    reg [31:0] rom [0:1023];
    
    // Initialize ROM from hex file
    initial begin
        $readmemh("boot_rom.hex", rom);
    end
    
    // Combinational read - CPU needs immediate response
    assign rdata = rom[addr];

endmodule

