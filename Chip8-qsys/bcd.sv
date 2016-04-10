module bcd(
	input logic [7:0] num;
	output logic [3:0] hundreds;
	output logic [3:0] tens;
	output logic [3:0] ones;
	
	logic [19:0] shift;
	integer i; 	//loop counter	

	shift[19:8] = 0;
	shift[7:0] = number;

	always_comb begin
		for (i=0; i<8; i=i+1) begin
			if(shift[11:8] >= 5)
				shift[11:8] = shift[11:8] + 3;
			if(shift[15:12] >= 5)
				shift[15:12] = shift[15:12] + 3;
			if(shift[19:16] >= 5)
				shift[19:16] = shift[19:16] + 3;
			// Shift entire register left once
			shift = shift << 1;

			hundreds = shift[19:16];
			tens     = shift[15:12];
			ones     = shift[11:8];
		end
	end

endmodule