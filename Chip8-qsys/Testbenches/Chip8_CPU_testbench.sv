module testBench ( ) ;
	logic clk;
	logic[15:0] instruction;
	logic[3:0] testIn1, testIn2;
	wire[7:0] testOut1, testOut2;

	//Initialize module here
	Chip8_CPU cpu (.cpu_clk(clk), .*);

	initial begin
		clk = 0;
		forever 
			#20ns clk = ~clk;
	end

	initial begin 
		instruction = 16'h6122;
		repeat (2)
			@(posedge clk);
		instruction = 16'h6020;
		repeat (2)
			@(posedge clk);
		instruction = 16'h8014;
		repeat (2)
			@(posedge clk);
		instruction = 16'h8014;
		repeat (2)
			@(posedge clk);
		instruction = 16'h8013;
		repeat (2)
			@(posedge clk);
		instruction = 16'h8015;
	end
endmodule