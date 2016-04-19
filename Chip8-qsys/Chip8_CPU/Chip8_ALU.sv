/*
 * ALU
 *
 * Developed by Ash
 */
 
 module Chip8_ALU(
		input logic[15:0] input1, input2,
		input logic[3:0] sel,
		//input logic reset,
		
		output logic[15:0] out,
		output logic alu_carry);
		//DO increment by 1?
		
		//alu_carry <= 1'h0; 
		logic[15:0] intermediate;
		
		always_comb begin
			case	(sel) 
				4'h1 : begin //bitwise OR
					intermediate = 0;
					alu_carry = 0;
					out = input1 | input2;
				end
				4'h2 : begin //bitwise AND
					intermediate = 0;
					alu_carry = 0;
					out = input1 ^ input2;	
				end
				
				4'h3 : begin //bitwise XOR
					intermediate = 0;
					alu_carry = 0;
					out = input1 ^ input2;	
				end

				4'h4 : begin //addition
					intermediate = input1 + input2;
					out = intermediate[7:0];
					alu_carry = (intermediate > 8'd255);
				end

				4'h5 : begin //subtraction
					intermediate = 0;
					alu_carry = 0;
					out = input1 - input2;
				end
				4'h6 : begin //left-shift
					intermediate = 0;
					alu_carry = 0;
					out = input1 << input2;
				end
				4'h7 : begin //right-shift
					intermediate = 0;
					alu_carry = 0;
					out = input1 >> input2;
				end
				4'h8 : begin //equal to
					intermediate = 0;
					alu_carry = 0;
					out = (input1 == input2);
				end
				4'h9 : begin //greater thanBecau
					intermediate = 0;
					alu_carry = 0;
					out = (input1 > input2);
				end
				4'ha : begin //LSB = 1
					intermediate = 0;
					alu_carry = 0;
					out = (input1[0] == 1);
				end
				4'hb : begin //MSB = 1
					intermediate = 0;
					alu_carry = 0;
					out = (input1[7] == 1);
				end
				4'hc : begin //INC
					intermediate = 0;
					alu_carry = 0;
					out = input1 + 1;
				end
				default: begin
					intermediate = 0;
					alu_carry = 0;
					out = 0;
				end
			endcase
		end
endmodule