/*
 * HMAC-SHA256 Module
 * 
 * Implements HMAC (Hash-based Message Authentication Code) using SHA-256
 * HMAC = H((K ⊕ opad) || H((K ⊕ ipad) || message))
 * 
 * Simplified version for firmware verification:
 * - Assumes key is exactly 256 bits (32 bytes)
 * - Message read from memory via bus interface
 */

`timescale 1ns / 1ps

module hmac_sha256 (
    input  wire         clk,
    input  wire         rst_n,
    
    // Control
    input  wire         start,          // Start HMAC calculation
    input  wire [255:0] key,            // 256-bit key
    input  wire [31:0]  msg_addr,       // Message start address
    input  wire [31:0]  msg_len,        // Message length in bytes
    
    // Memory interface for reading message
    output reg  [31:0]  mem_addr,
    output reg          mem_valid,
    input  wire [31:0]  mem_rdata,
    input  wire         mem_ready,
    
    // Output
    output reg  [255:0] mac_out,        // HMAC output
    output reg          ready,          // Ready for next operation
    output reg          done            // Operation complete
);

    //=================================================================
    // HMAC Constants
    //=================================================================
    localparam [7:0] IPAD = 8'h36;
    localparam [7:0] OPAD = 8'h5C;

    //=================================================================
    // State Machine
    //=================================================================
    localparam IDLE         = 4'b0000;
    localparam PREP_INNER   = 4'b0001;
    localparam HASH_INNER   = 4'b0010;
    localparam READ_MSG     = 4'b0011;
    localparam WAIT_MSG     = 4'b0100;
    localparam FINISH_INNER = 4'b0101;
    localparam PREP_OUTER   = 4'b0110;
    localparam HASH_OUTER   = 4'b0111;
    localparam FINISH_OUTER = 4'b1000;
    localparam COMPLETE     = 4'b1001;
    
    reg [3:0] state;
    reg [31:0] byte_count;
    reg [31:0] block_count;

    //=================================================================
    // SHA-256 Instance
    //=================================================================
    reg         sha_init;
    reg         sha_next;
    reg [511:0] sha_block;
    wire [255:0] sha_hash;
    wire        sha_ready;
    
    sha256 sha_inst (
        .clk(clk),
        .rst_n(rst_n),
        .init(sha_init),
        .next_block(sha_next),
        .block_in(sha_block),
        .hash_out(sha_hash),
        .ready(sha_ready)
    );

    //=================================================================
    // Key Padding (K ⊕ ipad and K ⊕ opad)
    //=================================================================
    reg [511:0] key_ipad;  // K ⊕ 0x36 (padded to 512 bits)
    reg [511:0] key_opad;  // K ⊕ 0x5C (padded to 512 bits)
    reg [255:0] inner_hash;
    
    integer i;
    always @(*) begin
        // Prepare ipad block: (K ⊕ 0x36363636...) || padding
        for (i = 0; i < 32; i = i + 1) begin
            key_ipad[511 - i*8 -: 8] = key[255 - i*8 -: 8] ^ IPAD;
            key_opad[511 - i*8 -: 8] = key[255 - i*8 -: 8] ^ OPAD;
        end
        // Pad rest with ipad/opad
        for (i = 32; i < 64; i = i + 1) begin
            key_ipad[511 - i*8 -: 8] = IPAD;
            key_opad[511 - i*8 -: 8] = OPAD;
        end
    end

    //=================================================================
    // Message Buffer (for building 512-bit blocks)
    //=================================================================
    reg [511:0] msg_block;
    reg [9:0]   msg_block_bytes;  // Bytes in current block (0-64)

    //=================================================================
    // Main State Machine
    //=================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ready <= 1'b1;
            done <= 1'b0;
            sha_init <= 1'b0;
            sha_next <= 1'b0;
            mem_valid <= 1'b0;
            byte_count <= 0;
            block_count <= 0;
            mac_out <= 256'h0;
            
        end else begin
            // Default: deassert control signals
            sha_init <= 1'b0;
            sha_next <= 1'b0;
            mem_valid <= 1'b0;
            
            case (state)
                IDLE: begin
                    ready <= 1'b1;
                    done <= 1'b0;
                    
                    if (start) begin
                        ready <= 1'b0;
                        state <= PREP_INNER;
                        byte_count <= 0;
                        block_count <= 0;
                        msg_block_bytes <= 0;
                    end
                end
                
                //==========================================================
                // INNER HASH: H((K ⊕ ipad) || message)
                //==========================================================
                PREP_INNER: begin
                    // Initialize SHA-256 for inner hash
                    sha_init <= 1'b1;
                    state <= HASH_INNER;
                end
                
                HASH_INNER: begin
                    if (sha_ready) begin
                        // Hash the (K ⊕ ipad) block first
                        sha_block <= key_ipad;
                        sha_next <= 1'b1;
                        state <= READ_MSG;
                        mem_addr <= msg_addr;
                    end
                end
                
                READ_MSG: begin
                    if (sha_ready) begin
                        if (byte_count < msg_len) begin
                            // Read next word from memory
                            mem_valid <= 1'b1;
                            state <= WAIT_MSG;
                        end else begin
                            // Message complete, finalize with padding
                            state <= FINISH_INNER;
                        end
                    end
                end
                
                WAIT_MSG: begin
                    if (mem_ready) begin
                        // Store word in message block
                        msg_block[511 - msg_block_bytes*8 -: 32] <= mem_rdata;
                        msg_block_bytes <= msg_block_bytes + 4;
                        byte_count <= byte_count + 4;
                        mem_addr <= mem_addr + 4;
                        
                        if (msg_block_bytes == 60) begin
                            // Block full, hash it
                            sha_block <= msg_block;
                            sha_next <= 1'b1;
                            msg_block_bytes <= 0;
                            state <= READ_MSG;
                        end else begin
                            state <= READ_MSG;
                        end
                    end
                end
                
                FINISH_INNER: begin
                    if (sha_ready) begin
                        // Add SHA-256 padding: 0x80 || zeros || length
                        // Simplified: assume message fits in remaining block space
                        msg_block[511 - msg_block_bytes*8 -: 8] <= 8'h80;
                        
                        // Add length in bits at end (last 64 bits)
                        // Total length = 64 bytes (ipad block) + msg_len
                        msg_block[63:0] <= {32'h0, ((32'd64 + msg_len) << 3)};
                        
                        sha_block <= msg_block;
                        sha_next <= 1'b1;
                        state <= PREP_OUTER;
                    end
                end
                
                //==========================================================
                // OUTER HASH: H((K ⊕ opad) || inner_hash)
                //==========================================================
                PREP_OUTER: begin
                    if (sha_ready) begin
                        // Save inner hash
                        inner_hash <= sha_hash;
                        
                        // Initialize for outer hash
                        sha_init <= 1'b1;
                        state <= HASH_OUTER;
                    end
                end
                
                HASH_OUTER: begin
                    if (sha_ready) begin
                        // Hash (K ⊕ opad) block
                        sha_block <= key_opad;
                        sha_next <= 1'b1;
                        state <= FINISH_OUTER;
                    end
                end
                
                FINISH_OUTER: begin
                    if (sha_ready) begin
                        // Hash inner_hash with padding
                        sha_block[511:256] <= inner_hash;
                        sha_block[255:248] <= 8'h80;  // Padding
                        sha_block[247:64] <= 184'h0;  // Zeros
                        sha_block[63:0] <= 64'd768;   // Length: (64 + 32) * 8 = 768 bits
                        
                        sha_next <= 1'b1;
                        state <= COMPLETE;
                    end
                end
                
                COMPLETE: begin
                    if (sha_ready) begin
                        mac_out <= sha_hash;
                        done <= 1'b1;
                        state <= IDLE;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

