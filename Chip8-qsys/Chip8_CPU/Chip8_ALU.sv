/******************************************************************************
 * Chip8_ALU.sv
 *
 * Simple ALU supporting instructions:
 * 	- OR 		- bitwise OR
 * 	- AND 		- bitwise AND
 * 	- XOR		- bitwise XOR
 * 	- ADD		- Addition
 * 	- MINUS		- Subtract
 * 	- LSHIFT	- Shift left
 * 	- RSHIFT	- Shift right
 * 	- EQUALS 	- Equals compare
 * 	- GREATER	- Greater than compare
 * 	- INC 		- Increment
 * 
 * This module is solely used by the Chip8_CPU module, and relies on the ALU_f
 * enum defined in enums.svh
 *
 * AUTHORS: David Watkins, Ashley Kling
 * Dependencies:
 * 	- enums.svh
 *****************************************************************************/
 
 `include "../enums.svh"
 
 module Chip8_ALU(
		input logic[15:0] input1, input2,
		input ALU_f sel,
		
		output logic[15:0] out,
		output logic alu_carry);
		
		logic[15:0] intermediate;
		
		always_comb begin
			case	(sel) 

				ALU_f_OR : begin
					alu_carry = 0;
					out = input1 | input2;
				end

				ALU_f_AND : begin
					alu_carry = 0;
					out = input1 & input2;	
				end
				
				ALU_f_XOR : begin
					alu_carry = 0;
					out = input1 ^ input2;	
				end

				ALU_f_ADD : begin
					out = input1 + input2;
					alu_carry = |(out[15:8]);
				end

				ALU_f_MINUS : begin
					alu_carry = input1 < input2;
					out = input1 - input2;
				end

				ALU_f_LSHIFT : begin
					alu_carry = 0;
					out = input1 << input2;
				end

				ALU_f_RSHIFT : begin
					alu_carry = 0;
					out = input1 >> input2;
				end

				ALU_f_EQUALS : begin
					alu_carry = 0;
					out = (input1 == input2);
				end

				ALU_f_GREATER : begin
					alu_carry = 0;
					out = (input1 > input2);
				end

				ALU_f_INC : begin
					alu_carry = 0;
					out = input1 + 1'h1;
				end

				default: begin
					alu_carry = 0;
					out = 0;
				end
			endcase
		end
endmodule
