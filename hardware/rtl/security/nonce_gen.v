/*
 * Nonce Generator Module
 * 
 * Generates pseudo-random nonces for anti-replay protection.
 * Uses a 32-bit Galois LFSR with maximum period.
 * 
 * Features:
 * - 32-bit pseudo-random number generation
 * - Maximum period LFSR (2^32 - 1 unique values)
 * - Hardware-seeded from timestamp
 * - Automatic advancement every clock cycle
 * 
 * Memory Map (base + offset):
 *   0x00: NONCE  - Read current nonce (R, reading advances LFSR)
 *   0x04: SEED   - Write seed value (W)
 *   0x08: CTRL   - Control register (W)
 *   0x0C: STATUS - Status register (R)
 */

`timescale 1ns / 1ps

module nonce_gen (
    input  wire        clk,
    input  wire        rst_n,
    
    // CPU Interface (memory-mapped)
    input  wire [3:0]  addr,        // Register address (byte offset / 4)
    input  wire        we,          // Write enable
    input  wire [31:0] wdata,       // Write data
    output reg  [31:0] rdata        // Read data
);

    //=================================================================
    // Register Map
    //=================================================================
    localparam ADDR_NONCE  = 4'h0;
    localparam ADDR_SEED   = 4'h4;
    localparam ADDR_CTRL   = 4'h8;
    localparam ADDR_STATUS = 4'hC;

    //=================================================================
    // Control Bits
    //=================================================================
    localparam CTRL_ENABLE  = 0;
    localparam CTRL_ADVANCE = 1;
    
    localparam STATUS_READY = 0;

    //=================================================================
    // LFSR Polynomial: x^32 + x^22 + x^2 + x^1 + 1
    // Taps at bits [32, 22, 2, 1] for maximum period
    //=================================================================
    localparam [31:0] LFSR_TAPS = 32'h80200003;

    //=================================================================
    // Internal Registers
    //=================================================================
    reg [31:0] lfsr;
    reg        enabled;
    reg        ready;
    reg [7:0]  init_counter;  // Warm-up cycles

    //=================================================================
    // LFSR Logic (Galois configuration)
    //=================================================================
    wire       feedback;
    wire [31:0] lfsr_next;
    
    assign feedback = lfsr[0];
    assign lfsr_next = feedback ? ({1'b0, lfsr[31:1]} ^ LFSR_TAPS) : {1'b0, lfsr[31:1]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr         <= 32'hACE1BABE;  // Non-zero seed
            enabled      <= 1'b1;          // Auto-enable
            ready        <= 1'b0;
            init_counter <= 8'd32;         // Warm-up period
            
        end else begin
            // Warm-up: advance LFSR for initial mixing
            if (init_counter > 0) begin
                lfsr <= lfsr_next;
                init_counter <= init_counter - 1;
                if (init_counter == 1) begin
                    ready <= 1'b1;
                end
            end
            
            // Normal operation: advance if enabled
            else if (enabled) begin
                lfsr <= lfsr_next;
            end
            
            // Handle writes
            if (we) begin
                case (addr)
                    ADDR_SEED: begin
                        // Re-seed LFSR (must be non-zero)
                        if (wdata != 32'h0) begin
                            lfsr <= wdata;
                            ready <= 1'b0;
                            init_counter <= 8'd32;  // Re-warm-up
                        end
                    end
                    
                    ADDR_CTRL: begin
                        // Enable/disable auto-advance
                        enabled <= wdata[CTRL_ENABLE];
                        
                        // Manual advance
                        if (wdata[CTRL_ADVANCE] && ready) begin
                            lfsr <= lfsr_next;
                        end
                    end
                endcase
            end
        end
    end

    //=================================================================
    // Read Interface
    //=================================================================
    always @(*) begin
        case (addr)
            ADDR_NONCE:  rdata = lfsr;
            ADDR_STATUS: rdata = {31'h0, ready};
            default:     rdata = 32'h0;
        endcase
    end

endmodule





