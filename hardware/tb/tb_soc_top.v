/*
 * Testbench for Secure RISC-V SoC
 * 
 * Tests:
 *   - Basic CPU operation
 *   - Memory access (ROM, RAM)
 *   - UART output
 *   - Boot sequence
 */

`timescale 1ns / 1ps

module tb_soc_top;

    //=================================================================
    // Clock and Reset
    //=================================================================
    reg clk = 0;
    reg rst_n = 0;
    
    // 100 MHz clock (10ns period)
    always #5 clk = ~clk;
    
    //=================================================================
    // DUT Signals
    //=================================================================
    wire uart_tx;
    wire [31:0] debug_pc;
    wire [31:0] debug_insn;
    wire trap;
    wire status_led;
    
    //=================================================================
    // Instantiate DUT
    //=================================================================
    soc_top dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .uart_tx    (uart_tx),
        .uart_rx    (1'b1),
        .debug_pc   (debug_pc),
        .debug_insn (debug_insn),
        .trap       (trap),
        .status_led (status_led)
    );
    
    //=================================================================
    // UART Monitor (bus-level, fast for simulation)
    //=================================================================
    integer uart_char_count = 0;
    
    // Instead of decoding the serial TX line (slow in simulation),
    // we snoop the memory bus and print whenever the CPU writes
    // to the UART TX register at 0x20000000. This is equivalent to
    // what the real UART does, but much faster to simulate.
    always @(posedge clk) begin
        if (rst_n &&
            dut.mem_valid && dut.mem_ready &&
            dut.uart_sel && |dut.mem_wstrb) begin
            
            // Print lowest byte of wdata as a character
            if (dut.mem_wdata[7:0] >= 32 && dut.mem_wdata[7:0] < 127) begin
                $write("%c", dut.mem_wdata[7:0]);
            end else if (dut.mem_wdata[7:0] == 8'h0A) begin
                $write("\n");
            end else if (dut.mem_wdata[7:0] == 8'h0D) begin
                // Ignore carriage return
            end else if (dut.mem_wdata[7:0] == 8'h04) begin
                $display("\n[SIM] EOT received - Test Complete");
                #100;
                $finish;
            end else begin
                $write("[0x%02h]", dut.mem_wdata[7:0]);
            end
            
            uart_char_count = uart_char_count + 1;
        end
    end
    
    //=================================================================
    // Instruction Trace (optional debug)
    //=================================================================
    reg trace_enable = 0;  // Disabled by default - too verbose
    reg [31:0] last_pc = 0;
    reg [31:0] insn_count = 0;
    
    always @(posedge clk) begin
        if (rst_n && dut.mem_valid && dut.mem_instr) begin
            insn_count = insn_count + 1;
            if (trace_enable && debug_pc != last_pc) begin
                $display("[%t] PC=0x%08h  INSN=0x%08h", $time, debug_pc, debug_insn);
                last_pc = debug_pc;
            end
        end
    end
    
    //=================================================================
    // Trap Monitor
    //=================================================================
    always @(posedge trap) begin
        $display("\n[ERROR] *** TRAP occurred at PC=0x%08h ***", debug_pc);
        $display("         Instruction: 0x%08h", debug_insn);
        #100;
        $finish;
    end
    
    //=================================================================
    // Test Control
    //=================================================================
    initial begin
        // $dumpfile("soc_simulation.vcd");
        // $dumpvars(0, tb_soc_top);
        
        // Display test header
        $display("\n================================================");
        $display("  Secure RISC-V SoC Testbench");
        $display("================================================");
        $display("Simulation started at %t", $time);
        $display("");
        
        // Hold reset for 10 clock cycles
        repeat(10) @(posedge clk);
        rst_n = 1;
        
        $display("[%t] Reset released - CPU starting...", $time);
        $display("Waiting for UART output...\n");
        
        // Run simulation
        // Need lots of cycles for:
        // - Secure boot HMAC calculation (can take millions of cycles for 65KB firmware)
        // - Anti-replay tests (multiple validation cycles)
        // - UART output (bus-level monitoring, fast)
        // Increased to 50M cycles to handle crypto operations
        repeat(50000000) @(posedge clk);
        
        // Check if we received any UART output
        $display("\n");
        $display("================================================");
        $display("  Simulation Summary");
        $display("================================================");
        $display("Instructions executed: %0d", insn_count);
        $display("UART characters received: %0d", uart_char_count);
        $display("Final PC: 0x%08h", debug_pc);
        $display("Trap status: %s", trap ? "TRAPPED" : "OK");
        $display("");
        
        if (uart_char_count > 0) begin
            $display("✓ Test PASSED - CPU executed and produced output");
        end else begin
            $display("⚠ Warning - No UART output detected");
        end
        
        $display("\nSimulation finished at %t", $time);
        $display("================================================\n");
        
        $finish;
    end
    
    //=================================================================
    // Timeout Watchdog
    //=================================================================
    initial begin
        #500_000_000; // 500ms timeout (increased for crypto operations)
        $display("\n[TIMEOUT] Simulation exceeded time limit!");
        $display("This might indicate the crypto accelerator is stuck.");
        $display("Check if HMAC calculation completed.");
        $finish;
    end

endmodule

