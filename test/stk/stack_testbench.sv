/******************************************************************************
 * stack_testbench.sv
 * 
 * Contains tests for stack push and pop operations.
 * Stack is used by Chip8_CPU.sv
 * Relies on enums.svh for operations
 * 
 * AUTHORS: Gabrielle Taylor
 * 
 *****************************************************************************/

`include "../enums.svh"

task automatic testReset(logic [15:0] data, logic rst, STACK_OP stk_op);

	data = 16'h0000;
	stk_op = STACK_HOLD;
	rst = 0;
	
endtask

task automatic testStack(ref logic clk, rst, ref logic [15:0] data, out
			ref STACK_OP op, ref int total);
	
	repeat (2) 
		@(posedge clk);
	// push to stack
	// size = 1
	data = 16'd61440;
	op = STACK_PUSH;
	// wait one cycle
	repeat (2) 
		@(posedge clk);
	op = STACK_HOLD;
	
	
	repeat (2) 
		@(posedge clk);
	// push to stack
	// size = 2
	data = 16'd3840;
	op = STACK_PUSH;
	// wait one cycle
	repeat (2) 
		@(posedge clk);
	op = STACK_HOLD;
	
	repeat (2) 
		@(posedge clk);	
	// push to stack
	// size = 3
	data = 16'd240;
	op = STACK_PUSH;
	// wait one cycle
	repeat (2)
		@(posedge clk);
	op = STACK_HOLD;

	repeat (2)
		@(posedge clk);
		

	// push to stack
	// size = 4
	data = 16'd15;
	op = STACK_PUSH;
	// wait one cycle
	repeat (2)
		@(posedge clk);
	op = STACK_HOLD;
	repeat (2)
		@(posedge clk);


	// pop from stack
	// size = 3
	//output: 16'd15
	op = STACK_POP;
	// wait one cycle
	repeat (2)
		@(posedge clk);
	op = STACK_HOLD;
	repeat (2)
		@(posedge clk);
	assert (out == 16'd15) begin
		$display ("STACK TEST 1 : PASSED");
		total = total + 1;
	end
    else $error("STACK TEST 1 : FAILED (Pushed 15, Popped %d)", out);

	// pop from stack
	// size = 2
	// out should = 16'd240
	op = STACK_POP;
	// wait one cycle
	repeat (2)
		@(posedge clk);
	op = STACK_HOLD;
	repeat (2)
		@(posedge clk);
	assert (out == 16'd240) begin
		$display ("STACK TEST 2 : PASSED");
		total = total + 1;
	end
    else $error("STACK TEST 2 : FAILED (Pushed 240, Popped %d)", out);
		

	// pop from stack
	// size = 1
	// out should = 16'd3840
	op = STACK_POP;
	// wait one cycle
	repeat (2)
		@(posedge clk);
	op = STACK_HOLD;
	repeat (2)
		@(posedge clk);
	assert (out == 16'd3840) begin
		$display ("STACK TEST 3 : PASSED");
		total = total + 1;
	end
    else $error("STACK TEST 3 : FAILED (Pushed 3840, Popped %d)", out);
		
	// push to stack
	// size = 2
	data = 16'd34954;
	op = STACK_PUSH;
	// wait one cycle
	repeat (2)
		@(posedge clk);
	op = STACK_HOLD;
	repeat (2)
		@(posedge clk);

	// pop from stack
	// size = 1
	// out should = 16'd34952
	op = STACK_POP;
	// wait one cycle
	repeat (2)
		@(posedge clk);
	op = STACK_HOLD;
	repeat (2)
		@(posedge clk);
	assert (out == 16'd3840) begin
		$display ("STACK TEST 4 : PASSED");
		total = total + 1;
	end
    else $error("STACK TEST 4 : FAILED (Pushed 34952, Popped %d)", out);
		
	// pop from stack
	// size = 0
	// out should = 16'd61140
	op = STACK_POP;
	// wait one cycle
	repeat (2)
		@(posedge clk);
	op = STACK_HOLD;
	repeat (2)
		@(posedge clk);	
	assert (out == 16'd61140) begin
		$display ("STACK TEST 5 : PASSED");
		total = total + 1;
	end
    else $error("STACK TEST 5 : FAILED (Pushed 61140, Popped %d)", out);
	
endtask


module stack_testbench();
	logic clk;
	logic rst;
	logic [15:0] data;
	STACK_OP op;
	logic [15:0] out;
	int total;
	
	Chip8_Stack dut(
		.cpu_clk(clk), 
		.reset(rst),
		.op(op), 
		.writedata(data),
		.outdata(out)
		);
	
	initial begin
		clk = 0;
		rst = 0;
		data = 16'd0;
		op = STACK_HOLD;
		forever 
			#20ns clk = ~clk;
	end

	initial begin
		
		$display("Starting test script...");
		testStack(clk, rst, op, data, out);
		$display("TESTS PASSED : %d", total);
		
	end
	
endmodule
	
