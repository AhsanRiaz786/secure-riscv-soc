/*
 * Secure RISC-V SoC - Top Level Module
 * 
 * Integrates:
 *   - PicoRV32 CPU core (RV32I)
 *   - Boot ROM (4KB) - Secure bootloader
 *   - Instruction Memory (64KB) - Application firmware
 *   - Data Memory (64KB) - Stack, heap, variables
 *   - UART - Debug console
 *   - Future: MPU, Crypto Accelerator, Key Store
 *
 * Memory Map:
 *   0x00000000 - 0x00000FFF : Boot ROM (4KB, read-only)
 *   0x00010000 - 0x0001FFFF : Instruction Memory (64KB)
 *   0x10000000 - 0x1000FFFF : Data Memory (64KB)
 *   0x20000000 - 0x200000FF : UART
 *   0x30000000 - 0x300000FF : Crypto Accelerator
 *   0x40000000 - 0x400000FF : Key Store
 *   0x50000000 - 0x500000FF : Anti-Replay Protection
 */

`timescale 1ns / 1ps

module soc_top (
    input  wire clk,
    input  wire rst_n,
    
    // UART signals
    output wire uart_tx,
    input  wire uart_rx,
    
    // Debug signals
    output wire [31:0] debug_pc,
    output wire [31:0] debug_insn,
    output wire        trap,
    
    // Status LED (optional)
    output wire status_led
);

    //=================================================================
    // CPU Memory Interface Signals
    //=================================================================
    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;
    
    //=================================================================
    // Memory Region Selection
    //=================================================================
    wire boot_rom_sel   = (mem_addr >= 32'h00000000 && mem_addr < 32'h00001000);
    wire instr_mem_sel  = (mem_addr >= 32'h00010000 && mem_addr < 32'h00020000);
    wire data_mem_sel   = (mem_addr >= 32'h10000000 && mem_addr < 32'h10010000);
    wire uart_sel       = (mem_addr >= 32'h20000000 && mem_addr < 32'h20000100);
    wire crypto_sel     = (mem_addr >= 32'h30000000 && mem_addr < 32'h30000100);
    wire anti_replay_sel = (mem_addr >= 32'h50000000 && mem_addr < 32'h50000100);
    
    //=================================================================
    // Memory Read Data Signals
    //=================================================================
    wire [31:0] boot_rom_rdata;
    wire [31:0] instr_mem_rdata;
    wire [31:0] data_mem_rdata;
    wire [31:0] uart_rdata;
    wire [31:0] crypto_rdata;
    wire [31:0] anti_replay_rdata;
    
    //=================================================================
    // Memory Protection Unit (MPU)
    //=================================================================
    wire mpu_violation;
    wire mpu_access_allowed;
    
    // Privilege mode: 0 = user mode, 1 = machine mode
    // For now, always run in user mode to test MPU
    // TODO: Connect to actual CPU privilege level when available
    wire privileged_mode = 1'b0;
    
    mpu mpu_inst (
        .addr(mem_addr),
        .is_write(|mem_wstrb),           // Any write strobe active?
        .is_exec(mem_instr),              // Instruction fetch?
        .privileged_mode(privileged_mode),
        .violation(mpu_violation),
        .access_allowed(mpu_access_allowed)
    );
    
    // Generate trap signal when MPU detects violation during valid access
    wire mpu_trap = mpu_violation && mem_valid;
    
    //=================================================================
    // PicoRV32 CPU Core
    //=================================================================
    wire cpu_trap;  // CPU's own trap signal
    
    picorv32 #(
        .ENABLE_COUNTERS(1),
        .ENABLE_COUNTERS64(1),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .LATCHED_MEM_RDATA(0),
        .TWO_STAGE_SHIFT(1),
        .BARREL_SHIFTER(0),
        .TWO_CYCLE_COMPARE(0),
        .TWO_CYCLE_ALU(0),
        .COMPRESSED_ISA(0),
        .CATCH_MISALIGN(1),
        .CATCH_ILLINSN(1),
        .ENABLE_PCPI(0),
        .ENABLE_MUL(1),
        .ENABLE_FAST_MUL(0),
        .ENABLE_DIV(1),
        .ENABLE_IRQ(1),
        .ENABLE_IRQ_QREGS(1),
        .ENABLE_IRQ_TIMER(1),
        .ENABLE_TRACE(0),
        .REGS_INIT_ZERO(1),
        .MASKED_IRQ(32'h00000000),
        .LATCHED_IRQ(32'hffffffff),
        .PROGADDR_RESET(32'h00000000),    // Boot from ROM
        .PROGADDR_IRQ(32'h00000010),
        .STACKADDR(32'h10010000)          // Stack pointer init (end of 64KB range)
    ) cpu (
        .clk       (clk),
        .resetn    (rst_n),
        .trap      (cpu_trap),
        
        // Memory Interface
        .mem_valid (mem_valid),
        .mem_instr (mem_instr),
        .mem_ready (mem_ready),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),
        .mem_rdata (mem_rdata),
        
        // Look-Ahead Interface (not used)
        .mem_la_read  (),
        .mem_la_write (),
        .mem_la_addr  (),
        .mem_la_wdata (),
        .mem_la_wstrb (),
        
        // Pico Co-Processor Interface (not used)
        .pcpi_valid   (),
        .pcpi_insn    (),
        .pcpi_rs1     (),
        .pcpi_rs2     (),
        .pcpi_wr      (1'b0),
        .pcpi_rd      (32'h00000000),
        .pcpi_wait    (1'b0),
        .pcpi_ready   (1'b0),
        
        // IRQ Interface
        .irq          (32'h00000000),     // No IRQs for now
        .eoi          (),
        
        // Trace Interface (not used)
        .trace_valid  (),
        .trace_data   ()
    );
    
    //=================================================================
    // Boot ROM (4KB) - Contains secure bootloader
    //=================================================================
    boot_rom boot_rom_inst (
        .clk   (clk),
        .addr  (mem_addr[11:2]),          // Word-addressed
        .rdata (boot_rom_rdata)
    );
    
    //=================================================================
    // Instruction Memory (64KB) - Application firmware
    //=================================================================
    // Multiplex address between CPU and crypto accelerator
    // Address calculation: extract word index from address
    // For 0x00010000-0x0001FFFF: word_idx = (addr - 0x00010000) >> 2
    wire [13:0] instr_mem_addr_mux;  // 14 bits for 16K words
    // Crypto accelerator only reads when it has a valid request
    wire        crypto_reading_instr = crypto_mem_valid && (crypto_mem_addr >= 32'h00010000 && crypto_mem_addr < 32'h00020000);
    // Explicitly calculate word index: (addr - base) >> 2
    wire [31:0] cpu_word_addr = (mem_addr - 32'h00010000) >> 2;
    wire [31:0] crypto_word_addr = (crypto_mem_addr - 32'h00010000) >> 2;
    // Only use crypto address if crypto is actively reading, otherwise use CPU address
    assign instr_mem_addr_mux = crypto_reading_instr ? crypto_word_addr[13:0] : cpu_word_addr[13:0];
    
    instruction_mem instr_mem_inst (
        .clk   (clk),
        .we    (mem_valid && mem_ready && instr_mem_sel && |mem_wstrb),
        .addr  (instr_mem_addr_mux),      // Word-addressed (multiplexed)
        .wdata (mem_wdata),
        .wstrb (mem_wstrb),
        .rdata (instr_mem_rdata)
    );
    
    //=================================================================
    // Data Memory (64KB) - Stack, heap, variables
    //=================================================================
    data_mem data_mem_inst (
        .clk   (clk),
        .we    (mem_valid && mem_ready && data_mem_sel && |mem_wstrb),
        .addr  (mem_addr[15:2]),          // Word-addressed
        .wdata (mem_wdata),
        .wstrb (mem_wstrb),
        .rdata (data_mem_rdata)
    );
    
    //=================================================================
    // UART Peripheral
    //=================================================================
    // Note: For real hardware, BAUD_RATE should be 115200.
    // For simulation we now monitor UART at the bus level in the
    // testbench, so the exact baud rate here is less important.
    uart #(
        .CLK_FREQ(100000000),
        .BAUD_RATE(115200)
    ) uart_inst (
        .clk   (clk),
        .rst_n (rst_n),
        .addr  (mem_addr[5:2]),
        .we    (mem_valid && mem_ready && uart_sel && |mem_wstrb),
        .wdata (mem_wdata),
        .rdata (uart_rdata),
        .tx    (uart_tx),
        .rx    (uart_rx)
    );
    
    //=================================================================
    // Crypto Accelerator (SHA-256, HMAC)
    //=================================================================
    wire [31:0] crypto_mem_addr;
    wire        crypto_mem_valid;
    wire [31:0] crypto_mem_rdata;
    wire        crypto_mem_ready;
    
    // Crypto needs to read firmware from instruction memory
    // Route its memory requests appropriately
    assign crypto_mem_rdata = (crypto_mem_addr >= 32'h00010000 && crypto_mem_addr < 32'h00020000) ? 
                               instr_mem_rdata : 32'h0;
    assign crypto_mem_ready = 1'b1;  // Instant response for now
    
    crypto_accelerator crypto_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .addr       (mem_addr[9:2]),  // 8 bits for address
        .we         (mem_valid && mem_ready && crypto_sel && |mem_wstrb),
        .wdata      (mem_wdata),
        .rdata      (crypto_rdata),
        .mem_addr   (crypto_mem_addr),
        .mem_valid  (crypto_mem_valid),
        .mem_rdata  (crypto_mem_rdata),
        .mem_ready  (crypto_mem_ready)
    );
    
    //=================================================================
    // Anti-Replay Protection Modules
    //=================================================================
    // Monotonic Counter (0x50000000 - 0x5000000F)
    wire [31:0] counter_rdata;
    monotonic_counter counter_inst (
        .clk   (clk),
        .rst_n (rst_n),
        .addr  (mem_addr[3:0]),
        .we    (mem_valid && mem_ready && anti_replay_sel && (mem_addr[7:4] == 4'h0) && |mem_wstrb),
        .wdata (mem_wdata),
        .rdata (counter_rdata)
    );
    
    // Nonce Generator (0x50000010 - 0x5000001F)
    wire [31:0] nonce_rdata;
    nonce_gen nonce_inst (
        .clk   (clk),
        .rst_n (rst_n),
        .addr  (mem_addr[3:0]),
        .we    (mem_valid && mem_ready && anti_replay_sel && (mem_addr[7:4] == 4'h1) && |mem_wstrb),
        .wdata (mem_wdata),
        .rdata (nonce_rdata)
    );
    
    // Anti-Replay Engine (0x50000020 - 0x5000003F)
    wire [31:0] replay_rdata;
    anti_replay replay_inst (
        .clk   (clk),
        .rst_n (rst_n),
        .addr  (mem_addr[4:0]),
        .we    (mem_valid && mem_ready && anti_replay_sel && (mem_addr[7:5] == 3'b001) && |mem_wstrb),
        .wdata (mem_wdata),
        .rdata (replay_rdata)
    );
    
    // Anti-replay read multiplexer
    assign anti_replay_rdata = (mem_addr[7:4] == 4'h0) ? counter_rdata :
                               (mem_addr[7:4] == 4'h1) ? nonce_rdata :
                               (mem_addr[7:5] == 3'b001) ? replay_rdata :
                               32'h00000000;
    
    //=================================================================
    // Memory Read Multiplexer
    //=================================================================
    assign mem_rdata = boot_rom_sel   ? boot_rom_rdata :
                       instr_mem_sel  ? instr_mem_rdata :
                       data_mem_sel   ? data_mem_rdata :
                       uart_sel       ? uart_rdata :
                       crypto_sel     ? crypto_rdata :
                       anti_replay_sel ? anti_replay_rdata :
                       32'h00000000;
    
    //=================================================================
    // Memory Ready Signal (single-cycle memory for now)
    //=================================================================
    assign mem_ready = mem_valid;
    
    //=================================================================
    // Trap Signal (CPU trap OR MPU violation)
    //=================================================================
    assign trap = cpu_trap || mpu_trap;
    
    //=================================================================
    // Debug Outputs
    //=================================================================
    assign debug_pc = mem_addr;
    assign debug_insn = mem_instr ? mem_rdata : 32'h00000000;
    
    //=================================================================
    // Status LED (blinks on activity)
    //=================================================================
    reg [25:0] led_counter;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            led_counter <= 0;
        else if (mem_valid)
            led_counter <= led_counter + 1;
    end
    assign status_led = led_counter[25];

endmodule

