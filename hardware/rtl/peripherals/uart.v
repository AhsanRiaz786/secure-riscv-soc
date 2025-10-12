/*
 * Simple UART Module for Debug Output
 * Memory-mapped registers for character transmission
 * Address Range: 0x20000000 - 0x200000FF
 * 
 * Register Map:
 *   0x00: TX Data Register (write to send character)
 *   0x04: Status Register (bit 0: TX busy)
 */

`timescale 1ns / 1ps

module uart #(
    parameter CLK_FREQ = 100000000,  // 100 MHz
    parameter BAUD_RATE = 115200
)(
    input  wire        clk,
    input  wire        rst_n,
    
    // Memory-mapped interface
    input  wire [3:0]  addr,
    input  wire        we,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    
    // UART signals
    output reg         tx,
    input  wire        rx
);

    // Baud rate generator
    localparam DIVISOR = CLK_FREQ / BAUD_RATE;
    reg [15:0] baud_counter;
    reg baud_tick;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= 0;
            baud_tick <= 0;
        end else begin
            if (baud_counter == DIVISOR - 1) begin
                baud_counter <= 0;
                baud_tick <= 1;
            end else begin
                baud_counter <= baud_counter + 1;
                baud_tick <= 0;
            end
        end
    end
    
    // TX state machine
    localparam TX_IDLE  = 2'd0;
    localparam TX_START = 2'd1;
    localparam TX_DATA  = 2'd2;
    localparam TX_STOP  = 2'd3;
    
    reg [1:0]  tx_state;
    reg [7:0]  tx_data;
    reg [2:0]  tx_bit_cnt;
    reg        tx_busy;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= TX_IDLE;
            tx <= 1'b1;
            tx_data <= 8'h00;
            tx_bit_cnt <= 0;
            tx_busy <= 0;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    tx <= 1'b1;
                    if (we && addr == 4'h0) begin
                        tx_data <= wdata[7:0];
                        tx_state <= TX_START;
                        tx_busy <= 1;
                    end
                end
                
                TX_START: begin
                    if (baud_tick) begin
                        tx <= 1'b0;  // Start bit
                        tx_state <= TX_DATA;
                        tx_bit_cnt <= 0;
                    end
                end
                
                TX_DATA: begin
                    if (baud_tick) begin
                        tx <= tx_data[tx_bit_cnt];
                        if (tx_bit_cnt == 7) begin
                            tx_state <= TX_STOP;
                        end else begin
                            tx_bit_cnt <= tx_bit_cnt + 1;
                        end
                    end
                end
                
                TX_STOP: begin
                    if (baud_tick) begin
                        tx <= 1'b1;  // Stop bit
                        tx_state <= TX_IDLE;
                        tx_busy <= 0;
                    end
                end
            endcase
        end
    end
    
    // Read interface
    always @(*) begin
        case (addr)
            4'h0: rdata = {24'h0, tx_data};
            4'h4: rdata = {31'h0, tx_busy};
            default: rdata = 32'h0;
        endcase
    end

endmodule

