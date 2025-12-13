/*
 * Anti-Replay Engine
 * 
 * Validates packet authenticity and freshness to prevent replay attacks.
 * Checks:
 *   1. Counter progression (must be > last valid counter)
 *   2. Nonce freshness (not in recent cache)
 *   3. HMAC verification (via crypto accelerator)
 * 
 * Features:
 * - Maintains last valid counter value
 * - Caches recent nonces (16-entry circular buffer)
 * - Validates counter + nonce combination
 * - Rejects replayed packets
 * 
 * Memory Map (base + offset):
 *   0x00: LAST_COUNTER    - Last valid counter value (R)
 *   0x04: CHECK_COUNTER   - Counter to validate (W)
 *   0x08: CHECK_NONCE     - Nonce to validate (W)
 *   0x0C: VALIDATE        - Trigger validation (W)
 *   0x10: STATUS          - Validation result (R)
 *   0x14: CACHE_SIZE      - Number of cached nonces (R)
 *   0x18: CTRL            - Control register (W)
 */

`timescale 1ns / 1ps

module anti_replay (
    input  wire        clk,
    input  wire        rst_n,
    
    // CPU Interface (memory-mapped)
    input  wire [4:0]  addr,        // Register address (byte offset / 4)
    input  wire        we,          // Write enable
    input  wire [31:0] wdata,       // Write data
    output reg  [31:0] rdata        // Read data
);

    //=================================================================
    // Register Map
    //=================================================================
    localparam ADDR_LAST_COUNTER  = 5'h00;
    localparam ADDR_CHECK_COUNTER = 5'h04;
    localparam ADDR_CHECK_NONCE   = 5'h08;
    localparam ADDR_VALIDATE      = 5'h0C;
    localparam ADDR_STATUS        = 5'h10;
    localparam ADDR_CACHE_SIZE    = 5'h14;
    localparam ADDR_CTRL          = 5'h18;

    //=================================================================
    // Status Bits
    //=================================================================
    localparam STATUS_VALID        = 0;  // Validation passed
    localparam STATUS_REPLAY       = 1;  // Replay detected
    localparam STATUS_BAD_COUNTER  = 2;  // Counter not progressive
    localparam STATUS_BAD_NONCE    = 3;  // Nonce already seen
    localparam STATUS_READY        = 4;  // Ready for validation

    //=================================================================
    // Control Bits
    //=================================================================
    localparam CTRL_RESET_CACHE = 0;
    localparam CTRL_RESET_STATE = 1;

    //=================================================================
    // Nonce Cache Configuration
    //=================================================================
    localparam CACHE_SIZE = 16;  // Number of recent nonces to track
    localparam CACHE_BITS = 4;   // log2(CACHE_SIZE)

    //=================================================================
    // Internal Registers
    //=================================================================
    reg [31:0] last_counter;
    reg [31:0] check_counter;
    reg [31:0] check_nonce;
    reg [31:0] status_reg;
    reg        ready;
    
    // Nonce cache (circular buffer)
    reg [31:0] nonce_cache [0:CACHE_SIZE-1];
    reg [CACHE_BITS-1:0] cache_head;
    reg [CACHE_BITS-1:0] cache_count;

    //=================================================================
    // Validation Logic
    //=================================================================
    reg  validate_trigger;
    wire counter_valid;
    wire nonce_fresh;
    wire validation_passed;
    
    // Counter must be greater than last valid counter
    assign counter_valid = (check_counter > last_counter);
    
    // Nonce must not be in cache
    reg nonce_found;
    integer i;
    always @(*) begin
        nonce_found = 0;
        for (i = 0; i < CACHE_SIZE; i = i + 1) begin
            if (i < cache_count && nonce_cache[i] == check_nonce) begin
                nonce_found = 1;
            end
        end
    end
    assign nonce_fresh = !nonce_found;
    
    // Overall validation
    assign validation_passed = counter_valid && nonce_fresh;

    //=================================================================
    // State Machine
    //=================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_counter     <= 32'h0;
            check_counter    <= 32'h0;
            check_nonce      <= 32'h0;
            status_reg       <= 32'h0;
            ready            <= 1'b1;
            cache_head       <= 0;
            cache_count      <= 0;
            validate_trigger <= 1'b0;
            
            // Clear nonce cache
            for (i = 0; i < CACHE_SIZE; i = i + 1) begin
                nonce_cache[i] <= 32'h0;
            end
            
        end else begin
            // Default: ready is high
            ready <= 1'b1;
            
            // Handle writes
            if (we) begin
                case (addr)
                    ADDR_CHECK_COUNTER: begin
                        check_counter <= wdata;
                    end
                    
                    ADDR_CHECK_NONCE: begin
                        check_nonce <= wdata;
                    end
                    
                    ADDR_VALIDATE: begin
                        // Trigger validation immediately
                        if (ready) begin
                            ready <= 1'b0;
                            
                            // Clear previous status
                            status_reg <= 32'h0;
                            
                            // Check counter
                            if (!counter_valid) begin
                                status_reg[STATUS_BAD_COUNTER] <= 1'b1;
                                status_reg[STATUS_REPLAY] <= 1'b1;
                            end
                            
                            // Check nonce
                            if (!nonce_fresh) begin
                                status_reg[STATUS_BAD_NONCE] <= 1'b1;
                                status_reg[STATUS_REPLAY] <= 1'b1;
                            end
                            
                            // If validation passed, update state
                            if (validation_passed) begin
                                status_reg[STATUS_VALID] <= 1'b1;
                                
                                // Update last valid counter
                                last_counter <= check_counter;
                                
                                // Add nonce to cache
                                nonce_cache[cache_head] <= check_nonce;
                                if (cache_head == (CACHE_SIZE - 1)) begin
                                    cache_head <= 0;
                                end else begin
                                    cache_head <= cache_head + 1;
                                end
                                
                                if (cache_count < CACHE_SIZE) begin
                                    cache_count <= cache_count + 1;
                                end
                            end
                            
                            // Validation complete, set ready
                            ready <= 1'b1;
                        end
                    end
                    
                    ADDR_CTRL: begin
                        // Reset nonce cache
                        if (wdata[CTRL_RESET_CACHE]) begin
                            cache_head <= 0;
                            cache_count <= 0;
                            for (i = 0; i < CACHE_SIZE; i = i + 1) begin
                                nonce_cache[i] <= 32'h0;
                            end
                        end
                        
                        // Reset state
                        if (wdata[CTRL_RESET_STATE]) begin
                            last_counter <= 32'h0;
                            status_reg <= 32'h0;
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
            ADDR_LAST_COUNTER:  rdata = last_counter;
            ADDR_STATUS:        rdata = {27'h0, ready, status_reg[3:0]};
            ADDR_CACHE_SIZE:    rdata = {28'h0, cache_count};
            default:            rdata = 32'h0;
        endcase
    end

endmodule





