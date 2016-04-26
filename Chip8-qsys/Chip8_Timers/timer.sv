/******************************************************************************
 * timer.sv
 *
 * Module for outputting a count down value based on a 60 Hz clock
 * Used for both the sound_timer and delay_timer in the Chip8_Top module
 *
 * AUTHORS: David Watkins, Gabrielle Taylor
 * Dependencies:
 *****************************************************************************/

module timer (
		input logic write_enable,             //Write enable
		input logic clk,        //50 MHz clock
		input logic clk_60,         //60 Hz clock
		input logic [7:0] data,
		output logic out,
		output logic [7:0] output_data);          
	
		logic [7:0] delay_reg = 8'b0000_0000;
		
		always @(posedge clk) 
		begin
			if(write_enable) begin
				delay_reg <= data;
			end else if (clk_60 & !(|delay_reg)) begin
				delay_reg <= delay_reg - 8'd1;
			end
			out <= |delay_reg;
			output_data <= delay_reg;
		end 
		
endmodule