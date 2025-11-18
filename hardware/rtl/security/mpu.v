/*
 * Memory Protection Unit (MPU) for Smart Lock SoC
 * 
 * Provides hardware-enforced memory protection to prevent:
 * - Unauthorized access to encryption keys
 * - Firmware modification attempts
 * - Bootloader tampering
 * 
 * Memory Regions:
 *   Boot ROM:   0x00000000 - 0x00000FFF (Read/Execute only)
 *   Firmware:   0x00010000 - 0x0001FFFF (Read/Execute only)
 *   Data RAM:   0x10000000 - 0x1000FFFF (Read/Write/Execute)
 *   UART:       0x20000000 - 0x200000FF (Read/Write)
 *   Key Store:  0x40000000 - 0x400000FF (Machine mode only)
 */

`timescale 1ns / 1ps

module mpu (
    // Memory access signals from CPU
    input  wire [31:0] addr,            // Memory address being accessed
    input  wire        is_write,        // Write operation?
    input  wire        is_exec,         // Instruction fetch?
    input  wire        privileged_mode, // CPU in machine mode? (0=user, 1=machine)
    
    // Protection status
    output reg         violation,       // Access violation detected
    output reg         access_allowed   // Access permitted
);

    //=================================================================
    // Memory Region Definitions
    //=================================================================
    
    // Boot ROM - Immutable bootloader
    localparam BOOT_ROM_START   = 32'h00000000;
    localparam BOOT_ROM_END     = 32'h00000FFF;
    
    // Firmware - Application code
    localparam FIRMWARE_START   = 32'h00010000;
    localparam FIRMWARE_END     = 32'h0001FFFF;
    
    // Data Memory - Stack, heap, variables
    localparam DATA_MEM_START   = 32'h10000000;
    localparam DATA_MEM_END     = 32'h1000FFFF;
    
    // UART Peripheral
    localparam UART_START       = 32'h20000000;
    localparam UART_END         = 32'h200000FF;
    
    // Key Store - PROTECTED REGION
    localparam KEY_STORE_START  = 32'h40000000;
    localparam KEY_STORE_END    = 32'h400000FF;
    
    //=================================================================
    // Protection Logic (Combinational - No clock cycles!)
    //=================================================================
    
    always @(*) begin
        // Default: deny access
        violation = 1'b0;
        access_allowed = 1'b0;
        
        //-------------------------------------------------------------
        // Boot ROM Protection
        //-------------------------------------------------------------
        if (addr >= BOOT_ROM_START && addr <= BOOT_ROM_END) begin
            if (is_write) begin
                // VIOLATION: Cannot write to boot ROM
                violation = 1'b1;
                access_allowed = 1'b0;
            end else begin
                // OK: Can read/execute boot ROM
                violation = 1'b0;
                access_allowed = 1'b1;
            end
        end
        
        //-------------------------------------------------------------
        // Firmware Protection
        //-------------------------------------------------------------
        else if (addr >= FIRMWARE_START && addr <= FIRMWARE_END) begin
            if (is_write) begin
                // VIOLATION: Cannot write to firmware (no self-modification)
                violation = 1'b1;
                access_allowed = 1'b0;
            end else begin
                // OK: Can read/execute firmware
                violation = 1'b0;
                access_allowed = 1'b1;
            end
        end
        
        //-------------------------------------------------------------
        // Data Memory Protection
        //-------------------------------------------------------------
        else if (addr >= DATA_MEM_START && addr <= DATA_MEM_END) begin
            // OK: Full access to data memory
            violation = 1'b0;
            access_allowed = 1'b1;
        end
        
        //-------------------------------------------------------------
        // UART Protection
        //-------------------------------------------------------------
        else if (addr >= UART_START && addr <= UART_END) begin
            // OK: Can access UART
            violation = 1'b0;
            access_allowed = 1'b1;
        end
        
        //-------------------------------------------------------------
        // KEY STORE Protection - CRITICAL SECURITY FEATURE
        //-------------------------------------------------------------
        else if (addr >= KEY_STORE_START && addr <= KEY_STORE_END) begin
            if (privileged_mode) begin
                // OK: Machine mode can access keys
                violation = 1'b0;
                access_allowed = 1'b1;
            end else begin
                // VIOLATION: User mode CANNOT access keys!
                // This prevents malware from stealing encryption keys
                violation = 1'b1;
                access_allowed = 1'b0;
            end
        end
        
        //-------------------------------------------------------------
        // Unmapped Region
        //-------------------------------------------------------------
        else begin
            // VIOLATION: Accessing unmapped memory
            violation = 1'b1;
            access_allowed = 1'b0;
        end
    end

endmodule

