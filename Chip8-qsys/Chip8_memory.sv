 module Chip8_memory(
		input logic			cpu_clk, //system clock that controls writing data
		input logic[7:0] 	writedata1, writedata2, //data to be written to corresponding addresses
		input logic 		WE1, WE2, //enable writing on addressed registers
		input logic[11:0]	addr1, addr2, //addresses to write to and read from
		output logic[7:0]	readdata1, readdata2); //data output from addressed registers
		
		logic[4095:0][7:0] mem;
		
	always_ff @(posedge cpu_clk) begin
		if(WE1) mem[addr1] <= writedata1;
		if(WE2) mem[addr2] <= writedata2;
	end
	
	always_comb begin
		readdata1  = mem[addr1];
		readdata2  = mem[addr2];
	end
		

endmodule 