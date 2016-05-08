/******************************************************************************
 * Stack Test Bench
 *
 * Author: Gabrielle Taylor, Ashley Kling
 *****************************************************************************/

//task automatic testReset(logic clk, 
//								logic[4:0] fb_addr_y,
//								logic[5:0] fb_addr_x,
//								logic fb_writedata,
//								logic fb_WE, 
//								logic reset);
//	fb_addr_y = 6'h0000;
//	fb_addr_x = 5'h0000;
//	fb_writedata = 1'h0;
//	fb_WE = 1'h0;
//	
//	reset = 1'h1;
//	repeat(2) @(posedge clk);
//	reset = 1'h0;
//	repeat(2) @(posedge clk);
//endtask
 
task automatic testWriteOne(ref logic clk, 
								ref logic[4:0] fb_addr_y,
								ref logic[5:0] fb_addr_x,
								ref logic fb_writedata,
								ref logic fb_WE,
								ref logic fb_readdata,
								ref logic reset,
								ref int total);
	fb_addr_y = 5'b00001;
	fb_addr_x = 6'b000001;
	fb_writedata = 1;
	fb_WE = 1;
	repeat(2) @(posedge clk);
		
	fb_addr_y = 5'b00000;
	fb_addr_x = 6'b000000;
	fb_writedata = 0;
	fb_WE = 0;
	repeat(2) @(posedge clk);
	
	fb_addr_y = 5'b00001;
	fb_addr_x = 6'b000001;
	fb_writedata = 0;
	fb_WE = 0;
	repeat(2) @(posedge clk);
	
	repeat(2) 
		@(posedge clk);
	assert (fb_readdata == 1'h1) begin
		$display ("WriteOne TEST 1 : PASSED");
		total = total + 1;
	end
    else $error("OR TEST 1 : FAILED (Got %h, Expected 1)", fb_readdata);

	fb_addr_y = 6'h0000;
	fb_addr_x = 5'h0000;
	fb_writedata = 1'h0;
	fb_WE = 1'h0;
	
	reset = 1'h1;
	repeat(2) @(posedge clk);
	reset = 1'h0;
	repeat(2) @(posedge clk);
	//testReset(clk, fb_addr_y, fb_addr_x, fb_writedata, fb_WE, reset);
	
endtask
 
task automatic testWriteOneReadElse(ref logic clk, 
								ref logic[4:0] fb_addr_y,
								ref logic[5:0] fb_addr_x,
								ref logic fb_writedata,
								ref logic fb_WE,
								ref logic fb_readdata,
								ref logic reset,
								ref int total);
	fb_addr_y = 5'b00001;
	fb_addr_x = 6'b000001;
	fb_writedata = 1;
	fb_WE = 1;
	repeat(2) @(posedge clk);
		
	fb_addr_y = 5'b00000;
	fb_addr_x = 6'b000000;
	fb_writedata = 0;
	fb_WE = 0;
	repeat(2) @(posedge clk);
							
	repeat(2) 
		@(posedge clk);
	assert (fb_readdata == 1'h0) begin
		$display ("WriteOneRead Else TEST 2 : PASSED");
		total = total + 1;
	end
    else $error("OR TEST 2 : FAILED (Got %h, Expected 0)", fb_readdata);

	fb_addr_y = 6'h0000;
	fb_addr_x = 5'h0000;
	fb_writedata = 1'h0;
	fb_WE = 1'h0;
	
	reset = 1'h1;
	repeat(2) @(posedge clk);
	reset = 1'h0;
	repeat(2) @(posedge clk);
	//testReset(clk, fb_addr_y, fb_addr_x, fb_writedata, fb_WE, reset);
							
endtask	

 
task automatic testWriteManyReadMany(ref logic clk, 
								ref logic[4:0] fb_addr_y,
								ref logic[5:0] fb_addr_x,
								ref logic fb_writedata,
								ref logic fb_WE,
								ref logic fb_readdata,
								ref logic reset,
								ref int total);
	repeat(4) @(posedge clk);
		
		fb_addr_y = 5'b00010;
		fb_addr_x = 6'b000010;
		fb_writedata = 1;
		fb_WE = 1;
		repeat(2) @(posedge clk);

		fb_addr_y = 5'b00000;
		fb_addr_x = 6'b000000;
		fb_writedata = 0;
		fb_WE = 0;
		repeat(2) @(posedge clk);
		
		fb_addr_y = 5'b00100;
		fb_addr_x = 6'b000100;
		fb_writedata = 1;
		fb_WE = 1;
		repeat(2) @(posedge clk);

		fb_addr_y = 5'b01000;
		fb_addr_x = 6'b001000;
		fb_writedata = 1;
		repeat(2) @(posedge clk);

		fb_addr_y = 5'b10000;
		fb_addr_x = 6'b010000;
		fb_writedata = 1;
		repeat(2) @(posedge clk);

		//fb_WE = 0;
		fb_addr_y = 5'b00000;
		fb_addr_x = 6'b000000;
		fb_writedata = 0;
		fb_WE = 0;
		repeat(2) @(posedge clk);
		
		fb_addr_y = 5'b00010;
		fb_addr_x = 6'b000010;
		fb_writedata = 0;
		fb_WE = 0;
		repeat(2) @(posedge clk);
 
		repeat(2) 
		@(posedge clk);
		assert (fb_readdata == 1'h1) begin
			$display ("WriteManyReadMany TEST 3 part 1 : PASSED");
		end
		else $error("WriteManyReadMany TEST 3 part 1 : FAILED (Got %h, Expected 1)", fb_readdata);
		
		fb_addr_y = 5'b00000;
		fb_addr_x = 6'b000000;
		fb_writedata = 0;
		fb_WE = 0;
		repeat(2) @(posedge clk);
		
		fb_addr_y = 5'b00100;
		fb_addr_x = 6'b000100;
		fb_writedata = 0;
		fb_WE = 0;
		repeat(2) @(posedge clk);
 
		repeat(2) 
		@(posedge clk);
		assert (fb_readdata == 1'h1) begin
			$display ("WriteManyReadMany TEST 3 part 2 : PASSED");
		end
		else $error("WriteManyReadMany TEST 3 part 2 : FAILED (Got %h, Expected 1)", fb_readdata);
		
		fb_addr_y = 5'b00000;
		fb_addr_x = 6'b000000;
		fb_writedata = 0;
		fb_WE = 0;
		repeat(2) @(posedge clk);
		
		fb_addr_y = 5'b01000;
		fb_addr_x = 6'b001000;
		fb_writedata = 0;
		fb_WE = 0;
		repeat(2) @(posedge clk);
 
		repeat(2) 
		@(posedge clk);
		assert (fb_readdata == 1'h1) begin
			$display ("WriteManyReadMany TEST 3 part 3 : PASSED");
		end
		else $error("WriteManyReadMany TEST 3 part 3 : FAILED (Got %h, Expected 1)", fb_readdata);

		fb_addr_y = 5'b00000;
		fb_addr_x = 6'b000000;
		fb_writedata = 0;
		fb_WE = 0;
		repeat(2) @(posedge clk);
		
		fb_addr_y = 5'b10000;
		fb_addr_x = 6'b010000;
		fb_writedata = 0;
		fb_WE = 0;
		repeat(2) @(posedge clk);
 
		repeat(2) 
		@(posedge clk);
		assert (fb_readdata == 1'h1) begin
			$display ("WriteManyReadMany TEST 3 part 4 : PASSED");
		end
		else $error("WriteManyReadMany TEST 3 part 4 : FAILED (Got %h, Expected 1)", fb_readdata);
		
		fb_addr_y = 5'b00000;
		fb_addr_x = 6'b000000;
		fb_writedata = 0;
		fb_WE = 0;
		repeat(2) @(posedge clk);
		
		fb_addr_y = 5'b10000;
		fb_addr_x = 6'b100000;
		fb_writedata = 0;
		fb_WE = 0;
		repeat(2) @(posedge clk);
 
		repeat(2) 
		@(posedge clk);
		assert (fb_readdata == 1'h0) begin
			$display ("WriteManyReadMany TEST 3 part 5 : PASSED");
			total = total + 1;
		end
		else $error("OR TEST 3 part 5 : FAILED (Got %h, Expected 0)", fb_readdata);
	
	fb_addr_y = 6'h0000;
	fb_addr_x = 5'h0000;
	fb_writedata = 1'h0;
	fb_WE = 1'h0;
	
	reset = 1'h1;
	repeat(2) @(posedge clk);
	reset = 1'h0;
	repeat(2) @(posedge clk);
	//testReset(clk, fb_addr_y, fb_addr_x, fb_writedata, fb_WE, reset);
endtask 
 
module fb_testbench();
	logic clk;
	logic reset;
	logic [4:0] fb_addr_y;
	logic [5:0] fb_addr_x;
	logic fb_writedata;
	logic fb_WE;
	logic fb_readdata;
	logic [7:0] VGA_R, VGA_G, VGA_B;
	logic VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n;
	logic VGA_SYNC_n;
	int total;
	
	Chip8_framebuffer dut(.*);
	
	initial begin
		clk = 0;
		reset = 0;
		fb_addr_y = 5'b00000;
		fb_addr_x = 6'b000000;
		fb_writedata = 0;
		fb_WE = 0;
		total = 0;
		forever 
			#20ns clk = ~clk;
	end

	initial begin
		
		$display("Starting test script...");
		testWriteOne(clk, fb_addr_y, fb_addr_x, fb_writedata, fb_WE, fb_readdata, reset, total);
		testWriteOneReadElse(clk, fb_addr_y, fb_addr_x, fb_writedata, fb_WE, fb_readdata, reset, total);
		testWriteManyReadMany(clk, fb_addr_y, fb_addr_x, fb_writedata, fb_WE, fb_readdata, reset, total);
		
		repeat(2) @(posedge clk);

	end
	
endmodule
	
