/*********************
* Delay Timer
*
*********************/

module timer(
		input logic clk_60,
		input logic we,
		input logic cpu_clk,
		input logic [7:0] data_in,
		output logic out);
	
		logic [7:0] delay_reg;
		
		always @(posedge cpu_clk or posedge clk_60) 
			if(cpu_clk & we)
				delay_reg <= data_in;
			else if (!we & clk_60 & !(|delay_reg))
				delay_reg <= delay_reg - 8'd1;
		
		assign out = |delay_reg;
		
endmodule
