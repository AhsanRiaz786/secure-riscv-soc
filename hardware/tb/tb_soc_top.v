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
    // UART Monitor (captures transmitted characters)
    //=================================================================
    reg [7:0] uart_rx_byte;
    integer uart_char_count = 0;
    
    // Simple UART RX monitor (baud rate 115200)
    localparam UART_BIT_PERIOD = 8680; // ns for 115200 baud
    
    task uart_rx_monitor;
        integer i;
        begin
            @(negedge uart_tx); // Wait for start bit
            #(UART_BIT_PERIOD / 2); // Sample in middle of start bit
            #UART_BIT_PERIOD; // Skip start bit
            
            // Receive 8 data bits
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx_byte[i] = uart_tx;
                #UART_BIT_PERIOD;
            end
            
            // Stop bit
            #UART_BIT_PERIOD;
            
            // Display character
            if (uart_rx_byte >= 32 && uart_rx_byte < 127) begin
                $write("%c", uart_rx_byte);
            end else if (uart_rx_byte == 8'h0A) begin
                $write("\n");
            end else if (uart_rx_byte == 8'h0D) begin
                // Carriage return - ignore
            end else begin
                $write("[0x%h]", uart_rx_byte);
            end
            
            uart_char_count = uart_char_count + 1;
        end
    endtask
    
    // Monitor UART continuously
    initial begin
        forever begin
            uart_rx_monitor();
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
        $dumpfile("soc_simulation.vcd");
        $dumpvars(0, tb_soc_top);
        
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
        // Let it run for a while (adjust as needed)
        repeat(50000) @(posedge clk);
        
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
        #100_000_000; // 100ms timeout
        $display("\n[TIMEOUT] Simulation exceeded time limit!");
        $finish;
    end

endmodule

