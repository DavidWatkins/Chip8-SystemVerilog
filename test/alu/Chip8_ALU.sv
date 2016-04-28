/******************************************************************************
 * Chip8_ALU.sv
 *
 * Simple ALU supporting instructions:
 * 	- OR 		- bitwise OR
 * 	- AND 		- bitwise AND
 * 	- XOR		- bitwise XOR
 * 	- ADD		- Addition
 * 	- SUB		- Subtract
 * 	- LSHIFT	- Shift left
 * 	- RSHIFT	- Shift right
 * 	- EQUALS 	- Equals compare
 * 	- GREATER	- Greater than compare
 * 	- LSB		- Least significant bit
 * 	- MSB		- Most significant bit
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
					intermediate = 0;
					alu_carry = 0;
					out = input1 | input2;
				end

				ALU_f_AND : begin
					intermediate = 0;
					alu_carry = 0;
					out = input1 ^ input2;	
				end
				
				ALU_f_XOR : begin
					intermediate = 0;
					alu_carry = 0;
					out = input1 ^ input2;	
				end

				ALU_f_ADD : begin
					intermediate = input1 + input2;
					out = intermediate[7:0];
					alu_carry = (intermediate > 8'd255);
				end

				ALU_f_MINUS : begin
					intermediate = 0;
					alu_carry = input1 > input2;
					out = input1 - input2;
				end

				ALU_f_LSHIFT : begin
					intermediate = 0;
					alu_carry = 0;
					out = input1 << input2;
				end

				ALU_f_RSHIFT : begin
					intermediate = 0;
					alu_carry = 0;
					out = input1 >> input2;
				end

				ALU_f_EQUALS : begin
					intermediate = 0;
					alu_carry = 0;
					out = (input1 == input2);
				end

				ALU_f_GREATER : begin
					intermediate = 0;
					alu_carry = 0;
					out = (input1 > input2);
				end

				ALU_f_LSB : begin //LSB = 1
					intermediate = 0;
					alu_carry = 0;
					out = (input1[0] == 1);
				end

				ALU_f_MSB : begin //MSB = 1
					intermediate = 0;
					alu_carry = 0;
					out = (input1[7] == 1);
				end

				ALU_f_INC : begin //INC
					intermediate = 0;
					alu_carry = 0;
					out = input1 + 1'h1;
				end

				default: begin
					intermediate = 0;
					alu_carry = 0;
					out = 0;
				end
			endcase
		end
endmodule