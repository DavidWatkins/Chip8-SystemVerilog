/******************************************************************************
 * Chip8_framebuffer.sv
 *
 * Top level framebuffer module that contains the memory for the main view
 * and has wires into the VGA emulator to ouput video
 *
 * Built off of Stephen Edwards's VGA_LED code
 *
 * AUTHORS: David Watkins, Levi Oliver, Ashley Kling, Gabrielle Taylor
 * Dependencies:
 *  - Chip8_VGA_Emulator.sv
 *  - Framebuffer.v
 *****************************************************************************/
module Chip8_framebuffer(
	input logic			clk,
	input logic			reset,
	
	input logic [4:0]	fb_addr_y,//max val = 31
	input logic [5:0]   fb_addr_x,//max val = 63
	input logic			fb_writedata, //data to write to addresse.
	input logic		    fb_WE, //enable writing to address
	input logic         is_paused, 

	output logic		fb_readdata, //data to write to addresse.
	
	output logic [7:0]  VGA_R, VGA_G, VGA_B,
	output logic        VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n,
	output logic        VGA_SYNC_n
);
	
	
	//The framebuffer memory has two ports. One is used
	//constantly and combinationaly by the VGA module.
	//The other one is general purpose. They are named
	//as such ("_addr" and "_general")
	wire[10:0] fb_addr_general = (fb_addr_y << 6) + (fb_addr_x);
	wire[10:0] fb_addr_vga;
	wire fb_writedata_general = fb_writedata;
	wire fb_writedata_vga;
	wire fb_WE_general = fb_WE;
	wire fb_WE_vga = 1'b0;//vga emulator will never write to FB mem
	wire fb_readdata_general;
	wire fb_readdata_vga;
	assign fb_readdata = fb_readdata_general;
	
	Chip8_VGA_Emulator led_emulator(
			.clk50(clk),
			.reset(reset),
			.fb_pixel_data(fb_readdata_vga),
			.fb_request_addr(fb_addr_vga),
			.is_paused(is_paused),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_CLK(VGA_CLK),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK_n(VGA_BLANK_n),
			.VGA_SYNC_n(VGA_SYNC_n)
	);
	
	Framebuffer fbmem (
			.clock(clk),
			.address_a(fb_addr_general),
			.address_b(fb_addr_vga),
			.data_a(fb_writedata_general),
			.data_b(fb_writedata_vga),
			.wren_a(fb_WE_general),
			.wren_b(fb_WE_vga),
			.q_a(fb_readdata_general),
			.q_b(fb_readdata_vga)
	);
	
				 
endmodule
