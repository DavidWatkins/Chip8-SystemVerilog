/******************************************************************************
 * Chip8_SoundController.sv
 *
 * Top level controller for audio output on the Chip8
 * Designed to interact directly with a Altera SoCKit Cyclone V board
 * Source originally borrowed from: 
 *  Howard Mao's FPGA blog
 *  http://zhehaomao.com/blog/fpga/2014/01/15/sockit-8.html
 *
 * AUTHORS: David Watkins, Gabrielle Taylor
 * Dependencies:
 *  - Chip8_Sound/clock_pll.v
 *  - Chip8_Sound/audio_effects.sv
 *  - Chip8_Sound/i2c_av_config.sv
 *  - Chip8_Sound/audio_codec.sv
 *****************************************************************************/

module Chip8_SoundController (
    input  OSC_50_B8A,   //reference clock
	inout  AUD_ADCLRCK, //Channel clock for ADC
    input  AUD_ADCDAT,
    inout  AUD_DACLRCK, //Channel clock for DAC
    output AUD_DACDAT,  //DAC data
    output AUD_XCK, 
    inout  AUD_BCLK, // Bit clock
    output AUD_I2C_SCLK, //I2C clock
    inout  AUD_I2C_SDAT, //I2C data
    output AUD_MUTE,   //Audio mute

    input logic clk,
    input logic is_on, //Turn on the output
    input logic reset
);

wire audio_clk;
wire main_clk;

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
);

assign AUD_XCK = audio_clk;
assign AUD_MUTE = (is_on == 1'b0);

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
    .control (is_on)
);

endmodule
