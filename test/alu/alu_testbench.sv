/*****************************************************************************
 * ALU Test Bench
 * GT
 *****************************************************************************/

`include "enums.svh"
 
module alu_testbench();
	logic clk;
	logic [15:0] carry_out;
	logic [15:0] result;
	logic[15:0] input1, input2;
   ALU_f alu_op;
	
	Chip8_ALU dut(
		.input1(input1), 
		.input2(input2), 
		.sel(alu_op),
		.out(result),
		.alu_carry(carry_out));
	
	initial begin
		clk = 0;
		input1 = 16'b0000_0000_0000_0000;
		input2 = 16'b0000_0000_0000_0000;
		alu_op = ALU_f_NOP;
		forever 
			#20ns clk = ~clk;
	end

	initial begin
		
		// testing bitwise OR
		// result = 1111_0000_1111_0000
		repeat(2) 
			@(posedge clk);
		input1 = 16'b1010_0000_1111_0000;
		input2 = 16'b0101_0000_1111_0000;
		alu_op = ALU_f_OR;
		
		// testing bitwise AND
		// result = 0000_0000_1111_1111
		repeat(2) 
			@(posedge clk);
		input1 = 16'b0000_1010_1111_1111;
		input2 = 16'b0000_0101_1111_1111;
		alu_op = ALU_f_AND;
		
		// testing bitwise XOR
		// result = 0000_1111_1111_0000
		repeat(2) 
			@(posedge clk);
		input1 = 16'b1111_0101_1010_0000;
		input2 = 16'b1111_1010_0101_0000;
		alu_op = ALU_f_XOR;
		
		// testing addition #1
		// result = 1000_0000_0000_0000
		// carry = 0
		repeat(2) 
			@(posedge clk);
		input1 = 16'b0111_1111_1111_1111;
		input2 = 16'b0000_0000_0000_0001;
		alu_op = ALU_f_ADD;

		// testing addition #2
		// result = 1000_0000_0000_0000
		// carry = 1
		repeat(2) 
			@(posedge clk);
		input1 = 16'b1100_0000_0000_0000;
		input2 = 16'b1100_0000_0000_0000;
		//alu_op = ALU_f_ADD;

		// testing addition #3
		// result = 1001_0001_1001_0001
		// carry = 0
		repeat(2) 
			@(posedge clk);
		input1 = 16'b0100_1110_1000_1000;
		input2 = 16'b0100_0011_0000_1001;
		//alu_op = ALU_f_ADD;

		// testing subtraction #1
		// result = 0000_0000_0000_0000
		repeat(2) 
			@(posedge clk);
		input1 = 16'b1100_0011_1100_0011;
		input2 = 16'b1100_0011_1100_0011;
		alu_op = ALU_f_MINUS;

		// testing subtraction #2
		// result = 0111_0000_1010_0010
		repeat(2) 
			@(posedge clk);
		input1 = 16'b1110_0000_1010_0101;
		input2 = 16'b0111_0000_0000_0011;
		//alu_op = ALU_f_MINUS;

		// testing left shift
		// result = 1111_0000_0000_0000
		repeat(2) 
			@(posedge clk);
		input1 = 16'b0100_1111_0000_0000;
		input2 = 16'b0000_0000_0000_0100;
		alu_op = ALU_f_LSHIFT;

		// testing right shift
		// result = 0000_0000_0000_1100
		repeat(2) 
			@(posedge clk);
		input1 = 16'b0000_0000_0011_0001;
		input2 = 16'b0000_0000_0000_0010;
		alu_op = ALU_f_RSHIFT;

		// testing equals #1
		// result = 0000_0000_0000_0000
		repeat(2) 
			@(posedge clk);
		input1 = 16'b0000_1000_0011_0010;
		input2 = 16'b0000_1000_0011_0010;
		alu_op = ALU_f_EQUALS;

		// testing equals #2
		// result = 0000_0000_0000_0001
		repeat(2) 
			@(posedge clk);
		//@(posedge clk);
		input1 = 16'b0000_0000_0011_0001;
		input2 = 16'b0000_0000_0000_0010;
		//alu_op = ALU_f_EQUALS;

		// testing greater #1
		// result = 0000_0000_0000_0000
		repeat(2) 
			@(posedge clk);
		input1 = 16'b1000_1000_0011_0010;
		input2 = 16'b0000_1000_0011_0010;
		alu_op = ALU_f_GREATER;

		// testing greater #2
		// result = 0000_0000_0000_0001
		repeat(2) 
			@(posedge clk);
		input1 = 16'b0000_1000_0011_0010;
		input2 = 16'b1000_1000_0011_0010;
		//alu_op = ALU_f_GREATER;

		// testing MSB #1
		// result = 0000_0000_0000_0000
		repeat(2) 
			@(posedge clk);
		input1 = 16'b0000_1000_0011_1000;
		alu_op = ALU_f_MSB;

		// testing MSB #2
		// result = 0000_0000_0000_0001
		repeat(2) 
			@(posedge clk);
		input1 = 16'b1000_1000_0011_0010;
		//alu_op = ALU_f_MSB;

		// testing LSB #1
		// result = 0000_0000_0000_0000
		repeat(2) 
			@(posedge clk);
		input1 = 16'b0000_1000_0011_1000;
		alu_op = ALU_f_LSB;

		// testing LSB #2
		// result = 0000_0000_0000_0001
		repeat(2) 
			@(posedge clk);
		input1 = 16'b0000_1000_0011_0011;
		//alu_op = ALU_f_LSB;

		// testing increment
		// result = 0000_0000_0000_1001
		repeat(2) 
			@(posedge clk);
		input1 = 16'b0000_0000_0000_1000;
		alu_op = ALU_f_INC;
		repeat(16) begin
			@(posedge clk);
			input1 = result;
		end
		alu_op = ALU_f_NOP;
		@(posedge clk);
		// at end result = 0000_0000_0001_0000
		

		//end of testbench, zero values to ensure correct functionality
		repeat(2) 
			@(posedge clk);		
		input1 = 16'b0000_0000_0000_0000;
		input2 = 16'b0000_0000_0000_0000;
		repeat(2) 
			@(posedge clk);	
		
		

	end
	
endmodule
	
