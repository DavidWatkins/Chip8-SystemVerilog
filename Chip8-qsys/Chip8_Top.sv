/*
 * Chip8 top level (Current a WIP)
 * Top level controller, has direct link to the linux side
 *
 * Columbia University
 */

// // enumeration type for the CPU state
// typedef enum 
// { CPU_f_RUNNING , CPU_f_PAUSED , CPU_f_LOADING , CPU_f_LOADFONT} CPU_f ;
 
function reg inbetween(input [17:0] low, value, high); 
begin
  inbetween = value >= low && value <= high;
end
endfunction
 
module Chip8_Top(
	input logic         clk,
	input logic         reset,
	input logic [31:0]  writedata,
	input logic 		write,
	input 		  		chipselect,
	input logic [17:0] 	address,

	output logic [31:0] data_out,
	output logic [7:0]  VGA_R, VGA_G, VGA_B,
	output logic        VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n,
	output logic        VGA_SYNC_n);

	logic [15:0] i, sp;
	logic [511:0] stack;

	//Program counter
	logic [7:0] pc_state;
	logic [15:0] pc;

	//Framebuffer values
	logic fbreset;
	logic [7:0] fbvx;
	logic [7:0] fbvy;
	logic [7:0] fbdata;
	logic fbwrite;
	
	//State variables
	logic [1:0] state;

	//Keyboard
	logic ispressed;
	logic [3:0] key;
	
	//Memory
	logic [7:0] memwritedata1, memwritedata2;
	logic memWE1, memWE2;
	logic [11:0] memaddr1, memaddr2;
	logic [7:0] memreaddata1, memreaddata2;

	//CPU
	logic [15:0] cpu_instruction;
	logic [3:0] cpu_testIn1, cpu_testIn2;
	logic [7:0] cpu_testOut1, cpu_testOut2;

	always_ff @(posedge clk) begin : proc_
		if(reset) begin
			//Add initial values for code
			pc <= 15'h200;

			fbwrite <= 1'b0;
			memWE1 <= 1'b0;
			memWE2 <= 1'b0;
			state <= 2'h0;
		//Handle input from the ARM processor
		end else if(chipselect) begin
			if(address[16]) begin
				//memaddr1 <= address[11:0];
				//data_out <= memreaddata1;
				//if(write) begin
				//	memWE1 <= 1'b1;
				//	memwritedata1 <= writedata[7:0];
				//end
			end else begin
				case (address) 
				
					// inbetween(17'h0, address, 17'hF) : begin end
					// 17'h11 : data_out <= {32'b0}; //Fix me
					// 17'h12 : data_out <= {32'b0}; //Fix me

					17'h10 : begin
						i <= writedata[15:0];
						data_out <= {16'b0, i};
					end
					17'h11 : data_out <= {32'b0}; //Fix me
					17'h12 : data_out <= {32'b0}; //Fix me
					
					17'h13 : begin
						data_out <= {16'b0, sp};
						if(write) sp <= writedata[5:0]; //0-63
					end

					17'h14 : begin 
						data_out <= {16'b0, pc};
						if(write) pc <= writedata[11:0]; //0-4095
					end

					17'h15 : begin 
						data_out <= {32'b0}; //No reading keypress
						if(write) begin
							ispressed <= writedata[7:4];
							key <= writedata[3:0];
						end
					end

					17'h16 : begin
						data_out <= {30'b0, state};
						if(write) state <= writedata[1:0];
					end

					17'h17 : begin
						data_out <= {32'b0}; //Read Framebuffer?
						if(write) begin 
							fbvx <= writedata[11:8]; 
							fbvy <= writedata[7:4];
							fbdata <= writedata[3:0];
							fbwrite <= 1'b1;
						end
					end

					17'h18 : begin 
						data_out <= {32'b0}; //Fix me {16'b0, stack[sp]}
						if(write) stack[0] <= 1'b0; //Fix me
					end	

				endcase
			end

		//Normal processor continuation if State is running
		end else if(state == 2'h0) begin
			pc <= pc + 2;
		end
	end

	always_comb begin 
		memaddr1 = pc[11:0];
		memaddr2 = pc[11:0] + 1;

		cpu_instruction = (memreaddata1 << 8) | (memreaddata2);
	end

	Framebuffer framebuffer(.clk(clk), 
							.reset(fbreset), 
							.write(fbwrite),
							.*);	

	/*Chip8_memory memory(.cpu_clk(clk),
					.writedata1(memwritedata1),
					.writedata2(memwritedata2),
					.WE1(memWE1),
					.WE2(memWE2),
					.addr1(memaddr1),
					.addr2(memaddr2),
					.readdata1(memreaddata1),
					.readdata2(memreaddata2));*/
	memory memory(memaddr1, memaddr2, clk, memwritedata1, memwritedata2,
					memWE1, memWE2, memreaddata1, memreaddata2);

	Chip8_CPU cpu(	.cpu_clk(clk),
					.instruction(cpu_instruction),
					.testIn1(cpu_testIn1),
					.testIn2(cpu_testIn2),
					.testOut1(cpu_testOut1),
					.testOut2(cpu_testOut2));

endmodule
