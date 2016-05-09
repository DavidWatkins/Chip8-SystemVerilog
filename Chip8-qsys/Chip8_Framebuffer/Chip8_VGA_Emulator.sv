/*
 * Chip8-Framebuffer to VGA module. 
 * Adjusts the dimensions of the screen so that it appears 8 times larger.
 *
 * Developed by Levi and Ash 
 *
 * Built off of Stephen Edwards's code
 * Columbia University
 */

 module Chip8_VGA_Emulator(
 	input logic        clk50, reset,
 	//input logic [2047:0] framebuffer,
	input logic fb_pixel_data,
	input logic is_paused,
	output logic[10:0] fb_request_addr,
 	output logic [7:0] VGA_R, VGA_G, VGA_B,
	output logic       VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n, VGA_SYNC_n);

	/*
	* 640 X 480 VGA timing for a 50 MHz clock: one pixel every other cycle
	* 
	* HCOUNT 1599 0             1279       1599 0
	*             _______________              ________
	* ___________|    Video      |____________|  Video
	* 
	* 
	* |SYNC| BP |<-- HACTIVE -->|FP|SYNC| BP |<-- HACTIVE
	*       _______________________      _____________
	* |____|       VGA_HS          |____|
	*/
	// Parameters for hcount
	parameter HACTIVE      = 11'd 1280,
	HFRONT_PORCH = 11'd 32,
	HSYNC        = 11'd 192,
	HBACK_PORCH  = 11'd 96,   
	HTOTAL       = HACTIVE + HFRONT_PORCH + HSYNC + HBACK_PORCH; // 1600

	// Parameters for vcount
	parameter VACTIVE      = 10'd 480,
	VFRONT_PORCH = 10'd 10,
	VSYNC        = 10'd 2,
	VBACK_PORCH  = 10'd 33,
	VTOTAL       = VACTIVE + VFRONT_PORCH + VSYNC + VBACK_PORCH; // 525

	logic [10:0] hcount; // Horizontal counter // Hcount[10:1] indicates pixel column (0-639)
	logic endOfLine;

	always_ff @(posedge clk50 or posedge reset)
	if (reset)          hcount <= 0;
	else if (endOfLine) hcount <= 0;
	else  	         	hcount <= hcount + 11'd 1;

	assign endOfLine = hcount == HTOTAL - 1;

	// Vertical counter
	logic [9:0] 			     vcount;
	logic 			     endOfField;

	always_ff @(posedge clk50 or posedge reset)
	if (reset)          vcount <= 0;
	else if (endOfLine)
	if (endOfField)   vcount <= 0;
	else              vcount <= vcount + 10'd 1;

	assign endOfField = vcount == VTOTAL - 1;

	// Horizontal sync: from 0x520 to 0x5DF (0x57F)
	// 101 0010 0000 to 101 1101 1111
	assign VGA_HS = !( (hcount[10:8] == 3'b101) & !(hcount[7:5] == 3'b111));
	assign VGA_VS = !( vcount[9:1] == (VACTIVE + VFRONT_PORCH) / 2);

	assign VGA_SYNC_n = 1; // For adding sync to video signals; not used for VGA

	// Horizontal active: 0 to 1279     Vertical active: 0 to 479
	// 101 0000 0000  1280	       01 1110 0000  480
	// 110 0011 1111  1599	       10 0000 1100  524
	assign VGA_BLANK_n = !( hcount[10] & (hcount[9] | hcount[8]) ) &
	!( vcount[9] | (vcount[8:5] == 4'b1111) );   

	/* VGA_CLK is 25 MHz
	*             __    __    __
	* clk50    __|  |__|  |__|
	*        
	*             _____       __
	* hcount[0]__|     |_____|
	*/
	assign VGA_CLK = hcount[0]; // 25 MHz clock: pixel latched on rising edge

	parameter chip_hend = 7'd 64;
	parameter chip_vend = 6'd 32; 

	parameter left_bound = 7'd64;
	parameter right_bound = 10'd576;
	parameter top_bound = 7'd112;
	parameter bottom_bound = 9'd368;
	
	logic[11:0] fb_pos;
	assign fb_request_addr = ((((vcount[8:0] - top_bound) & (8'b1111_1000)) << (4'd3)) + ((hcount[10:1] - left_bound) >> (4'd3)));
								//(((vcount[8:0] - top_bound) >> (4'd3))*(7'd64)) + ((hcount[10:1] - left_bound) >> (4'd3));
								//this commented out line is the old code (which was believed to work). New code is more efficient
								//in area and time. Hopefully this helps if we have a too long critical path
									 

	logic inChip;
   	//120 <= Y-dim < 360
   	//64 <= X-dim < 576

	/*
	*    +--------------------------------+
	*    | VGA Screen (640x480)           |
	*    |   64                      576  |
	*    |    +----------------------+112 |
	*    |    |      Chip8 Screen    |    |
	*    |    |      (64*8x32*8)     |    |
	*    |    +----------------------+368 |
	*    |                                |
	*    +--------------------------------+
   	*/


//   	assign inChip = (((hcount[10:1]) >= (chip_hend * (5'd8) + 7'd64)) & (((hcount[10:1]) < (chip_hend * (5'd8) + 10'd576)) &
//   			((vcount[8:0]) >= (chip_vend * (5'd8) + 7'd112))  & ((vcount[8:0]) < (chip_vend * (5'd8) + 10'd368));
		
		
		assign inChip = (	((hcount[10:1]) >= (left_bound)) &
								((hcount[10:1]) <  (right_bound))	&
								((vcount[8:0])  >= (top_bound)) &
								((vcount[8:0])) <  (bottom_bound)	);


		/**
		 * 16 columns, 8 rows
		 * +-----------------------------------------+
		 * |      px24                               |
		 * |   px48	███ ███ █ █ ███ ███ ███  px432   |
		 * |        █ █ █ █ █ █ █   █   █ ██         |
		 * |        ███ ███ █ █ ███ ███ █  █         |
		 * |        █   █ █ █ █   █ █   █ ██         |
		 * |        █   █ █ ███ ███ ███ ███  px88    | 
		 *
		 */

		parameter paused_left = 10'd64;
		parameter paused_right = 10'd576;
		parameter paused_top = 10'd24;
		parameter paused_bottom = 10'd88;

		logic [9:0] hcount_offseted, vcount_offseted;
		assign hcount_offseted = (hcount[10:1] - paused_left) >> 4;
		assign vcount_offseted = (vcount[8:0] - paused_top) >> 3;

	 	reg  [31:0] romdata [7:0];

		initial begin
		    romdata[7] = 32'b0000_1110_1110_1010_1110_1110_1110_0000;
		    romdata[6] = 32'b0000_1010_1010_1010_1000_1000_1011_0000;
		    romdata[5] = 32'b0000_1110_1110_1010_1110_1110_1001_0000;
		    romdata[4] = 32'b0000_1000_1010_1010_0010_1000_1011_0000;
		    romdata[3] = 32'b0000_1000_1010_1110_1110_1110_1110_0000;
		    romdata[2] = 32'b0;
		    romdata[1] = 32'b0;
		    romdata[0] = 32'b0;
		end
		assign inPaused = is_paused & (
				((hcount[10:1]) >= (paused_left)) &
				((hcount[10:1]) < (paused_right)) &
				((vcount[8:0]) >= (paused_top)) &
				((vcount[8:0]) < (paused_bottom)) & 
				romdata[vcount_offseted][hcount_offseted]
			);
		
   always_comb begin
	  	{VGA_R, VGA_G, VGA_B} = {8'h0, 8'h0, 8'h0}; // Black
	  	if (inChip & fb_pixel_data) begin//framebuffer[fb_pos]) begin
	  		//White to show on-pixel
			{VGA_R, VGA_G, VGA_B} = {8'hFF, 8'hFF, 8'hFF}; 
		end else if(inChip) begin
			//purple to show general area
			{VGA_R, VGA_G, VGA_B} = {8'h0, 8'h0, 8'hFF};
		end else if(inPaused) begin
			{VGA_R, VGA_G, VGA_B} = {8'hFF, 8'hFF, 8'hFF};
		end
	end

endmodule // VGA_LED_Emulator