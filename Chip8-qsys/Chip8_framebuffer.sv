/*
 * Chip8 Framebuffer Module
 *
 * Columbia University
 */

module Chip8_Framebuffer(
         input logic          clk,
         input logic          reset,
         input logic          write,
         input logic [7:0]    writedata,
         input logic [7:0]    vx,
         input logic [7:0]    vy,

         output logic [7:0]   VGA_R, VGA_G, VGA_B,
         output logic         VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n,
         output logic         VGA_SYNC_n);

   
   logic [64][4][8] framebuffer; //4 * 8 = 32

   VGA_LED_Emulator led_emulator(.clk50(clk), .*);

   always_ff @(posedge clk)
     if (reset) begin
        //Need to use some kind of loop or something to reset all values
     end else if (write)
       framebuffer[vy][vx] = writedata
         
endmodule
