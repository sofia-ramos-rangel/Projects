`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2020 04:56:40 PM
// Design Name: 
// Module Name: 2_1x8
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


module m2_1(
    input data_in,
    input data_out,
    input select,
    output out
    );
    
    // created a mux to select either data_in or data_out depending on the select
    // select represents reset being high so data_in gets shoved as the input to the flip-flop's
    assign out = (~select & data_in) | (select & data_out);
    
endmodule
