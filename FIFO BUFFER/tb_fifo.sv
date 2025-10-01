

`timescale 1ns/1ps

module tb_fifo;
	parameter WIDTH = 8;
	parameter DEPTH = 16;
	
	logic clk,rst,wr_en,rd_en;
	logic [WIDTH-1:0] din;
	logic [WIDTH-1:0] dout;
	logic full,empty;
	logic [$clog2(DEPTH):0] level;
	
	fifo #(
		.WIDTH(WIDTH),
		.DEPTH(DEPTH)
	) dut (
		.clk(clk),
		.rst(rst),
		.wr_en(wr_en),
		.din(din),
		.rd_en(rd_en),
		.dout(dout),
		.full(full),
		.empty(empty),
		.level(level)
	);
		
	logic [WIDTH-1:0] ref_queue [$];
	
	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end
	
	initial begin
		rst = 0;wr_en = 0;rd_en = 0;din = 0;
		#20 rst = 1;
	end
	
	initial begin
		$dumpfile("fifo_wave.vcd");
		$dumpvars(0,tb_fifo);
	end
	
	initial begin
		@(posedge rst);
		repeat(200) begin
			@(posedge clk);
			
			if(!$urandom_range(0,2) && !full) begin
				wr_en = 1;
				din = $urandom_range(0,255);
				ref_queue.push_back(din);
			
			end else begin
				wr_en = 0;
			end
			
			if (!$urandom_range(0,2) && !empty) begin
				rd_en = 1;
			end else begin
				rd_en = 0;
			end
		end
		while(!empty) begin
			@(posedge clk);
			rd_en = 1;
		end
		@(posedge clk);
		rd_en = 0;
		
		#20;
		$display("testbench fully successful!");
		$finish;
	end
	
	always @(posedge clk) begin
		if(rd_en && !empty) begin
			if(dout !== ref_queue.pop_front()) begin
				$error("FIFO mismatch , expected = %0d,got=%0d",ref_queue[0],dout);
				$stop;
			end
		end
	end
	
	always @(posedge clk) begin
		if (full && wr_en) begin
			$error("Write attempted FIFO full");
	    end
	    
	    if(empty && rd_en) begin
			$error("Read attempted,while FIFO is empty");
	    end
	end
	
	
	
endmodule









