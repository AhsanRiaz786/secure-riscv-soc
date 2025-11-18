/*
 * Crypto Accelerator - Memory-Mapped Peripheral
 * 
 * Provides CPU interface to cryptographic operations:
 * - SHA-256 hashing
 * - HMAC-SHA256 authentication
 * 
 * Base Address: 0x30000000
 * 
 * Register Map:
 *   0x00: CTRL       - Control register
 *   0x04: STATUS     - Status register
 *   0x08: MODE       - Operation mode
 *   0x0C: MSG_ADDR   - Message address
 *   0x10: MSG_LEN    - Message length
 *   0x14-0x30: KEY   - Key registers (8 x 32-bit)
 *   0x40-0x5C: HASH  - Output hash (8 x 32-bit)
 */

`timescale 1ns / 1ps

module crypto_accelerator (
    input  wire        clk,
    input  wire        rst_n,
    
    // CPU Interface (memory-mapped)
    input  wire [7:0]  addr,           // Register address (byte offset / 4)
    input  wire        we,             // Write enable
    input  wire [31:0] wdata,          // Write data
    output reg  [31:0] rdata,          // Read data
    
    // Memory Interface (for HMAC to read firmware)
    output wire [31:0] mem_addr,
    output wire        mem_valid,
    input  wire [31:0] mem_rdata,
    input  wire        mem_ready
);

    //=================================================================
    // Register Map
    //=================================================================
    localparam ADDR_CTRL     = 8'h00;
    localparam ADDR_STATUS   = 8'h04;
    localparam ADDR_MODE     = 8'h08;
    localparam ADDR_MSG_ADDR = 8'h0C;
    localparam ADDR_MSG_LEN  = 8'h10;
    localparam ADDR_KEY_BASE = 8'h14;  // 0x14-0x30 (8 words)
    localparam ADDR_HASH_BASE = 8'h40; // 0x40-0x5C (8 words)

    //=================================================================
    // Control/Status Bits
    //=================================================================
    localparam CTRL_START = 0;
    localparam CTRL_RESET = 1;
    
    localparam STATUS_BUSY  = 0;
    localparam STATUS_DONE  = 1;
    localparam STATUS_ERROR = 2;
    
    localparam MODE_SHA256      = 2'b00;
    localparam MODE_HMAC_SHA256 = 2'b01;

    //=================================================================
    // Registers
    //=================================================================
    reg [31:0] ctrl_reg;
    reg [31:0] status_reg;
    reg [31:0] mode_reg;
    reg [31:0] msg_addr_reg;
    reg [31:0] msg_len_reg;
    reg [31:0] key_reg [0:7];
    reg [31:0] hash_reg [0:7];

    //=================================================================
    // HMAC Instance
    //=================================================================
    reg         hmac_start;
    wire [255:0] hmac_key;
    wire [255:0] hmac_mac;
    wire        hmac_ready;
    wire        hmac_done;
    
    // Pack key registers into 256-bit vector
    assign hmac_key = {key_reg[0], key_reg[1], key_reg[2], key_reg[3],
                      key_reg[4], key_reg[5], key_reg[6], key_reg[7]};
    
    hmac_sha256 hmac_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(hmac_start),
        .key(hmac_key),
        .msg_addr(msg_addr_reg),
        .msg_len(msg_len_reg),
        .mem_addr(mem_addr),
        .mem_valid(mem_valid),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready),
        .mac_out(hmac_mac),
        .ready(hmac_ready),
        .done(hmac_done)
    );

    //=================================================================
    // Control Logic
    //=================================================================
    reg operation_active;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operation_active <= 1'b0;
            hmac_start <= 1'b0;
            status_reg <= 32'h0;
            ctrl_reg <= 32'h0;
            hash_reg[0] <= 32'h0;
            hash_reg[1] <= 32'h0;
            hash_reg[2] <= 32'h0;
            hash_reg[3] <= 32'h0;
            hash_reg[4] <= 32'h0;
            hash_reg[5] <= 32'h0;
            hash_reg[6] <= 32'h0;
            hash_reg[7] <= 32'h0;
            
        end else begin
            // Default: clear one-shot signals
            hmac_start <= 1'b0;
            
            // Handle START command
            if (ctrl_reg[CTRL_START] && !operation_active) begin
                operation_active <= 1'b1;
                status_reg[STATUS_BUSY] <= 1'b1;
                status_reg[STATUS_DONE] <= 1'b0;
                
                // Start appropriate operation based on mode
                if (mode_reg[1:0] == MODE_HMAC_SHA256) begin
                    hmac_start <= 1'b1;
                end
                
                // Clear start bit
                ctrl_reg[CTRL_START] <= 1'b0;
            end
            
            // Check for completion
            if (operation_active && hmac_done) begin
                operation_active <= 1'b0;
                status_reg[STATUS_BUSY] <= 1'b0;
                status_reg[STATUS_DONE] <= 1'b1;
                
                // Store result
                hash_reg[0] <= hmac_mac[255:224];
                hash_reg[1] <= hmac_mac[223:192];
                hash_reg[2] <= hmac_mac[191:160];
                hash_reg[3] <= hmac_mac[159:128];
                hash_reg[4] <= hmac_mac[127:96];
                hash_reg[5] <= hmac_mac[95:64];
                hash_reg[6] <= hmac_mac[63:32];
                hash_reg[7] <= hmac_mac[31:0];
            end
            
            // Handle RESET
            if (ctrl_reg[CTRL_RESET]) begin
                operation_active <= 1'b0;
                status_reg <= 32'h0;
                ctrl_reg[CTRL_RESET] <= 1'b0;
            end
        end
    end

    //=================================================================
    // Register Write Interface
    //=================================================================
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mode_reg <= 32'h0;
            msg_addr_reg <= 32'h0;
            msg_len_reg <= 32'h0;
            for (i = 0; i < 8; i = i + 1) begin
                key_reg[i] <= 32'h0;
            end
            
        end else if (we) begin
            case (addr)
                ADDR_CTRL: begin
                    ctrl_reg <= wdata;
                end
                
                ADDR_MODE: begin
                    mode_reg <= wdata;
                end
                
                ADDR_MSG_ADDR: begin
                    msg_addr_reg <= wdata;
                end
                
                ADDR_MSG_LEN: begin
                    msg_len_reg <= wdata;
                end
                
                // Key registers (0x14-0x30)
                8'h14: key_reg[0] <= wdata;
                8'h18: key_reg[1] <= wdata;
                8'h1C: key_reg[2] <= wdata;
                8'h20: key_reg[3] <= wdata;
                8'h24: key_reg[4] <= wdata;
                8'h28: key_reg[5] <= wdata;
                8'h2C: key_reg[6] <= wdata;
                8'h30: key_reg[7] <= wdata;
                
                default: begin
                    // Read-only or invalid address
                end
            endcase
        end
    end

    //=================================================================
    // Register Read Interface
    //=================================================================
    always @(*) begin
        case (addr)
            ADDR_CTRL:     rdata = ctrl_reg;
            ADDR_STATUS:   rdata = status_reg;
            ADDR_MODE:     rdata = mode_reg;
            ADDR_MSG_ADDR: rdata = msg_addr_reg;
            ADDR_MSG_LEN:  rdata = msg_len_reg;
            
            // Key registers
            8'h14: rdata = key_reg[0];
            8'h18: rdata = key_reg[1];
            8'h1C: rdata = key_reg[2];
            8'h20: rdata = key_reg[3];
            8'h24: rdata = key_reg[4];
            8'h28: rdata = key_reg[5];
            8'h2C: rdata = key_reg[6];
            8'h30: rdata = key_reg[7];
            
            // Hash output registers
            8'h40: rdata = hash_reg[0];
            8'h44: rdata = hash_reg[1];
            8'h48: rdata = hash_reg[2];
            8'h4C: rdata = hash_reg[3];
            8'h50: rdata = hash_reg[4];
            8'h54: rdata = hash_reg[5];
            8'h58: rdata = hash_reg[6];
            8'h5C: rdata = hash_reg[7];
            
            default: rdata = 32'h0;
        endcase
    end

endmodule

