`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/17/2020 11:54:32 AM
// Design Name: 
// Module Name: regex
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


module regex(
    input clk,
    input res_n,
    input [1:0] symbol_in,
    input last_symbol,
    output reg done,
    output reg result
    );
    
    // created for state machine
    reg [3:0] state;
    reg [3:0] next_state;
    reg repeatF, choseA1, choseD1, start_flag;
	reg [1:0] chose;
	reg [7:0] Bcount, Brcount;
	
    
    // encoding table
    parameter IDLE = 4'b0000;
    parameter A = 4'b0001;
    parameter B = 4'b0010;
    parameter C = 4'b0011;
    parameter D1 = 4'b0100;
	parameter A1 = 4'b0101;
    parameter D2 = 4'b0110;
	parameter REPEAT = 4'b0111;
    parameter MATCH = 4'b1000;
    
    // always block for state machine
    always @(*)
        begin: state_machine
        next_state = IDLE;
        case(state)
          IDLE:         
                // if symbol_in: D and last_symbol: 1'b1
                if(symbol_in == 2'b11 & last_symbol == 1'b1 & start_flag) begin
                    next_state = MATCH; 
                end

                // if symbol_in: A and last_symbol: 1'b0
                else if(symbol_in == 2'b00 & last_symbol == 1'b0 & start_flag) begin
                    next_state = A;
                end
                
                else begin
                    next_state = IDLE;
                end
            
            A:                
                // if symbol in: B and last_symbol: 1'b0
                if(symbol_in == 2'b01 & last_symbol == 1'b0) begin
                    next_state = B;
                end

                else begin
                    next_state = IDLE;
                end
                
            B:
                // if symbol_in: B and last_symbol: 0
                if(symbol_in == 2'b01 & last_symbol == 1'b0) begin
                    next_state = B;
                end
                
                // if symbol_in: C and last_symbol: 0
                else if(symbol_in == 2'b10 & last_symbol == 1'b0) begin
                    next_state = C;
                end

                else begin
                    next_state = IDLE;
                end
                
            C: 
				// if its the first runthrough, proceed as normal
				if(repeatF == 1'b0) begin					
					// if symbol_in: A and last_symbol: 0
					if(symbol_in == 2'b00 & last_symbol == 1'b0) begin
						next_state = A1;
					end
					
					// if symbol_in: D and last_symbol: 0
					else if(symbol_in == 2'b11 & last_symbol == 1'b0) begin
						next_state = D1;
					end
					
					else begin
						next_state = IDLE;
					end
				end
                
				// if repeating and the b counters match, proceed as normal
				else if ((repeatF == 1'b1) & (Bcount == Brcount)) begin
					// if symbol_in: A and last_symbol: 0
					if(symbol_in == 2'b00 & last_symbol == 1'b0) begin
						next_state = A1;
					end
					
					// if symbol_in: D and last_symbol: 0
					else if(symbol_in == 2'b11 & last_symbol == 1'b0) begin
						next_state = D1;
					end
					
					else begin
						next_state = IDLE;
					end
				end
				
				// if it is repeating, and the b counters don't match then it's not a match
				else if ((repeatF == 1'b1) & (Bcount != Brcount)) begin
					next_state = IDLE;
				end
				
				else begin
                    next_state = IDLE;
                end
				
				
            D1:
				// if this is the first run, proceed as normal
				if(repeatF == 1'b0) begin
					// if symbol_in: B and last_symbol: 1'b0
					if(symbol_in == 2'b01 & last_symbol == 1'b0) begin
						next_state = D2;
					end
					
					// if symbol_in C and last_symbol: 1'b0
					else if(symbol_in == 2'b10 & last_symbol == 1'b0) begin
						next_state = D2;
					end
					
					// if symbol_in: D and last_symbol: 1'b0
					else if(symbol_in == 2'b11 & last_symbol == 1'b0) begin
						next_state = D2;
					end

					else begin
						next_state = IDLE;
					end
				end
				
				// if repeating and D was chosen again, then proceeds as normal
				else if ((repeatF == 1'b1) & (choseD1 == 1)) begin
					// if symbol_in: B and last_symbol: 1'b0
					if(symbol_in == 2'b01 & last_symbol == 1'b0) begin
						next_state = D2;
					end
					
					// if symbol_in C and last_symbol: 1'b0
					else if(symbol_in == 2'b10 & last_symbol == 1'b0) begin
						next_state = D2;
					end
					
					// if symbol_in: D and last_symbol: 1'b0
					else if(symbol_in == 2'b11 & last_symbol == 1'b0) begin
						next_state = D2;
					end

					else begin
						next_state = IDLE;
					end
				end
				
				// if repeated and in state D1, if choseD1 is 0 then no match
				else if ((repeatF == 1'b1) & (choseD1 == 0)) begin
					next_state = IDLE;
				end	
				
				else begin
                    next_state = IDLE;
                end
				
                
            A1:
				// if first run, proceed as normal
				if(repeatF == 1'b0) begin					
					// if symbol in: D and last symbol: 1'b1
					if (symbol_in == 2'b11 & last_symbol == 1'b1) begin
						next_state = MATCH;
					end
					
					//if symbol in: A and last symbol: 1'b0
					else if (symbol_in == 2'b00 & last_symbol == 1'b0) begin
						next_state = REPEAT;
					end
					
					else begin
					   next_state = IDLE;
					end
				end
				
				// if repeating and A was chosen again, then proceeds as normal
				else if ((repeatF == 1'b1) & (choseA1 == 1)) begin
					// if symbol in: D and last symbol: 1'b1
					if (symbol_in == 2'b11 & last_symbol == 1'b1) begin
						next_state = MATCH;
					end
					
					//if symbol in: A and last symbol: 1'b0
					else if (symbol_in == 2'b00 & last_symbol == 1'b0) begin
						next_state = REPEAT;
					end
					
					else begin
					   next_state = IDLE;
					end	
				end
				
				// if repeated and in state A1, if choseA1 is 0 then no match
				else if ((repeatF == 1'b1) & (choseA1 == 0)) begin
					next_state = IDLE;
				end
				
				else begin
                    next_state = IDLE;
                end
					
			
			
			D2:
				// if this is the first run, proceed as normal
				if(repeatF == 1'b0) begin
					// if symbol in: D and last_symbol: 1'b1
					if(symbol_in == 2'b11 & last_symbol == 1'b1) begin
						next_state = MATCH; 
					end
					
					// if symbol in: A and last symbol is 1'b0
					else if (symbol_in == 1'b00 & last_symbol == 1'b0) begin
						next_state = REPEAT;
					end
					
					else begin
						next_state = IDLE;
					end	
				end

				// if repeated, and the same letter was chosen for both runs, then proceed as normal
				else if ((repeatF == 1'b1) & (symbol_in == chose)) begin
					// if symbol in: D and last_symbol: 1'b1
					if(symbol_in == 2'b11 & last_symbol == 1'b1) begin
						next_state = MATCH; 
					end
					
					// if symbol in: A and last symbol is 1'b0
					else if (symbol_in == 1'b00 & last_symbol == 1'b0) begin
						next_state = REPEAT;
					end
					
					else begin
						next_state = IDLE;
					end	
				end
				
				// if repeated and X was chosen first but now its not X, => no match
				else if ((repeatF == 1'b1) & (symbol_in != chose)) begin
					next_state = IDLE;
				end
				
				else begin
                    next_state = IDLE;
                end
				
			
			REPEAT:
				// if symbol in: B and last_symbol: 1'b0
				if (symbol_in == 1'b01 & last_symbol == 1'b0) begin
					next_state = B;
				end
				
				else begin
                    next_state = IDLE;
                end
				
			
            MATCH:
                // if there is a match, it'll stay here until reset to accept the next input
                begin
                end
                
        default:
		  begin
		      next_state = IDLE;
	      end

                
        endcase   
    end
    
    // always block combintaional for output logic
    always @(*)
        begin: output_sm1
        case(state)
            IDLE:
                begin
                    // if starting in the beginning, its not done right away
					if(start_flag == 1'b1) begin
						result = 1'b0;
						done = 1'b0;
					end
                    
                    // if returning to IDLE from anywhere, it is done
					else if(start_flag == 1'b0) begin
						result = 1'b0;
						done = 1'b1;
					end    

                end
                
            A:
                begin
                    result = 1'b0;
                    done = 1'b0;                 
                end   
                
            B:
                begin
                    result = 1'b0;
                    done = 1'b0;                 
                end        
                
            C:
                begin
                    result = 1'b0;
                    done = 1'b0;                 
                end
            D1:
                begin
                    result = 1'b0;
                    done = 1'b0;                 
                end                        
            
            A1:
                begin
                    result = 1'b0;
                    done = 1'b0;                 
                end               
            
            D2:
                begin
                    result = 1'b0;
                    done = 1'b0;                 
                end               
            
             REPEAT:
                begin
                    result = 1'b0;
                    done = 1'b0;                 
                end              
  
             MATCH:
                begin
                    result = 1'b1;
                    done = 1'b1;                 
                end    
            
             default:
                begin
                    result = 1'b0;
                    done = 1'b0;                 
                end              
        endcase
        end    
                 
    
    // always block for outputs of each state
    always @(posedge clk)
        begin: output_sm
        case(state)
            IDLE:
                begin
					// reset repeat trackers
					repeatF <= 1'b0;
					Bcount <= 'b0;
					Brcount <= 'b0;
					choseA1 <= 1'b0;
					choseD1 <= 1'b0;
					chose <= 'b0;
                end
            A:
                begin              
                end
            B:
                begin					
					if (repeatF == 1'b0) begin		// if this is the first run, keep track of B*
						Bcount <= Bcount + 1'b1;
					end 
					
					else if (repeatF == 1'b1) begin	// if this is a repeated run, keep track of new B*
						Brcount <= Brcount + 1'b1;
					end		
                end   
            C:
                begin
                end
            D1:
				begin
					if(repeatF == 1'b0) begin
						choseD1 <= 1'b1;
					end
				end
			
			A1:
				begin
					if(repeatF == 1'b0) begin
						choseA1 <= 1'b1;
					end
				end
				
            D2:
                begin
					// on first run, if X is chosen, set the tracker to X
					if (repeatF == 1'b0) begin
						chose <= symbol_in;
					end
                end
				
			REPEAT:
				begin
					if(repeatF == 1'b0) begin		// if this is 0 then its the first time repeating
						repeatF <= 1'b1;			// set a tracker to show that it is repeating
					end
					else if (repeatF == 1'b1) begin	// if this is 1, then its a repeated run
						Brcount <= 'b0;				// reset the Brcounter to count B*
					end
				end 
				
            MATCH:
                begin 
                end
            
            default:
                begin
                end
            
        endcase
    end
    
    
    // always block to move to next state every clock cycle
    always @(posedge clk) begin
        if(res_n == 1'b0) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end
    
    always @(posedge clk) begin
        start_flag <= ~res_n;   // resets initilizes start_flag
    end
    
endmodule
