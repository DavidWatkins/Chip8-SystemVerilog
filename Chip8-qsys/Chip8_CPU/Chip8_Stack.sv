module Chip8_Stack(
			input logic 		cpu_clk,	//clock
			input logic [1:0]		WE,			//write enable: [0,0] = nothing, [0,1] = push, [1,0] = pop
			input logic [15:0]	writedata,	//input PC
			output logic [15:0]	outdata);	//data output when 
			
			logic	[3:0]  address;
			logic	[15:0]  data;
			logic	  wren;
			logic	[15:0]  q;
			
			stack_ram stack(address, cpu_clk, data, wren, q);
			
			logic[3:0] stackptr = 4'h0;
			logic secondcycle = 1'h0;
			
			
			
			always_ff @(posedge cpu_clk) begin
			
				address = 		4'h0;
				data = 			16'h0;
				wren = 			1'h0;
			
				if(WE == 2'd1) begin
					address <= stackptr;
					data <= writedata;
					if(secondcycle == 1'h0) begin
						wren <= 1'h1;
						secondcycle <= 1'h1;
					end else begin
						wren <= 1'h0;
						stackptr <= stackptr + 4'b0001;
						secondcycle <= 1'h0;
					end
				end if (WE == 2'd2) begin
					address <= stackptr - 4'b0001;
					wren <= 1'h0;
					outdata <= q;
					if(secondcycle == 1'h0) begin
						secondcycle <= 1'h1;
						stackptr <= stackptr - 4'b0001;
					end else begin
						secondcycle <= 1'h0;
					end
				end
			end
endmodule