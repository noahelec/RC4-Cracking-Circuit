module ksa (
    input logic CLOCK_50,              // Clock pin
    input logic [3:0] KEY,             // push button switches
    input logic [9:0] SW,              // slider switches
    output logic [9:0] LEDR,           // red lights
    output logic [6:0] HEX0,
    output logic [6:0] HEX1,
    output logic [6:0] HEX2,
    output logic [6:0] HEX3,
    output logic [6:0] HEX4,
    output logic [6:0] HEX5
);

parameter int keylength = 3;
parameter int message_length = 32;

//inputs for SevenSegmentDisplay
logic [6:0] out;
logic [3:0] in;

// Clock and reset signals
logic clk, reset_n;

// secret key
logic [23:0] secret_key;

assign clk = CLOCK_50;
assign reset_n = KEY[3];

SevenSegmentDisplayDecoder SevenSegmentDisplay (.ssOut(out), .nIn(in));

logic [7:0] s [0:255];
logic [7:0] s_address, d_address, e_address;
logic [7:0] s_data, d_data;
logic s_wren, d_wren;
logic [7:0] s_q, d_q, e_q;
logic [7:0] s_init_count;
logic [7:0] i,j,k,f,temp_i, temp_j;
logic [7:0] i_element, j_element;
logic [7:0] key, key_element, temp;
// Decryption related signals
logic [7:0] decrypted_output [0:31];
logic [7:0] encrypted_input [0:31];
logic invalid_ascii = 1'b0;
logic start_init, start_shuffle, start_compute;
logic finish_init, finish_compute, finish_shuffle;

s_memory s_memory_inst (
    .address(s_address), //this is the address of the memory
    .clock(clk), //this is the clock
    .data(s_data), //this is the data to be written
    .wren(s_wren), //this is the write enable signal, this writes it whenever this is 1 and the clock is high
    .q(s_q) // this is the output of the memory
);

// include D memory structurally
d_memory d_memory_inst(	.address(d_address),
					.clock(clk),
					.data(d_data),
					.wren(d_wren),
					.q(d_q));

// include e_ROM structurally			
e_rom e_rom_inst (		.address(e_address),
					.clock(clk),
					.q(e_q));

controller_fsm_lab4 controller (
    .clk(clk),
	.reset_n(reset_n), 
	.finish_compute(finish_compute), 
	.finish_init(finish_init),
	.finish_shuffle(finish_shuffle),
	.invalid_ascii(invalid_ascii),
	.start_init(start_init),
	.start_shuffle(start_shuffle), 
	.start_compute(start_compute)
	);

typedef enum logic [7:0] {
    IDLE,
    INIT,
    TASK_2_init,
    s_set_key_element,
    s_get_key,
    s_sum_j,
    task2_update_j,
    s_read_array_i,
    s_read_array_i_wait,
    s_read_array_j,
    s_read_array_j_wait,
    s_read_done,
    s_swap_i_to_j,
    s_swap_j_to_i,
    s_swap_done,
    s_loop_task2a,
    waitbeforeDECRYPT,
    decrypt_init,
    d_incr_i,
    d_read_s_i,
    d_wait_s_i,
    d_update_j,
    d_read_s_j,
    d_wait_s_j,
    d_swap1,
    d_swap2,
    d_read_for_f,
    d_wait_for_f,
    d_read_from_rom,
    d_wait_from_rom,
    d_compute_and_output,
    d_turnon_dwren,
    d_check_if_valid,
    d_final_check,
    start_initalizing,
    start_shuffling,
    start_computing,
    DEBUG,
    DONE
} state_t;

state_t state;

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state <= IDLE;  
        i <= 8'd0;
        k <= 8'd0;
    end else begin
        case (state)
            start_initalizing: begin
                finish_compute <= 1'b0;
                if (start_init) state <= IDLE;
                else state <= start_initalizing;
            end

            IDLE: begin
                i <= 8'd0;
                state <= INIT;
                LEDR <= 10'b0;
            end

            INIT: begin
                if (i == 8'd255) begin
                    s_wren <= 1'b0;
                    finish_init <= 1'b1;
                    s_address <= i;
                    state <= start_shuffling;
                end else begin
                    s_address <= s_address + 1'd1;
                    s_data <= s_data + 1'd1;
                    s_wren <= 1'b1;
                    i <= i + 1'b1;
                    state <= INIT;
                end
            end

            start_shuffling: begin
                finish_init <= 1'b0;
                if (start_shuffle) state <= TASK_2_init;
                else state <= start_shuffling;
            end
            
            TASK_2_init: begin
                i <= 8'd0;
                j <= 8'd0;
                s_wren <= 1'b0;
                state <= s_set_key_element;
                //secret_key [23:0] <= SW[9:0];
                secret_key [23:0] <= 24'b00000000_00000010_01001001; //this is the test key for task 2a
            end

            s_set_key_element: begin
			   s_address <= i[7:0];
				key_element <= i % 3; //keylength is 3 in our implementation
				state <= s_get_key;
			end 
			
			s_get_key: begin
				 if (key_element == 8'b0) 
					key <= secret_key[23:16]; 
				 else if (key_element == 8'b1) 
					key <= secret_key[15:8]; 
				 else 
					key <= secret_key[7:0]; 
				 
				 state <= s_sum_j;
			end 

            s_sum_j: begin
                j <= j + s_q + key;
                state <= s_read_array_i;
            end
			
			s_read_array_i: begin
				s_address <= i[7:0];
				s_wren <= 1'b0;
				state <= s_read_array_i_wait;
			end 
			
			s_read_array_i_wait: begin
				//Wait for 1 extra cycle for reading
				state <= s_read_array_j;
			end 
			
			s_read_array_j: begin
				i_element <= s_q;
				s_address <= j[7:0];
				state <= s_read_array_j_wait;
			end 
			
			s_read_array_j_wait: begin
				//Wait for 1 extra cycle for reading
				state <= s_read_done;
			end 

			s_read_done: begin
				j_element <= s_q;
				s_wren <= 1'b1;
				state <= s_swap_i_to_j;
			end 
			
			s_swap_i_to_j: begin
				s_address <= j[7:0];
				s_data <= i_element;
				state <= s_swap_j_to_i;
			end 
			
			s_swap_j_to_i: begin
				s_address <= i[7:0];
				s_data <= j_element;
				state <= s_swap_done;
			end 
			
			s_swap_done: begin
				s_wren <= 1'b0;
				state <= s_loop_task2a;
			end 
			
			s_loop_task2a: begin
				i <= i + 8'd1;
				if (i == 255) begin
					state <= start_computing;
                    finish_shuffle <= 1'b1;
				end
				else begin
					state <= s_set_key_element;
				end 
			end 

            start_computing: begin
                if (start_compute) state <= waitbeforeDECRYPT;
                else state <= start_computing;
            end

            waitbeforeDECRYPT: begin
                finish_shuffle <= 1'b0;
                e_address <= 8'b0;
                d_address <= 8'b0;
                s_address <= 8'b0;
                s_data <= 8'b0;
                d_data <= 8'b0;
                temp <= 8'b0;
                state <= decrypt_init;
            end

            decrypt_init: begin
                temp_i <= 8'd0;
                temp_j <= 8'd0;
                k <= 8'd0;
                invalid_ascii <= 1'b0;
                state <= d_incr_i;
            end

            d_incr_i: begin
                d_wren <=0;
                temp_i <= temp_i + 8'd1;
                state <= d_read_s_i;
            end

            d_read_s_i: begin
                s_address <= temp_i;
                state <= d_wait_s_i;
            end

            d_wait_s_i: begin
                state <= d_update_j;
            end

            d_update_j: begin
                i_element <= s_q;
                temp_j <= temp_j + s_q;
                state <= d_read_s_j;
            end

            d_read_s_j: begin
                s_address <= temp_j;
                state <= d_wait_s_j;
            end

            d_wait_s_j : begin
                state <= d_swap1;
            end

            d_swap1: begin
                j_element <= s_q;
                s_address <= temp_i;
                s_data <= s_q;
                temp <= i_element;
                state <= d_swap2; 
            end

            d_swap2: begin
                s_wren <= 1'b1;
                i_element <= s_q;
                s_address <= temp_j;
                s_data <= temp;
                state <= d_read_for_f;
            end

            d_read_for_f: begin
                j_element <= s_q;
                s_address <= temp + i_element;
                state <= d_wait_for_f;
            end         

            d_wait_for_f: begin
                s_wren  <= 1'b0;
                state <= d_read_from_rom;
            end

            d_read_from_rom: begin
                f <= s_q;
                e_address <= k;
                state <= d_wait_from_rom;
            end

            d_wait_from_rom: begin
                state <= d_compute_and_output;
            end

            d_compute_and_output: begin   
                d_address <= k;
                d_data <= f^e_q; //xor
                state <= d_turnon_dwren;
            end

            d_turnon_dwren: begin
                d_wren <= 1'b1;
                state <= d_check_if_valid;
            end

            d_check_if_valid: begin
                if((d_data < 8'd97 || d_data > 8'd122) && (d_data != 8'd32)) begin
                        invalid_ascii <= 1'b1;
                        state <= DONE;
                    end else begin
                        invalid_ascii <= 1'b0;
                        if(k == message_length-1) 
                        state <= DONE;
                        else begin
                                k <= k + 1;   
                                state <= d_incr_i;
                            end
                        end  
            end


            DONE: begin
                state <= start_initalizing;
                finish_compute <= 1'b1;
                d_wren <= 1'b0;
                s_address <= 8'b0;
                s_data <= 8'b0;
                d_address <= 8'b0;
                d_data <= 8'b0;
            end
            default: begin
                state <= start_initalizing;
                secret_key [23:0] <= 24'b00000000_00000010_01001001; //this is the test key for task 2a
            end
        endcase
    end
end
endmodule