/*
 * SHA-256 Hardware Accelerator
 * 
 * Implements SHA-256 cryptographic hash function
 * Based on FIPS 180-4 specification
 * 
 * Features:
 * - Processes 512-bit blocks
 * - Outputs 256-bit hash
 * - ~64 clock cycles per block
 */

`timescale 1ns / 1ps

module sha256 (
    input  wire         clk,
    input  wire         rst_n,
    
    // Control
    input  wire         init,           // Initialize hash state
    input  wire         next_block,     // Process next block
    input  wire [511:0] block_in,       // Input block (512 bits)
    
    // Output
    output reg  [255:0] hash_out,       // Hash output
    output reg          ready           // Ready for next operation
);

    //=================================================================
    // SHA-256 Constants (first 32 bits of fractional parts of cube roots of first 64 primes)
    //=================================================================
    reg [31:0] K [0:63];
    initial begin
        K[0]  = 32'h428a2f98; K[1]  = 32'h71374491; K[2]  = 32'hb5c0fbcf; K[3]  = 32'he9b5dba5;
        K[4]  = 32'h3956c25b; K[5]  = 32'h59f111f1; K[6]  = 32'h923f82a4; K[7]  = 32'hab1c5ed5;
        K[8]  = 32'hd807aa98; K[9]  = 32'h12835b01; K[10] = 32'h243185be; K[11] = 32'h550c7dc3;
        K[12] = 32'h72be5d74; K[13] = 32'h80deb1fe; K[14] = 32'h9bdc06a7; K[15] = 32'hc19bf174;
        K[16] = 32'he49b69c1; K[17] = 32'hefbe4786; K[18] = 32'h0fc19dc6; K[19] = 32'h240ca1cc;
        K[20] = 32'h2de92c6f; K[21] = 32'h4a7484aa; K[22] = 32'h5cb0a9dc; K[23] = 32'h76f988da;
        K[24] = 32'h983e5152; K[25] = 32'ha831c66d; K[26] = 32'hb00327c8; K[27] = 32'hbf597fc7;
        K[28] = 32'hc6e00bf3; K[29] = 32'hd5a79147; K[30] = 32'h06ca6351; K[31] = 32'h14292967;
        K[32] = 32'h27b70a85; K[33] = 32'h2e1b2138; K[34] = 32'h4d2c6dfc; K[35] = 32'h53380d13;
        K[36] = 32'h650a7354; K[37] = 32'h766a0abb; K[38] = 32'h81c2c92e; K[39] = 32'h92722c85;
        K[40] = 32'ha2bfe8a1; K[41] = 32'ha81a664b; K[42] = 32'hc24b8b70; K[43] = 32'hc76c51a3;
        K[44] = 32'hd192e819; K[45] = 32'hd6990624; K[46] = 32'hf40e3585; K[47] = 32'h106aa070;
        K[48] = 32'h19a4c116; K[49] = 32'h1e376c08; K[50] = 32'h2748774c; K[51] = 32'h34b0bcb5;
        K[52] = 32'h391c0cb3; K[53] = 32'h4ed8aa4a; K[54] = 32'h5b9cca4f; K[55] = 32'h682e6ff3;
        K[56] = 32'h748f82ee; K[57] = 32'h78a5636f; K[58] = 32'h84c87814; K[59] = 32'h8cc70208;
        K[60] = 32'h90befffa; K[61] = 32'ha4506ceb; K[62] = 32'hbef9a3f7; K[63] = 32'hc67178f2;
    end

    //=================================================================
    // Initial Hash Values (first 32 bits of fractional parts of square roots of first 8 primes)
    //=================================================================
    localparam [31:0] H0_INIT = 32'h6a09e667;
    localparam [31:0] H1_INIT = 32'hbb67ae85;
    localparam [31:0] H2_INIT = 32'h3c6ef372;
    localparam [31:0] H3_INIT = 32'ha54ff53a;
    localparam [31:0] H4_INIT = 32'h510e527f;
    localparam [31:0] H5_INIT = 32'h9b05688c;
    localparam [31:0] H6_INIT = 32'h1f83d9ab;
    localparam [31:0] H7_INIT = 32'h5be0cd19;

    //=================================================================
    // State Machine
    //=================================================================
    localparam IDLE        = 2'b00;
    localparam PROCESS     = 2'b01;
    localparam FINALIZE    = 2'b10;
    
    reg [1:0] state;
    reg [6:0] round;

    //=================================================================
    // Working Variables
    //=================================================================
    reg [31:0] H [0:7];     // Hash state
    reg [31:0] W [0:63];    // Message schedule
    reg [31:0] a, b, c, d, e, f, g, h;
    reg [31:0] T1, T2;

    //=================================================================
    // SHA-256 Functions
    //=================================================================
    function [31:0] Ch;
        input [31:0] x, y, z;
        begin
            Ch = (x & y) ^ (~x & z);
        end
    endfunction

    function [31:0] Maj;
        input [31:0] x, y, z;
        begin
            Maj = (x & y) ^ (x & z) ^ (y & z);
        end
    endfunction

    function [31:0] Sigma0;
        input [31:0] x;
        begin
            Sigma0 = {x[1:0], x[31:2]} ^ {x[12:0], x[31:13]} ^ {x[21:0], x[31:22]};
        end
    endfunction

    function [31:0] Sigma1;
        input [31:0] x;
        begin
            Sigma1 = {x[5:0], x[31:6]} ^ {x[10:0], x[31:11]} ^ {x[24:0], x[31:25]};
        end
    endfunction

    function [31:0] sigma0;
        input [31:0] x;
        begin
            sigma0 = {x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ (x >> 3);
        end
    endfunction

    function [31:0] sigma1;
        input [31:0] x;
        begin
            sigma1 = {x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ (x >> 10);
        end
    endfunction

    //=================================================================
    // Message Schedule Generation
    //=================================================================
    integer i;
    always @(*) begin
        // First 16 words from input block (big-endian)
        for (i = 0; i < 16; i = i + 1) begin
            W[i] = block_in[511 - i*32 -: 32];
        end
        
        // Extend to 64 words
        for (i = 16; i < 64; i = i + 1) begin
            W[i] = sigma1(W[i-2]) + W[i-7] + sigma0(W[i-15]) + W[i-16];
        end
    end

    //=================================================================
    // Main State Machine
    //=================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            round <= 0;
            ready <= 1'b1;
            
            // Initialize hash values
            H[0] <= H0_INIT;
            H[1] <= H1_INIT;
            H[2] <= H2_INIT;
            H[3] <= H3_INIT;
            H[4] <= H4_INIT;
            H[5] <= H5_INIT;
            H[6] <= H6_INIT;
            H[7] <= H7_INIT;
            
            hash_out <= {H0_INIT, H1_INIT, H2_INIT, H3_INIT, H4_INIT, H5_INIT, H6_INIT, H7_INIT};
            
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b1;
                    
                    if (init) begin
                        // Reset to initial hash values
                        H[0] <= H0_INIT;
                        H[1] <= H1_INIT;
                        H[2] <= H2_INIT;
                        H[3] <= H3_INIT;
                        H[4] <= H4_INIT;
                        H[5] <= H5_INIT;
                        H[6] <= H6_INIT;
                        H[7] <= H7_INIT;
                        
                    end else if (next_block) begin
                        // Start processing new block
                        ready <= 1'b0;
                        state <= PROCESS;
                        round <= 0;
                        
                        // Initialize working variables
                        a <= H[0];
                        b <= H[1];
                        c <= H[2];
                        d <= H[3];
                        e <= H[4];
                        f <= H[5];
                        g <= H[6];
                        h <= H[7];
                    end
                end
                
                PROCESS: begin
                    // Perform one round of SHA-256 compression
                    T1 = h + Sigma1(e) + Ch(e, f, g) + K[round] + W[round];
                    T2 = Sigma0(a) + Maj(a, b, c);
                    
                    h <= g;
                    g <= f;
                    f <= e;
                    e <= d + T1;
                    d <= c;
                    c <= b;
                    b <= a;
                    a <= T1 + T2;
                    
                    if (round == 63) begin
                        state <= FINALIZE;
                    end else begin
                        round <= round + 1;
                    end
                end
                
                FINALIZE: begin
                    // Add compressed chunk to hash values
                    H[0] <= H[0] + a;
                    H[1] <= H[1] + b;
                    H[2] <= H[2] + c;
                    H[3] <= H[3] + d;
                    H[4] <= H[4] + e;
                    H[5] <= H[5] + f;
                    H[6] <= H[6] + g;
                    H[7] <= H[7] + h;
                    
                    // Update output
                    hash_out <= {H[0] + a, H[1] + b, H[2] + c, H[3] + d,
                                H[4] + e, H[5] + f, H[6] + g, H[7] + h};
                    
                    state <= IDLE;
                    ready <= 1'b1;
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

