module clk_div (
	input logic clk_in,
	input logic reset,    //resets on high
	output logic clk_out);
 
	//Input: 50 MHz clock 
	//Output: 60 Hz clock
	//NOTE - Actual output clock frequency: 60.000024 Hz
	//Calculation:
	//50 MHz = 50,000,000 hz
	//50,000,000 hz / 60 hz = 833,333.33
	//Scaling factor rounded to 833,333

	logic [19:0] count = 20'd0;           //counts up to 833333
	logic [19:0] stop = 20'd833333;       //833333 in hex

	always @(posedge clk_in)
	begin
		if(~reset) begin
			clk_out <= 1'b0;
			if (count==stop) begin
				count <= 20'd0;
				clk_out <= 1'b1; //set clock high for one 60 MHz cycle
			end else begin
				count <= count + 20'd1;
			end
		end else begin
			count <= 20'd0;
			clk_out <= 1'b0;
		end
	end
endmodule

