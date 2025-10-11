`timescale 1ns/1ps
module tb_uart;

  // Parameters
  localparam int FREQ       = 50_000_000;
  localparam int BAUD_RATE  = 9600;
  localparam int DATA_BITS  = 3;

  // Clock & reset
  logic clk = 0;
  logic rst = 1;

  // UART signals
  logic tx_start;
  logic [DATA_BITS-1:0] tx_data;
  logic tx_done;
  logic rx_done;
  logic [DATA_BITS-1:0] rx_data;

  // Instantiate DUT
  uart_top #(
    .FREQ(FREQ),
    .BAUD_RATE(BAUD_RATE),
    .DATA_BITS(DATA_BITS)
  ) dut (
    .clk(clk),
    .rst(rst),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx_done(tx_done),
    .rx_done(rx_done),
    .rx_data(rx_data)
  );

  // Clock generation (20 ns -> 50 MHz)
  always #10 clk = ~clk;

  // VCD dump for GTKWave
  initial begin
    $dumpfile("uart_wave.vcd");
    $dumpvars(0, tb_uart);
  end

  // Reset sequence
  initial begin
    rst = 1;
    tx_start = 0;
    tx_data = 0;
    #200_000; // 200 ns reset
    rst = 0;
    $display("[%0t] INFO: Reset deasserted", $time);
  end

  // Test sequence
initial begin : UART_TEST
    @(negedge rst);
    repeat (2) @(posedge clk);

    for (int i = 0; i < 8; i++) begin
        tx_data = i[DATA_BITS-1:0]; // assign integer sliced to DATA_BITS
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;
        $display("[%0t] TX STARTED for data = %0d", $time, tx_data);

        @(posedge tx_done);
        $display("[%0t] TX DONE for data = %0d", $time, tx_data);

        @(posedge rx_done);
        $display("[%0t] RX DONE, Received = %0d", $time, rx_data);

        if (rx_data !== tx_data)
            $error("[%0t] MISMATCH: TX=%0d, RX=%0d", $time, tx_data, rx_data);
        else
            $display("[%0t] MATCH: TX=%0d, RX=%0d ✅", $time, tx_data, rx_data);

        repeat (5000) @(posedge clk);
    end

    $display("[%0t] TEST COMPLETED ✅", $time);
    $finish;
end


endmodule
