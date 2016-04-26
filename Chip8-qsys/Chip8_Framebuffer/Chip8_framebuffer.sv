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
 *****************************************************************************/
module Chip8_framebuffer(
	input logic         clk,
	input logic         reset,
	input logic [7:0]   fbvx_read, fbvy_read,
	input logic [7:0]   fbvx_write, fbvy_write,
	input logic [7:0]   fbdata, 
	input logic         write,

	output logic [7:0]  fb_readdata,

	output logic [7:0]  VGA_R, VGA_G, VGA_B,
	output logic        VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n,
	output logic        VGA_SYNC_n
);

	logic[2047:0] framebuffer;

	always_ff @(posedge clk) begin
		if(reset) begin
			framebuffer <= 2048'd0; //This is for real reset later (will be useful for instruction 0x0055)
			framebuffer[805:794]   <= 12'b001000000100;
			framebuffer[869:858]   <= 12'b100100001001;
			framebuffer[933:922]   <= 12'b101111111101;
			framebuffer[997:986]   <= 12'b101011110101;
			framebuffer[1061:1050] <= 12'b111111111111;
			framebuffer[1125:1114] <= 12'b011111111110;
			framebuffer[1189:1178] <= 12'b001000000100;
			framebuffer[1253:1242] <= 12'b010000000010;
		end else if(write) begin
			//Consider merits of checking for xor'd overwriting here, or in the outside. 
			framebuffer[fbvy_write*32 + fbvx_write   ] 	<= fbdata[0];
			framebuffer[fbvy_write*32 + fbvx_write +1] 	<= fbdata[1];
			framebuffer[fbvy_write*32 + fbvx_write +2] 	<= fbdata[2];
			framebuffer[fbvy_write*32 + fbvx_write +3] 	<= fbdata[3];
			framebuffer[fbvy_write*32 + fbvx_write +4] 	<= fbdata[4];
			framebuffer[fbvy_write*32 + fbvx_write +5] 	<= fbdata[5];
			framebuffer[fbvy_write*32 + fbvx_write +6] 	<= fbdata[6];
			framebuffer[fbvy_write*32 + fbvx_write +7] 	<= fbdata[7];
		end

		fb_readdata[0] <= framebuffer[fbvy_read*32 + fbvx_read   ];
		fb_readdata[1] <= framebuffer[fbvy_read*32 + fbvx_read +1];
		fb_readdata[2] <= framebuffer[fbvy_read*32 + fbvx_read +2];
		fb_readdata[3] <= framebuffer[fbvy_read*32 + fbvx_read +3];
		fb_readdata[4] <= framebuffer[fbvy_read*32 + fbvx_read +4];
		fb_readdata[5] <= framebuffer[fbvy_read*32 + fbvx_read +5];
		fb_readdata[6] <= framebuffer[fbvy_read*32 + fbvx_read +6];
		fb_readdata[7] <= framebuffer[fbvy_read*32 + fbvx_read +7];
	end
	
	 Chip8_VGA_Emulator led_emulator(.clk50(clk), .*);
				 
endmodule
