// safe baud rate generator
`timescale 1ns/1ps
module baud_rate_generator #(
    parameter int BAUD_RATE = 9600,
    parameter int FREQ      = 50_000_000
)(
    input  logic clk,
    input  logic rst,       // Active high reset
    output logic baud_tick
);

    // Derived constant (integer)
    localparam int TICK_RATE = (FREQ + (BAUD_RATE/2)) / BAUD_RATE; // rounding
    // width guard: $clog2 requires >=1
    localparam int WIDTH = (TICK_RATE <= 1) ? 1 : $clog2(TICK_RATE);

    logic [WIDTH-1:0] count;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count     <= '0;
            baud_tick <= 1'b0;
        end
        else begin
            if (count == (TICK_RATE - 1)) begin
                count     <= '0;
                baud_tick <= 1'b1; // one-clock pulse
            end
            else begin
                count     <= count + 1;
                baud_tick <= 1'b0;
            end
        end
    end

endmodule
