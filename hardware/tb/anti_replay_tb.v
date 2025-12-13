`timescale 1ns / 1ps

module anti_replay_tb;

    // Inputs
    reg clk;
    reg rst_n;
    reg [4:0] addr;
    reg we;
    reg [31:0] wdata;

    // Outputs
    wire [31:0] rdata;

    // Instantiate the Unit Under Test (UUT)
    anti_replay uut (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .we(we),
        .wdata(wdata),
        .rdata(rdata)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Register constants
    localparam ADDR_LAST_COUNTER  = 5'h00;
    localparam ADDR_CHECK_COUNTER = 5'h04;
    localparam ADDR_CHECK_NONCE   = 5'h08;
    localparam ADDR_VALIDATE      = 5'h0C;
    localparam ADDR_STATUS        = 5'h10;
    localparam ADDR_CACHE_SIZE    = 5'h14;
    localparam ADDR_CTRL          = 5'h18;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        addr = 0;
        we = 0;
        wdata = 0;

        $dumpfile("anti_replay.vcd");
        $dumpvars(0, anti_replay_tb);

        // Wait 100 ns for global reset to finish
        #100;
        rst_n = 1;
        
        $display("Starting Anti-Replay Test...");

        // Reset the module first
        write_reg(ADDR_CTRL, 3); // Reset Cache | Reset State
        #20;

        // Test 1: First valid packet
        $display("Test 1: Valid packet (Counter=1, Nonce=0xAAAA)");
        write_reg(ADDR_CHECK_COUNTER, 1);
        write_reg(ADDR_CHECK_NONCE, 32'hAAAA);
        write_reg(ADDR_VALIDATE, 1);
        #20;
        verify_status(1); // STATUS_VALID = 0th bit (1)

        // Test 2: Replay same packet (should fail)
        $display("Test 2: Replay packet (Counter=1, Nonce=0xAAAA)");
        write_reg(ADDR_CHECK_COUNTER, 1);
        write_reg(ADDR_CHECK_NONCE, 32'hAAAA);
        write_reg(ADDR_VALIDATE, 1);
        #20;
        // Logic: 0xAAAA found (Bad Nonce), 1 > 1 False (Bad Counter)
        // Bits: REPLAY(1) | BAD_COUNTER(2) | BAD_NONCE(3)
        // Val: 2 + 4 + 8 = 14
        verify_status(14); 

        // Test 3: Old counter (should fail)
        $display("Test 3: Old Counter (Counter=0, Nonce=0xBBBB)");
        write_reg(ADDR_CHECK_COUNTER, 0);
        write_reg(ADDR_CHECK_NONCE, 32'hBBBB); // New nonce
        write_reg(ADDR_VALIDATE, 1);
        #20;
        // Logic: 0 > 1 False (Bad Counter)
        // Nonce Fresh (True)
        // Bits: REPLAY(1) | BAD_COUNTER(2)
        // Val: 2 + 4 = 6.
        verify_status(6);
        
        // Test 4: New valid packet (should pass)
        $display("Test 4: New Valid Packet (Counter=2, Nonce=0xBBBB)");
        write_reg(ADDR_CHECK_COUNTER, 2);
        write_reg(ADDR_CHECK_NONCE, 32'hBBBB);
        write_reg(ADDR_VALIDATE, 1);
        #20;
        verify_status(1); // STATUS_VALID = 1

        $finish;
    end

    task write_reg;
        input [4:0] reg_addr;
        input [31:0] val;
        begin
            @(posedge clk);
            addr = reg_addr;
            wdata = val;
            we = 1;
            @(posedge clk);
            we = 0;
        end
    endtask

    // Function replaced with direct access in the test logic or verify task
    task verify_status;
        input [31:0] expected;
        begin
             if ((uut.status_reg & 32'hF) == expected) 
                 $display("  PASS: Status matches %d", expected);
             else 
                 $display("  FAIL: Expected %d, Got %d", expected, uut.status_reg & 32'hF);
        end
    endtask

endmodule
