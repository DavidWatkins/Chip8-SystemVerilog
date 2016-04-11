module clk_div (
	input logic clk_in,
	input logic reset,
	output logic clk_out);
 
	//Input: 50 MHz clock 
	//Output: 60 Hz clock
	//NOTE - Actual output clock frequency: 60.000024 Hz
	//Calculation:
	//50 MHz = 50,000,000 hz
	//50,000,000 hz / 60 hz = 833,333.33
	//Scaling factor rounded to 833,333

	logic [19:0] count;           //counts up to 833333
	logic stop = 20'hcb735;       //833333 in hex

	always @(posedge clk_in)
	begin
		if(~reset) begin
			if (count==stop) begin
				count <= 0;
				clk_out <= ~clk_out; //toggle clock
			end else begin
				count <= count + 1;
				clk_out <= clk_out;
			end
		end else begin
			count <= 0;
			clk_out <= 0;
		end
	end
endmodule


	
