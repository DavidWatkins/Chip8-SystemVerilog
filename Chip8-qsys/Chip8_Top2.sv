/*
 * Chip8 top level (Current a WIP)
 * Top level controller, has direct link to the linux side
 *
 * Columbia University
 */
 
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

	logic [15:0] i, pc, sp;
	logic [511:0] stack;
	logic [32767:0] memory;

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
	
	//Register File
	logic[7:0] 	regwritedata1, regwritedata2, VFwritedata;
	logic 		regWE1, regWE2, regWEVF;
	logic[3:0]	regaddr1, regaddr2;
	logic[7:0]	regreaddata1, regreaddata2, regVFreaddata;
	
	//Memory

	always_ff @(posedge clk)
		if(reset) begin
			fbreset <= 1'b1;
			memory <= 32768'd0;
		end else if(write && chipselect) begin
			if(address[16]) begin
				memory[0] <= 1'b0; //Fix me
			end else begin
				case (address) 
				
					inbetween(17'h0, address, 17'hF) : begin
						regwritedata1 <= writedata[7:0];
						regWE1 <= 1'b1;
						//regaddr1 <= address[3:0];
					 end

					17'h10 : i <= writedata[15:0];
					// 17'h11 : data_out <= {32'b0}; //Fix me
					// 17'h12 : data_out <= {32'b0}; //Fix me
					17'h13 : sp <= writedata[5:0]; //0-63
					17'h14 : pc <= writedata[11:0]; //0-4095

					17'h15 : begin
								ispressed <= writedata[7:4];
								key <= writedata[3:0];
							end

					17'h16 : state <= writedata[1:0];

					17'h17 : begin 
								fbvx <= writedata[11:8]; 
								fbvy <= writedata[7:4];
								fbdata <= writedata[3:0];
								fbwrite <= 1'b1;
								end

					17'h18 : stack[0] <= 1'b0; //Fix me

				endcase
			end
		end else begin
			fbwrite <= 1'b0;
			regWE1 <= 1'b0;
			regWE2 <= 1'b0;
			regWEVF <= 1'b0;
		end
		
	// OUTPUTS
	// deltas for joint parameters
	always_ff @(posedge clk) begin
		if (reset) begin
			data_out <= {32'b0};
		end else if ( chipselect ) begin
			if(address[16]) begin
				data_out <= {32'b0}; //Fix me
			end else begin
				case (address)

					inbetween(17'h0, address, 17'hF) : begin
						regaddr1 <= address[3:0];
						data_out <= {24'b0, regreaddata1};
					end

					17'h10 : data_out <= {16'b0, i};
					17'h11 : data_out <= {32'b0}; //Fix me
					17'h12 : data_out <= {32'b0}; //Fix me
					17'h13 : data_out <= {16'b0, sp};
					17'h14 : data_out <= {16'b0, pc};
					17'h15 : data_out <= {32'b0}; //No reading keypress
					17'h16 : data_out <= {30'b0, state};
					17'h17 : data_out <= {32'b0}; //Read Framebuffer?
					17'h18 : data_out <= {32'b0}; //Fix me {16'b0, stack[sp]}

				endcase
			end
		end
	end

	Framebuffer framebuffer(.clk(clk), 
							.reset(fbreset), 
							.write(fbwrite),
							.*);	
							
	Chip8_register_file reg_file (.cpu_clk(clk), 
							 .WE1 	(regWE1), 
							 .WE2 	(regWE2),
							 .WEVF 	(regWEVF), 
							 .writedata1 (regwritedata1),
							 .writedata2 (regwritedata2),
							 .VFwritedata (VFWritedata),
							 .addr1 (regaddr1),
							 .addr2 (regaddr2),
							 .readdata1 (regreaddata1),
							 .readdata2 (regreaddata2),
							 .VFreaddata (regVFreaddata));
endmodule
