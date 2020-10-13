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


module fifo_stage #(parameter WIDTH=64)(
	input clk, input res_n, input shift_in, input shift_out, input LFull, input RFull,
	input [WIDTH-1:0] data_in, input [WIDTH-1:0] data_left,
	output reg [WIDTH-1:0] data_out, output reg CFull);
	
	reg [WIDTH-1:0] data;
	
	
	always @(posedge clk) begin

		// if reset is active, set the current occupancy and data_out to 0
		if (~res_n) begin
			CFull <= 1'd0;
			data_out <= 'd0;
		end

		//assign the current occupy for each case
		else begin
			// if shifting in while the right side is full, then current stage will be full
			if (shift_in & ~shift_out & ~CFull & RFull) begin
				CFull <= 1'b1;
			end

			// if shifting in while the right side is empty, then current stage will be empty since right side will be filled
			else if (shift_in & ~shift_out & ~CFull & ~RFull) begin
				CFull <= 1'b0;
			end

			// if shifting in and out while left is empty, the current value is shifted out but replaced
			else if (shift_in & shift_out & CFull & ~LFull) begin
				CFull <= 1'b1;
			end
			
			// if shifting in and out while left and current are full then the current one stays full
			else if (shift_in & shift_out & CFull & LFull) begin
				CFull <= 1'b1;
			end			
			
			// if shifting out while nothing is in the left side, the current stage will be empty
			else if (~shift_in & shift_out & ~LFull) begin
				CFull <= 1'b0;
			end

			// if shifting out while the left is full, then the current stage will be full
			else if (~shift_in & shift_out & LFull) begin
				CFull <= 1'b1;
			end

			// if shift in and shift out are both zero, then hold the current status
			else if (~shift_in & ~shift_out) begin
				CFull <= CFull;
			end
			
			else 
				CFull <= CFull;
			
			// sets data_out to the result of the mux below
			data_out <= data;	
		end
	end
	
	// mux logic to determine what the new data out should be
	always @(*) begin
		casez({shift_in, shift_out, LFull, CFull, RFull})
			5'b10?01:
				data = data_in;		// if shifting in, while the right is full then data in goes here
			5'b10?00:
				data = data_out;	// if shifting in while the right is empty, then data holds its value
			5'b1101?:
				data = data_in;		// if shifting in/out and left is empty and CFull is 1, the new data in goes to the current stage
			5'b1111?:
				data = data_left;	// if shifting in/out while left is full and CFull is 1, data left gets stored in current stage
			// 5'b010??:
				// data = data_out		// if shifting out while left is 0, current stage gets data left which is 0    THIS IS FOR CASE WHERE IT IS ALL EMPTY AND SHIFTING OUT
			5'b011??:
				data = data_left;	// if shifting out while left has a value, current stage gets this value
			5'b00???:
				data = data_out;	// if its not shifting, hold the value
			default:
				data = data_out;
		endcase
	end
			
	
	
endmodule
