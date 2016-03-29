/*
 * Seven-segment LED emulator
 *
 * Stephen A. Edwards, Columbia University
 */

module VGA_LED_Emulator(
 input logic 	    clk50, reset,
 input logic [64][4][8] framebuffer,
 output logic [7:0] VGA_R, VGA_G, VGA_B,
 output logic 	    VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n, VGA_SYNC_n);

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

   logic [10:0]			     hcount; // Horizontal counter
                                             // Hcount[10:1] indicates pixel column (0-639)
   logic 			     endOfLine;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          hcount <= 0;
     else if (endOfLine) hcount <= 0;
     else  	         hcount <= hcount + 11'd 1;

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

   /* 
    *    0 1 2 3 4 5 6 7
    * 
    * 0  afa a a a ab
    * 1  f         b
    * 2  f         b
    * 3  f         b
    * 4  f         b
    * 5  f         b
    * 6 efgggggggggbc 
    * 7  e         c
    * 8  e         c
    * 9  e         c
    * 10 e         c
    * 11 e         c
    * 12 edddddddddc
    * 13
    * 14             h
    * 15
    *
    * 640 x 480
    * 
    * Each seven-segment "pixel" is 8x8: 64 pixels across, 512 pixels for
    * 8 characters being displayed
    * 64 + 512 + 64 = 640  Start in column 64, end in column 576
    * 
    * 128 pixels high: start at row 128, end at row 256
    * 128 + 128 + 224 = 480  Start in row 128
    */

    //Needs to be enlarged
   logic 			     isActivated; // Current framebuffer segment is activated
   assign isActivated = framebuffer[vcount][hcount[9:6]][hcount[5:1]];

   
   always_comb begin
      {VGA_R, VGA_G, VGA_B} = {8'h0, 8'h0, 8'h0}; // Black
      if (isActivated)
        {VGA_R, VGA_G, VGA_B} = {8'h20, 8'h20, 8'h20};
      end  
   
endmodule // VGA_LED_Emulator
