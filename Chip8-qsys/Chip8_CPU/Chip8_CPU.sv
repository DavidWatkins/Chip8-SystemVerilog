

module Chip8_CPU(	input logic cpu_clk,
						input logic[15:0] instruction,
						input logic[7:0] reg_readdata1, reg_readdata2, mem_readdata1, mem_readdata2,
						input logic[15:0] reg_I_readdata,
						input logic[7:0] delay_timer_readdata,
						
						input logic[3:0] CONTROL,
						
						input logic[3:0] testIn1, testIn2,
						
						output logic delay_timer_WE, sound_timer_WE,
						output logic[7:0] delay_timer_writedata, sound_timer_writedata,
						
						output logic reg_WE1, reg_WE2,
						output logic[3:0] reg_addr1, reg_addr2,
						output logic[7:0] reg_writedata1, reg_writedata2,
						
						output logic mem_WE1, mem_WE2,
						output logic[11:0] mem_addr1, mem_addr2,
						output logic[ 7:0] mem_writedata1, mem_writedata2,
						
						output logic reg_I_WE,
						output logic[15:0] reg_I_writedata,
						output logic[7:0] testOut1, testOut2);

		logic[15:0] alu_in1, alu_in2, alu_out;
		logic[3:0] alu_cmd;
		logic alu_carry;
//		logic[7:0] reg_writedata1, reg_writedata2;
//		logic reg_WE1, reg_WE2;
//		logic[3:0] reg_addr1, reg_addr2;
//		logic[7:0] reg_readdata1, reg_readdata2;
		
		wire[15:0] rand_num; 
		Chip8_rand_num_generator(cpu_clk, rand_num);
		wire[7:0] to_bcd;
		wire[3:0] bcd_hundreds, bcd_tens, bcd_ones;
		bcd(to_bcd, bcd_hundreds, bcd_tens, bcd_ones);
		Chip8_ALU alu(alu_in1, alu_in2, alu_cmd, alu_out, alu_carry);
	
//		reg_file register_file(reg_addr1, reg_addr2, cpu_clk, 
//				reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, 
//				reg_readdata1, reg_readdata2);

		always_comb begin
			/*DEFAULT WIRE VALUES BEGIN*/
			alu_in1 = 16'b0;
			alu_in2 = 16'b0;
			alu_cmd = 4'b0;
			reg_writedata1 = 8'b0;
			reg_writedata2 = 8'b0;
			reg_WE1 = 1'b0;
			reg_WE2 = 1'b0;
			reg_addr1 = testIn1;
			reg_addr2 = testIn2;
			reg_I_WE = 1'b0;
			reg_I_writedata = 16'b0;
			delay_timer_WE = 1'b0;
			sound_timer_WE = 1'b0;
			delay_timer_writedata = 8'b0;
			sound_timer_writedata = 8'b0;
			mem_WE1 = 1;
			mem_WE2 = 1;
			mem_addr1 = 12'b0;
			mem_addr2 = 12'b0;
			mem_writedata1 = 8'b0;
			mem_writedata2 = 8'b0;
			to_bcd = 8'b0;
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
			end else if((instruction[15:12]) == (4'h6)) begin
			//6ykk : Vy = kk
				reg_addr1 = instruction[11:8];
				reg_writedata1 = instruction[7:0];
				reg_WE1 = 1'b1;
				testOut1 = instruction[7:0];
				testOut2 = 8'b0;
			end else if((instruction[15:12]) == (4'h7)) begin //7xkk
				reg_addr1 = instruction[11:8];
				alu_in1 = instruction[7:0];
				alu_in2 = reg_readdata1;
				alu_cmd = 4'h4;
				reg_writedata1 = alu_out[7:0];
				reg_WE1 = 1'b1;
			end else if((instruction[15:12] == 4'h8) & (~|instruction[3:0])) begin
				//8xy0 : Vx = Vy
				reg_addr1 = instruction[11:8]; //Vx
				reg_addr2 = instruction[ 7:4]; //Vy
				reg_writedata1 = reg_readdata2;
				reg_WE1 = 1'b1; 
			end else if((instruction[15:12] == 4'h8) & (instruction[3:0] <= (4'h5))) begin
			//8xy1 : Vx = Vx | Vy, 
			//8xy2 : Vx = Vx & Vy, 
			//8xy3 : Vx = Vx XOR Vy, 
			//8xy4 : Vx = Vx ADD Vy, 
			//8xy5 : Vx = Vx SUB Vy
				reg_addr1 = instruction[11:8]; //Vx
				reg_addr2 = instruction[ 7:4]; //Vy
				alu_in1 = reg_readdata1;
				alu_in2 = reg_readdata2;
				alu_cmd = instruction[3:0];
				reg_writedata1 = alu_out[7:0];
				//@TODO: VF write??
				reg_WE1 = 1'b1; 
				testOut1 = alu_out[7:0];
				testOut2 = reg_readdata2;
			end else if((instruction[15:12] == 4'h8) & (instruction[3:0] == (4'h6))) begin
			 	//8xy6: Vx >> 1
				reg_addr1 = instruction[11:8];
				reg_addr2 = 4'hF;
				reg_WE2 = 1'b1;
				if(reg_readdata1[0] == 1'b0) begin
					reg_writedata2 = 8'b0;
				end else begin
					reg_writedata2 = 8'b1;
				end
				alu_in1 = reg_readdata1;
				alu_in2 = 16'd1;
				alu_cmd = 4'h7;
				reg_writedata1 = alu_out[7:0];	
				reg_WE1 = 1;
			end else if((instruction[15:12] == 4'h8) & (instruction[3:0] <= (4'h7))) begin
				//8xy7 : Vx = Vy SUB Vx (similar to 8xy5 but subtraction is backwards)
				reg_addr1 = instruction[11:8]; //Vx
				reg_addr2 = instruction[ 7:4]; //Vy
				alu_cmd = 4'h5;
				alu_in1 = reg_readdata2;
				alu_in2 = reg_readdata1;
				reg_writedata1 = alu_out[7:0];
				reg_WE1 = 1;
				
				//@TODO: VF need be set here?
			end else if((instruction[15:12] == 4'h8) & (instruction[3:0] <= (4'h5))) begin
				//8xyE: Vx >> 1
				reg_addr1 = instruction[11:8];
				reg_addr2 = 4'hF;
				reg_WE2 = 1'b1;
				if(reg_readdata1[7] == 1'b0) begin
					reg_writedata2 = 8'b0;
				end else begin
					reg_writedata2 = 8'b1;
				end
				alu_in1 = reg_readdata1;
				alu_in2 = 16'd1;
				alu_cmd = 4'h6;
				reg_writedata1 = alu_out[7:0];	
				reg_WE1 = 1;
			end else if((instruction[15:12] == 4'hA)) begin
				reg_addr1 = instruction[11:8]; //Vx
				reg_addr2 = instruction[ 7:4]; //Vy
				alu_in1 = reg_readdata1;
				alu_in2 = reg_readdata2;
				alu_cmd = 4'h8;
				//@TODO: prog counter is incread by 2
			end else if((instruction[15:12] == 4'hA)) begin //Annn
				//Annn: I = nnn
				reg_I_writedata = {4'b0,instruction[11:0]};
				reg_I_WE = 1;
			end else if((instruction[15:12] == 4'hB)) begin //Bnnn
				alu_in1 = instruction[11:0]; //?
				reg_addr1 = 4'h0;
				alu_in2 = reg_readdata1;
				alu_cmd = 4'h4;
				//@TODO: program counter = alu_out;
			end else if((instruction[15:12] == 4'hC)) begin //Cxkk
				//Vx = random AND kk
				reg_addr1 = instruction[11:8];
				alu_cmd = 4'h2;
				alu_in1 = instruction[7:0];
				alu_in2 = rand_num;
				reg_writedata1 = alu_out[7:0];
				reg_I_WE = 1;
			end else if((instruction[15:12] == 4'hD)) begin //Dxyn
				//@TODO: sprite stuff
			end else if((instruction[15:12] == 4'hE) & (instruction[7:0] == 8'h9E)) begin //Ex9E
				//@TODO: skip next instruction if key with value Vx is pressed
			end else if((instruction[15:12] == 4'hE) & (instruction[7:0] == 8'hA1)) begin //ExA1
				//@TODO: skip next instruction if key with value Vx is not pressed
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h07)) begin //Fx07
				//set Vx to delay timer value
				reg_addr1 = instruction[11:8];
				reg_writedata1 = delay_timer_readdata;
				reg_WE1 = 1;
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h0A)) begin //Fx0A
				//wait for a key press and then store the key value in Vx
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h15)) begin //Fx15
				//set delay timer to Vx
				reg_addr1 = instruction[11:8];
				delay_timer_writedata = reg_readdata1;
				delay_timer_WE = 1;
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h18)) begin //Fx18
				//set sound timer to Vx
				reg_addr1 = instruction[11:8];
				sound_timer_writedata = reg_readdata1;
				sound_timer_WE = 1;
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h1E)) begin //Fx1E
				//I = I + Vx
				reg_addr1 = instruction[11:8];
				alu_in1 = reg_readdata1;
				alu_in2 = reg_I_readdata;
				alu_cmd = 4'h4;
				reg_I_writedata = alu_out;
				reg_I_WE = 1;
				
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h29)) begin //Fx29
				//@TODO: set 1 to location of sprite for digit Vx
				reg_addr1 = instruction[11:8];
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h33)) begin //Fx33
				//store BCD representation of Vx in I, I+1, I+2
				//NEEDS MULTIPLE CYCLESSSSS!
				reg_addr1 = instruction[11:8];
				to_bcd = reg_readdata1;
				reg_I_writedata = {bcd_hundreds, bcd_tens, bcd_ones, 4'b0};
				reg_I_WE = 1;
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h55)) begin //Fx44
				//store registers V0 through Vx in memory starting at location I
				//THIS is one of those multicycle instructions
				//I expect the instruction to hold over multiple cycles while CONTROL increases by 1 every cycle
				alu_in1 = reg_I_WE;
				alu_in2 = {12'b0, CONTROL};
				alu_cmd = 4'h4; //I + CONTROL
				
				reg_addr1 = CONTROL;
				
				mem_addr1 = alu_out[11:0];
				mem_writedata1 = reg_readdata1;
				mem_WE1 = 1;
				
			end else if((instruction[15:12] == 4'hF) & (instruction[7:0] == 8'h65)) begin //Fx65
				//read registers V0 through Vx in memory starting at location I
				//THIS is one of those multicycle instructions
				//I expect the instruction to hold over multiple cycles while CONTROL increases by 1 every cycle
				alu_in1 = reg_I_WE;
				alu_in2 = {12'b0, CONTROL};
				alu_cmd = 4'h4; //I + CONTROL
				
				reg_addr1 = CONTROL;
				
				mem_addr1 = alu_out[11:0];
				reg_writedata1 = mem_readdata1;
				reg_WE1 = 1;
			end else begin
				reg_addr1 = testIn1;
				reg_addr2 = testIn2;
				testOut1 = reg_readdata1;
				testOut2 = reg_readdata2;
			end

			/*END INSTRUCTION DECODE*/
				
		end
	
	
	
endmodule