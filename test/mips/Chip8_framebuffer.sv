/*
 * Framebuffer for the chip8
 * Writes information directly to the VGA_LED module to display on VGA
 *
 * Built off of Stephen Edwards's VGA_LED code
 * Columbia University
 */
 
module Framebuffer(
	input logic         clk,
	input logic         reset,
	input logic [7:0]   fbvx,
	input logic [7:0]   fbvy,
	input logic [7:0]   fbdata, 
	input logic         write,

	output logic [7:0]  VGA_R, VGA_G, VGA_B,
	output logic        VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n,
	output logic        VGA_SYNC_n);

	
	logic[2047:0] framebuffer;

	always_ff @(posedge clk)
		if(reset) begin
			framebuffer <= 2048'd0; //This is for real reset later (will be useful for instruction 0x0055)
			framebuffer[805:794]   = 12'b001000000100;
			framebuffer[869:858]   = 12'b100100001001;
			framebuffer[933:922]   = 12'b101111111101;
			framebuffer[997:986]   = 12'b101011110101;
			framebuffer[1061:1050] = 12'b111111111111;
			framebuffer[1125:1114] = 12'b011111111110;
			framebuffer[1189:1178] = 12'b001000000100;
			framebuffer[1253:1242] = 12'b010000000010;
		end else if(write) begin
			//Consider merits of checking for xor'd overwriting here, or in the outside. 
			framebuffer[fbvy*64 + fbvx] = fbdata[0];
			framebuffer[fbvy*64 + fbvx +1] = fbdata[1];
			framebuffer[fbvy*64 + fbvx +2] = fbdata[2];
			framebuffer[fbvy*64 + fbvx +3] = fbdata[3];
			framebuffer[fbvy*64 + fbvx +4] = fbdata[4];
			framebuffer[fbvy*64 + fbvx +5] = fbdata[5];
			framebuffer[fbvy*64 + fbvx +6] = fbdata[6];
			framebuffer[fbvy*64 + fbvx +7] = fbdata[7];
		end
	
	 Chip8_VGA_Emulator led_emulator(.clk50(clk), .*);
				 
endmodule
