 /******************************************************************************
 * Chip8_Top.sv
 *
 * Top level Chip8 module that controls all other modules
 *
 * AUTHORS: David Watkins, Levi Oliver, Ashley Kling, Gabrielle Taylor
 * Dependencies:
 *  - Chip8_SoundController.sv
 *  - Chip8_framebuffer.sv
 * 	- timer.sv
 * 	- clk_div.sv
 *  - memory.v
 *  - reg_file.v
 *  - enums.svh
 *  - utils.svh
 *  - Chip8_CPU.sv
 *****************************************************************************/
 
`include "enums.svh"
`include "utils.svh"
 
module Chip8_Top(
	input logic         clk,
	input logic         reset,
	input logic [31:0]  writedata,
	input logic 		write,
	input 		  		chipselect,
	input logic [17:0] 	address,

	output logic [31:0] data_out,

	//VGA Output
	output logic [7:0]  VGA_R, VGA_G, VGA_B,
	output logic        VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n,
	output logic        VGA_SYNC_n,

	//Audio Output
	input  OSC_50_B8A,   	//reference clock
	inout  AUD_ADCLRCK, 	//Channel clock for ADC
    input  AUD_ADCDAT,
    inout  AUD_DACLRCK, 	//Channel clock for DAC
    output AUD_DACDAT,  	//DAC data
    output AUD_XCK, 
    inout  AUD_BCLK, 		//Bit clock
    output AUD_I2C_SCLK, 	//I2C clock
    inout  AUD_I2C_SDAT, 	//I2C data
    output AUD_MUTE   		//Audio mute
);

	logic [15:0] 	I;
	logic [5:0] 	sp;
	logic [63:0][11:0] 	stack;

	//Program counter
	logic [7:0] 	pc_state;
	logic [11:0] 	pc;
	logic [11:0]    next_pc;
	logic [31:0] 	stage;

	//Framebuffer values
	logic 		fbreset;
	logic [7:0] fbvx_read, fbvy_read;
	logic [7:0] fbvx_write, fbvy_write;
	logic [7:0] fbdata;
	logic 		fbwrite;
	logic [7:0] fb_readdata;

	//Keyboard
	logic 		ispressed;
	logic [3:0] key;
	
	//Memory
	logic [7:0] 	memwritedata1, memwritedata2;
	logic 			memWE1, memWE2;
	logic [11:0] 	memaddr1, memaddr2;
	logic [7:0] 	memreaddata1, memreaddata2;

	//Reg file
	logic [7:0] 	reg_writedata1, reg_writedata2;
	logic 			regWE1, regWE2;
	logic [3:0] 	reg_addr1, reg_addr2;
	logic [7:0] 	reg_readdata1, reg_readdata2;

	//CPU
	logic [15:0] 	cpu_instruction;
	logic 			cpu_delay_timer_WE, cpu_sound_timer_WE;
	logic [7:0] 	cpu_delay_timer_writedata, cpu_sound_timer_writedata;
	PC_SRC 			cpu_pc_src;
	logic [11:0] 	cpu_PC_writedata;
	logic 			cpu_reg_WE1, cpu_reg_WE2;
	logic [3:0] 	cpu_reg_addr1, cpu_reg_addr2;
	logic [7:0] 	cpu_reg_writedata1, cpu_reg_writedata2;
	logic 			cpu_mem_WE1, cpu_mem_WE2;
	logic [11:0] 	cpu_mem_addr1, cpu_mem_addr2;
	logic [ 7:0] 	cpu_mem_writedata1, cpu_mem_writedata2;
	logic 			cpu_reg_I_WE;
	logic [15:0] 	cpu_reg_I_writedata;
	logic 			cpu_sp_push, cpu_sp_pop;
	logic 			cpu_fbreset;
	logic [5:0] 	cpu_fbvx_read_addr, cpu_fbvy_read_addr;
	logic [5:0] 	cpu_fbvx_write_addr, cpu_fbvy_write_addr;
	logic 			cpu_fb_WE;
	logic [7:0] 	cpu_fb_writedata;
	logic 			cpu_halt_for_keypress;

	//Sound
 	// logic sound_on;
	logic 			sound_reset;

	//Timers
	logic 			clk_div_reset, clk_div_clk_out;
	logic 			delay_timer_write_enable, delay_timer_out;
	logic [7:0] 	delay_timer_data, delay_timer_output_data;
	logic 			sound_timer_write_enable, sound_timer_out;
	logic [7:0] 	sound_timer_data, sound_timer_output_data;

	//State
	Chip8_STATE state;

	always_ff @(posedge clk) begin
		if(reset) begin
			//Add initial values for code
			pc <= 16'h200;

			fbwrite <= 1'b0;
			memWE1 <= 1'b0;
			memWE2 <= 1'b0;
			cpu_instruction <= 16'h0;
			delay_timer_write_enable <= 1'b0;
			sound_timer_write_enable <= 1'b0;
			I <= 16'h0;
			sp <= 6'h0;
			fbreset <= 1'b0;
			fbwrite <= 1'b0;
			regWE1 <= 1'b0;
			regWE2 <= 1'b0;

			state <= Chip8_PAUSED;
			cpu_instruction <= 16'h0;
			stage <= 32'h0;

		//Handle input from the ARM processor
		end else if(chipselect) begin

			if(address[16]) begin
				memaddr1 <= address[11:0];
				data_out <= memreaddata1;
				if(write) begin
					memWE1 <= 1'b1;
					memwritedata1 <= writedata[7:0];
				end
			end else begin
				case (address) 
				
					//Read/write from register
					inbetween(17'h0, address, 17'hF) : begin
						reg_addr1 <= address[3:0];
						data_out <= {24'h0, reg_readdata1};
						if(write) begin
							regWE1 <= 1'b1;
							reg_writedata1 <= writedata[7:0];
						end
					end

					17'h10 : begin
						I <= writedata[15:0];
						data_out <= {16'b0, I};
					end

					//Read/write to sound_timer
					17'h11 : begin
						data_out <= {24'h0, sound_timer_output_data};
						if(write) begin
							sound_timer_write_enable <= 1'b1;
							sound_timer_data <= writedata[7:0];
						end 
					end

					//Read/write to delay_timer
					17'h12 : begin
						data_out <= {24'h0, delay_timer_output_data};
						if(write) begin
							delay_timer_write_enable <= 1'b1;
							delay_timer_data <= writedata[7:0];
						end
					end
					
					//Read/write to stack pointer
					17'h13 : begin
						data_out <= {26'b0, sp};
						if(write) sp <= writedata[5:0]; //0-63
					end

					//Read/write to program counter
					17'h14 : begin 
						data_out <= {16'b0, pc};
						if(write) pc <= writedata[11:0]; //0-4095
					end

					//Read/write key presses
					17'h15 : begin 
						data_out <= {32'b0}; //No reading keypress
						if(write) begin
							ispressed <= writedata[4];
							key <= writedata[3:0];
						end
					end

					//Read/write the state of the emulator
					17'h16 : begin
						data_out <= {30'b0, state};
						if(write) begin
							case (writedata[1:0])
								2'h0: state <= Chip8_RUNNING;
								2'h1: state <= Chip8_LOADING_ROM;
								2'h2: state <= Chip8_LOADING_FONT;
								2'h3: state <= Chip8_PAUSED;
								default : /* default */;
							endcase
						end
					end

					//Modify framebuffer
					17'h17 : begin
						fbvx_read <= writedata[11:8];
						fbvy_read <= writedata[7:4];
						data_out <=  {24'h0, fb_readdata};

						if(write) begin 
							fbvx_write <= writedata[11:8]; 
							fbvy_write <= writedata[7:4];
							fbdata <= writedata[3:0];
							fbwrite <= 1'b1;
						end
					end

					//Read/write stack
					17'h18 : begin 
						data_out <= {20'b0, stack[sp]};
						if(write) stack[sp] <= 1'b0;
					end	

				endcase
			end

		//Handle current processor state and cpu output
		end else begin
			case (state)
				Chip8_RUNNING: begin
					if(stage == 32'h0) begin
						memaddr1 <= pc;
						memaddr2 <= pc + 1;	
						cpu_instruction <= 16'h0;
					end else if (stage == 32'h1) begin
						cpu_instruction[15:8] <= memreaddata1;
						cpu_instruction[7:0]  <= memreaddata2;
					end else if (stage >= 32'h2) begin

						if(cpu_delay_timer_WE) begin
							delay_timer_write_enable <= 1'b1;
							delay_timer_data <= cpu_delay_timer_writedata;
						end else begin
							delay_timer_write_enable <= 1'b0;
						end

						if(cpu_sound_timer_WE) begin
							sound_timer_write_enable <= 1'b1;
							sound_timer_data <= cpu_sound_timer_writedata;
						end else begin
							sound_timer_write_enable <= 1'b0;
						end

						if(cpu_reg_WE1) begin
							regWE1 <= 1'b1;
							reg_writedata1 <= cpu_reg_writedata1;
						end else begin
							regWE1 <= 1'b0;
						end

						if(cpu_reg_WE2) begin
							regWE2 <= 1'b1;
							reg_writedata2 <= cpu_reg_writedata2;
						end else begin
							regWE2 <= 1'b0;
						end

						if(cpu_mem_WE1) begin
							memwritedata1 <= cpu_mem_writedata1;
							memWE1 <= 1'b1;
						end else begin
							memWE1 <= 1'b0;
						end

						if(cpu_mem_WE2) begin
							memwritedata2 <= cpu_mem_writedata2;
							memWE2 <= 1'b1;
						end else begin
							memWE2 <= 1'b0;
						end

						if(cpu_reg_I_WE) begin
							I <= cpu_reg_I_writedata;
						end else begin
							//Nothing
						end

						if(cpu_sp_push) begin
							if(sp + 1 < 64)
								sp <= sp + 1;
							stack[sp] <= pc;
						end 

						if(cpu_sp_pop) begin
							if(sp - 1 >= 0)
								sp <= sp - 1;
							// pc <= stack[sp];
							next_pc <= stack[sp];
						end else begin
							case (cpu_pc_src)
								PC_SRC_ALU	: next_pc <= cpu_PC_writedata;
								PC_SRC_SKIP	: next_pc <= pc + 4;
								PC_SRC_NEXT	: next_pc <= pc + 2;
								default : next_pc <= pc + 2;
							endcase
						end

						if(cpu_fbreset) begin
							fbreset <= 1'b1;
						end else begin
							fbreset <= 1'b0;
						end

						if(cpu_fb_WE) begin
							fbwrite <= 1'b1;
							fbdata <= cpu_fb_writedata;
							fbvx_write <= cpu_fbvx_write_addr;
							fbvy_write <= cpu_fbvy_write_addr;
						end else begin
							fbwrite <= 1'b0;
						end

						// cpu_halt_for_keypress;

						//Always
						reg_addr1 <= cpu_reg_addr1;
						reg_addr2 <= cpu_reg_addr2;
						fbvx_read <= cpu_fbvx_read_addr;
						fbvy_read <= cpu_fbvy_read_addr;
						memaddr1 <= cpu_mem_addr1;
						memaddr2 <= cpu_mem_addr2;
					end

					//Cap of 50, since 1000 instructions/sec is reasonable
					if(stage + 1 > 50) begin
						stage <= 32'h0;
						pc <= next_pc;
					end else begin
						stage <= stage + 1;
					end
				end
				Chip8_LOADING_ROM: begin
				end
				Chip8_LOADING_FONT: begin
				end
				Chip8_PAUSED: begin
				end
				default : /* default */;
			endcase
		end
	end

	Chip8_framebuffer framebuffer(
		.clk(clk),
		.reset(fbreset),
		.fbvx_read(fbvx_read),
		.fbvy_read(fbvy_read),
		.fbvx_write(fbvx_write),
		.fbvy_write(fbvy_write),
		.fbdata(fbdata),
		.write(fbwrite),
		.fb_readdata(fb_readdata),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_CLK(VGA_CLK),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK_n(VGA_BLANK_n),
		.VGA_SYNC_n(VGA_SYNC_n)
	);	

	memory memory(
		.address_a(memaddr1),
		.address_b(memaddr2),
		.clock(clk),
		.data_a(memwritedata1),
		.data_b(memwritedata2),
		.wren_a(memWE1),
		.wren_b(memWE2),
		.q_a(memreaddata1),
		.q_b(memreaddata2)
	);

	reg_file reg_file(
		.clock(clk),
		.address_a(reg_addr1),
		.address_b(reg_addr2),
		.data_a(reg_writedata1),
		.data_b(reg_writedata2),
		.wren_a(regWE1),
		.wren_b(regWE2),
		.q_a(reg_readdata1),
		.q_b(reg_readdata2)
	);

	Chip8_CPU cpu(	
		.cpu_clk(clk),
		.instruction(cpu_instruction),
		.reg_readdata1(reg_readdata1), 
		.reg_readdata2(reg_readdata2), 
		.mem_readdata1(memreaddata1), 
		.mem_readdata2(memreaddata2),
		.reg_I_readdata(I),
		.delay_timer_readdata(delay_timer_data),
		.key_pressed(ispressed),
		.key_press(key),
		.PC_readdata(pc),
		.stage(stage),
		.top_level_state(state),
		.fb_readdata(fb_readdata),
		.delay_timer_WE(cpu_delay_timer_WE),
		.sound_timer_WE(cpu_sound_timer_WE),
		.delay_timer_writedata(cpu_delay_timer_writedata),
		.sound_timer_writedata(cpu_sound_timer_writedata),
		.pc_src(cpu_pc_src),
		.PC_writedata(cpu_PC_writedata),
		.reg_WE1(cpu_reg_WE1),
		.reg_WE2(cpu_reg_WE2),
		.reg_addr1(cpu_reg_addr1),
		.reg_addr2(cpu_reg_addr2),
		.reg_writedata1(cpu_reg_writedata1),
		.reg_writedata2(cpu_reg_writedata2),
		.mem_WE1(cpu_mem_WE1),
		.mem_WE2(cpu_mem_WE2),
		.mem_addr1(cpu_mem_addr1),
		.mem_addr2(cpu_mem_addr2),
		.mem_writedata1(cpu_mem_writedata1),
		.mem_writedata2(cpu_mem_writedata2),
		.reg_I_WE(cpu_reg_I_WE),
		.reg_I_writedata(cpu_reg_I_writedata),
		.sp_push(cpu_sp_push),
		.sp_pop(cpu_sp_pop),
		.fbreset(cpu_fbreset),
		.fbvx_read_addr(cpu_fbvx_read_addr),
		.fbvy_read_addr(cpu_fbvy_read_addr),
		.fbvx_write_addr(cpu_fbvx_write_addr),
		.fbvy_write_addr(cpu_fbvy_write_addr),
		.fb_WE(cpu_fb_WE),
		.fb_writedata(cpu_fb_writedata),
		.halt_for_keypress(cpu_halt_for_keypress)
	);

	Chip8_SoundController sound(
		.OSC_50_B8A(OSC_50_B8A),
		.AUD_ADCLRCK(AUD_ADCLRCK),
		.AUD_ADCDAT(AUD_ADCDAT),
		.AUD_DACLRCK(AUD_DACLRCK),
		.AUD_DACDAT(AUD_DACDAT),
		.AUD_XCK(AUD_XCK),
		.AUD_BCLK(AUD_BCLK),
		.AUD_I2C_SCLK(AUD_I2C_SCLK),
		.AUD_I2C_SDAT(AUD_I2C_SDAT),
		.AUD_MUTE(AUD_MUTE),

		.clk(clk),
		.is_on(sound_timer_out),
		.reset(sound_reset)
	);

	clk_div clk_div(
		.clk_in(clk),
		.reset(clk_div_reset),
		.clk_out(clk_div_clk_out)
	);

	timer sound_timer(
		.clk(clk),        			//50 MHz clock
		.clk_60(clk_div_clk_out),   //60 Hz clock
		.write_enable(delay_timer_write_enable),     	//Write enable
		.data(delay_timer_data),
		.out(delay_timer_out),
		.output_data (sound_timer_output_data)
	);

	timer delay_timer(
		.clk(clk),        			//50 MHz clock
		.clk_60(clk_div_clk_out),   //60 Hz clock
		.write_enable(sound_timer_write_enable),     	//Write enable
		.data(sound_timer_data),
		.out(sound_timer_out),
		.output_data (delay_timer_output_data)
	);

endmodule
