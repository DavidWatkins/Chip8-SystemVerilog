/*********************
* Delay Timer
* GT
*********************/

module delay_timer (
		input logic write_enable,             //Write enable
		input logic clk,        //50 MHz clock
		input logic clk_60,         //60 Hz clock
		input logic [7:0] data,
		output logic out);          
	
		logic [7:0] delay_reg = 8'b0000_0000;
		
		always @(posedge clk) 
		begin
			if(clk & write_enable) begin
				delay_reg <= data;
			end else if (!write_enable & clk_60 & !(|delay_reg)) begin
				delay_reg <= delay_reg - 8'd1;
			end
			out <= |delay_reg;
		end 
		
endmodule