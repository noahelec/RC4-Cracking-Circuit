module controller_fsm_lab4 (input logic clk, reset_n, invalid_ascii,
						input logic finish_init, finish_shuffle, finish_compute, 
						output logic start_init, start_shuffle, start_compute,
						output logic [9:0] LEDR,
						output logic [23:0] secret_key);

    // Main state machine
    parameter IDLE = 4'b0000;
    parameter INITIAL = 4'b0001;
    parameter SHUFFLE = 4'b0010;
    parameter COMPUTE = 4'b0100;
    parameter DONE = 4'b1000;

    logic [3:0] state /*synthesis keep*/;

    // Assign start signals based on state
    assign start_init = state[0];
    assign start_shuffle = state[1];
    assign start_compute = state[2];

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin // if reset_n is pressed, reset
            state <= IDLE;
            secret_key <= 24'b0;
            LEDR <= 10'b0;
        end else begin
            case(state)
                IDLE: 
                    state <= INITIAL;
                
                INITIAL: 
                    if (finish_init) 
                        state <= SHUFFLE;
                    else 
                        state <= INITIAL;

                SHUFFLE: 
                    if (finish_shuffle) 
                        state <= COMPUTE;
                    else 
                        state <= SHUFFLE;

                COMPUTE: begin
								if (finish_compute && invalid_ascii && secret_key < 24'd16777215) begin //loop back and try next secret key
									state <= INITIAL;
									secret_key <= secret_key + 1;
								end
								else if(finish_compute && !invalid_ascii) begin //if we got a valid secret key, done
									LEDR[0] <= 1;
									state <= DONE;
								end
								else if(finish_compute && secret_key == 24'd16777215) begin //out of key space, no valid one, done
									LEDR[1] <= 1;
									state <= DONE;
								end
								else state <= COMPUTE;
							end
                DONE: 
                    state <= DONE;

                default: 
                    state <= IDLE;
            endcase
        end
    end

endmodule
