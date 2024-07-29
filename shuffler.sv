module shuffle(
    input logic start,        // Signal to start the shuffling process
    input logic clk,          // Clock signal
    input logic reset_n,      // Active-low reset signal
    input logic [7:0] q,      // Data input from memory
    input logic [23:0] secret_key, // Secret key for shuffling algorithm
    output logic [7:0] data,  // Data to be written to memory
    output logic [7:0] address, // Address for accessing memory
    output logic finish,      // Signal indicating the shuffling process is finished
    output logic wren         // Write enable signal for memory
);

    // Internal state register
    logic [4:0] state /*synthesis keep*/;
    logic [7:0] temp_val_i, temp_addr_i, temp_val_j, temp_addr_j;

    // State encoding
    // `state` is a 5-bit signal where:
    // - bit 1 represents the `wren` signal
    // - bit 0 represents the `finish` signal
    parameter idle = 5'b00000;       // Idle state
    parameter wait_s_i = 5'b00100;   // Wait state for reading `s_i`
    parameter read_s_i = 5'b01000;   // Read state for `s_i`
    parameter wait_s_j = 5'b01100;   // Wait state for reading `s_j`
    parameter read_s_j = 5'b10000;   // Read state for `s_j`
    parameter write_s_ij = 5'b00010; // Write state for `s_i` and `s_j`
    parameter counting = 5'b01010;   // Counting state
    parameter done = 5'b00001;       // Done state

    // Assign the `finish` and `wren` signals based on the state
    assign finish = state[0];
    assign wren = state[1];

    // Sequential logic for state transitions and output assignments
    always_ff @(posedge clk or negedge reset_n)
        if (!reset_n) 
            // Reset state: go to idle state and clear data and address
            state <= idle;
        else 
            case (state)
                idle: 
                    if (start) begin
                        // If start signal is active, transition to read_s_i state
                        state <= read_s_i;
                        data <= 0;
                        address <= 0;
                    end else begin    
                        // Remain in idle state if start signal is not active
                        state <= idle;
                        data <= 0;
                        address <= 0;
                        temp_val_i <= 0;
                        temp_addr_i <= 0;
                        temp_val_j <= 0;
                        temp_addr_j <= 0;
                    end

                wait_s_i: 
                    // Transition to read_s_i state
                    state <= read_s_i;

                read_s_i: 
                    begin
                        // Transition to wait_s_j state and store the current data and address
                        state <= wait_s_j;
                        temp_val_i <= q;
                        temp_addr_i <= address;

                        // Determine the new address based on the current address and secret key
                        case (address % 3)
                            8'd0: 
                                begin
                                    temp_addr_j <= temp_addr_j + q + secret_key[23:16];
                                    address <= temp_addr_j + q + secret_key[23:16];
                                end
                            8'd1: 
                                begin
                                    temp_addr_j <= temp_addr_j + q + secret_key[15:8];
                                    address <= temp_addr_j + q + secret_key[15:8];
                                end
                            8'd2: 
                                begin    
                                    temp_addr_j <= temp_addr_j + q + secret_key[7:0];
                                    address <= temp_addr_j + q + secret_key[7:0];
                                end
                            default: 
                                begin
                                    temp_addr_j <= temp_addr_j + q + 0;
                                    address <= temp_addr_j + q + 0;
                                end
                        endcase
                    end

                wait_s_j: 
                    // Transition to read_s_j state
                    state <= read_s_j;

                read_s_j: 
                    begin
                        // Transition to write_s_ij state and store the current data
                        state <= write_s_ij; 
                        data <= temp_val_i;
                        temp_val_j <= q;
                    end

                write_s_ij: 
                    begin
                        // Transition to counting state and update the data and address
                        state <= counting; 
                        data <= temp_val_j;
                        address <= temp_addr_i;
                    end    

                counting: 
                    if (address >= 8'd255) begin    
                        // If address reaches 255, transition to done state
                        state <= done;
                        data <= 0;
                        address <= 0;
                    end else begin
                        // Continue counting and transition to wait_s_i state
                        state <= wait_s_i;
                        address <= address + 1'b1;
                    end

                done: 
                    begin
                        // Once done, transition back to idle state and clear data and address
                        state <= idle;
                        data <= 0;
                        address <= 0;
                        temp_val_i <= 0;
                        temp_addr_i <= 0;
                        temp_val_j <= 0;
                        temp_addr_j <= 0;
                    end

                default: 
                    begin 
                        // Default case to handle unexpected states
                        state <= idle;
                        data <= 0;
                        address <= 0;
                        temp_val_i <= 0;
                        temp_addr_i <= 0;
                        temp_val_j <= 0;
                        temp_addr_j <= 0;
                    end
            endcase
    
endmodule
