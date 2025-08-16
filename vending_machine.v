

`timescale 1ns/1ps

module vending_machine(
    input [1:0] in,       // 00=no coin, 01=1 Rs, 10=2 Rs
    input clk, rst,
    output reg [1:0] change,
    output reg out
);

    // States
    parameter s0 = 2'b00, // 0 Rs
              s1 = 2'b01, // 1 Rs
              s2 = 2'b10; // 2 Rs

    reg [1:0] cur_state, next_state;

    // Sequential Block - State Update
    always @(posedge clk or posedge rst) begin
        if (rst)
            cur_state <= s0;
        else
            cur_state <= next_state;
    end

    // Combinational Block - Next State & Outputs
    always @(*) begin
        // default values
        next_state = cur_state;
        out = 0;
        change = 2'b00;

        case (cur_state)
            s0: begin
                if (in == 2'b01) next_state = s1;
                else if (in == 2'b10) next_state = s2;
            end

            s1: begin
                if (in == 2'b00) begin
                    next_state = s0;
                    change = 2'b01; // return 1 Rs
                end
                else if (in == 2'b01) next_state = s2;
                else if (in == 2'b10) begin
                    next_state = s0;
                    out = 1;  // dispense product
                end
            end

            s2: begin
                if (in == 2'b00) begin
                    next_state = s0;
                    change = 2'b10; // return 2 Rs
                end
                else if (in == 2'b01) begin
                    next_state = s0;
                    out = 1;  // dispense product
                end
                else if (in == 2'b10) begin
                    next_state = s0;
                    out = 1;
                    change = 2'b10; // return 2 Rs extra
                end
            end
        endcase
    end

endmodule
