module Chip8_Top_test ( ) ;
	//Garbage variables here
	logic         	clk;
	logic         	reset;
	logic [31:0]  	writedata;
	logic 			write;
	logic 	  		chipselect;
	logic [17:0] 	address;

	logic [31:0] data_out;
	logic [7:0]  VGA_R, VGA_G, VGA_B;
	logic        VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n;
	logic        VGA_SYNC_n;

	//Initialize module here
	Chip8_Top(.*);

	initial begin
		clk = 0;
		forever 
			#20ns clk = ~clk;
	end

	initial begin // Initially set the PC to 200
		//Reset
		reset = 0;
		repeat (2)
			@(posedge clk);
		reset = 1;
		repeat (2)
			@(posedge clk);
		reset = 0;
	end
endmodule