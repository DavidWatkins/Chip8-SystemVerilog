/*
 *
 * Semi-naive pseudo-random number generator
 *
 * Implemented by Levi
 *
 */
module Chip8_rand_num_generator(input logic cpu_clk, output logic[15:0] out);

	logic [15:0] rand_num;

	initial begin
		rand_num <= 16'b1111010111010010;
	end

	always_ff @(posedge cpu_clk) begin
		if(~|(rand_num[15:0])) begin
			rand_num[15:0] <= 16'b1111010111010010;
		end else begin
			rand_num[0] <= rand_num[15] ^ rand_num[14];
			rand_num[1] <= rand_num[14] ^ rand_num[13];
			rand_num[2] <= rand_num[13] ^ rand_num[12];
			rand_num[3] <= rand_num[12] ^ rand_num[11];
			rand_num[4] <= rand_num[11] ^ rand_num[10];
			rand_num[5] <= rand_num[10] ^ rand_num[9];
			rand_num[6] <= rand_num[9] ^ rand_num[8];
			rand_num[7] <= rand_num[8] ^ rand_num[7];
			rand_num[8] <= rand_num[7] ^ rand_num[6];
			rand_num[9] <= rand_num[6] ^ rand_num[5];
			rand_num[10] <= rand_num[5] ^ rand_num[4];
			rand_num[11] <= rand_num[4] ^ rand_num[3];
			rand_num[12] <= rand_num[3] ^ rand_num[2];
			rand_num[13] <= rand_num[2] ^ rand_num[1];
			rand_num[14] <= rand_num[1] ^ rand_num[0];
			rand_num[15] <= rand_num[0] ^ rand_num[15]; 
		end

		out <= rand_num;
	end
endmodule