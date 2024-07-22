module main_fsm(input logic clk, reset_n, invalid_ascii,
						input logic finish_init, finish_shuffle, finish_compute, 
						output logic start_init, start_shuffle, start_compute,
						output logic [9:0] LEDR,
						output logic [23:0] secret_key);
	//Main state machine
	parameter idle = 4'b0000;
	parameter task1 = 4'b0001;
	parameter task2a = 4'b0010;
	parameter task2b = 4'b0100;
	parameter done = 4'b1000;

	logic [3:0] state /*synthesis keep*/;
	
	assign start_init = state[0];
	assign start_shuffle = state[1];
	assign start_compute = state[2];

	always_ff @(posedge clk, negedge reset_n)
		if (!reset_n) begin //if KEY[3] is pressed, reset
			state <= idle;
			secret_key <= 24'b0;
			LEDR <= 10'b0;
			end
		else
			case(state)
				idle: 	state <= task1;
				task1: 	if (finish_init) state <= task2a;
							else state <= task1;
				task2a: 	if (finish_shuffle) state <= task2b;
							else state <= task2a;
				task2b: 	begin
								if (finish_compute && invalid_ascii && secret_key < 24'd16777215) begin //loop back and try next secret key
									state <= task1;
									secret_key <= secret_key + 1;
								end
								else if(finish_compute && !invalid_ascii) begin //if we got a valid secret key, done
									LEDR[0] <= 1;
									state <= done;
								end
								else if(finish_compute && secret_key == 24'd16777215) begin //out of key space, no valid one, done
									LEDR[1] <= 1;
									state <= done;
								end
								else state <= task2b;
							end
				done: 	state <= done;
				default: state <= idle;
			endcase
endmodule