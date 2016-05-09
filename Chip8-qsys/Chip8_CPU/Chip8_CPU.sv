/******************************************************************************
 * CHIP8_CPU.sv
 *
 * Contains the code for interpreting and running instructions as per the Chip8
 * ISA defined at: http://devernay.free.fr/hacks/chip8/C8TECH10.HTM
 * 
 * The main idea behind the instructions is that initially the CPU will request
 * data from registers and memory at stage 0, and then operate on the data 
 * returned by the request at stage i, where i > 0. This way the CPU can handle
 * instructions that operate over multiple cycles and return values that are
 * a function of the number of cycles that have occured. 
 *
 * AUTHORS: David Watkins, Levi Oliver
 * Dependencies:
 * 	- Chip8_CPU/Chip8_ALU.sv
 *	- Chip8_CPU/Chip8_rand_num_generator.sv
 *	- Chip8_CPU/bcd.sv
 * 	- enums.svh
 * 	- utils.svh
 *****************************************************************************/

`include "../enums.svh"
`include "../utils.svh"

module Chip8_CPU(	
	input logic cpu_clk,
	input logic[15:0] instruction,
	input logic[7:0] reg_readdata1, reg_readdata2, 
					 mem_readdata1, mem_readdata2,
	input logic[15:0] reg_I_readdata,
	input logic[7:0] delay_timer_readdata,

	input logic key_pressed,
	input logic[3:0] key_press,
	
	input logic[11:0] PC_readdata,

	input logic[31:0] stage,

	input logic fb_readdata,

	input Chip8_STATE top_level_state,

	output logic delay_timer_WE, sound_timer_WE,
	output logic[7:0] delay_timer_writedata, sound_timer_writedata,
	
	output PC_SRC pc_src,
	output logic[11:0] PC_writedata,
	
	output logic reg_WE1, reg_WE2,
	output logic[3:0] reg_addr1, reg_addr2,
	output logic[7:0] reg_writedata1, reg_writedata2,
	
	output logic mem_WE1, mem_WE2,
	output logic[11:0] mem_addr1, mem_addr2,
	output logic[ 7:0] mem_writedata1, mem_writedata2,
	output logic       mem_request,
	
	output logic reg_I_WE,
	output logic[15:0] reg_I_writedata,

	output logic stk_reset, 
	output STACK_OP stk_op,
	output logic[15:0] stk_writedata,

	output logic [4:0]	fb_addr_y,//max val = 31
	output logic [5:0]	fb_addr_x,//max val = 63
	output logic		fb_writedata, //data to write to addresse.
	output logic		fb_WE, //enable writing to address
	output logic		fbreset,

	output logic		bit_overwritten, //VF overwritten
	output logic 		isDrawing, 		 //Draw instruction where VF could be overwritten

	output logic halt_for_keypress
);

	logic[15:0] alu_in1, alu_in2, alu_out;
	ALU_f alu_cmd;
	logic alu_carry;
	
	wire[15:0] rand_num; 
	logic[7:0] to_bcd;
	wire[3:0] bcd_hundreds, bcd_tens, bcd_ones;
	
	wire[31:0] stage_shift_hold = (stage >> 32'h4) - 32'h1;
	wire[7:0] stage_shifted_by4_minus1 = stage_shift_hold[7:0];
	logic[3:0] num_rows_written; //used for sprite writing

	Chip8_rand_num_generator rand_num_generator(cpu_clk, rand_num);
	bcd binary_to_dec(to_bcd, bcd_hundreds, bcd_tens, bcd_ones);
	Chip8_ALU alu(alu_in1, alu_in2, alu_cmd, alu_out, alu_carry);
	
	always_comb begin
		/*DEFAULT WIRE VALUES BEGIN*/
		delay_timer_WE 			= 1'b0;
		sound_timer_WE 			= 1'b0;
		delay_timer_writedata	= 8'b0;
		sound_timer_writedata	= 8'b0;
		pc_src 					= PC_SRC_NEXT;
		PC_writedata 			= 12'b0;
		reg_WE1 				= 1'b0;
		reg_WE2 				= 1'b0;
		reg_addr1 				= 4'b0;
		reg_addr2 				= 4'b0;
		reg_writedata1 			= 8'b0;
		reg_writedata2			= 8'b0;
		mem_WE1 				= 1'b0;
		mem_WE2 				= 1'b0;
		mem_addr1 				= 12'h0;
		mem_addr2 				= 12'h0;
		mem_request             = 1'b0;
		mem_writedata1			= 8'h0;
		mem_writedata2			= 8'h0;
		reg_I_WE 				= 1'b0;
		reg_I_writedata			= 16'h0;
		fb_addr_y				= 5'h0;
		fb_addr_x				= 6'h0;
		fb_writedata			= 1'b0;
		fb_WE					= 1'b0;
		fbreset 				= 1'b0;
		num_rows_written		= 4'h0;
		bit_overwritten 		= 1'b0;
		halt_for_keypress 		= 1'b0;
		alu_in1 				= 16'h0;
		alu_in2 				= 16'h0;
		alu_cmd 				= ALU_f_NOP;
		to_bcd 					= 8'h0;
		stk_op					= STACK_HOLD;
		stk_reset 				= 1'b0;
		stk_writedata 			= 16'b0;
		isDrawing 				= 1'b0;
		/*END DEFAULT VALUES*/
		
		
		/*BEGIN INSTRUCTION DECODE*/
		if(top_level_state == Chip8_RUNNING && stage != 32'h0) begin
		casex (instruction)
			// 16'h???: begin
			//This instruction is only used on the old computers on which Chip-8
			//was originally implemented. It is ignored by modern interpreters.
			// end

			16'h00E0: begin //00E0 - CLS
				//Clear the screen
				if(stage == 32'h2) begin
					fbreset = 1'b1;
				end else if (stage > 32'h2 & stage < 32'd8189) begin
					fb_addr_x = stage[7:2];
					fb_addr_y = stage[12:8];
					fb_WE = 1'b1;
					fb_writedata = 1'b0;
					//CPU DONE
				end
			end

			16'h00EE: begin //00EE - RET
				//Return from a subroutine.
				//The interpreter sets the program counter to the address at the
				//top of the stack, then subtracts 1 from the stack pointer.
				if(stage == 32'h3 || stage == 32'h4) begin //two stages b/c stack takes two cycles
					stk_op = STACK_POP;
					pc_src = PC_SRC_STACK;
				end else begin
					//CPU DONE
				end
			end

			16'h1xxx: begin //1nnn - JP addr
				//Jump to location nnn.
				//The interpreter sets the program counter to nnn.
				if(stage == 32'h3) begin
					pc_src = PC_SRC_ALU;
					PC_writedata = instruction[11:0];
				end else begin
					//CPU DONE
				end
			end

			16'h2xxx: begin //2nnn - CALL addr
				//Call subroutine at nnn.
				//The interpreter increments the stack pointer, then puts the
				//current PC on the top of the stack. The PC is then set to nnn.

				if(stage == 32'h3) begin
					stk_op = STACK_PUSH;
					stk_writedata = PC_readdata;
					pc_src = PC_SRC_ALU;
					PC_writedata = instruction[11:0];
				end else begin
					//CPU DONE
				end
			end

			16'h3xxx: begin //3xkk - SE Vx, byte
				//Skip next instruction if Vx = kk.
				//The interpreter compares register Vx to kk, and if they are
				//equal, increments the program counter by 2.
				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
				end else if(stage == 32'h3 && reg_readdata1 == instruction[7:0]) 
				begin
					reg_addr1 = instruction[11:8];
					pc_src = PC_SRC_SKIP;
				end else begin
					//CPU DONE
				end
			end

			16'h4xxx: begin //4xkk - SNE Vx, byte
				//Skip next instruction if Vx != kk.
				//The interpreter compares register Vx to kk, and if they are 
				//not equal, increments the program counter by 2.
				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
				end else if(stage == 32'h3 && reg_readdata1 != instruction[7:0]) 
				begin
					reg_addr1 = instruction[11:8];
					pc_src = PC_SRC_SKIP;
				end else begin
					//CPU DONE
				end
			end

			16'h5xx0: begin //5xy0 - SE Vx, Vy
				//Skip next instruction if Vx = Vy.
				//The interpreter compares register Vx to register Vy, and if 
				//they are equal, increments the program counter by 2.
				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
					reg_addr2 = instruction[ 7:4];
				end else if(stage == 32'h3 && reg_readdata1 == reg_readdata2) 
				begin
					reg_addr1 = instruction[11:8];
					reg_addr2 = instruction[ 7:4];
					pc_src = PC_SRC_SKIP;
				end else begin
					//CPU DONE
				end
			end

			16'h6xxx: begin //6xkk - LD Vx, byte
				//Set Vx = kk.
				//The interpreter puts the value kk into register Vx.

				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
					reg_writedata1 = instruction[7:0];
					reg_WE1 = 1'b1;
				end else begin
					//CPU DONE
				end
			end

			16'h7xxx: begin //7xkk - ADD Vx, byte
				//Set Vx = Vx + kk.
				//Adds the value kk to the value of register Vx, then stores the
				//result in Vx. 
				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
				end else if(stage == 32'h3) begin
					reg_addr1 = instruction[11:8];
					reg_writedata1 = alu_out[7:0];
					reg_WE1 = 1'b1;

					alu_in1 = reg_readdata1;
					alu_in2 = instruction[7:0];
					alu_cmd = ALU_f_ADD;
				end else begin
					//CPU DONE
				end
			end

			//Arithmetic operators
			16'h8xxx: begin //8xyk
				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
					reg_addr2 = instruction[ 7:4];
				end else if(stage == 32'h3) begin
					case (instruction[3:0])
						4'h0: begin //8xy0 - LD Vx, Vy
							//Set Vx = Vy.
							//Stores the value of register Vy in register Vx.
							reg_addr1 = instruction[11:8];
							reg_addr2 = instruction[ 7:4];
							reg_writedata1 = reg_readdata2;
							reg_WE1 = 1'b1;
						end

						4'h1: begin //8xy1 - OR Vx, Vy
							//Set Vx = Vx OR Vy.
							//Performs a bitwise OR on the values of Vx and Vy, 
							//then stores the result in Vx. A bitwise OR 
							//compares the corrseponding bits from two values, 
							//and if either bit is 1, then the same bit in the 
							//result is also 1. Otherwise, it is 0. 

							alu_cmd = ALU_f_OR;
							alu_in1 = reg_readdata1;
							alu_in2 = reg_readdata2;

							reg_addr1 = instruction[11:8];
							reg_addr2 = instruction[ 7:4];
							reg_WE1 = 1'b1;
							reg_writedata1 = alu_out[7:0];
						end

						4'h2: begin //8xy2 - AND Vx, Vy
							//Set Vx = Vx AND Vy.
							//Performs a bitwise AND on the values of Vx and Vy, 
							//then stores the result in Vx. A bitwise AND 
							//compares the corrseponding bits from two values, 
							//and if both bits are 1, then the same bit in the 
							//result is also 1. Otherwise, it is 0. 

							alu_cmd = ALU_f_AND;
							alu_in1 = reg_readdata1;
							alu_in2 = reg_readdata2;

							reg_addr1 = instruction[11:8];
							reg_addr2 = instruction[ 7:4];
							reg_WE1 = 1'b1;
							reg_writedata1 = alu_out[7:0];
						end

						4'h3: begin //8xy3 - XOR Vx, Vy
							//Set Vx = Vx XOR Vy.
							//Performs a bitwise exclusive OR on the values of 
							//Vx and Vy, then stores the result in Vx. An 
							//exclusive OR compares the corrseponding bits from 
							//two values, and if the bits are not both the same, 
							//then the corresponding bit in the result is set to 
							//1. Otherwise, it is 0. 

							alu_cmd = ALU_f_XOR;
							alu_in1 = reg_readdata1;
							alu_in2 = reg_readdata2;

							reg_addr1 = instruction[11:8];
							reg_addr2 = instruction[ 7:4];
							reg_WE1 = 1'b1;
							reg_writedata1 = alu_out[7:0];
						end

						4'h4: begin //8xy4 - ADD Vx, Vy
							//Set Vx = Vx + Vy, set VF = carry.
							//The values of Vx and Vy are added together. If the 
							//result is greater than 8 bits (i.e., > 255,) VF is 
							//set to 1, otherwise 0. Only the lowest 8 bits of 
							//the result are kept, and stored in Vx.

							alu_cmd = ALU_f_ADD;
							alu_in1 = reg_readdata1;
							alu_in2 = reg_readdata2;

							reg_addr1 = instruction[11:8];
							reg_WE1 = 1'b1;
							reg_writedata1 = alu_out[7:0];

							reg_addr2 = 4'hF;
							reg_WE2 = 1'b1;
							reg_writedata2 = alu_carry;
						end
						
						4'h5: begin //8xy5 - SUB Vx, Vy
							//Set Vx = Vx - Vy, set VF = NOT borrow.
							//If Vx > Vy, then VF is set to 1, otherwise 0. Then 
							//Vy is subtracted from Vx, and the results stored 
							//in Vx.

							alu_cmd = ALU_f_MINUS;
							alu_in1 = reg_readdata1;
							alu_in2 = reg_readdata2;

							reg_addr1 = instruction[11:8];
							reg_WE1 = 1'b1;
							reg_writedata1 = alu_out[7:0];

							reg_addr2 = 4'hF;
							reg_WE2 = 1'b1;
							reg_writedata2 = alu_carry;
						end
						
						4'h6: begin //8xy6 - SHR Vx {, Vy}
							//Set Vx = Vx SHR 1.
							//If the least-significant bit of Vx is 1, then VF 
							//is set to 1, otherwise 0. Then Vx is divided by 2.

							reg_addr1 = instruction[11:8];
							reg_WE2 = 1'b1;
							reg_writedata2 = {7'h0, reg_readdata1[0]};

							alu_cmd = ALU_f_RSHIFT;
							alu_in1 = reg_readdata1;
							alu_in2 = 1;

							reg_addr2 = 4'hF;
							reg_WE1 = 1'b1;
							reg_writedata1 = alu_out[7:0];
						end
						
						4'h7: begin //8xy7 - SUBN Vx, Vy
							//Set Vx = Vy - Vx, set VF = NOT borrow.
							//If Vy > Vx, then VF is set to 1, otherwise 0. Then 
							//Vx is subtracted from Vy, and the results stored 
							//in Vx.

							reg_addr1 = instruction[11:8];

							alu_cmd = ALU_f_MINUS;
							alu_in1 = reg_readdata2;
							alu_in2 = reg_readdata1;

							reg_addr1 = instruction[11:8];
							reg_WE1 = 1'b1;
							reg_writedata1 = alu_out[7:0];

							reg_addr2 = 4'hF;
							reg_WE2 = 1'b1;
							reg_writedata2 = alu_carry;
						end
						
						4'hE: begin //8xyE - SHL Vx {, Vy}
							//Set Vx = Vx SHL 1.
							//If the most-significant bit of Vx is 1, then VF is 
							//set to 1, otherwise to 0. Then Vx is multiplied 
							//by 2.

							reg_addr2 = 4'hF;
							reg_WE2 = 1'b1;
							reg_writedata2 = {7'h0, reg_readdata1[7]};

							alu_cmd = ALU_f_LSHIFT;
							alu_in1 = reg_readdata1;
							alu_in2 = 1;

							reg_addr1 = instruction[11:8];
							reg_WE1 = 1'b1;
							reg_writedata1 = alu_out[7:0];
						end
						
						default : /* default */;
					endcase
				end else begin
					//CPU DONE
				end
			end

			16'h9xx0: begin //9xy0 - SNE Vx, Vy
				//Skip next instruction if Vx != Vy.
				//The values of Vx and Vy are compared, and if they are not 
				//equal, the program counter is increased by 2.

				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
					reg_addr2 = instruction[ 7:4];
				end else if(stage == 32'h3 && reg_readdata1 != reg_readdata2) begin
					reg_addr1 = instruction[11:8];
					reg_addr2 = instruction[ 7:4];
					pc_src = PC_SRC_SKIP;
				end else begin
					//CPU DONE
				end
			end

			16'hAxxx: begin //Annn - LD I, addr
				//Set I = nnn.
				//The value of register I is set to nnn.
				if(stage == 32'h2) begin
					reg_I_WE = 1'b1;
					reg_I_writedata = {4'h0, instruction[11:0]};
				end else begin
					//CPU DONE
				end
				
			end

			16'hBxxx: begin //Bnnn - JP V0, addr
				//Jump to location nnn + V0.
				//The program counter is set to nnn plus the value of V0.

				if(stage == 32'h2) begin
					reg_addr1 = 4'h0;
				end else if(stage == 32'h3) begin
					alu_cmd = ALU_f_ADD;
					alu_in1 = reg_readdata1;
					alu_in2 = instruction[11:0];

					pc_src = PC_SRC_ALU;
					PC_writedata = alu_out[11:0];
				end else begin
					//CPU DONE
				end
			end

			16'hCxxx: begin //Cxkk - RND Vx, byte
				//Set Vx = random byte AND kk.
				//The interpreter generates a random number from 0 to 255, which 
				//is then ANDed with the value kk. The results are stored in Vx. 
				//See instruction 8xy2 for more information on AND.

				if(stage == 32'h2) begin
					alu_cmd = ALU_f_AND;
					alu_in1 = rand_num;
					alu_in2 = instruction[7:0];

					reg_addr1 = instruction[11:8];
					reg_WE1 = 1'b1;
					reg_writedata1 = alu_out[7:0];
				end else begin
					//CPU DONE
				end
				
			end

			16'hDxxx: begin //Dxyn - DRW Vx, Vy, nibble
				//Display n-byte sprite starting at memory location I at 
				//(Vx, Vy), set VF = collision.

				//The interpreter reads n bytes from memory, starting at the 
				//address stored in I. These bytes are then displayed as sprites 
				//on screen at coordinates (Vx, Vy). Sprites are XORed onto the 
				//existing screen. If this causes any pixels to be erased, VF is 
				//set to 1, otherwise it is set to 0. If the sprite is 
				//positioned so part of it is outside the coordinates of the 
				//display, it wraps around to the opposite side of the screen. 
				//See instruction 8xy3 for more information on XOR, and section 
				//2.4, Display, for more information on the Chip-8 screen and 
				//sprites.
				
				if(stage >= 32'h2) begin
					reg_addr1 = instruction[11:8];
					reg_addr2 = instruction[ 7:4];
					
					if(stage <= 32'h15) num_rows_written = 4'b0;
					else num_rows_written = stage_shifted_by4_minus1[3:0];//((stage >> 32'h4) - 32'h1);
					
					mem_addr1 = reg_I_readdata[11:0] + {8'b0,num_rows_written};
					mem_request = (stage >= 32'd16) & (num_rows_written < instruction[3:0]) & !(stage[0]);
					fb_WE = (stage >= 32'd16) & (num_rows_written < instruction[3:0]) & (stage[0]);
					fb_addr_x = reg_readdata1 + ({5'b0, stage[3:1]});
					fb_addr_y = reg_readdata2 + ({4'b0, num_rows_written});
					fb_writedata = mem_readdata1[stage[3:1]] ^ fb_readdata;
					bit_overwritten = (mem_readdata1[stage[3:1]]) & (fb_readdata) & fb_WE;
						//bit_overwritten goes high whenever a pixel is set from 1 to 0
					isDrawing = 1'b1;
				end
				
			end
			16'hEx9E: begin //Ex9E - SKP Vx
				//Skip next instruction if key with the value of Vx is pressed.
				//Checks the keyboard, and if the key corresponding to the value 
				//of Vx is currently in the down position, PC is increased by 2.

				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
				end else if(stage == 32'h3 && key_pressed && key_press == reg_readdata1) begin
					pc_src = PC_SRC_SKIP;
					//CPU DONE
				end else begin
					//CPU DONE
				end
			end

			16'hExA1: begin //ExA1 - SKNP Vx
				//Skip next instruction if key with the value of Vx is not 
				//pressed.
				//Checks the keyboard, and if the key corresponding to the value 
				//of Vx is currently in the up position, PC is increased by 2.

				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
				end else if(stage == 32'h3 && key_pressed == 1'h0 || key_press != reg_readdata1) begin
					pc_src = PC_SRC_SKIP;
				end else begin
					//CPU DONE
				end
			end


			//F Instructions
			16'hFx07: begin //Fx07 - LD Vx, DT
				//Set Vx = delay timer value.
				//The value of DT is placed into Vx.

				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
					reg_writedata1 = delay_timer_readdata;
					reg_WE1 = 1'b1;
				end else begin
					//CPU DONE
				end
			end

			16'hFx0A: begin //Fx0A - LD Vx, K
				//Wait for a key press, store the value of the key in Vx.
				//All execution stops until a key is pressed, then the value of 
				//that key is stored in Vx.

				if(stage == 32'h2) begin
					halt_for_keypress = 1'b1;
				end else if(key_pressed) begin
					halt_for_keypress = 1'b0;
					reg_addr1 = instruction[11:8];
					reg_writedata1 = key_press;
					reg_WE1 = 1'b1;
				end else begin
					//CPU DONE
				end
			end

			16'hFx15: begin //Fx15 - LD DT, Vx
				//Set delay timer = Vx.
				//DT is set equal to the value of Vx.

				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
				end else if(stage == 32'h3) begin
					delay_timer_writedata = reg_readdata1;
					delay_timer_WE = 1'b1;
				end else begin
					//CPU DONE
				end
			end

			16'hFx18: begin //Fx18 - LD ST, Vx
				//Set sound timer = Vx.
				//ST is set equal to the value of Vx.

				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
				end else if(stage == 32'h3) begin
					sound_timer_writedata = reg_readdata1;
					sound_timer_WE = 1'b1;
				end else begin
					//CPU DONE
				end
			end

			16'hFx1E: begin //Fx1E - ADD I, Vx
				//Set I = I + Vx.
				//The values of I and Vx are added, and the results are stored 
				//in I.

				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
				end else if(stage == 32'h3) begin
					alu_cmd = ALU_f_ADD;
					alu_in1 = reg_I_readdata;
					alu_in2 = reg_readdata1;

					reg_I_writedata = alu_out;
					reg_I_WE = 1'b1;
				end else begin
					//CPU DONE
				end
			end

			16'hFx29: begin //Fx29 - LD F, Vx
				//Set I = location of sprite for digit Vx.
				//The value of I is set to the location for the hexadecimal 
				//sprite corresponding to the value of Vx. See section 2.4, 
				//Display, for more information on the Chip-8 hexadecimal font.

				//The chip8 fontset has each character starting from 0 to 80,
				//where each character takes 5 bytes each. 

				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
				end else if(stage == 32'h3) begin
					reg_I_writedata = {12'h0, reg_readdata1[3:0]} * 16'h5;
					reg_I_WE = 1'b1;
				end else begin
					//CPU DONE
				end
			end

			16'hFx33: begin //Fx33 - LD B, Vx
				//Store BCD representation of Vx in memory locations I, I+1, and 
				//I+2.
				//The interpreter takes the decimal value of Vx, and places the 
				//hundreds digit in memory at location in I, the tens digit at 
				//location I+1, and the ones digit at location I+2.

				if(stage == 32'h2) begin
					reg_addr1 = instruction[11:8];
				end else if(stage == 32'h3) begin
					to_bcd = reg_readdata1;
					reg_addr1 = instruction[11:8];

					mem_addr1 = reg_I_readdata[11:0];
					mem_request = 1'b1;
					mem_writedata1 = bcd_hundreds;
					mem_WE1 = 1'b1;
				end else if(stage == 32'h4) begin
					to_bcd = reg_readdata1;
					reg_addr1 = instruction[11:8];

					alu_cmd = ALU_f_ADD;
					alu_in1 = reg_I_readdata;
					alu_in2 = 1;

					mem_addr1 = alu_out[11:0];
					mem_request = 1'b1;
					mem_writedata1 = bcd_tens;
					mem_WE1 = 1'b1;
				end else if(stage == 32'h5) begin
					to_bcd = reg_readdata1;

					alu_cmd = ALU_f_ADD;
					alu_in1 = reg_I_readdata;
					alu_in2 = 2;

					mem_addr1 = alu_out[11:0];
					mem_request = 1'b1;
					mem_writedata1 = bcd_ones;
					mem_WE1 = 1'b1;
				end else begin
					//CPU DONE
				end
			end

			16'hFx55: begin //Fx55 - LD [I], Vx
				//Store registers V0 through Vx in memory starting at location I
				//The interpreter copies the values of registers V0 through Vx 
				//into memory, starting at the address in I.
				if(stage == 32'h2) begin
					reg_addr1 = 4'h0;
				end else if(stage >= 32'h3 & stage <= instruction[11:8] + 3) begin
					reg_addr1 = stage[3:0] - 2'd2;

					alu_cmd = ALU_f_ADD;
					alu_in1 = reg_I_readdata;
					alu_in2 = stage[15:0] - 2'h3;

					mem_addr1 = alu_out[11:0];
					mem_request = 1'b1;
					mem_writedata1 = reg_readdata1;
					mem_WE1 = 1'b1;
				end else begin
					//CPU DONE
				end
				
			end

			16'hFx65: begin //Fx65 - LD Vx, [I]
				//Read registers V0 through Vx from memory starting at location 
				//I.
				//The interpreter reads values from memory starting at location 
				//I into registers V0 through Vx.
				if(stage == 32'h2) begin
					mem_addr1 = reg_I_readdata[11:0];
					mem_request = 1'b1;
				end else if(stage >= 32'h3 & stage <= instruction[11:8] + 3) begin
					alu_cmd = ALU_f_ADD;
					alu_in1 = reg_I_readdata;
					alu_in2 = stage[15:0] - 2'h3;
					mem_addr1 = alu_out[11:0];
					mem_request = 1'b1;

					reg_addr1 = stage[3:0] - 2'h3;
					reg_writedata1 = mem_readdata1;
					reg_WE1 = 1'b1;
				end else begin
					//CPU DONE
				end
				
			end
		
			default : /* default */;
		endcase
		end
		/*END INSTRUCTION DECODE*/
			
	end
	
endmodule