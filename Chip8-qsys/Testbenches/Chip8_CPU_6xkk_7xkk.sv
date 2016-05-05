`timescale 1ns/100ps

`include "../enums.svh"
//`include "../utils.svh"

/**
 * Test to make sure that after an instruction happens, 
 * all output values get reset to their defaults
 */
task automatic test_resets(ref logic[31:0] stage, ref int total, ref int failed,
	ref logic delay_timer_WE, sound_timer_WE,
	ref logic[7:0] delay_timer_writedata, sound_timer_writedata,
	//ref PC_SRC pc_src,
	ref logic[11:0] PC_writedata,
	ref logic reg_WE1, reg_WE2,
	ref logic[3:0] reg_addr1, reg_addr2,
	ref logic[7:0] reg_writedata1, reg_writedata2,
	ref logic mem_WE1, mem_WE2,
	ref logic[11:0] mem_addr1, mem_addr2,
	ref logic[ 7:0] mem_writedata1, mem_writedata2,
	ref logic reg_I_WE,
	ref logic[15:0] reg_I_writedata,
	ref logic sp_push, sp_pop,
	ref logic [4:0]	fb_addr_y,//max val = 31
	ref logic [5:0]	fb_addr_x,//max val = 63
	ref logic fb_writedata,fb_WE, fbreset,
	ref logic halt_for_keypress);
	#1ns;
	assert(
			delay_timer_WE 			== 1'b0 &
			sound_timer_WE 			== 1'b0 &
			delay_timer_writedata	== 8'b0 &
			sound_timer_writedata	== 8'b0 &
//			pc_src 					== PC_SRC_NEXT &
			PC_writedata 			== 12'b0 &
			reg_WE1 				== 1'b0 &
			reg_WE2 				== 1'b0 &
			reg_addr1 				== 4'b0 &
			reg_addr2 				== 4'b0 &
			reg_writedata1 			== 8'b0 &
			reg_writedata2			== 8'b0 &
			mem_WE1 				== 1'b0 &
			mem_WE2 				== 1'b0 &
			mem_addr1 				== 12'h0 &
			mem_addr2 				== 12'h0 &
			mem_writedata1			== 8'h0 &
			mem_writedata2			== 8'h0 &
			reg_I_WE 				== 1'b0 &
			reg_I_writedata			== 16'h0 &
			sp_push 				== 1'b0 &
			sp_pop 					== 1'b0 &
			fb_addr_y	==	5'h0 &
			fb_addr_x	==	6'h0 &
			fb_writedata	==	1'b0 &
			fb_WE		==	1'b0 &
			fbreset 				== 1'b0 &
			halt_for_keypress 		== 1'b0) begin
		$display("All outputs reset to their defaults");
		total = total + 1;
	end else begin
		$display("Outputs were NOT reset to their defaults. Current stage: %d",stage);
		failed = failed + 1;
	end
endtask


/**
 * Tests to make sure CPU outputs proper
 * request signafor 7xkk by sending 7E54;
 */
task automatic test7xkk(ref logic cpu_clk, 
					ref logic[15:0] instruction,
					ref logic[31:0] stage,
					ref int total,
					ref int failed,
					ref logic reg_WE1, reg_WE2,
					ref logic[3:0] reg_addr1, reg_addr2,
					ref logic[7:0] reg_writedata1, reg_writedata2);
	
	repeat (2) @(posedge cpu_clk);
	stage = 32'h0;
	instruction = 16'h7E54;
	
	
	wait(stage == 32'h2); #1ns;
	assert(reg_addr1 == instruction[11:8])
	else	$display("Instruction 7xkk failed with instruction %h in stage %d", instruction, stage);
	
	wait(stage == 32'h3); #1ns;
	assert(reg_addr1 == instruction[11:8] &
				//cannot check reg_writedata1 without register file
				reg_WE1 == 1'b1 
				//cannot check alu_in1, alu_in2, alu_cmd without internal access
				) begin
		total = total + 1;
		$display("Instruction 7xkk passed with instruction %h", instruction);
	end else begin
		failed = failed + 1;
		$display("Instruction 7xkk failed with instruction %h in stage %d", instruction, stage);
	end
	
	wait(stage == 32'h4);
	
	
endtask

/**
 * Tests to make sure instruction 6xkk works
 * by testing 61F0.
 */
task automatic test6xkk(ref logic cpu_clk, 
					ref logic[15:0] instruction,
					ref logic[31:0] stage,
					ref int total,
					ref int failed,
					ref logic reg_WE1, reg_WE2,
					ref logic[3:0] reg_addr1, reg_addr2,
					ref logic[7:0] reg_writedata1, reg_writedata2);
	repeat (2) @(posedge cpu_clk);
	stage = 32'h0;
	repeat (1) @(posedge cpu_clk);
	
	instruction = 16'h61F0;
	
	wait(instruction && 16'h61F0 && stage == 32'h2);
	#1ns;
	assert((reg_addr1 == 4'h1) && (reg_writedata1 == 8'hF0) && (reg_WE1 == 1'h1))begin
		$display("6xkk passed with instr %h", instruction);
		total = total + 1;
	end else begin
		$display("6xkk FAILED with instr %h", instruction);
		failed = failed + 1;
	end
	wait(stage == 32'h3);
								
endtask

module Chip8_CPU_6xkk_7xkk( ) ;
	
	logic cpu_clk;
	logic[15:0] instruction;
	logic[7:0]	reg_readdata1, reg_readdata2, 
					mem_readdata1, mem_readdata2;
	logic[15:0] reg_I_readdata;
	logic[7:0] delay_timer_readdata;
	
	logic key_pressed;
	logic[3:0] key_press;
		
	logic[11:0] PC_readdata;
	
	logic[31:0] stage;
	
	logic fb_readdata;
	
	Chip8_STATE top_level_state;
	
	logic delay_timer_WE, sound_timer_WE;
	logic[7:0] delay_timer_writedata, sound_timer_writedata;
		
	PC_SRC pc_src;
	logic[11:0] PC_writedata;
		
	logic reg_WE1, reg_WE2;
	logic[3:0] reg_addr1, reg_addr2;
	logic[7:0] reg_writedata1, reg_writedata2;
			
	logic mem_WE1, mem_WE2;
	logic[11:0] mem_addr1, mem_addr2;
	logic[ 7:0] mem_writedata1, mem_writedata2;
	
	logic reg_I_WE;
	logic[15:0] reg_I_writedata;
	logic sp_push, sp_pop;

	logic [4:0]	fb_addr_y;//max val = 31
	logic [5:0]	fb_addr_x;//max val = 63
	logic		fb_writedata, //data to write to addresse.
							fb_WE, //enable writing to address
							fbreset;

	logic halt_for_keypress;
	int total = 0;
	int failed = 0;


	Chip8_CPU dut(.*);



	initial begin
		cpu_clk = 0;
		stage = 32'b0;
		forever begin
			#20ns cpu_clk = 1;
			stage = stage + 1;
			#20ns cpu_clk = 0;
		end
	end
	
	initial begin 
		$display("Starting test tasks.");
		test6xkk(cpu_clk, instruction, stage,total,failed,reg_WE1, reg_WE2,
					reg_addr1, reg_addr2,reg_writedata1, reg_writedata2);
					
		test_resets(stage, total,failed,delay_timer_WE, sound_timer_WE,
			delay_timer_writedata, sound_timer_writedata, /*PC_SRC pc_src,*/
			PC_writedata,reg_WE1, reg_WE2,reg_addr1, reg_addr2,reg_writedata1, reg_writedata2,
			mem_WE1, mem_WE2, mem_addr1, mem_addr2,mem_writedata1, mem_writedata2,
			reg_I_WE,reg_I_writedata,sp_push, sp_pop,fb_addr_y,fb_addr_x,
			fb_writedata,fb_WE, fbreset,halt_for_keypress);
			
		test7xkk(cpu_clk, instruction, stage,total,failed,reg_WE1, reg_WE2,
					reg_addr1, reg_addr2, reg_writedata1, reg_writedata2);

		test_resets(stage, total,failed,delay_timer_WE, sound_timer_WE,
			delay_timer_writedata, sound_timer_writedata, /*PC_SRC pc_src,*/
			PC_writedata,reg_WE1, reg_WE2,reg_addr1, reg_addr2,reg_writedata1, reg_writedata2,
			mem_WE1, mem_WE2, mem_addr1, mem_addr2,mem_writedata1, mem_writedata2,
			reg_I_WE,reg_I_writedata,sp_push, sp_pop,fb_addr_y,fb_addr_x,
			fb_writedata,fb_WE, fbreset,halt_for_keypress);		
			
		$display("Total number of tests passed: %d", total);
		$display("Total number of tests failed: %d", failed);
	end
	/*
	initial begin 
		repeat (2) @(posedge cpu_clk);
		stage = 32'h0;
		repeat (1) @(posedge cpu_clk);
		
		instruction = 16'h61F0;
		
		
		wait(instruction && 16'h61F0 && stage == 32'h2);
		#1ns;
		assert((reg_addr1 == 4'h1) && (reg_writedata1 == 8'hF0) && (reg_WE1 == 1'h1))
			$display("6xkk passed with instr %h", instruction);
		else 
			$display("6xkk FAILED with instr %h", instruction);
	end
	*/
	
endmodule