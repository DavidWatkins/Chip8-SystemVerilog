/*********************
* Timer Test Bench
* GT
*********************/

module test_bench();
	logic clk;
	logic clk_60;
	logic reset;
	logic [7:0] data;
	logic [19:0] count = 20'd0; 
	logic write_enable;
	logic out;
	
	delay_timer dut(.write_enable, .clk, .clk_60, .data, .out);
	
	initial begin
		clk = 0;
		reset = 0;
		data = 8'b0000_0000;
		write_enable = 0;
		out = 0;
		forever 
			#20ns clk = ~clk;
		reset = 0;
		write_enable = 1;
	end
		
	always @(posedge clk) begin
		if(~reset) begin
			clk_60 <= 1'b0;
			if (count == 20'd833333) begin
				count <= 20'd0;
				clk_60 <= 1'b1; //set clock high for one 60 MHz cycle
			end else begin
				count <= count + 20'd1;
			end
		end else begin
			count <= 20'd0;
			clk_60 <= 1'b0;
		end
		
	end
	
endmodule
	