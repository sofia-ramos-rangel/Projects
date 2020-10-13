`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2020 01:57:59 PM
// Design Name: 
// Module Name: lfsr_structural
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
/////////////////////////////////////////////////////////////////////////////////


module lfsr_structural(
    input clk,
    input res_n,
    input [7:0] data_in,
    output [7:0] data_out
    );

    // wires to use to wire the instance of the mux
    wire [7:0] out_2;
    wire [7:0] data_out2;
    
    // data_out2: represents the output of the mux when reset is not high
    // had to do them seperately since some of the bits are XOR'd together
    assign data_out2[0] = data_out[7];
    assign data_out2[1] = data_out[0];
    assign data_out2[2] = data_out[1] ^ data_out[7];
    assign data_out2[3] = data_out[2] ^ data_out[7];
    assign data_out2[4] = data_out[3] ^ data_out[7];
    assign data_out2[5] = data_out[4];
    assign data_out2[6] = data_out[5];
    assign data_out2[7] = data_out[6];
    
    // calling 8 instances of the module m2_1 for each flip flop
    // data in stays the same
    // data_out is wired to data_out2 to take care of the XOR's
    // out_2 represets the output of the mux which chooses if data_in or data_out
    m2_1 LF_OG0 (.data_in(data_in[0]), .data_out(data_out2[0]), .select(res_n), .out(out_2[0]));
    m2_1 LF_OG1 (.data_in(data_in[1]), .data_out(data_out2[1]), .select(res_n), .out(out_2[1]));
    m2_1 LF_OG2 (.data_in(data_in[2]), .data_out(data_out2[2]), .select(res_n), .out(out_2[2]));
    m2_1 LF_OG3 (.data_in(data_in[3]), .data_out(data_out2[3]), .select(res_n), .out(out_2[3]));
    m2_1 LF_OG4 (.data_in(data_in[4]), .data_out(data_out2[4]), .select(res_n), .out(out_2[4]));
    m2_1 LF_OG5 (.data_in(data_in[5]), .data_out(data_out2[5]), .select(res_n), .out(out_2[5]));
    m2_1 LF_OG6 (.data_in(data_in[6]), .data_out(data_out2[6]), .select(res_n), .out(out_2[6]));
    m2_1 LF_OG7 (.data_in(data_in[7]), .data_out(data_out2[7]), .select(res_n), .out(out_2[7]));
    
    // flip-flop's
    FDRE #(.INIT(1'b1)) LF0 (.C(clk), .R(1'b0), .CE(1'b1), .D(out_2[0]), .Q(data_out[0]));
    FDRE #(.INIT(1'b0)) LF1 (.C(clk), .R(1'b0), .CE(1'b1), .D(out_2[1]), .Q(data_out[1]));
    FDRE #(.INIT(1'b0)) LF2 (.C(clk), .R(1'b0), .CE(1'b1), .D(out_2[2]), .Q(data_out[2]));
    FDRE #(.INIT(1'b0)) LF3 (.C(clk), .R(1'b0), .CE(1'b1), .D(out_2[3]), .Q(data_out[3]));
    FDRE #(.INIT(1'b0)) LF4 (.C(clk), .R(1'b0), .CE(1'b1), .D(out_2[4]), .Q(data_out[4]));
    FDRE #(.INIT(1'b0)) LF5 (.C(clk), .R(1'b0), .CE(1'b1), .D(out_2[5]), .Q(data_out[5]));
    FDRE #(.INIT(1'b0)) LF6 (.C(clk), .R(1'b0), .CE(1'b1), .D(out_2[6]), .Q(data_out[6]));
    FDRE #(.INIT(1'b0)) LF7 (.C(clk), .R(1'b0), .CE(1'b1), .D(out_2[7]), .Q(data_out[7]));
   
endmodule
