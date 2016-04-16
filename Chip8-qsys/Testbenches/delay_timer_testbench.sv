/*********************
* Timer Test Bench
* GT
*********************/

module delay_timer_testbench();
	logic clk;
	logic clk_60;
	logic reset;
	logic [7:0] data;
	logic write_enable;
	wire out;
	
	delay_timer dut(.write_enable, .clk, .clk_60, .data, .out);
	
	initial begin
		clk = 0;
		forever 
			#20ns clk = ~clk;
	end

	initial begin
		clk_60 = 1'b0;
		reset = 0;
		data = 8'b0000_0000;
		write_enable = 0;

		repeat (8) begin
			@(posedge clk);
			clk_60 = ~clk_60;
		end

		clk_60 = 1'b1;
		data = 8'b0000_1000;
		write_enable = 1;

		repeat (2)
			@(posedge clk);
		write_enable = 0;

		repeat (64) begin
			@(posedge clk);
			clk_60 = ~clk_60;
		end

	end
	
endmodule
	