/******************************************************************************
 * alu_testbench.sv
 *
 * Contains tests for the following instructions:
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
 * This module is solely used by the Chip8_CPU module, && relies on the ALU_f
 * enum defined in enums.svh
 *
 * AUTHORS: David Watkins, Gabrielle Taylor
 * Dependencies:
 * 	- enums.svh
 *  - Chip8_CPU/Chip8_ALU.sv
 *****************************************************************************/

`include "enums.svh"

task testReset(logic [15:0] input1, input2, 
				   ALU_f alu_op);
	input1 = 16'h0000;
	input2 = 16'h0000;
	alu_op = ALU_f_NOP;
endtask


/**
 * Tests the OR instruction for the ALU
 *
 * @test 1
 * @input input1 = 16'hF5A0
 * @input input2 = 16'hFA50
 * @input alu_op = ALU_f_OR
 * @expected result = 16'FFF0
 * @expected alu_carry = 1'b0
 */
task testOR(logic clk, alu_carry,
				logic [15:0] input1, input2, result, 
				ALU_f alu_op, 
				int total);
    //Setup test 1
	repeat(2) 
		@(posedge clk);
	input1 = 16'hF5A0;
	input2 = 16'hFA50;
	alu_op = ALU_f_OR;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'hFFF0 && alu_carry == 1'b0) begin
		$display ("OR TEST 1 : PASSED");
		total = total + 1;
	end
    else $error("OR TEST 1 : FAILED (Got %0d, Expected 0xFFF0)", result);

	testReset(input1, input2, alu_op);
endtask


/**
 * Tests the AND instruction for the ALU
 *
 * @test 1
 * @input input1 = 16'hF5A0
 * @input input2 = 16'hFA50
 * @input alu_op = ALU_f_AND
 * @expected result = 16'F000
 * @expected alu_carry = 1'b0
 */
task testAND(logic clk, alu_carry,
				logic [15:0] input1, input2, result, 
				ALU_f alu_op, 
				int total);
    //Setup test 1
	repeat(2) 
		@(posedge clk);
	input1 = 16'hF5A0;
	input2 = 16'hFA50;
	alu_op = ALU_f_AND;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'hF000 && alu_carry == 1'b0) begin
		$display ("AND TEST 1 : PASSED");
		total = total + 1;
	end
    else $error("AND TEST 1 : FAILED (Got %0d, Expected 0xF000)", result);

    testReset(input1, input2, alu_op);
endtask


/**
 * Tests the XOR instruction for the ALU
 *
 * @test 1
 * @input input1 = 16'hF5A0
 * @input input2 = 16'hFA50
 * @input alu_op = ALU_f_XOR
 * @expected result = 16'h0FF0
 * @expected alu_carry = 1'b0
 */
task testXOR(logic clk, alu_carry,
				logic [15:0] input1, input2, result, 
				ALU_f alu_op, 
				int total);
    //Setup test 1
	repeat(2) 
		@(posedge clk);
	input1 = 16'hF5A0;
	input2 = 16'hFA50;
	alu_op = ALU_f_XOR;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'h0FF0 && alu_carry == 1'b0) begin
		$display ("XOR TEST 1 : PASSED");
		total = total + 1;
	end
    else $error("XOR TEST 1 : FAILED (Got %0d, Expected 0x0FF0)", result);

	testReset(input1, input2, alu_op);
endtask


/**
 * Tests the MINUS instruction for the ALU
 *
 * @test 1
 * @input input1 = 16'd180
 * @input input2 = 16'd180
 * @input alu_op = ALU_f_ADD
 * @expected result = 16'd360
 * @expected alu_carry = 1'b1
 *
 * @test 2
 * @input input1 = 16'd5
 * @input input2 = 16'd5
 * @input alu_op = ALU_f_ADD
 * @expected result = 16'd10
 * @expected alu_carry = 1'b1
 */
task testADD(logic clk, alu_carry,
				logic [15:0] input1, input2, result, 
				ALU_f alu_op, 
				int total);
    //Setup test 1
	repeat(2) 
		@(posedge clk);
	input1 = 16'd180;
	input2 = 16'd180;
	alu_op = ALU_f_ADD;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'd360 && alu_carry == 1'b1) begin
		$display ("ADD TEST 1 : PASSED");
		total = total + 1;
	end
    else $error("ADD TEST 1 : FAILED (Got %d, Expected 360) (Got %d, Expected 1)", result, alu_carry);

    //Setup test 2
	repeat(2) 
		@(posedge clk);
	input1 = 16'd5;
	input2 = 16'd5;
	alu_op = ALU_f_ADD;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'd10 && alu_carry == 1'b0) begin
		$display ("ADD TEST 2 : PASSED");
		total = total + 1;
	end
    else $error("ADD TEST 2 : FAILED (Got %d, Expected 10) (Got %d, Expected 0)", result, alu_carry);

	testReset(input1, input2, alu_op);
endtask


/**
 * Tests the MINUS instruction for the ALU
 *
 * @test 1
 * @input input1 = 16'hC3C3
 * @input input2 = 16'hC3C3
 * @input alu_op = ALU_f_MINUS
 * @expected result = 16'h0000
 * @expected alu_carry = 1'b0
 *
 * @test 2
 * @input input1 = 16'hE0A5
 * @input input2 = 16'h7003
 * @input alu_op = ALU_f_MINUS
 * @expected result = 16'h70A2
 * @expected alu_carry = 1'b0
 *
 * @test 3
 * @input input1 = 16'h7003
 * @input input2 = 16'hE0A5
 * @input alu_op = ALU_f_MINUS
 * @expected result = 16'h????
 * @expected alu_carry = 1'b0
 */
task testMINUS(logic clk, alu_carry,
				logic [15:0] input1, input2, result, 
				ALU_f alu_op, 
				int total);

	//Setup test 1
	repeat(2) 
		@(posedge clk);
	input1 = 16'hC3C3;
	input2 = 16'hC3C3;
	alu_op = ALU_f_MINUS;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'h0000 && alu_carry == 1'b0) begin
		$display ("MINUS TEST 1 : PASSED");
		total = total + 1;
	end
    else $error("MINUS TEST 1 : FAILED (Got %0d, Expected 0x0000)", result);

    //Setup test 2
	repeat(2) 
		@(posedge clk);
	input1 = 16'hE0A5;
	input2 = 16'h7003;
	alu_op = ALU_f_MINUS;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'h70A2 && alu_carry == 1'b0) begin
		$display ("MINUS TEST 2 : PASSED");
		total = total + 1;
	end
    else $error("MINUS TEST 2 : FAILED (Got %0d, Expected 0x2222)", result);

    //Setup test 3
	repeat(2) 
		@(posedge clk);
	input1 = 16'hE0A5;
	input2 = 16'h7003;
	alu_op = ALU_f_MINUS;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'h0000 && alu_carry == 1'b1) begin
		$display ("MINUS TEST 3 : PASSED");
		total = total + 1;
	end
    else $error("MINUS TEST 3 : FAILED (Got %0d, Expected 0x????) (Got %d, Expected 1)", result, alu_carry);

	testReset(input1, input2, alu_op);
endtask


/**
 * Tests the lSHIFT instruction for the ALU
 *
 * @test 1
 * @input input1 = 16'h0031
 * @input input2 = 16'h0002
 * @input alu_op = ALU_f_LSHIFT
 * @expected result = 16'h00C4
 * @expected alu_carry = 1'b0
 *
 * @test 2
 * @input input1 = 16'h1111
 * @input input2 = 16'h0001
 * @input alu_op = ALU_f_LSHIFT
 * @expected result = 16'h2222
 * @expected alu_carry = 1'b0
 */
task testLSHIFT(logic clk, alu_carry,
				logic [15:0] input1, input2, result, 
				ALU_f alu_op, 
				int total);
	//Setup test 1
	repeat(2) 
		@(posedge clk);
	input1 = 16'h0031;
	input2 = 16'h0002;
	alu_op = ALU_f_RSHIFT;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'h00C4 && alu_carry == 1'b0) begin
		$display ("LSHIFT TEST 1 : PASSED");
		total = total + 1;
	end
    else $error("LSHIFT TEST 1 : FAILED (Got %0d, Expected 0x00C4)", result);

    //Setup test 2
	repeat(2) 
		@(posedge clk);
	input1 = 16'h1111;
	input2 = 16'h0001;
	alu_op = ALU_f_RSHIFT;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'h2222 && alu_carry == 1'b0) begin
		$display ("LSHIFT TEST 2 : PASSED");
		total = total + 1;
	end
    else $error("LSHIFT TEST 2 : FAILED (Got %0d, Expected 0x2222)", result);

	testReset(input1, input2, alu_op);
endtask


/**
 * Tests the RSHIFT instruction for the ALU
 *
 * @test 1
 * @input input1 = 16'h0031
 * @input input2 = 16'h0002
 * @input alu_op = ALU_f_RSHIFT
 * @expected result = 16'h000C
 * @expected alu_carry = 1'b0
 *
 * @test 2
 * @input input1 = 16'h1111
 * @input input2 = 16'h0001
 * @input alu_op = ALU_f_RSHIFT
 * @expected result = 16'h0888
 * @expected alu_carry = 1'b0
 */
task testRSHIFT(logic clk, alu_carry,
				logic [15:0] input1, input2, result, 
				ALU_f alu_op, 
				int total);
	//Setup test 1
	repeat(2) 
		@(posedge clk);
	input1 = 16'h0031;
	input2 = 16'h0002;
	alu_op = ALU_f_RSHIFT;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'h000C && alu_carry == 1'b0) begin
		$display ("RSHIFT TEST 1 : PASSED");
		total = total + 1;
	end
    else $error("RSHIFT TEST 1 : FAILED (Got %0d, Expected 0x000C)", result);

    //Setup test 2
	repeat(2) 
		@(posedge clk);
	input1 = 16'h1111;
	input2 = 16'h0001;
	alu_op = ALU_f_RSHIFT;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'h0888 && alu_carry == 1'b0) begin
		$display ("RSHIFT TEST 2 : PASSED");
		total = total + 1;
	end
    else $error("RSHIFT TEST 2 : FAILED (Got %0d, Expected 0x0888)", result);

	testReset(input1, input2, alu_op);
endtask


/**
 * Tests the GREATER instruction for the ALU
 *
 * @test 1
 * @input input1 = 16'd180
 * @input input2 = 16'd15
 * @input alu_op = ALU_f_GREATER
 * @expected result = 16'd1
 * @expected alu_carry = 1'b0
 *
 * @test 2
 * @input input1 = 16'd15
 * @input input2 = 16'd180
 * @input alu_op = ALU_f_EQUALS
 * @expected result = 16'd0
 * @expected alu_carry = 1'b0
 *
 * @test 3
 * @input input1 = 16'd15
 * @input input2 = 16'd15
 * @input alu_op = ALU_f_EQUALS
 * @expected result = 16'd0
 * @expected alu_carry = 1'b0
 */
task testGREATER(logic clk, alu_carry,
				logic [15:0] input1, input2, result, 
				ALU_f alu_op, 
				int total);
	//Setup test 1
	repeat(2) 
		@(posedge clk);
	input1 = 16'd180;
	input2 = 16'd15;
	alu_op = ALU_f_GREATER;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'd1 && alu_carry == 1'b0) begin
		$display ("GREATER TEST 1 : PASSED");
		total = total + 1;
	end
    else $error("GREATER TEST 1 : FAILED (Got %d, Expected 1)", result);

	//Setup test 2
	repeat(2) 
		@(posedge clk);
	input1 = 16'd15;
	input2 = 16'd180;
	alu_op = ALU_f_GREATER;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'd0 && alu_carry == 1'b0) begin
		$display ("GREATER TEST 2 : PASSED");
		total = total + 1;
	end
    else $error("GREATER TEST 2 : FAILED (Got %d, Expected 0)", result);

    //Setup test 3
	repeat(2) 
		@(posedge clk);
	input1 = 16'd180;
	input2 = 16'd15;
	alu_op = ALU_f_GREATER;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'd0 && alu_carry == 1'b0) begin
		$display ("GREATER TEST 3 : PASSED");
		total = total + 1;
	end
    else $error("GREATER TEST 3 : FAILED (Got %d, Expected 0)", result);

	testReset(input1, input2, alu_op);
endtask


/**
 * Tests the EQUALS instruction for the ALU
 *
 * @test 1
 * @input input1 = 16'd8
 * @input input2 = 16'd8
 * @input alu_op = ALU_f_EQUALS
 * @expected result = 16'd1
 * @expected alu_carry = 1'b0
 *
 * @test 2
 * @input input1 = 16'd8
 * @input input2 = 16'd9
 * @input alu_op = ALU_f_EQUALS
 * @expected result = 16'd0
 * @expected alu_carry = 1'b0
 */
task testEQUALS(logic clk, alu_carry,
				logic [15:0] input1, input2, result, 
				ALU_f alu_op, 
				int total);
	//Setup test 1
	repeat(2) 
		@(posedge clk);
	input1 = 16'd8;
	input2 = 16'd8;
	alu_op = ALU_f_EQUALS;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'd1 && alu_carry == 1'b0) begin
		$display ("EQUALS TEST 1 : PASSED");
		total = total + 1;
	end
    else $error("EQUALS TEST 1 : FAILED (Got %d, Expected 1)", result);

	//Setup test 2
	repeat(2) 
		@(posedge clk);
	input1 = 16'd8;
	input2 = 16'd9;
	alu_op = ALU_f_EQUALS;

	repeat(2) 
		@(posedge clk);
	assert (result == 16'd0 && alu_carry == 1'b0) begin
		$display ("EQUALS TEST 2 : PASSED");
		total = total + 1;
	end
    else $error("EQUALS TEST 2 : FAILED (Got %d, Expected 0)", result);

	testReset(input1, input2, alu_op);
endtask


/**
 * Tests the INC instruction for the ALU
 *
 * @test 1
 * @input input1 = 16'd8
 * @input alu_op = ALU_f_INC
 * @expected result = 16'd26
 * @expected alu_carry = 1'b0
 */
task testINC(logic clk, alu_carry,
				logic [15:0] input1, input2, result, 
				ALU_f alu_op, 
				int total);
	//Setup
	repeat(2) 
		@(posedge clk);
	input1 = 16'd8;
	input2 = 16'h0000;
	alu_op = ALU_f_INC;
	repeat(16) begin
		@(posedge clk);
		input1 = result;
	end

	//Check
	repeat(2) 
		@(posedge clk);
	assert (result == 16'd26 && alu_carry == 1'b0) begin
		$display ("INC TEST : PASSED");
		total = total + 1;
	end
    else $error("INC TEST : FAILED (Got %d, Expected 24)", result);

	testReset(input1, input2, alu_op);
endtask


module alu_testbench();
	logic clk;
	logic alu_carry;
	logic [15:0] result;
	logic[15:0] input1, input2;
	ALU_f alu_op;
	int total;

	Chip8_ALU dut(
		.input1(input1), 
		.input2(input2), 
		.sel(alu_op),
		.out(result),
		.alu_carry(alu_carry));
	
	initial begin
		clk = 0;
		input1 = 16'h0000;
		input2 = 16'h0000;
		alu_op = ALU_f_NOP;
		forever 
			#20ns clk = ~clk;
	end

	initial begin
		testOR(clk, alu_carry, input1, input2, result, alu_op, total);
		testAND(clk, alu_carry, input1, input2, result, alu_op, total);
		testXOR(clk, alu_carry, input1, input2, result, alu_op, total);
		testADD(clk, alu_carry, input1, input2, result, alu_op, total);
		testMINUS(clk, alu_carry, input1, input2, result, alu_op, total);
		testLSHIFT(clk, alu_carry, input1, input2, result, alu_op, total);
		testRSHIFT(clk, alu_carry, input1, input2, result, alu_op, total);
		testEQUALS(clk, alu_carry, input1, input2, result, alu_op, total);
		testGREATER(clk, alu_carry, input1, input2, result, alu_op, total);
		testINC(clk, alu_carry, input1, input2, result, alu_op, total);
		
		$display("TESTS PASSED : %d", total);
	end
	
endmodule
	
