`timescale 1ps/1ps

module adder_verify(
    input logic [3:0] a,
    input logic [3:0] b,
    input logic cin,
    output logic [3:0] sum,
    output logic cout
);

    assign {cout,sum} = a + b + cin;

endmodule

interface adder_iff;
    logic [3:0] a;
    logic [3:0] b;
    logic cin;
    logic [3:0] sum;
    logic cout;
  	event driver_done;
endinterface