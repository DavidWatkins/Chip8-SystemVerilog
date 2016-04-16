module bcd(
	input logic [7:0] num,
	output logic [3:0] hundreds,
	output logic [3:0] tens,
	output logic [3:0] ones);
	
	logic [19:0] shift;

	always_comb begin
		shift[19:8] = 11'd0;
		shift[7:0] = num;
		repeat (8) begin
			if(shift[11:8] >= 3'd5)
				shift[11:8] = shift[11:8] + 3'd3;
			if(shift[15:12] >= 3'd5)
				shift[15:12] = shift[15:12] + 3'd3;
			if(shift[19:16] >= 3'd5)
				shift[19:16] = shift[19:16] + 3'd3;
			// Shift entire register left once
			shift = shift << 1;
		end
		hundreds = shift[19:16];
		tens     = shift[15:12];
		ones     = shift[11:8];
	end

endmodule
