/*
 * Monotonic Counter Module
 * 
 * Hardware counter that only increments, never decrements.
 * Used for anti-replay protection to ensure packet freshness.
 * 
 * Features:
 * - 32-bit counter (0 to 4,294,967,295)
 * - Increment-only (cannot decrement or reset to lower value)
 * - Lock mechanism (freeze counter after boot/provisioning)
 * - Overflow protection (saturates at maximum value)
 * 
 * Memory Map (base + offset):
 *   0x00: COUNTER      - Current counter value (R/W)
 *   0x04: CTRL         - Control register (W)
 *   0x08: LOCK         - Lock register (W, write 0xDEADLOCK to lock)
 *   0x0C: STATUS       - Status register (R)
 */

`timescale 1ns / 1ps

module monotonic_counter (
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
    localparam ADDR_COUNTER = 4'h0;
    localparam ADDR_CTRL    = 4'h4;
    localparam ADDR_LOCK    = 4'h8;
    localparam ADDR_STATUS  = 4'hC;

    //=================================================================
    // Control Bits
    //=================================================================
    localparam CTRL_INCREMENT = 0;
    localparam CTRL_LOAD      = 1;
    
    localparam STATUS_LOCKED   = 0;
    localparam STATUS_OVERFLOW = 1;

    //=================================================================
    // Lock Magic Value
    //=================================================================
    localparam LOCK_MAGIC = 32'hDEAD10CC;

    //=================================================================
    // Internal Registers
    //=================================================================
    reg [31:0] counter;
    reg        locked;
    reg        overflow;

    //=================================================================
    // Counter Logic
    //=================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter  <= 32'h0;
            locked   <= 1'b0;
            overflow <= 1'b0;
            
        end else if (!locked && we) begin
            case (addr)
                ADDR_CTRL: begin
                    // Increment counter
                    if (wdata[CTRL_INCREMENT]) begin
                        if (counter == 32'hFFFFFFFF) begin
                            overflow <= 1'b1;  // Saturate at max
                        end else begin
                            counter <= counter + 1;
                        end
                    end
                    
                    // Load counter: CTRL_LOAD bit triggers increment (for compatibility)
                    // Actual counter value should be written to ADDR_COUNTER register
                    if (wdata[CTRL_LOAD]) begin
                        // This is a no-op - use ADDR_COUNTER for direct writes
                        // Kept for API compatibility
                    end
                end
                
                ADDR_COUNTER: begin
                    // Direct write: only accept if value > current counter
                    if (wdata > counter && !overflow) begin
                        counter <= wdata;
                    end
                end
                
                ADDR_LOCK: begin
                    // Lock counter permanently
                    if (wdata == LOCK_MAGIC) begin
                        locked <= 1'b1;
                    end
                end
            endcase
        end
    end

    //=================================================================
    // Read Interface
    //=================================================================
    always @(*) begin
        case (addr)
            ADDR_COUNTER: rdata = counter;
            ADDR_STATUS:  rdata = {30'h0, overflow, locked};
            default:      rdata = 32'h0;
        endcase
    end

endmodule

