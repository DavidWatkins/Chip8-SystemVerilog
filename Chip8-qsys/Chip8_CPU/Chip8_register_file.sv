/*
 *
 * Register file allowing for two simultaneous reads and writes
 * 16 8-bit registers (V0 to VF)
 *
 * Implemented by Levi
 *
 */
/*
1) Excluding VF, it allows registers to be addressed at a single time.

2) VF has its own special channel. It can be read from/written to independently of V0-VE.

3) Reading is combinational -- it is always is outputting data 

4) Writing is clocked. 

5) Points 3 and 4 mean that you can read data combinationally, process it, and write it back before the clock cycle goes high again. You can only address 2 registers at a time, so you can read from 2 addresses, process them, and write back to one of them. 
(Ex: Vx = Vx + Vy   works fine but Vx = Vy + Vz    bad)
*/
module Chip8_register_file(
		input logic			cpu_clk, //system clock that controls writing data
		input logic[7:0] 	writedata1, writedata2, VFwritedata, //data to be written to corresponding addresses
		input logic 		WE1, WE2, WEVF, //enable writing on addressed registers
		input logic[3:0]	addr1, addr2, //addresses to write to and read from
		output logic[7:0]	readdata1, readdata2, VFreaddata); //data output from addressed registers

		//writedata1, WE1, addr1, and readdata1 are all grouped together
		//writedata2, WE2, addr2, and readdata2 are all grouped together
		//VFwritedata, WEVF, VFreaddata are all grouped together
		
	logic [15:0][7:0] reg_file;
	
	always_ff @(posedge cpu_clk) begin
		if(WE1) reg_file[addr1] = writedata1;
		if(WE2) reg_file[addr2] = writedata2;
		if(WEVF) reg_file[15] = VFwritedata;
	end
	
	always_comb begin
		readdata1  = reg_file[addr1];
		readdata2  = reg_file[addr2];
		VFreaddata = reg_file[15];
	end
		
		
endmodule	