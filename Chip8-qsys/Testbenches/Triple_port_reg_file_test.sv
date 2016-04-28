`timescale 10ns/10ns

module Triple_port_reg_file_test ( ) ;
	logic			cpu_clk; //system clock that controls writing data
	logic[7:0] 	writedata1, writedata2, VFwritedata; //data to be written to corresponding addresses
	logic 		WE1, WE2, WEVF; //enable writing on addressed registers
	logic[3:0]	addr1, addr2; //addresses to write to and read from
	logic[7:0]	readdata1, readdata2, VFreaddata; //data output from addressed registers
	
	
	//Initialize module here
	Chip8_register_file tprf (.cpu_clk(cpu_clk), .*);

	initial begin
		cpu_clk = 0;
		forever 
			#20ns cpu_clk = ~cpu_clk;
	end
	
	initial begin 
		WE1 = 1;
		writedata1 = 8'hEE;
		addr1 = 4'h0;
		repeat (2)
			@(posedge cpu_clk);
		WE2 = 1;
		writedata2 = 8'h44;
		addr2 = 4'h1;
		repeat (2)
			@(posedge cpu_clk);
		WEVF = 1;
		VFwritedata = 8'hFF;
		repeat (2)
			@(posedge cpu_clk);
		WE1 = 0;
		WE2 = 0;
		WEVF = 0;
		addr1 = 4'h0;
		addr2 = 4'h0;
		repeat (2)
			@(posedge cpu_clk);
		WE1 = 1;
		WE2 = 1;
		WEVF = 1;
		addr1 = 4'h5;
		writedata1 = 8'h5;
		addr2 = 4'h6;
		writedata2 = 8'h6;
		VFwritedata = 8'hFE;
		repeat (2)
			@(posedge cpu_clk);
		WE1 = 0;
		WE2 = 0;
		WEVF = 0;
		addr1 = 4'h0;
		addr2 = 4'h0;
		repeat (2)
			@(posedge cpu_clk);
		addr1 = 4'h5;
		addr2 = 4'h6;
		repeat (2)
			@(posedge cpu_clk);
		addr1 = 4'h0;
		addr2 = 4'h1;
	end
endmodule 