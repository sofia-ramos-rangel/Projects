`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/24/2020 11:05:02 AM
// Design Name: 
// Module Name: fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo #(parameter WIDTH=32, parameter DEPTH=8)(
	input clk, input res_n, input shift_in, input shift_out, 
	input [WIDTH-1:0] data_in,  
	output reg full, output reg empty,
	output reg [WIDTH-1:0] data_out);
	
	
	// this keeps track of the occupancy in the fifo stages
	wire [DEPTH - 1 :0] data_now;
	
	always @(*) begin
        // checking index 7 (first stage), if it doesn't have data it's empty
        empty = ~(data_now[DEPTH - 1]);	
    
        // if the index 0 (last stage) is full, then the entire fifo must be full
        full = data_now[0];
    end
	
	// data to pass through stages
	wire [WIDTH-1:0] data_shift [DEPTH-1:0];
	
	// first

	// to be able to shift into this one there has to be something to the right (output)
	fifo_stage #(WIDTH) FS_first(.clk(clk), .res_n(res_n), .shift_in(shift_in), .shift_out(shift_out),								
										.LFull(data_now[DEPTH - 2]), .RFull(1'b1), .data_in(data_in), .data_left(data_shift[DEPTH-2]),
										.data_out(data_shift[DEPTH-1]), .CFull(data_now[DEPTH - 1]));
	
	// adding flip flop to buffer data_out of the fifo
	always @(posedge clk) begin
		if (shift_out == 1'b1) begin			// if shift_out is high then the data_out will be updated
            data_out <= data_shift[DEPTH-1];
		end
		else begin								// other wise, the data_out value will be held
			data_out <= data_out;
		end
	end


	// middle
	genvar i;
	generate 
		// generates (DEPTH - 2) amount of fifo stages
		for (i = 1; i < DEPTH - 1; i = i + 1) begin : mid
			fifo_stage #(WIDTH) FS(.clk(clk), .res_n(res_n), .shift_in(shift_in), .shift_out(shift_out),
										  .LFull(data_now[i-1]), .RFull(data_now[i+1]), .data_in(data_in), .data_left(data_shift[i-1]), 
										  .data_out(data_shift[i]), .CFull(data_now[i]));
		end
		
	endgenerate


	// last stage
	fifo_stage #(WIDTH) FS_last(.clk(clk), .res_n(res_n), .shift_in(shift_in), .shift_out(shift_out),
									   .LFull(1'b0), .RFull(data_now[1]), .data_in(data_in), .data_left('b0), 
									   .data_out(data_shift[0]), .CFull(data_now[0]));
										
endmodule
