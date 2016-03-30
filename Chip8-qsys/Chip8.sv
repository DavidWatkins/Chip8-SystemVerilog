/*
 * Chip8 top level (Current a WIP)
 * Top level controller, has direct link to the linux side
 *
 * Columbia University
 */

 
module Chip8_Top(
	input logic          clk,
	input logic          reset,
	input logic [31:0]   linux_write_val,

	output logic [7:0]  VGA_R, VGA_G, VGA_B,
	output logic        VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n,
	output logic        VGA_SYNC_n);

	
	logic [8:0] v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, vA, vB, vC, vD, vE, vF;
	logic [15:0] i, pc, sp;
	logic [511:0] stack;
	logic [32767:0] memory;

	//Framebuffer values
	logic fbreset;
	logic [8:0] fbvx;
	logic [8:0] fbvy;
	logic [8:0] fbdata;
	logic fbwrite;

	always_ff @(posedge clk)
		if(reset) begin
			fbreset <= 1'b1;
			memory <= 32768'd0;
		end else
			if()
		end
	end
				

	Framebuffer framebuffer(.clk(clk), 
							.reset(fbreset), 
							.vx(fbvx),
							.vy(fbvy),
							.write(fbwrite),
							.*);	 
endmodule
