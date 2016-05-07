`include "../enums.svh"

module Chip8_Stack(
	input logic 		cpu_clk,	//clock
	input logic 		reset,		//reset
	input STACK_OP 		op,			//See enums.svh for ops
	input logic [15:0]	writedata,	//input PC
	output logic [15:0]	outdata		//data output 
);	
	
	logic [3:0]  address = 4'd0;
	logic [15:0] data;
	logic	  	 wren;
	logic [15:0] q;
	
	stack_ram stack(address, cpu_clk, data, wren, q);
	
	logic[3:0] 	stackptr = 4'h0;
	logic 		secondcycle = 1'h0;
	logic 		hold = 1'h0;
	
	always_ff @(posedge cpu_clk) begin
		if(reset) begin
			address <= 4'd0;
			hold <= 1'd0;
			wren <= 1'b0;
			secondcycle <= 1'h0;
			stackptr <= 4'd0;
		end else begin
			case (op)
				STACK_PUSH: begin
					if(~hold) begin
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
					end
				end
				STACK_POP: begin
					if(~hold) begin
						address <= stackptr - 4'b0001;
						wren <= 1'h0;
						outdata <= q;
						if(secondcycle == 1'h0) begin
							secondcycle <= 1'h1;
							stackptr <= stackptr - 4'b0001;
						end else begin
							secondcycle <= 1'h0;
							hold <= 1'b1;
						end
					end
				end
				STACK_HOLD: hold = 1'b0;
				default : /* default */;
			endcase
		end
	end
endmodule
