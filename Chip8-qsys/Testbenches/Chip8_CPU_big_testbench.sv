`timescale 1ns/100ps

`include "../enums.svh"

/**
 * Test to make sure that after an instruction happens, 
 * all output values get reset to their defaults
 */
task automatic test_resets(ref logic cpu_clk, ref logic[31:0] stage, ref int total, ref int failed,
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
	#3ns;
	wait(cpu_clk == 1'b0);
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
	repeat (2) @(posedge cpu_clk);

endtask


task automatic testDxyn(ref logic cpu_clk, 
					ref logic[15:0] instruction,
					ref logic[31:0] stage,
					ref int total,
					ref int failed,
					ref logic[3:0] reg_addr1, reg_addr2,
					ref logic reg_WE1, reg_WE2,
					ref logic[7:0] reg_readdata1, reg_readdata2,
					ref logic[7:0] mem_readdata1, mem_writedata1,
					ref logic mem_WE1,
					ref logic[11:0] mem_addr1,
					ref logic[5:0] fb_addr_x,
					ref logic[4:0] fb_addr_y,
					ref logic fb_writedata, fb_readdata, fb_WE,
					ref logic[15:0] reg_I_readdata,
					ref logic bit_overwritten);
	instruction = 16'hd392;
	stage = 32'h0;
	reg_I_readdata = 16'h0F0F;
	
	if((stage == 32'h0) || (stage == 32'h1)) begin
		assert(reg_WE1==1'b0  &  reg_WE2==1'b0  &  mem_WE1==1'b0  &  fb_WE==1'b0)
		else begin
			$display("INSTR DXYN HAS INVALID WRITE_ENEABLE VALS BEFORE STAGE 2");
			failed = failed + 1;
		end
	end
	
	
	wait(stage == 32'h2); #1ns;
	assert(reg_addr1==instruction[11:8] & reg_addr2==instruction[7:4] &
			mem_addr1==reg_I_readdata & reg_WE1==1'b0  &  reg_WE2==1'b0  &  
			mem_WE1==1'b0  &  fb_WE==1'b0)
	else begin
		$display("INSTR DXYN HAS FAILED TO SET INITIAL OUTPUT VALS IN STAGE 3");
		failed = failed + 1;
	end
	
	fb_readdata = 1'b0;
	reg_readdata1 = 8'd3; //write to x = 3
	reg_readdata2 = 8'd9; //write to y = 9
								 //that is position x + 64y = 576
	mem_readdata1 = 8'hAF;
	
	wait(stage == 32'h3); #1ns;
	assert(reg_addr1==instruction[11:8] & reg_addr2==instruction[7:4] &
			mem_addr1==reg_I_readdata & reg_WE1==1'b0  &  reg_WE2==1'b0  &  
			mem_WE1==1'b0  &  fb_WE==1'b0)
	else begin
		$display("INSTR DXYN HAS FAILED TO HOLD VALS FROM STATE 2 IN STATE 3\n\tEx--mem_addr1= %h",mem_addr1);
		failed = failed + 1;
	end
	
	wait(stage == 32'd15); #1ns;
	assert(reg_addr1==instruction[11:8] & reg_addr2==instruction[7:4] &
			mem_addr1==reg_I_readdata & reg_WE1==1'b0  &  reg_WE2==1'b0  &  
			mem_WE1==1'b0  &  fb_WE==1'b0)
	else begin
		$display("INSTR DXYN HAS FAILED TO HOLD VALS FROM STATE 2 IN STATE 15\n\tEx--mem_addr1= %h",mem_addr1);
		failed = failed + 1;
	end
	

	
	wait(stage == 32'd17); #1ns;
	assert(reg_addr1==instruction[11:8] & reg_addr2==instruction[7:4] &
			mem_addr1==reg_I_readdata & fb_WE==1'b1  & 
			fb_addr_x==reg_readdata1 & fb_addr_y==reg_readdata2 & 
			fb_writedata==1'b1 & bit_overwritten==1'b0)
	else begin
		$display("INSTR DXYN FAILED IN ITS FIRST WRITE STAGE");
		failed = failed + 1;
	end
	wait(stage == 32'd18); #1ns;
	assert(reg_addr1==instruction[11:8] & reg_addr2==instruction[7:4] &
			mem_addr1==reg_I_readdata & fb_WE==1'b0  & 
			fb_addr_x==(reg_readdata1+1) & fb_addr_y==reg_readdata2 &
			bit_overwritten==1'b0)
	else begin
		$display("INSTR DXYN FAILED IN STAGE 18");
		failed = failed + 1;
	end
	fb_readdata = 1'b1;
	wait(stage == 32'd31); #1ns;
	assert(reg_addr1==instruction[11:8] & reg_addr2==instruction[7:4] &
			mem_addr1==reg_I_readdata & fb_WE==1'b1  & 
			fb_addr_x==(reg_readdata1+7) & fb_addr_y==reg_readdata2 &
			bit_overwritten==1'b1)
	else begin
		$display("INSTR DXYN FAILED IN STAGE 31");
		failed = failed + 1;
	end
	fb_readdata = 1'b0;
	
	
	wait(stage == 32'd32); #3ns;
	assert(reg_addr1==instruction[11:8] & reg_addr2==instruction[7:4] &
			mem_addr1==(reg_I_readdata+1) & fb_WE==1'b0  & 
			fb_addr_x==(reg_readdata1) & fb_addr_y==(reg_readdata2+1) &
			bit_overwritten==1'b0)
	else begin
		$display("INSTR DXYN FAILED IN STAGE 32\n\treg_readdata2=%h\n\tfb_addr_y=%h",reg_readdata2,fb_addr_y);
		$display("\tmem_addr1=%h\n\treg_I_readdata=%h",mem_addr1,reg_I_readdata);
		failed = failed + 1;
	end
	
	mem_readdata1 = 8'b1101000;
	
	wait(stage == 32'd33); #1ns;
	assert(reg_addr1==instruction[11:8] & reg_addr2==instruction[7:4] &
			mem_addr1==(reg_I_readdata+1) & fb_WE==1'b1  & 
			fb_addr_x==(reg_readdata1) & fb_addr_y==(reg_readdata2+1) &
			bit_overwritten==1'b0)
	else begin
		$display("INSTR DXYN FAILED IN STAGE 33\n\treg_readdata2=%h\n\tfb_addr_y=%h",reg_readdata2,fb_addr_y);
		$display("\tmem_addr1=%h\n\treg_I_readdata=%h",mem_addr1,reg_I_readdata);
		failed = failed + 1;
	end
	
	wait(stage == 32'd39); #1ns;
	assert(reg_addr1==instruction[11:8] & reg_addr2==instruction[7:4] &
			mem_addr1==(reg_I_readdata+1) & fb_WE==1'b1  & 
			fb_addr_x==(reg_readdata1+8'h3) & fb_addr_y==(reg_readdata2+1) &
			fb_writedata==1'b1 & bit_overwritten==1'b0)
	else begin
		$display("INSTR DXYN FAILED IN STAGE 39\n\treg_readdata2=%h\n\tfb_addr_y=%h",reg_readdata2,fb_addr_y);
		$display("\tmem_addr1=%h\n\treg_I_readdata=%h",mem_addr1,reg_I_readdata);
		failed = failed + 1;
	end
	
	wait(stage == 32'd47); #1ns;
	assert(reg_addr1==instruction[11:8] & reg_addr2==instruction[7:4] &
			mem_addr1==(reg_I_readdata+1) & fb_WE==1'b1  & 
			fb_addr_x==(reg_readdata1+8'h7) & fb_addr_y==(reg_readdata2+1) &
			fb_writedata==1'b0 & bit_overwritten==1'b0)
	else begin
		$display("INSTR DXYN FAILED IN STAGE 47\n\treg_readdata2=%h\n\tfb_addr_y=%h",reg_readdata2,fb_addr_y);
		$display("\tmem_addr1=%h\n\treg_I_readdata=%h",mem_addr1,reg_I_readdata);
		failed = failed + 1;
	end
	
	wait(stage == 32'd48); #1ns;
	assert(fb_WE==1'b0  &  bit_overwritten==1'b0)
	else begin
		failed = failed + 1;
		$display("INSTR DXYN FAILED IN STAGE: %d", stage);
	end

	
	wait(stage == 32'd61); #1ns;
	assert(fb_WE==1'b0  &  bit_overwritten==1'b0) begin
		$display("Dxyn draw sprite works!! :D");
		total = total + 1;
	end else begin
		$display("INSTR DXYN FAILED IN STAGE: %d", stage);
		failed = failed + 1;
	end
	
	$display("WOOOOOOBL");
	wait(stage == 32'd100);#1ns;
	stage = 32'b0;
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
					ref logic[7:0] reg_writedata1, reg_writedata2,
										reg_readdata1);
	
	repeat (2) @(posedge cpu_clk);
	stage = 32'h0;
	instruction = 16'h7EF0;
	reg_readdata1 = 8'h01;
	
	wait(stage == 32'h2); #1ns;
	assert(reg_addr1 == instruction[11:8])
	else	$display("Instruction 7xkk failed with instruction %h in stage %d", instruction, stage);
	
	wait(stage == 32'h3); #1ns;
	assert(reg_addr1 == instruction[11:8] &
				(reg_writedata1 == (reg_readdata1 + instruction[7:0])) &
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

module Chip8_CPU_big_testbench( ) ;
	
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
	
	logic stk_reset;
	STACK_OP stk_op;
	logic[15:0] stk_writedata;
	logic bit_overwritten;
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
					
		test_resets(cpu_clk, stage, total,failed,delay_timer_WE, sound_timer_WE,
			delay_timer_writedata, sound_timer_writedata, /*PC_SRC pc_src,*/
			PC_writedata,reg_WE1, reg_WE2,reg_addr1, reg_addr2,reg_writedata1, reg_writedata2,
			mem_WE1, mem_WE2, mem_addr1, mem_addr2,mem_writedata1, mem_writedata2,
			reg_I_WE,reg_I_writedata,sp_push, sp_pop,fb_addr_y,fb_addr_x,
			fb_writedata,fb_WE, fbreset,halt_for_keypress);
			
		test7xkk(cpu_clk, instruction, stage,total,failed,reg_WE1, reg_WE2,
					reg_addr1, reg_addr2, reg_writedata1, reg_writedata2, reg_readdata1);

		test_resets(cpu_clk, stage, total,failed,delay_timer_WE, sound_timer_WE,
			delay_timer_writedata, sound_timer_writedata, /*PC_SRC pc_src,*/
			PC_writedata,reg_WE1, reg_WE2,reg_addr1, reg_addr2,reg_writedata1, reg_writedata2,
			mem_WE1, mem_WE2, mem_addr1, mem_addr2,mem_writedata1, mem_writedata2,
			reg_I_WE,reg_I_writedata,sp_push, sp_pop,fb_addr_y,fb_addr_x,
			fb_writedata,fb_WE, fbreset,halt_for_keypress);		
		
		testDxyn(cpu_clk, instruction, stage,total,failed,
					reg_addr1, reg_addr2, reg_WE1, reg_WE2,
					reg_readdata1, reg_readdata2,mem_readdata1, 
					mem_writedata1,mem_WE1, mem_addr1, fb_addr_x,fb_addr_y,
					fb_writedata, fb_readdata, fb_WE,reg_I_readdata, bit_overwritten);
		
		test_resets(cpu_clk, stage, total,failed,delay_timer_WE, sound_timer_WE,
			delay_timer_writedata, sound_timer_writedata, /*PC_SRC pc_src,*/
			PC_writedata,reg_WE1, reg_WE2,reg_addr1, reg_addr2,reg_writedata1, reg_writedata2,
			mem_WE1, mem_WE2, mem_addr1, mem_addr2,mem_writedata1, mem_writedata2,
			reg_I_WE,reg_I_writedata,sp_push, sp_pop,fb_addr_y,fb_addr_x,
			fb_writedata,fb_WE, fbreset,halt_for_keypress);	
		
			
		$display("Total number of tests passed: %d", total);
		$display("Total number of tests failed: %d", failed);
	end

	
endmodule