/******************************************************************************
 * Stack Test Bench
 *
 * Author: Gabrielle Taylor
 *****************************************************************************/

module stack_testbench();
	logic clk;
	logic reset;
	logic [4:0] fb_addr_y;
	logic [5:0] fb_addr_x;
	logic fb_writedata;
	logic fb_WE;
	logic fb_readdata;
	logic [7:0] VGA_R, VGA_G, VGA_B;
	logic VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n;
	logic VGA_SYNC_n;
	
	Chip8_framebuffer dut(.*);
	
	initial begin
		clk = 0;
		fb_addr_y = 5'b00000;
		fb_addr_x = 6'b000000;
		fb_writedata = 0;
		fb_WE = 0;
		forever 
			#20ns clk = ~clk;
	end

	initial begin
		
		repeat(4) @(posedge clk);
		
		fb_addr_y = 5'b00001;
		fb_addr_x = 6'b000001;
		fb_writedata = 1;
		fb_WE = 1;
		repeat(2) @(posedge clk);
		
		fb_addr_y = 5'b00010;
		fb_addr_x = 6'b000010;
		fb_writedata = 1;
		repeat(2) @(posedge clk);

		fb_addr_y = 5'b00100;
		fb_addr_x = 6'b000100;
		fb_writedata = 1;
		repeat(2) @(posedge clk);

		fb_addr_y = 5'b01000;
		fb_addr_x = 6'b001000;
		fb_writedata = 1;
		repeat(2) @(posedge clk);

		fb_addr_y = 5'b10000;
		fb_addr_x = 6'b010000;
		fb_writedata = 1;
		repeat(2) @(posedge clk);

		fb_WE = 0;
		repeat(2) @(posedge clk);

	end
	
endmodule
	
