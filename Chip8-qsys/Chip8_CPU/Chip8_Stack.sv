module Chip8_Stack(
			input logic 		cpu_clk,	//clock
			input logic [1:0]		WE,			//write enable: [0,0] = nothing, [0,1] = push, [1,0] = pop
			input logic [15:0]	writedata,	//input PC
			//input logic [4:0]	stackptr,	//stack pointer adjustments
			output logic [15:0]	outdata);	//data output when 
			
			logic[7:0] stackptr;
			logic[15:0][15:0] stack;
			
			always_ff @(posedge cpu_clk) begin
				if(WE == 2'd1) begin
					stack[stackptr] <= writedata;
					stackptr <= stackptr + 1;
				end if (WE == 2'd2) begin
					outdata <= stack[stackptr - 1];
					stackptr <= stackptr - 1;
				end
endmodule