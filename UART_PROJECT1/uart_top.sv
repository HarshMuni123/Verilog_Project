`timescale 1ns/1ps
module uart_top #(
    parameter int FREQ       = 50_000_000,
    parameter int BAUD_RATE  = 9600,
    parameter int DATA_BITS  = 3
)(
    input  logic clk,
    input  logic rst,
    input  logic tx_start,
    input  logic [DATA_BITS-1:0] tx_data,
    output logic tx_done,
    output logic rx_done,
    output logic [DATA_BITS-1:0] rx_data
);

    // Internal connections
    logic baud_tick;
    logic tx_serial;

    // Instantiate baud rate generator
    baud_rate_generator #(
        .FREQ(FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_baud_gen (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick)
    );

    // Instantiate UART transmitter
    uart_tx #(
        .DATA_BITS(DATA_BITS)
    ) u_tx (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .baud_tick(baud_tick),
        .tx_serial(tx_serial),
        .tx_done(tx_done),
        .tx_busy()           // optional, unused here
    );

    // Instantiate UART receiver
    uart_rx #(
        .DATA_BITS(DATA_BITS)
    ) u_rx (
        .clk(clk),
        .rst(rst),
        .rx_serial(tx_serial),   // loopback connection
        .baud_tick(baud_tick),
        .data_out(rx_data),
        .rx_done(rx_done)
    );

endmodule

