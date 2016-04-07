

module Chip8_CPU(	input logic cpu_clk,
						input logic[15:0] instruction,
						input logic[3:0] testIn1, testIn2,
						output logic[7:0] testOut1, testOut2);

		
//		wire alu_in1, alu_in2, alu_cmd, alu_out, alu_carry;
		wire[15:0] alu_in1, alu_in2, alu_out;
		wire[3:0] alu_cmd;
		wire alu_carry;
		wire[7:0] reg_writedata1, reg_writedata2, reg_VFwritedata;
		wire reg_WE1, reg_WE2, reg_WEVF;
		wire[3:0] reg_addr1, reg_addr2;
		wire[7:0] reg_readdata1, reg_readdata2, reg_VFreaddata;
		
		Chip8_ALU alu(alu_in1, alu_in2, alu_cmd, alu_out, alu_carry);
		Chip8_register_file register_file(cpu_clk, reg_writedata1, reg_writedata2, reg_VFwritedata,
			reg_WE1, reg_WE2, reg_WEVF, reg_addr1, reg_addr2,
			reg_readdata1, reg_readdata2, reg_VFreaddata);
		
		//always_ff @(posedge cpu_clk) begin
		always_comb begin
			/*DEFAULT WIRE VALUES BEGIN*/
			alu_in1 = 16'b0;
			alu_in2 = 16'b0;
			alu_cmd = 4'b0;
			alu_carry = 1'b0;
			reg_writedata1 = 8'b0;
			reg_writedata2 = 8'b0;
			reg_VFwritedata = 8'b0;
			reg_WE1 = 1'b0;
			reg_WE2 = 1'b0;
			reg_WEVF = 1'b0;
			reg_addr1 = testIn1;
			reg_addr2 = testIn2;
			testOut1 = reg_readdata1;
			testOut2 = reg_readdata2;
			/*END DEFAULT VALUES*/
			
			
			/*BEGIN INSTRUCTION DECODE*/
			if((instruction[15:12]) == (4'd6)) begin
			//6ykk : Vy = kk
				reg_addr1 = instruction[11:8];
				reg_writedata1 = instruction[7:0];
				reg_WE1 = 1'b1;
			end else if((instruction[15:12] == 4'd8) & (~|instruction[3:0])) begin
			//8xy0 : Vx = Vy
				reg_addr1 = instruction[11:8]; //Vx
				reg_addr2 = instruction[ 7:4]; //Vy
				reg_writedata1 = reg_readdata2;
				reg_WE1 = 1'b1; 
			end 
			/*END INSTRUCTION DECODE*/
				
		end
	
	
	
endmodule