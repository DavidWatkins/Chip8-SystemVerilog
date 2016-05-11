`timescale 1ns/100ps

`include "../enums.svh"

module Stack_playground();

	logic 		cpu_clk;	//clock
	logic 		reset;		//reset
	STACK_OP 		op;			//See enums.svh for ops
	logic [15:0]	writedata;	//input PC
	logic [15:0]	outdata;		//data output 
	Chip8_Stack stack(.*);
	

	initial begin
		cpu_clk = 0;
		reset = 1'b1;
		forever begin
			#20ns cpu_clk = 1;
			#20ns cpu_clk = 0;
		end
	end	
	
	initial begin
		
		repeat(1) @(posedge cpu_clk);
		reset = 1'b0;
		repeat(1) @(posedge cpu_clk);

		op = STACK_PUSH;
		writedata = 16'hFF;
		repeat(6) @(posedge cpu_clk);
		op = STACK_HOLD;
		repeat(2) @(posedge cpu_clk);
		op = STACK_PUSH;
		writedata = 16'h66;
		repeat(2) @(posedge cpu_clk);
		op = STACK_HOLD;
		
		repeat(3) @(posedge cpu_clk);
		op = STACK_POP;
		repeat(5) @(posedge cpu_clk);
		op = STACK_HOLD;
		repeat(5) @(posedge cpu_clk);
		op = STACK_POP;
		repeat(5) @(posedge cpu_clk);
		op = STACK_POP;

	end
	
endmodule
