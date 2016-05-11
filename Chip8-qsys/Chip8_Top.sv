 /******************************************************************************
 * Chip8_Top.sv
 *
 * Top level Chip8 module that controls all other modules
 *
 * AUTHORS: David Watkins, Levi Oliver, Ashley Kling, Gabrielle Taylor
 * Dependencies:
 *  - Chip8_SoundController.sv
 *  - Chip8_framebuffer.sv
 *  - timer.sv
 *  - clk_div.sv
 *  - memory.v
 *  - reg_file.v
 *  - enums.svh
 *  - utils.svh
 *  - Chip8_CPU.sv
 *****************************************************************************/
 
 `include "enums.svh"
 `include "utils.svh"
 
 module Chip8_Top(
    input logic         clk,
    input logic         reset,
    input logic [31:0]  writedata,
    input logic         write,
    input               chipselect,
    input logic [17:0]  address,

    output logic [31:0] data_out,

    //VGA Output
    output logic [7:0]  VGA_R, VGA_G, VGA_B,
    output logic        VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n,
    output logic        VGA_SYNC_n,

    //Audio Output
    input  OSC_50_B8A,      //reference clock
    inout  AUD_ADCLRCK,     //Channel clock for ADC
    input  AUD_ADCDAT,
    inout  AUD_DACLRCK,     //Channel clock for DAC
    output AUD_DACDAT,      //DAC data
    output AUD_XCK, 
    inout  AUD_BCLK,        //Bit clock
    output AUD_I2C_SCLK,    //I2C clock
    inout  AUD_I2C_SDAT,    //I2C data
    output AUD_MUTE         //Audio mute
    );

    //Index register
    logic [15:0] I;

    //Program counter
    logic [7:0]  pc_state;
    logic [11:0] pc = 12'h200;
    logic [11:0] next_pc;
    logic [31:0] stage;
    logic        halt_for_keypress;
    logic [31:0] last_stage;
    //Framebuffer values
    logic		fbreset;
	logic [4:0]	fb_addr_y;//max val = 31
	logic [5:0] fb_addr_x;//max val = 63
	logic		fb_writedata; //data to write to addresse.
	logic		fb_WE; //enable writing to address
	logic		fb_readdata; //data to write to addresse.
    logic       fb_paused;

    //Keyboard
    logic       ispressed;
    logic [3:0] key;
    
    //Memory
    logic [7:0]  memwritedata1, memwritedata2;
    logic        memWE1, memWE2;
    logic [11:0] memaddr1, memaddr2;
    logic [7:0]  memreaddata1, memreaddata2;

    //Reg file
    logic [7:0] reg_writedata1, reg_writedata2;
    logic       regWE1, regWE2;
    logic [3:0] reg_addr1, reg_addr2;
    logic [7:0] reg_readdata1, reg_readdata2;

    //CPU
    logic [15:0] cpu_instruction;
    logic        cpu_delay_timer_WE, cpu_sound_timer_WE;
    logic [7:0]  cpu_delay_timer_writedata, cpu_sound_timer_writedata;
    PC_SRC       cpu_pc_src;
    logic [11:0] cpu_PC_writedata;
    logic        cpu_reg_WE1, cpu_reg_WE2;
    logic [3:0]  cpu_reg_addr1, cpu_reg_addr2;
    logic [7:0]  cpu_reg_writedata1, cpu_reg_writedata2;
    logic        cpu_mem_WE1, cpu_mem_WE2;
    logic [11:0] cpu_mem_addr1, cpu_mem_addr2;
    logic        cpu_mem_request;
    logic [ 7:0] cpu_mem_writedata1, cpu_mem_writedata2;
    logic        cpu_reg_I_WE;
    logic [15:0] cpu_reg_I_writedata;
    logic        cpu_fbreset;
    logic [4:0]	 cpu_fb_addr_y;
    logic [5:0]	 cpu_fb_addr_x;
    logic		 cpu_fb_writedata; 
    logic		 cpu_fb_readdata;
    logic		 cpu_fb_WE; 
    logic        cpu_halt_for_keypress;
    logic        cpu_stk_reset;
    STACK_OP     cpu_stk_op;
    logic[15:0]  cpu_stk_writedata;
    logic        cpu_bit_overwritten;
    logic        cpu_is_drawing;

    //Sound
    logic sound_on;
    logic sound_reset;

    //Timers
    logic       clk_div_reset, clk_div_clk_out;
    logic       delay_timer_write_enable, delay_timer_out;
    logic [7:0] delay_timer_data, delay_timer_output_data;
    logic       sound_timer_write_enable, sound_timer_out;
    logic [7:0] sound_timer_data, sound_timer_output_data;

    //Stack
    logic           stack_reset;
    STACK_OP        stack_op;
    logic [15:0]    stack_writedata;
    logic [15:0]    stack_outdata;

    //State
    Chip8_STATE state = Chip8_PAUSED;
    logic       bit_ovewritten;
    logic       is_drawing;

    //ARM Registers
    logic [5:0]  fbvx_prev;
    logic [4:0]  fbvy_prev;
    logic [11:0] mem_addr_prev;
    logic        chipselect_happened;

    initial begin
        pc <= 12'h200;

        last_stage <= 32'h0;
        memWE1 <= 1'b0;
        memWE2 <= 1'b0;
        cpu_instruction <= 16'h0;
        delay_timer_write_enable <= 1'b0;
        sound_timer_write_enable <= 1'b0;
        I <= 16'h0;
        regWE1 <= 1'b0;
        regWE2 <= 1'b0;

        fbreset <= 1'b0;
        fb_addr_y <= 5'b0;
        fb_addr_x <= 6'b0;
        fb_writedata <= 1'b0; 
        fb_WE <= 1'b0;

        stack_op <= STACK_HOLD;

        state <= Chip8_PAUSED;
        cpu_instruction <= 16'h0;
        stage <= 32'h0;

        stack_reset <= 1'b1;

        fbvx_prev <= 6'h0;
        fbvy_prev <= 5'h0;
        mem_addr_prev <= 12'h0;

        sound_on <= 1'b0;
        chipselect_happened <= 1'b0;

        fb_paused <= 1'b1;

        halt_for_keypress <= 1'b0;
    end

    always_ff @(posedge clk) begin
        if(reset) begin
            //Add initial values for code
            pc <= 12'h200;

            memWE1 <= 1'b0;
            memWE2 <= 1'b0;
            cpu_instruction <= 16'h0;
            delay_timer_write_enable <= 1'b0;
            sound_timer_write_enable <= 1'b0;
            I <= 16'h0;
            regWE1 <= 1'b0;
            regWE2 <= 1'b0;

            fbreset <= 1'b0;
            fb_addr_y <= 5'b0;
            fb_addr_x <= 6'b0;
            fb_writedata <= 1'b0; 
            fb_WE <= 1'b0;

            stack_op <= STACK_HOLD;

            state <= Chip8_PAUSED;
            cpu_instruction <= 16'h0;
            stage <= 32'h0;

            stack_reset <= 1'b1;

            fbvx_prev <= 6'h0;
            fbvy_prev <= 5'h0;
            mem_addr_prev <= 12'h0;

            sound_on <= 1'b0;
            chipselect_happened <= 1'b0;

            fb_paused <= 1'b1;

            halt_for_keypress <= 1'b0;

        //Handle input from the ARM processor
    end else if(chipselect) begin

        chipselect_happened <= 1'b1;
        casex (address) 

    			//Read/write from register
                18'b00_0000_0000_0000_xxxx: begin
                    reg_addr1 <= address[3:0];
                    data_out <= {24'h0, reg_readdata1};
                    if(write) begin
                        regWE1 <= 1'b1;
                        reg_writedata1 <= writedata[7:0];
                    end
                end

                18'h10 : begin
                    if(write) 
                        I <= writedata[15:0];
                    data_out <= {16'b0, I};
                end

    			//Read/write to sound_timer
    			18'h11 : begin
    				data_out <= {24'h0, sound_timer_output_data};
    				if(write) begin
    					sound_timer_write_enable <= 1'b1;
    					sound_timer_data <= writedata[7:0];
    				end 
    			end

    			//Read/write to delay_timer
    			18'h12 : begin
                    data_out <= {24'h0, delay_timer_output_data};
                    if(write) begin 
                     delay_timer_write_enable <= 1'b1;
                     delay_timer_data <= writedata[7:0];
                 end
             end

    			//Reset stack 
				18'h13 : begin 
					if(write) stack_reset <= 1'b1; 
					data_out <= 32'h13; 
				end

    			//Read/write to program counter
    			18'h14 : begin 
    				data_out <= {4'h0, cpu_instruction, pc};
    				if(write) pc <= writedata[11:0]; //0-4095
    			end

    			//Read/write key presses
    			18'h15 : begin 
    				data_out <= {27'b0, ispressed, key};
    				if(write) begin
    					ispressed <= writedata[4];
    					key <= writedata[3:0];
    				end
    			end

    			//Read/write the state of the emulator
    			18'h16 : begin
                    data_out <= state;
                    if(write) begin
                        case (writedata[1:0])
                            2'h0: state <= Chip8_RUNNING;
                            2'h1: state <= Chip8_RUN_INSTRUCTION;
                            2'h2: state <= Chip8_PAUSED;
                            default : state <= Chip8_PAUSED;
                        endcase
                    end
                end

    			//Modify framebuffer
    			18'h17 : begin
                    if(write) begin
                        fbvx_prev <= writedata[10:5];
                        fbvy_prev <= writedata[4:0];

                        fb_addr_x <= writedata[10:5];
                        fb_addr_y <= writedata[4:0];
                        fb_writedata <= writedata[11];
                        fb_WE <= writedata[12];
                    end else begin 
                        data_out <= {31'h0, fb_readdata};
                        fb_addr_x <= fbvx_prev;
                        fb_addr_y <= fbvy_prev;
                        fb_WE <= 1'b0;
                    end
                end

    			//Read/write stack
    			18'h18 : begin 
    				$display("READ/WRITE STACK NOT IMPLEMENTED");
    				data_out <= 32'h18;
    			end 

                //MODIFY MEMORY
                18'h19 : begin
                    if(write) begin
                        memaddr1 <= writedata[19:8];
                        memWE1 <= writedata[20] & write;
                        memwritedata1 <= writedata[7:0];

                        mem_addr_prev <= writedata[19:8];
                    end else begin 
                        data_out <= {12'h0, mem_addr_prev, memreaddata1};
                        memWE1 <= 1'b0;
                        memaddr1 <= mem_addr_prev;
                    end
                end

                //Load single instruction
                18'h1A : begin
                    if(write) 
                        cpu_instruction <= writedata[15:0];
                    data_out <= {stage[15:0], cpu_instruction};
                    stage <= 32'h0;
                end

                default: begin
                   data_out <= 32'd101;
               end

           endcase

       end else if(chipselect_happened) begin 
        memWE1 <= 1'b0; 
		  fb_WE <= 1'b0; 
		  regWE1 <= 1'b0; 
		  sound_timer_write_enable <= 1'b0; 
		  delay_timer_write_enable <= 1'b0; 
		  chipselect_happened <= 1'b0; 
		  stack_reset <= 1'b0;

        // fb_addr_x <= fbvx_prev;
        // fb_addr_y <= fbvy_prev;
        // memaddr1 <= mem_addr_prev;
    end else begin 
        fb_paused <= state == Chip8_PAUSED;
            // sound_on <= sound_timer_out;

            case (state)
                Chip8_RUNNING: begin
                    sound_on <= sound_timer_out;   
                    // memaddr1 <= pc;
                    // memaddr2 <= pc + 12'h1; 

                    if(halt_for_keypress) begin
                        if(ispressed) begin
                            halt_for_keypress <= 1'b0;
                        end
                    end else if(stage == 32'h0) begin
                        memaddr1 <= pc;
                        memaddr2 <= pc + 12'h1; 
                        cpu_instruction <= 16'h0;

                        bit_ovewritten <= 1'b0;
                        is_drawing <= 1'b0;

                        delay_timer_write_enable <= 1'b0;
                        sound_timer_write_enable <= 1'b0;
                        regWE1 <= 1'b0;
                        regWE2 <= 1'b0;
                        memWE1 <= 1'b0;
                        memWE2 <= 1'b0;
                        stack_op <= STACK_HOLD;
                    end else if (stage == 32'h1) begin
                        memaddr1 <= pc;
                        memaddr2 <= pc + 12'h1;
                        cpu_instruction <= {memreaddata1, memreaddata2};
                        last_stage <= stage;
                    end else if (stage >= 32'h2) begin
                        last_stage <= stage;
                        if(cpu_delay_timer_WE) begin
                            delay_timer_write_enable <= 1'b1;
                            delay_timer_data <= cpu_delay_timer_writedata;
                        end else begin
                            delay_timer_write_enable <= 1'b0;
                        end

                        if(cpu_sound_timer_WE) begin
                            sound_timer_write_enable <= 1'b1;
                            sound_timer_data <= cpu_sound_timer_writedata;
                        end else begin
                            sound_timer_write_enable <= 1'b0;
                        end

                        if(cpu_reg_WE1) begin
                            regWE1 <= 1'b1;
                            reg_writedata1 <= cpu_reg_writedata1;
                        end else begin
                            regWE1 <= 1'b0;
                        end

                        if(cpu_is_drawing) begin
                            is_drawing <= 1'b1;
                        end

                        if(cpu_bit_overwritten) begin
                            bit_ovewritten <= 1'b1;
                        end

                        if(stage == 32'd30000 && is_drawing) begin
                            regWE2 <= 1'b1;
                            reg_writedata2 <= {7'h0, bit_ovewritten};
                            reg_addr2 <= 4'hF; //Setting VF register to write
                        end else if(cpu_reg_WE2) begin
                            regWE2 <= 1'b1;
                            reg_writedata2 <= cpu_reg_writedata2;
                            reg_addr2 <= cpu_reg_addr2;
                        end else begin
                            regWE2 <= 1'b0;
                            reg_addr2 <= cpu_reg_addr2;
                        end

								/*
                        if(cpu_mem_WE1) begin
                            memwritedata1 <= cpu_mem_writedata1;
                            memWE1 <= 1'b1;
                        end else begin
                            memWE1 <= 1'b0;
                        end

                        if(cpu_mem_WE2) begin
                            memwritedata2 <= cpu_mem_writedata2;
                            memWE2 <= 1'b1;
                        end else begin
                            memWE2 <= 1'b0;
                        end
								*/

                        if(cpu_reg_I_WE) begin
                            I <= cpu_reg_I_writedata;
                        end

                        if(cpu_stk_op == STACK_PUSH) begin
                            stack_op <= STACK_PUSH;
                            stack_writedata <= cpu_stk_writedata;
                        end 

                        //next_pc final modification on NEXT_PC_WRITE_STAGE
                        if((stage >= NEXT_PC_WRITE_STAGE - 32'h3) & (stage <= NEXT_PC_WRITE_STAGE)) begin
                            if(cpu_stk_op == STACK_POP) begin
                                stack_op <= STACK_POP;
                                next_pc <= stack_outdata[11:0];
                            end else begin
                                case (cpu_pc_src)
                                    PC_SRC_ALU  : next_pc <= cpu_PC_writedata;
                                    PC_SRC_SKIP : next_pc <= pc + 12'd4;
                                    PC_SRC_NEXT : next_pc <= pc + 12'd2;
                                    default : next_pc <= pc /*default next_pc <= pc + 12'd2*/;
                                endcase
                            end
                        end

                        // if(cpu_fbreset) begin
                        //     fbreset <= 1'b1;
                        // end else begin
                        //     fbreset <= 1'b0;
                        // end

                        if(cpu_fb_WE) begin
                            fb_writedata <= cpu_fb_writedata;
                            fb_WE <= cpu_fb_WE;
                        end else begin
                            fb_WE <= 1'b0;   
                        end   

                        if(cpu_halt_for_keypress & !ispressed) begin
                            halt_for_keypress <= 1'b1;
                        end                     

                        if(cpu_mem_request) begin
                            memaddr1 <= cpu_mem_addr1;
                            memaddr2 <= cpu_mem_addr2;
							memwritedata1 <= cpu_mem_writedata1;
							memwritedata2 <= cpu_mem_writedata2;
							memWE1 <= cpu_mem_WE1;
							memWE2 <= cpu_mem_WE2;
                        end 

                        //Always
                        reg_addr1 <= cpu_reg_addr1;
                        fb_addr_x <= cpu_fb_addr_x;
                        fb_addr_y <= cpu_fb_addr_y;
                        // memaddr1 <= cpu_mem_addr1;
                        // memaddr2 <= cpu_mem_addr2;
                    end

                    //Cap of 50000, since 1000 instructions/sec is reasonable
                    if(!halt_for_keypress) begin
                        if(stage >= CPU_CYCLE_LENGTH) begin
                            stage <= 32'h0;
                            pc <= next_pc;
                        end 
                        else if (stage == 32'h1) begin
                            if(stage == last_stage) stage <= 32'h2;
                            else stage <= 32'h1;
                        end else if(stage == 32'h2) begin
                            if(stage == last_stage) stage <= 32'h3;
                            else stage <= 32'h2;
                        end 

                        else begin
                            stage <= stage + 32'h1;
                        end
                    end
                end
                Chip8_RUN_INSTRUCTION: begin
                    sound_on <= 1'b1;
                end
                Chip8_PAUSED: begin
                    // sound_on <= 1'b1;
                end
                default : /* default */;
            endcase
        end
    end

    Chip8_framebuffer framebuffer(
        .clk(clk),
        .reset(fbreset),
        .fb_addr_y(fb_addr_y),
        .fb_addr_x(fb_addr_x),
        .fb_writedata(fb_writedata),
        .fb_WE(fb_WE),
        .fb_readdata(fb_readdata),
        .is_paused   (fb_paused),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_CLK(VGA_CLK),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_n(VGA_BLANK_n),
        .VGA_SYNC_n(VGA_SYNC_n)
        );  

    memory memory(
        .address_a(memaddr1),
        .address_b(memaddr2),
        .clock(clk),
        .data_a(memwritedata1),
        .data_b(memwritedata2),
        .wren_a(memWE1),
        .wren_b(memWE2),
        .q_a(memreaddata1),
        .q_b(memreaddata2)
        );

    reg_file reg_file(
        .clock(clk),
        .address_a(reg_addr1),
        .address_b(reg_addr2),
        .data_a(reg_writedata1),
        .data_b(reg_writedata2),
        .wren_a(regWE1),
        .wren_b(regWE2),
        .q_a(reg_readdata1),
        .q_b(reg_readdata2)
        );

    Chip8_CPU cpu(  
        .cpu_clk(clk),
        .instruction(cpu_instruction),
        .reg_readdata1(reg_readdata1), 
        .reg_readdata2(reg_readdata2), 
        .mem_readdata1(memreaddata1), 
        .mem_readdata2(memreaddata2),
        .reg_I_readdata(I),
        .delay_timer_readdata(delay_timer_output_data),
        .key_pressed(ispressed),
        .key_press(key),
        .PC_readdata(pc),
        .stage(stage),
        .top_level_state(state),
        .delay_timer_WE(cpu_delay_timer_WE),
        .sound_timer_WE(cpu_sound_timer_WE),
        .delay_timer_writedata(cpu_delay_timer_writedata),
        .sound_timer_writedata(cpu_sound_timer_writedata),
        .pc_src(cpu_pc_src),
        .PC_writedata(cpu_PC_writedata),
        .reg_WE1(cpu_reg_WE1),
        .reg_WE2(cpu_reg_WE2),
        .reg_addr1(cpu_reg_addr1),
        .reg_addr2(cpu_reg_addr2),
        .reg_writedata1(cpu_reg_writedata1),
        .reg_writedata2(cpu_reg_writedata2),
        .mem_WE1(cpu_mem_WE1),
        .mem_WE2(cpu_mem_WE2),
        .mem_addr1(cpu_mem_addr1),
        .mem_addr2(cpu_mem_addr2),
        .mem_request      (cpu_mem_request),
        .mem_writedata1(cpu_mem_writedata1),
        .mem_writedata2(cpu_mem_writedata2),
        .reg_I_WE(cpu_reg_I_WE),
        .reg_I_writedata(cpu_reg_I_writedata),
        .fbreset(cpu_fbreset),

        .fb_addr_y(cpu_fb_addr_y),
        .fb_addr_x(cpu_fb_addr_x),
        .fb_writedata(cpu_fb_writedata), 
        .fb_WE(cpu_fb_WE), 
        .fb_readdata(fb_readdata),

        .bit_overwritten(cpu_bit_overwritten),
        .isDrawing(cpu_is_drawing),

        .stk_reset(cpu_stk_reset),
        .stk_op(cpu_stk_op),
        .stk_writedata(cpu_stk_writedata),

        .halt_for_keypress(cpu_halt_for_keypress)
        );

    Chip8_SoundController sound(
        .OSC_50_B8A(OSC_50_B8A),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_ADCDAT(AUD_ADCDAT),
        .AUD_DACLRCK(AUD_DACLRCK),
        .AUD_DACDAT(AUD_DACDAT),
        .AUD_XCK(AUD_XCK),
        .AUD_BCLK(AUD_BCLK),
        .AUD_I2C_SCLK(AUD_I2C_SCLK),
        .AUD_I2C_SDAT(AUD_I2C_SDAT),
        .AUD_MUTE(AUD_MUTE),

        .clk(clk),
        .is_on(sound_on),
        .reset(sound_reset)
        );

    clk_div clk_div(
        .clk_in(clk),
        .reset(clk_div_reset),
        .clk_out(clk_div_clk_out)
        );

    timer delay_timer(
        .clk(clk),       
        .clk_60(clk_div_clk_out),  
        .write_enable(delay_timer_write_enable),
        .data(delay_timer_data),
        .out(delay_timer_out),
        .output_data (delay_timer_output_data)
        );

    timer sound_timer(
        .clk(clk), 
        .clk_60(clk_div_clk_out), 
        .write_enable(sound_timer_write_enable),
        .data(sound_timer_data),
        .out(sound_timer_out),
        .output_data (sound_timer_output_data)
        );

    Chip8_Stack stack (
        .reset(stack_reset),
        .cpu_clk(clk),
        .op(stack_op),
        .writedata(stack_writedata),
        .outdata(stack_outdata)
        );


endmodule
