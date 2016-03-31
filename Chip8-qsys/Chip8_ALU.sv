/*
 * ALU
 *
 * Developed by Ash
 */
 
 module chip8_ALU(
		input logic[15:0] input1, input2,
		input logic[3:0] sel,
		
		output logic[15:0] out,
		output logic alu_carry);
		//DO increment by 1?
		
		//alu_carry <= 1'h0; 
		logic[15:0] intermediate;
		always_comb begin
				alu_carry = 1'd0;
				out = 16'd0;
				intermediate = 16'd0;
				if(sel == 4'h1) begin //bitwise OR
						out = input1 | input2;
				end else if(sel == 4'h2) begin //bitwise AND
						out = input1 & input2;
				end else if(sel == 4'h3) begin //bitwise XOR
						out = input1 ^ input2;						
				end else if(sel == 4'h4) begin //addition
						intermediate = input1 + input2;
						out = intermediate[7:0];
						alu_carry = (intermediate > 8'd255);
				end else if(sel == 4'h5) begin //subtraction
						out = input1 - input2;
				end else if(sel == 4'h6) begin //left-shift
						out = input1 << input2;
				end else if(sel == 4'h7) begin //right-shift
						out = input1 >> input2;
				end else if(sel == 4'h8) begin //equal to
						out = (input1 == input2);
				end else if(sel == 4'h9) begin //greater than
						out = (input1 > input2);
				end else if(sel == 4'ha) begin //LSB = 1
						out = (input1[0] == 1);
				end else if(sel == 4'hb) begin //MSB = 1
						out = (input1[7] == 1);
				end else if(sel == 4'hc) begin //INC
						out = input1;
						out++;
				end
		end
endmodule