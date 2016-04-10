
// Original audio codec code taken from
//Howard Mao's FPGA blog
//http://zhehaomao.com/blog/fpga/2014/01/15/sockit-8.html
//MOdified as needed

/* Audio_top.sv
Contains the top-level audio controller. Instantiates sprite ROM blocks and
communicates with the avalon bus */

module Audio_top (
    input  OSC_50_B8A,   //reference clock
    input  [1:0] audio_ctrl,    
	 inout  AUD_ADCLRCK, //Channel clock for ADC
    input  AUD_ADCDAT,
    inout  AUD_DACLRCK, //Channel clock for DAC
    output AUD_DACDAT,  //DAC data
    output AUD_XCK, 
    inout  AUD_BCLK, // Bit clock
    output AUD_I2C_SCLK, //I2C clock
    inout  AUD_I2C_SDAT, //I2C data
    output AUD_MUTE,   //Audio mute
    input  [3:0] KEY,
    input  [3:0] SW,
    output [3:0] LED
);

wire reset = !KEY[0];
wire main_clk;
wire audio_clk;

wire [1:0] sample_end;
wire [1:0] sample_req;
wire [15:0] audio_output;


//generate audio clock
clock_pll pll (
    .refclk (OSC_50_B8A),
    .rst (reset),
    .outclk_0 (audio_clk),
    .outclk_1 (main_clk)
);

//Configure registers of audio codec ssm2603
i2c_av_config av_config (
    .clk (main_clk),
    .reset (reset),
    .i2c_sclk (AUD_I2C_SCLK),
    .i2c_sdat (AUD_I2C_SDAT),
    .status (LED)
);

assign AUD_XCK = audio_clk;
assign AUD_MUTE = (SW != 4'b0);



//Call Audio codec interface
audio_codec ac (
    .clk (audio_clk),
    .reset (reset),
    .sample_end (sample_end),
    .sample_req (sample_req),
    .audio_output (audio_output),
    .channel_sel (2'b10),

    .AUD_ADCLRCK (AUD_ADCLRCK),
    .AUD_ADCDAT (AUD_ADCDAT),
    .AUD_DACLRCK (AUD_DACLRCK),
    .AUD_DACDAT (AUD_DACDAT),
    .AUD_BCLK (AUD_BCLK)
);


audio_effects ae (
    .clk (audio_clk),
    .sample_end (sample_end[1]),
    .sample_req (sample_req[1]),
    .audio_output (audio_output),
    .control (SW)
);

endmodule