/*********************
* Stack Test Bench
* GT
*********************/

module stack_testbench();
	logic clk;
	logic [15:0] data;
	logic [1:0] write_enable;
	logic [15:0] out;
	
	Chip8_Stack dut(
		.cpu_clk(clk), 
		.WE(write_enable),
		.writedata(data), 
		.outdata(out)
		);
	
	initial begin
		clk = 0;
		data = 16'b0000_0000_0000_0000;
		write_enable = 2'b00;
		forever 
			#20ns clk = ~clk;
	end

	initial begin
		
		repeat(4) 
			@(posedge clk);
		
		// push to stack
		// size = 1
		data = 16'b1111_0000_0000_0000;
		write_enable = 2'b01;
		// wait one cycle
		repeat (2)
			@(posedge clk);
		write_enable = 2'b00;
		repeat (2)
			@(posedge clk);
		
		// push to stack
		// size = 2
		data = 16'b0000_1111_0000_0000;
		write_enable = 2'b01;
		// wait one cycle
		repeat (2)
			@(posedge clk);
		write_enable = 2'b00;
		repeat (2)
			@(posedge clk);
		
		// push to stack
		// size = 3
		data = 16'b0000_0000_1111_0000;
		write_enable = 2'b01;
		// wait one cycle
		repeat (2)
			@(posedge clk);
		write_enable = 2'b00;
		repeat (2)
			@(posedge clk);
		
		// push to stack
		// size = 4
		data = 16'b0000_0000_0000_1111;
		write_enable = 2'b01;
		// wait one cycle
		repeat (2)
			@(posedge clk);
		write_enable = 2'b00;
		repeat (2)
			@(posedge clk);

		// pop from stack
		// size = 3
		write_enable = 2'b10;
		// wait one cycle
		repeat (2)
			@(posedge clk);
		write_enable = 2'b00;
		repeat (2)
			@(posedge clk);
		
		// push to stack
		// size = 4
		//data = 16'b0000_0000_0000_1111;
		//write_enable = 2'b01;
		// wait one cycle
		//repeat (2)
		//	@(posedge clk);
		//write_enable = 2'b00;
		//repeat (2)
		//	@(posedge clk);

		// pop from stack
		// size = 3
		// out should = 16'b0000_0000_0000_1111
		write_enable = 2'b10;
		// wait one cycle
		repeat (2)
			@(posedge clk);
		write_enable = 2'b00;
		repeat (2)
			@(posedge clk);
		

		// pop from stack
		// size = 2
		// out should = 16'b0000_0000_1111_0000
		write_enable = 2'b10;
		// wait one cycle
		repeat (2)
			@(posedge clk);
		write_enable = 2'b00;
		repeat (2)
			@(posedge clk);
		
		// push to stack
		// size = 3
		data = 16'b1000_1000_1000_1000;
		write_enable = 2'b01;
		// wait one cycle
		repeat (2)
			@(posedge clk);
		write_enable = 2'b00;
		repeat (2)
			@(posedge clk);

		// pop from stack
		// size = 2
		// out should = 16'b1000_1000_1000_1000
		write_enable = 2'b10;
		// wait one cycle
		repeat (2)
			@(posedge clk);
		write_enable = 2'b00;
		repeat (2)
			@(posedge clk);
		
		// pop from stack
		// size = 1
		// out should = 16'b0000_1111_0000_0000
		write_enable = 2'b10;
		// wait one cycle
		repeat (2)
			@(posedge clk);
		write_enable = 2'b00;
		repeat (2)
			@(posedge clk);
		
		// pop from stack
		// size = 0
		// out should = 16'b1111_0000_0000_0000
		//write_enable = 2'b10;
		// wait one cycle
		//repeat (2)
		//	@(posedge clk);
		//write_enable = 2'b00;
		//repeat (2)
		//	@(posedge clk);

	end
	
endmodule
	