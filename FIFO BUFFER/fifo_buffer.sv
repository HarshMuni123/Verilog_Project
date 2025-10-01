
`timescale 1ns/1ps

module fifo # (parameter WIDTH = 8,
			   parameter DEPTH = 16)
	(		input logic clk,
			input logic rst,
			
			input logic wr_en,
			input logic [WIDTH-1:0] din,
			
			input logic rd_en,
			output logic [WIDTH-1:0] dout,
			
			output logic full,
			output logic empty,
			output logic [$clog2(DEPTH):0] level
);
		
	logic [WIDTH-1:0] mem [DEPTH-1:0];
	
	logic [$clog2(DEPTH)-1:0] wr_ptr,rd_ptr;
	logic [$clog2(DEPTH):0] count;
	
	always_ff @(posedge clk or negedge rst) begin
		if (!rst) begin
			rd_ptr <= 0;
			dout <= 0;
		end
		else if (rd_en && !empty) begin
			dout <= mem[rd_ptr];
			rd_ptr <= rd_ptr + 1;
		end
	end
	
	always_ff @(posedge clk or negedge rst) begin
		if (!rst) begin
			count <= 0;
		end
		else begin
			case({wr_en && !full,rd_en && !empty})
				2'b01: count <= count + 1;
				2'b10: count <= count - 1;
				default: count <= count;
			endcase
		end
	end
	
	assign full = (count == DEPTH);
	assign empty = (count == 0);
	assign level = count;
	
endmodule
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

