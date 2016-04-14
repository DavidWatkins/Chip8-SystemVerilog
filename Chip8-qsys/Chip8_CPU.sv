

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
			//0nnn ignored; no longer in use
			if((instruction) == (16'he)) begin //00E0
				//clear display
			end else if((instruction) == (16'h00ee)) begin //00EE
				//pop stack & set prog counter to that address
			end else if((instruction[15:12]) == (4'h1)) begin //1nnn
				//set program counter to nnn
			end else if((instruction[15:12]) == (4'h2)) begin //2nnn
				//push current prog counter to stack, set prog counter to nnn
			end else if((instruction[15:12]) == (4'h3)) begin //3xkk
				//if reg Vx = kk, prog counter + 4
			end else if((instruction[15:12]) == (4'h4)) begin //4xkk
				//if reg Vx != kk, prog counter + 4
			end else if((instruction[15:12]) == (4'h5)) begin //5xy0
				//if vx = vy, prog counter + 8
			if((instruction[15:12]) == (4'h6)) begin
			//6ykk : Vy = kk
				reg_addr1 = instruction[11:8];
				reg_writedata1 = instruction[7:0];
				reg_WE1 = 1'b1;
			end else if((instruction[15:12]) == (4'h7)) begin //7xkk
				reg_addr1 = instruction[11:8];
				alu_in1 = instruction[7:0];
				alu_in2 = reg_readdata1;
				alu_cmd = 4'h4;
				reg_writedata1 = alu_out;
				reg_WE1 = 1'b1;
			end else if((instruction[15:12] == 4'h8) & (~|instruction[3:0]))
				//8xy0 : Vx = Vy
				reg_addr1 = instruction[11:8]; //Vx
				reg_addr2 = instruction[ 7:4]; //Vy
				reg_writedata1 = reg_readdata2;
				reg_WE1 = 1'b1; 
			end else if((instruction[15:12] == 4'h8) & (instruction[3:0] <= (4'h5))) begin
			//8xy1 : Vx = Vx | Vy, 8xy2 : Vx = Vx & Vy, 8xy3 : Vx = Vx XOR Vy, 8xy4 : Vx = Vx ADD Vy, 8xy5 : Vx = Vx SUB Vy
				reg_addr1 = instruction[11:8]; //Vx
				reg_addr2 = instruction[ 7:4]; //Vy
				alu_in1 = reg_readdata1;
				alu_in2 = reg_readdata2;
				alu_cmd = instruction[3:0];
				reg_writedata1 = alu_out;
				//VF write??
				reg_WE1 = 1'b1; 
			end else if((instruction[15:12] == 4'h8) & (instruction[3:0] == (4'h6))) begin
			 	//8xy6
			end else if((instruction[15:12] == 4'h8) & (instruction[3:0] <= (4'h7))) begin
				//8xy7
			end else if((instruction[15:12] == 4'h8) & (instruction[3:0] <= (4'h5))) begin
				//8xyE
			end else if((instruction[15:12] == 4'hA)) begin
				reg_addr1 = instruction[11:8]; //Vx
				reg_addr2 = instruction[ 7:4]; //Vy
				alu_in1 = reg_readdata1;
				alu_in2 = reg_readdata2;
				alu_cmd = 4'h8;
				//prog counter is incread by 2
			end else if((instruction[15:12] == 4'hA)) begin //Annn
				//instruction = instruction[11:0];
				//Need to pass in the i register
			end else if((instruction[15:12] == 4'hB)) begin //Bnnn
				alu_in1 = instruction[11:0]; //?
				reg_addr1 = 4'h0;
				alu_in2 = reg_writedata1;
				alu_cmd = 4'h4;
				//program counter = alu_out;
			end else if((instruction[15:12] == 4'hC)) begin //Cxkk
				//Vx = random AND kk
			end else if((instruction[15:12] == 4'hD)) begin //Dxyn
				//sprite stuff
			end else if((instruction[15:12] == 4'hE) & (instruction[7:0] == 8'h9E)) begin //Ex9E
				//skip next instruction if key with value Vx is pressed
			end else if((instruction[15:12] == 4'hE) & (instruction[7:0] == 8'hA1)) begin //ExA1
				//skip next instruction if key with value Vx is not pressed
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h07)) begin //Fx07
				//set Vx to delay timer value
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h0A)) begin //Fx0A
				//wait for a key press and then store the key value in Vx
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h15)) begin //Fx15
				//set delay timer to Vx
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h18)) begin //Fx18
				//set sound timer to Vx
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h1E)) begin //Fx1E
				alu_in1 = instruction; //?
				reg_addr1 = instruction[11:8];
				alu_in2 = reg_readdata1;
				alu_cmd = 4'h4;
				//i register?
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h29)) begin //Fx29
				//set 1 to location of sprite for digit Vx
				reg_addr1 = instruction[11:8];
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h33)) begin //Fx33
				//store BCD representation of Vx in I, I+1, I+2
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h55)) begin //Fx44
				//store registers V0 through Vx in memory starting at location I
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h65)) begin //Fx65
				//read registers V0 through Vx in memory starting at location I
			end 

			/*END INSTRUCTION DECODE*/
				
		end
	
	
	
endmodule