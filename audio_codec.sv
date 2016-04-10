


// Original audio codec code taken from
//Howard Mao's FPGA blog
//http://zhehaomao.com/blog/fpga/2014/01/15/sockit-8.html
//MOdified as needed

/*
audio_codec.sv 
Sends samples to the audio codec ssm 2603 at audio clock rate.
*/


//Audio codec interface
module audio_codec (
    input  clk, //audio clock
    input  reset,
    output [1:0]  sample_end,   //end of sample
    output [1:0]  sample_req,   //request new sample
    input  [15:0] audio_output, //audio output sent to audio codec 
    input  [1:0] channel_sel,   //select channel
    output AUD_ADCLRCK, //ADC channel clock
    input AUD_ADCDAT,
    output AUD_DACLRCK, //DAC channel clock
    output AUD_DACDAT,  
    output AUD_BCLK //Bit clock
);

// divided by 256 clock for the LRC clock, one clock is oen audio frame
reg [7:0] lrck_divider;

// divided by 4 clock for the bit clock BCLK
reg [1:0] bclk_divider;

reg [15:0] shift_out;
reg [15:0] shift_temp;

wire lrck = !lrck_divider[7];

//assigning clocks from the clock divider
assign AUD_ADCLRCK = lrck;
assign AUD_DACLRCK = lrck;
assign AUD_BCLK = bclk_divider[1];

// assigning data as last bit of shift register
assign AUD_DACDAT = shift_out[15];


always @(posedge clk) begin
    if (reset) begin
        lrck_divider <= 8'hff;
        bclk_divider <= 2'b11;
    end else begin
        lrck_divider <= lrck_divider + 1'b1;
        bclk_divider <= bclk_divider + 1'b1;
    end
end

//first 16 bit sample sent after 16 bclks or 4*16=64 mclk
assign sample_end[1] = (lrck_divider == 8'h40);
//second 16 bit sample sent after 48 bclks or 4*48 = 192 mclk 
assign sample_end[0] = (lrck_divider == 8'hc0);

// end of one lrc clk cycle (254 mclk cycles)
assign sample_req[1] = (lrck_divider == 8'hfe);
// end of half lrc clk cycle (126 mclk cycles) so request for next sample
assign sample_req[0] = (lrck_divider == 8'h7e);

wire clr_lrck = (lrck_divider == 8'h7f); // 127 mclk
wire set_lrck = (lrck_divider == 8'hff); // 255 mclk
// high right after bclk is set
wire set_bclk = (bclk_divider == 2'b10 && !lrck_divider[6]);
// high right before bclk is cleared
wire clr_bclk = (bclk_divider == 2'b11 && !lrck_divider[6]);

//implementing shift operation to send the audio samples
always @(posedge clk) begin
    if (reset) begin
        shift_out <= 16'h0;
        shift_temp <= 16'h0;
  	 end
	 else if (set_lrck) begin
            shift_out <= audio_output;
            shift_temp <= audio_output;
    end
	 else if (clr_lrck) begin
			shift_out <= shift_temp;
    end else if (clr_bclk == 1) begin
        shift_out <= {shift_out[14:0], 1'b0};
    end
end

endmodule
