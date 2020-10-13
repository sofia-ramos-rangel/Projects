`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2020 10:31:03 PM
// Design Name: 
// Module Name: lfsr_behavioural
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


module lfsr_behavioural(
    input clk,
    input [7:0] data_in,
    input res_n,
    output reg [7:0] data_out
    );
    
    reg [7:0] out_2;
    reg [7:0] data_out2;
    
    // doing an if/else to represet a mux choosing between two inputs as done in lfsr_structural
    // reset is high: data_out2 will equal data_in
    // reset is low: data_in is not in the FF's, and data_out takes into account the XOR's
    always @(*) begin
        if(res_n == 1'b0)
            data_out2 = data_in; 
        
        else
        begin             
            data_out2[0] = data_out[7];
            data_out2[1] = data_out[0];
            data_out2[2] = data_out[1] ^ data_out[7];
            data_out2[3] = data_out[2] ^ data_out[7];
            data_out2[4] = data_out[3] ^ data_out[7];
            data_out2[5] = data_out[4];
            data_out2[6] = data_out[5];
            data_out2[7] = data_out[6];
        end
    end
    
    always @(posedge clk) begin
        data_out <= data_out2;
    end
    
endmodule
