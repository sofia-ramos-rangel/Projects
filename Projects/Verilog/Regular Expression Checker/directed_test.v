`timescale 1ns / 1ps

module directed_test;

	parameter WIDTH = 'd16;
	parameter DEPTH = 'd8;
	
	reg clk, res_n, shift_in, shift_out;
	reg [WIDTH-1:0] data_in;

	wire full, empty;
	wire [WIDTH-1:0] data_out;

	fifo #(WIDTH, DEPTH) dut(.clk(clk), .res_n(res_n), .shift_in(shift_in), .shift_out(shift_out), .data_in(data_in),
			 .full(full), .empty(empty), .data_out(data_out));
			 
	always 
        #5 clk = !clk;
    
	initial begin
		// initialize inputs and reset
		clk = 0;
		res_n = 0;
		shift_in = 0;
		shift_out = 0;
		data_in = 'b0;
		@(posedge clk); #1 res_n = 1;
		
		// this tests shift in and out at the same time
//		data_in = 32'd1;
//		shift_in = 1'b1;
//		#10 shift_in = 1'b0;
		
		
//        #10 shift_in = 1'b1;
//            shift_out = 1'b1;
//            data_in = 32'd2;
            
//        #10 shift_out = 1'b0;
//            shift_in = 1'b0;
		// -----------------------------------------------

		// fill in everything and then output it
		data_in = 'd1;
		shift_in = 1'b1;
		#10 shift_in = 1'b0;
		
		data_in = 'd2;
		shift_in = 1'b1;
		#10 shift_in = 1'b0;
				
		data_in = 'd3;
		shift_in = 1'b1;
		#10 shift_in = 1'b0;
				
		data_in = 'd4;
		shift_in = 1'b1;
		#10 shift_in = 1'b0;
				
		data_in = 'd5;
		shift_in = 1'b1;
		#10 shift_in = 1'b0;
				
		data_in = 'd6;
		shift_in = 1'b1;
		#10 shift_in = 1'b0;
				
		data_in = 'd7;
		shift_in = 1'b1;
		#10 shift_in = 1'b0;
				
		data_in = 'd8;
		shift_in = 1'b1;
		#10 shift_in = 1'b0;
		
		// shift it all out
		#10 shift_out = 1'b1;
		#80 shift_out = 1'b0;
		
		
		
		
		end

endmodule
