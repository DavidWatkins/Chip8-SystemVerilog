/******************************************************************************
 * CPU Fragment Test Bench
 *
 * Author: Ashley Kling
 *****************************************************************************/

 `include "../Chip8-qsys/enums.svh"
 
 task automatic testreset(ref logic[15:0] instruction,
								ref logic[31:0] stage,
								ref logic[7:0] reg_readdata1, reg_readdata2);
								
	instruction = 16'h0;
	stage = 32'h1;
	reg_readdata1 = 8'h0;
	reg_readdata2 = 8'h0;
	
endtask

//test 00EE, which returns from a subroutine by setting the progam counter to the address from the stack
task automatic test00EE(ref logic clk,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									STACK_OP stk_op,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h0;
	instruction[11:8] = 4'h0;
	instruction[7:4] = 4'hE;
	instruction[3:0] = 4'hE;
	
	repeat(2) @(posedge clk);
	stage = stage + 2;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_STACK && stk_op == STACK_POP) begin
			$display ("00EE TEST : PASSED");
			total = total + 1;
		end
		else $error("00EE TEST : FAILED (Got %h, Expected PC_SRC_STACK)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 1nnn, which sets the progam counter to nnn
task automatic test1nnn(ref logic clk,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref logic[11:0] PC_writedata,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h1;
	instruction[11:8] = 4'h2;
	instruction[7:4] = 4'ha;
	instruction[3:0] = 4'h6;
	
	repeat(2) @(posedge clk);
	stage = stage + 2;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_ALU && PC_writedata == 12'h2A6) begin
			$display ("1nnn TEST : PASSED");
			total = total + 1;
		end
		else $error("1nnn TEST : FAILED (Got %h, Expected PC_SRC_ALU)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 2nnn, which sets the progam counter to nnn and pushes the current value to the stack
task automatic test2nnn(ref logic clk,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref logic[11:0] PC_writedata,
									ref logic[11:0] PC_readdata,
									ref STACK_OP stk_op, 
									ref logic[15:0] stk_writedata,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h2;
	instruction[11:8] = 4'h0;
	instruction[7:4] = 4'h4;
	instruction[3:0] = 4'h2;
	
	repeat(2) @(posedge clk);
	stage = stage + 2;
	PC_readdata = 12'h413;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_ALU && PC_writedata == 12'h042 && stk_op == STACK_PUSH && stk_writedata == 12'h413) begin
			$display ("2nnn TEST : PASSED");
			total = total + 1;
		end
		else $error("2nnn TEST : FAILED (Got %h , %h, %h, %h, Expected PC_SRC_ALU, 042, STACK_PUSH, 00413)", pc_src, PC_writedata, stk_op, stk_writedata);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 3xkk, which skips the next instruction if Vx = kk
task automatic test3xkk_part1(ref logic clk,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h3;
	instruction[11:8] = 4'h1;
	instruction[7:4] = 4'h0;
	instruction[3:0] = 4'h5;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h5;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_SKIP) begin
			$display ("3xkk part 1 TEST : PASSED");
			total = total + 1;
		end
		else $error("3xkk part 1 TEST : FAILED (Got %h, Expected skip)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 3xkk, which skips the next instruction if Vx = kk (testing Vx != kk)
task automatic test3xkk_part2(ref logic clk,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h3;
	instruction[11:8] = 4'h1;
	instruction[7:4] = 4'h0;
	instruction[3:0] = 4'h5;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h7;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_NEXT) begin
			$display ("3xkk part 2 TEST : PASSED");
			total = total + 1;
		end
		else $error("3xkk part 2 TEST : FAILED (Got %h, Expected next)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 4xkk, which skips the next instruction if Vx != kk
task automatic test4xkk_part1(ref logic clk,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h4;
	instruction[11:8] = 4'h2;
	instruction[7:4] = 4'h0;
	instruction[3:0] = 4'h7;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h2;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_SKIP) begin
			$display ("4xkk part 1 TEST : PASSED");
			total = total + 1;
		end
		else $error("4xkk part 1 TEST : FAILED (Got %h, Expected skip)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 4xkk, which skips the next instruction if Vx != kk (testing Vx = kk)
task automatic test4xkk_part2(ref logic clk,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h4;
	instruction[11:8] = 4'h2;
	instruction[7:4] = 4'h0;
	instruction[3:0] = 4'h8;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h8;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_NEXT) begin
			$display ("4xkk part 2 TEST : PASSED");
			total = total + 1;
		end
		else $error("4xkk part 2 TEST : FAILED (Got %h, Expected next)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 5xy0, which skips the next instruction if Vx = Vy
task automatic test5xy0_part1(ref logic clk,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h5;
	instruction[11:8] = 4'h2;
	instruction[7:4] = 4'h3;
	instruction[3:0] = 4'h0;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h9;
	reg_readdata2 = 8'h9;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_SKIP) begin
			$display ("5xy0 part 1 TEST : PASSED");
			total = total + 1;
		end
		else $error("5xy0 part 1 TEST : FAILED (Got %h, Expected skip)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 5xy0, which skips the next instruction if Vx = Vy (testing Vx != Vy)
task automatic test5xy0_part2(ref logic clk,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h5;
	instruction[11:8] = 4'h2;
	instruction[7:4] = 4'h3;
	instruction[3:0] = 4'h0;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h8;
	reg_readdata2 = 8'hb;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_NEXT) begin
			$display ("5xy0 part 2 TEST : PASSED");
			total = total + 1;
		end
		else $error("5xy0 part 2 TEST : FAILED (Got %h, Expected next)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask
 
 //test 8xy0, which sets register x to the value of register y
 task automatic test8xy0(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h1;
	instruction[7:4] = 4'h2;
	instruction[3:0] = 4'h0;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata2 = 8'h5;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == 8'h5 && reg_addr1 == 4'h1 && reg_addr2 == 4'h2) begin
			$display ("8xy0 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xy0 TEST : FAILED (Got %h, Expected 101)", reg_writedata1);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 8xy1, which sets register x to x | y
task automatic test8xy1(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h3;
	instruction[7:4] = 4'h2;
	instruction[3:0] = 4'h1;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h8;
	reg_readdata2 = 8'h5;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == (8'h5 | 8'h8) && reg_addr1 == 4'h3 && reg_addr2 == 4'h2) begin
			$display ("8xy1 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xy1 TEST : FAILED (Got %h, Expected 1101)", reg_writedata1);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 8xy2, which sets register x to x & y
task automatic test8xy2(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h3;
	instruction[7:4] = 4'h4;
	instruction[3:0] = 4'h2;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h15;
	reg_readdata2 = 8'h5;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == (8'h15 & 8'h5) && reg_addr1 == 4'h3 && reg_addr2 == 4'h4) begin
			$display ("8xy2 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xy2 TEST : FAILED (Got %h, Expected 0101)", reg_writedata1);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 8xy3, which sets register x to x XOR y
task automatic test8xy3(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h5;
	instruction[7:4] = 4'h4;
	instruction[3:0] = 4'h3;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'hf;
	reg_readdata2 = 8'h5;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == (8'hf ^ 8'h5) && reg_addr1 == 4'h5 && reg_addr2 == 4'h4) begin
			$display ("8xy3 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xy3 TEST : FAILED (Got %h, Expected 1010)", reg_writedata1);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 8xy4, which sets register x to x + y (and VF = carry)
task automatic test8xy4_part1(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h5;
	instruction[7:4] = 4'h6;
	instruction[3:0] = 4'h4;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'hf;
	reg_readdata2 = 8'h5;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == (8'hf + 8'h5) && reg_addr1 == 4'h5 && reg_addr2 == 4'hf && reg_writedata2 == 1'h0 && reg_WE2 == 1'h1) begin
			$display ("8xy4 part 1 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xy4 part 1 TEST : FAILED (Got %h, Expected 10100)", reg_writedata1);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 8xy4, which sets register x to x + y (and VF = carry), testing carry specifically
task automatic test8xy4_part2(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h7;
	instruction[7:4] = 4'h6;
	instruction[3:0] = 4'h4;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'b1000_0101;
	reg_readdata2 = 8'b1000_0100;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == (8'h4 + 8'h5) && reg_addr1 == 4'h7 && reg_addr2 == 4'hf && reg_writedata2 == 1'h1 && reg_WE2 == 1'h1) begin
			$display ("8xy4 part 2 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xy4 part 2 TEST : FAILED (Got %h, Expected 1001)", reg_writedata1);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 8xy5, which sets register x to x - y (and VF = !carry)
task automatic test8xy5_part1(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h7;
	instruction[7:4] = 4'h8;
	instruction[3:0] = 4'h5;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h5;
	reg_readdata2 = 8'hf;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == (8'h5 - 8'hf) && reg_addr1 == 4'h7 && reg_addr2 == 4'hf && reg_writedata2 == 1'h0 && reg_WE2 == 1'h1) begin
			$display ("8xy5 part 1 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xy5 part 1 TEST : FAILED (Got %h, Expected %h) (Got carry %h, Expected 0)", reg_writedata1, 8'h5-8'hf, reg_writedata2, 1'h0);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 8xy5, which sets register x to x - y (and VF = !carry), testing carry specifically
task automatic test8xy5_part2(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h9;
	instruction[7:4] = 4'h8;
	instruction[3:0] = 4'h5;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'b1000_0101;
	reg_readdata2 = 8'b1000_0100;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == (8'h5 - 8'h4) && reg_addr1 == 4'h9 && reg_addr2 == 4'hf && reg_writedata2 == 1'h1 && reg_WE2 == 1'h1) begin
			$display ("8xy5 part 2 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xy5 part 2 TEST : FAILED (Got %h, Expected 0001) (Got carry %h, Expected %h)", reg_writedata1, reg_writedata2, 1'h1);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 8xy6, which sets register x to x/2 (and VF = LSB(x))
task automatic test8xy6_part1(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h9;
	instruction[7:4] = 4'h10;
	instruction[3:0] = 4'h6;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h6;
	reg_readdata2 = 8'hf;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == (8'h6/2) && reg_addr1 == 4'h9 && reg_addr2 == 4'hf && reg_writedata2 == 1'h0 && reg_WE2 == 1'h1) begin
			$display ("8xy6 part 1 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xy6 part 1 TEST : FAILED (Got %h, Expected %h) (Got carry %h, Expected 0)", reg_writedata1, 8'h6/2, reg_writedata2, 1'h0);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 8xy6, which sets register x to x/2 (and VF = LSB(x)), testing carry specifically
task automatic test8xy6_part2(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h9;
	instruction[7:4] = 4'h10;
	instruction[3:0] = 4'h6;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h7;
	reg_readdata2 = 8'b1000_0100;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == (8'h7>>1) && reg_addr1 == 4'h9 && reg_addr2 == 4'hf && reg_writedata2 == 1'h1 && reg_WE2 == 1'h1) begin
			$display ("8xy6 part 2 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xy6 part 2 TEST : FAILED (Got %h, Expected 0011) (Got carry %h, Expected %h)", reg_writedata1, reg_writedata2, 1'h1);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 8xy7, which sets register x to y - x (and VF = !carry)
task automatic test8xy7_part1(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h11;
	instruction[7:4] = 4'h10;
	instruction[3:0] = 4'h7;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h6;
	reg_readdata2 = 8'h1;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == (8'h1 - 8'h6) && reg_addr1 == 4'h11 && reg_addr2 == 4'hf && reg_writedata2 == 1'h0 && reg_WE2 == 1'h1) begin
			$display ("8xy7 part 1 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xy7 part 1 TEST : FAILED (Got %h, Expected %h) (Got carry %h, Expected 0)", reg_writedata1, 8'h6/2, reg_writedata2, 1'h0);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 8xy7, which sets register x to y - x (and VF = !carry), testing carry specifically
task automatic test8xy7_part2(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h11;
	instruction[7:4] = 4'h10;
	instruction[3:0] = 4'h7;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h4;
	reg_readdata2 = 8'h9;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == (8'h9-8'h4) && reg_addr1 == 4'h11 && reg_addr2 == 4'hf && reg_writedata2 == 1'h1 && reg_WE2 == 1'h1) begin
			$display ("8xy7 part 2 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xy7 part 2 TEST : FAILED (Got %h, Expected 0101) (Got carry %h, Expected %h)", reg_writedata1, reg_writedata2, 1'h1);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 8xyE, which sets register x to x*2 (and VF = MSB)
task automatic test8xyE_part1(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h12;
	instruction[7:4] = 4'h10;
	instruction[3:0] = 4'hE;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h5;
	reg_readdata2 = 8'h1;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == (8'h5*2) && reg_addr1 == 4'h12 && reg_addr2 == 4'hf && reg_writedata2 == 1'h0 && reg_WE2 == 1'h1) begin
			$display ("8xyE part 1 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xyE part 1 TEST : FAILED (Got %h, Expected %h) (Got carry %h, Expected 0)", reg_writedata1, 8'h6/2, reg_writedata2, 1'h0);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 8xyE, which sets register x to x*2 (and VF = MSB), testing carry specifically
task automatic test8xyE_part2(ref logic clk,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h8;
	instruction[11:8] = 4'h12;
	instruction[7:4] = 4'h10;
	instruction[3:0] = 4'hE;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'b_1000_0100;
	reg_readdata2 = 8'h9;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (reg_WE1 == 1'h1 && reg_writedata1 == (8'h4<<1) && reg_addr1 == 4'h12 && reg_addr2 == 4'hf && reg_writedata2 == 1'h1 && reg_WE2 == 1'h1) begin
			$display ("8xyE part 2 TEST : PASSED");
			total = total + 1;
		end
		else $error("8xyE part 2 TEST : FAILED (Got %h, Expected 1000) (Got carry %h, Expected %h)", reg_writedata1, reg_writedata2, 1'h1);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 9xy0, which skips the next instruction if Vx != Vy
task automatic test9xy0_part1(ref logic clk,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h9;
	instruction[11:8] = 4'h2;
	instruction[7:4] = 4'h4;
	instruction[3:0] = 4'h0;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h3;
	reg_readdata2 = 8'hd;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_SKIP) begin
			$display ("9xy0 part 1 TEST : PASSED");
			total = total + 1;
		end
		else $error("9xy0 part 1 TEST : FAILED (Got %h, Expected skip)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test 9xy0, which skips the next instruction if Vx != Vy (testing Vx = Vy)
task automatic test9xy0_part2(ref logic clk,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'h9;
	instruction[11:8] = 4'h2;
	instruction[7:4] = 4'h5;
	instruction[3:0] = 4'h0;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'hc;
	reg_readdata2 = 8'hc;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_NEXT) begin
			$display ("9xy0 part 2 TEST : PASSED");
			total = total + 1;
		end
		else $error("9xy0 part 2 TEST : FAILED (Got %h, Expected next)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test Ex9E, which skips the next instruction if Vx = key pressed
task automatic testEx9E_part1(ref logic clk,
									ref logic key_pressed,
									ref logic[3:0] key_press,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'hE;
	instruction[11:8] = 4'h2;
	instruction[7:4] = 4'h9;
	instruction[3:0] = 4'hE;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'hd;
	key_pressed = 1'h1;
	key_press = 4'hd;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_SKIP) begin
			$display ("Ex9E part 1 TEST : PASSED");
			total = total + 1;
		end
		else $error("Ex9E part 1 TEST : FAILED (Got %h, Expected skip)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test Ex9E, which skips the next instruction if Vx = key pressed (testing Vx != key)
task automatic testEx9E_part2(ref logic clk,
									ref logic key_pressed,
									ref logic[3:0] key_press,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'hE;
	instruction[11:8] = 4'h2;
	instruction[7:4] = 4'h9;
	instruction[3:0] = 4'hE;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'hc;
	key_pressed = 1'h1;
	key_press = 4'h8;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_NEXT) begin
			$display ("Ex9E part 2 TEST : PASSED");
			total = total + 1;
		end
		else $error("Ex9E part 2 TEST : FAILED (Got %h, Expected next)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test Ex9E, which skips the next instruction if Vx = key pressed (testing no key pressed)
task automatic testEx9E_part3(ref logic clk,
									ref logic key_pressed,
									ref logic[3:0] key_press,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'hE;
	instruction[11:8] = 4'h2;
	instruction[7:4] = 4'h9;
	instruction[3:0] = 4'hE;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'hc;
	key_pressed = 1'h0;
	key_press = 4'hc;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_NEXT) begin
			$display ("Ex9E part 3 TEST : PASSED");
			total = total + 1;
		end
		else $error("Ex9E part 3 TEST : FAILED (Got %h, Expected next)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test ExA1, which skips the next instruction if Vx != key pressed
task automatic testExA1_part1(ref logic clk,
									ref logic key_pressed,
									ref logic[3:0] key_press,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'hE;
	instruction[11:8] = 4'h2;
	instruction[7:4] = 4'hA;
	instruction[3:0] = 4'h1;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'hd;
	key_pressed = 1'h1;
	key_press = 4'he;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_SKIP) begin
			$display ("ExA1 part 1 TEST : PASSED");
			total = total + 1;
		end
		else $error("ExA1 part 1 TEST : FAILED (Got %h, Expected skip)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test ExA1, which skips the next instruction if Vx != key pressed (testing Vx = key)
task automatic testExA1_part2(ref logic clk,
									ref logic key_pressed,
									ref logic[3:0] key_press,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'hE;
	instruction[11:8] = 4'h2;
	instruction[7:4] = 4'hA;
	instruction[3:0] = 4'h1;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'h7;
	key_pressed = 1'h1;
	key_press = 4'h7;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_NEXT) begin
			$display ("ExA1 part 2 TEST : PASSED");
			total = total + 1;
		end
		else $error("ExA1 part 2 TEST : FAILED (Got %h, Expected next)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

//test ExA1, which skips the next instruction if Vx != key pressed (testing no key pressed)
task automatic testExA1_part3(ref logic clk,
									ref logic key_pressed,
									ref logic[3:0] key_press,
									ref PC_SRC pc_src,
									ref logic[15:0] instruction,
									ref logic[7:0] reg_readdata1, reg_readdata2,
									ref logic[31:0] stage,
									ref logic[7:0] reg_writedata1, reg_writedata2,
									ref logic reg_WE1, reg_WE2,
									ref logic[3:0] reg_addr1, reg_addr2,
									ref int total);
									
	repeat(4) @(posedge clk);
	instruction[15:12] = 4'hE;
	instruction[11:8] = 4'h2;
	instruction[7:4] = 4'hA;
	instruction[3:0] = 4'h1;
	
	repeat(2) @(posedge clk);
	stage = stage + 1;
	reg_readdata1 = 8'hc;
	key_pressed = 1'h0;
	key_press = 4'hc;
	repeat(2) @(posedge clk);
	stage = stage + 1;
	repeat(2) @(posedge clk);
		assert (pc_src == PC_SRC_SKIP) begin
			$display ("ExA1 part 3 TEST : PASSED");
			total = total + 1;
		end
		else $error("ExA1 part 3 TEST : FAILED (Got %h, Expected skip)", pc_src);
	
	testreset(instruction, stage, reg_readdata1, reg_readdata2);
endtask

module cpu_testbench();
	logic cpu_clk;
	logic[15:0] instruction;
	logic[7:0] reg_readdata1, reg_readdata2, 
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
	logic mem_request;
	
	logic reg_I_WE;
	logic[15:0] reg_I_writedata;

	logic stk_reset;
	STACK_OP stk_op;
	logic[15:0] stk_writedata;

	logic [4:0]	fb_addr_y;//max val = 31
	logic [5:0]	fb_addr_x;//max val = 63
	logic		fb_writedata, //data to write to addresse.
							fb_WE, //enable writing to address
							fbreset,
							bit_overwritten;
							
	logic isDrawing;
							
	logic halt_for_keypress;
	
	int total;
	
	Chip8_CPU dut(.*);
	
	initial begin
		cpu_clk = 1'h0;
		instruction = 16'h0;
		reg_readdata1 = 8'h0;
		reg_readdata2 = 8'h0;	
		mem_readdata1 = 8'h0;
		mem_readdata2 = 8'h0;
		reg_I_readdata = 16'h0;
		delay_timer_readdata = 8'h0;
		key_pressed = 1'h0;
		key_press = 4'h0;
		PC_readdata = 12'h0;
		stage = 32'h1;
		fb_readdata = 1'h0;
		top_level_state = Chip8_RUNNING;
		total = 0;
		
		forever 
			#20ns cpu_clk = ~cpu_clk;
	end
	
	initial begin
		$display("Starting test script...");
		test00EE(cpu_clk, pc_src, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, stk_op, total);
		test1nnn(cpu_clk, pc_src, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, PC_writedata, total);
		test2nnn(cpu_clk, pc_src, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, PC_writedata,
			PC_readdata, stk_op, stk_writedata, total);
		test3xkk_part1(cpu_clk, pc_src, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test3xkk_part2(cpu_clk, pc_src, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test4xkk_part1(cpu_clk, pc_src, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test4xkk_part2(cpu_clk, pc_src, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test5xy0_part1(cpu_clk, pc_src, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test5xy0_part2(cpu_clk, pc_src, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xy0(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xy1(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xy2(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xy3(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xy4_part1(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xy4_part2(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xy5_part1(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xy5_part2(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xy6_part1(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xy6_part2(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xy7_part1(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xy7_part2(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xyE_part1(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test8xyE_part2(cpu_clk, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test9xy0_part1(cpu_clk, pc_src, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		test9xy0_part2(cpu_clk, pc_src, instruction, reg_readdata1, reg_readdata2, stage, 
			reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, reg_addr2, total);
		testEx9E_part1(cpu_clk, key_pressed, key_press, pc_src, instruction, reg_readdata1, 
			reg_readdata2, stage, reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, 
			reg_addr2, total);
		testEx9E_part2(cpu_clk, key_pressed, key_press, pc_src, instruction, reg_readdata1, 
			reg_readdata2, stage, reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, 
			reg_addr2, total);
		testEx9E_part3(cpu_clk, key_pressed, key_press, pc_src, instruction, reg_readdata1, 
			reg_readdata2, stage, reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, 
			reg_addr2, total);
		testExA1_part1(cpu_clk, key_pressed, key_press, pc_src, instruction, reg_readdata1, 
			reg_readdata2, stage, reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, 
			reg_addr2, total);
		testExA1_part2(cpu_clk, key_pressed, key_press, pc_src, instruction, reg_readdata1, 
			reg_readdata2, stage, reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, 
			reg_addr2, total);
		testExA1_part3(cpu_clk, key_pressed, key_press, pc_src, instruction, reg_readdata1, 
			reg_readdata2, stage, reg_writedata1, reg_writedata2, reg_WE1, reg_WE2, reg_addr1, 
			reg_addr2, total);
			
		$display("TESTS PASSED : %d", total);
	end
	
endmodule 