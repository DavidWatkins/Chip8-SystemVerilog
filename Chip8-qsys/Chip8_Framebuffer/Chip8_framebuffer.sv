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
	
	logic[10:0] counter;

	initial begin
		counter = 11'b0;
	end
	
	wire[10:0] copy_from_addr;
	wire[10:0] copy_to_addr;
	wire copy_data;
	wire copyWE;
	wire deadwire;

	logic [31:0] fb_stage;
	logic [31:0] time_since_last_copy;

	initial begin
		time_since_last_copy <= 32'h0;
		fb_stage <= 32'h0;
	end

	always_ff @(posedge clk) begin
		if(fb_WE) begin
			fb_stage <= 32'h0;
		end else if(fb_stage < FRAMEBUFFER_REFRESH_HOLD) begin
			fb_stage <= fb_stage;
		end else begin
			fb_stage <= fb_stage + 32'h1;
		end
	end
	
	always_ff @(posedge clk) begin
		if(fb_stage >= FRAMEBUFFER_REFRESH_HOLD || time_since_last_copy > COPY_THRESHOLD) begin
			counter <= counter + 1;
			
			copyWE <= 1'b1;

			copy_from_addr <= counter + 11'h1;
			copy_to_addr <= counter;

			if(counter == 11'b111_1111_1111) time_since_last_copy <= 32'h0;
		end else begin
			copyWE <= 1'b0;
			time_since_last_copy <= time_since_last_copy + 32'h1;
			counter <= 11'h0;
		end
	end
	
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
	
	Framebuffer from_cpu (
			.clock(clk),
			.address_a(fb_addr_general),
			.address_b(copy_from_addr),
			.data_a(fb_writedata_general),
			.data_b(fb_writedata_vga),
			.wren_a(fb_WE_general),
			.wren_b(fb_WE_vga),
			.q_a(fb_readdata_general),
			.q_b(copy_data)
	);
	
	Framebuffer toscreen (
			.clock(clk),
			.address_a(fb_addr_vga),
			.address_b(copy_to_addr),
			.data_a(fb_writedata_vga),
			.data_b(copy_data),
			.wren_a(fb_WE_vga),
			.wren_b(copyWE),
			.q_a(fb_readdata_vga),
			.q_b(deadwire)
	);
	
				 
endmodule