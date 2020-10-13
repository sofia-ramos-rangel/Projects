`timescale 1ns / 1ps

module random_test;

	parameter WIDTH = 'd32;
	parameter DEPTH = 'd1000;
	
	// inputs
	reg clk, res_n, shift_in, shift_out;
	reg [WIDTH-1:0] data_in;
    
    // outputs
	wire full, empty;
	wire [WIDTH-1:0] data_out;

    // variables for reading and writing
	reg [WIDTH-1:0] store [DEPTH-1:0];
	reg [WIDTH-1:0] out [DEPTH-1:0];
	
	reg e, f;

	fifo #(WIDTH, DEPTH) dut(.clk(clk), .res_n(res_n), .shift_in(shift_in), .shift_out(shift_out), .data_in(data_in),
			 .full(full), .empty(empty), .data_out(data_out));
		
	always 
        #5 clk = !clk;
    
    always @(*) begin
        e = empty;
        f = full;
    end
    
    integer i, j;
    reg k;
    
    
	initial begin
        // initialize inputs and reset
        clk = 0;
        res_n = 0;
        shift_in = 0;
        shift_out = 0;
        data_in = 'b0;
        e = 1'b1;
        f = 1'b0;
        i = 0;
        j = 0;
        k = 1'b0;
    
        @(posedge clk); #1 res_n = 1;       
        // read inputs from file and store to data_in  
        $readmemb("input.txt",store);
        #10;
        data_in = store[i];
//        shift_in = 'b1;
        while((i < (DEPTH)) | (j < (DEPTH))) begin
            // transfer inputs and outputs correctly
            if ((shift_in == 1'b1) & (shift_out == 1'b0) & ~full) begin
                data_in = store[i+1];
                i = i + 1;
            end
            else if ((shift_out == 1'b1) & (shift_in == 1'b0) & ~empty) begin
                out[j] = data_out;
                j = j + 1;
            end
            else if ((shift_in == 1'b1) & (shift_out == 1'b1) & ~empty & ~full) begin
                data_in = store[i+1];
                i = i + 1;
                out[j] = data_out;
                j = j + 1;
            end
            else if ((shift_in == 1'b1) & (shift_out == 1'b0) & full) begin		// look at these after random shifts have been made
                data_in = store[i+1];
            end
            else if ((shift_out == 1'b1) & (shift_in == 1'b0) & empty) begin
                out[j] = data_out;
            end
            else begin
              data_in = data_in;
              out[j] = data_out;
            end
            
            k = 1'b1;
            #10;
            // following lines are for testing
//              $display("i = %d      j = %d",i,j);
//              $display("j = %d",j);
//              $writememb("output.txt", out);
        end
    	   $writememb("output.txt", out);
    	   // for testing purposes
//    	   $display("Finished running.");
    	   k = 1'b0;
    	   $finish;
	end	
	
	
		// randomizing shift operations
	always @(posedge clk) begin	
		// takes care of shifting in when full
		if (f | ~k | ~(i<DEPTH)) begin			// if k is 0 then it is not in the loop
			shift_in <= 1'b0;
		end
		else begin
			shift_in <= $random();
		end
		
		// takes care of shifting out when empty
		if (e | ~k | ~(j<DEPTH)) begin
			shift_out <= 1'b0;
		end
		else begin
			shift_out <= $random();
		end
	end			
endmodule


