module Chip8_Stack(
			input logic 		cpu_clk,	//clock
			input logic [1:0]		WE,			//write enable: [0,0] = nothing, [0,1] = push, [1,0] = pop
			input logic [15:0]	writedata,	//input PC
			output logic [15:0]	outdata);	//data output when 
			
			logic	[3:0]  address;
			logic	  clock;
			logic	[15:0]  data;
			logic	  wren;
			logic	[15:0]  q;
			
			stack_ram stack(address, cpu_clk, data, wren, q);
			
			logic[7:0] stackptr;
			//logic[15:0][15:0] stack;
			
			//default
			
			
			
			always_ff @(posedge cpu_clk) begin
			
				address = 		16'h0;
				data = 			16'h0;
				wren = 			1'h0;
			
				if(WE == 2'd1) begin
					//stack[stackptr] <= writedata;
					address <= stackptr;
					data <= writedata;
					wren <= 1'h1;
					stackptr <= stackptr + 1'h1;
				end if (WE == 2'd2) begin
					address <= stackptr + 1'h1;
					wren <= 1'h0;
					outdata <= q;
					//outdata <= stack[stackptr - 1];
					stackptr <= stackptr - 1'h1;
				end
			end
endmodule