`timescale 1ns/1ps

module tb_vending_machine;
    reg [1:0] in;
    reg clk, rst;
    wire [1:0] change;
    wire out;

    // DUT instance
    vending_machine dut (
        .in(in),
        .clk(clk),
        .rst(rst),
        .change(change),
        .out(out)
    );

    // Clock generation (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_vending_machine);

        // Reset sequence
        rst = 1; in = 2'b00;
        #12 rst = 0;

        // Case 1: Insert 1Rs, then 1Rs, then product (total 2 Rs)
        $display("Case 1: Insert 1, then 1, then expect product");
        in = 2'b01; #10;   // 1 Rs
        in = 2'b01; #10;   // another 1 Rs
        in = 2'b00; #10;   // should dispense product
        in = 2'b00; #10;

        // Case 2: Insert 2 Rs directly
        $display("Case 2: Insert 2 directly, expect product");
        in = 2'b10; #10;   // 2 Rs at once
        in = 2'b00; #10;

        // Case 3: Insert 1 Rs, then 2 Rs (overpay: expect product + no change)
        $display("Case 3: Insert 1 then 2, expect product");
        in = 2'b01; #10;   // 1 Rs
        in = 2'b10; #10;   // 2 Rs, should vend
        in = 2'b00; #10;

        // Case 4: Overpayment with 2 Rs + 2 Rs (expect product + 2 Rs change)
        $display("Case 4: Insert 2 then 2, expect product + change");
        in = 2'b10; #10;   // 2 Rs
        in = 2'b10; #10;   // another 2 Rs
        in = 2'b00; #10;

        // Case 5: Insert 1 Rs, then cancel (expect 1 Rs back)
        $display("Case 5: Insert 1 then cancel, expect change=1");
        in = 2'b01; #10;
        in = 2'b00; #10;

        $finish;
    end
endmodule
