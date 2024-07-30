module computeEncryptedByte( // Task 2b
    // Input signals
    input logic start,       // Signal to start the encryption process
    input logic clk,         // Clock signal
    input logic reset_n,     // Active-low reset signal

    // Output signals
    output logic [7:0] e_address = 8'b0, // Address for accessing encryption ROM
    input logic [7:0] e_q,                // Data read from encryption ROM
    output logic [7:0] s_data = 8'b0,     // Data to be written to S memory
    output logic [7:0] s_address = 8'b0,  // Address for accessing S memory
    output logic s_wren,                  // Write enable signal for S memory
    input logic [7:0] s_q,                // Data read from S memory
    output logic [7:0] d_data = 8'b0,     // Data to be written to D memory
    output logic [7:0] d_address = 8'b0,  // Address for accessing D memory
    output logic d_wren,                  // Write enable signal for D memory
    output logic invalid_ascii = 1'b0,    // Signal indicating invalid ASCII character
    output logic finish                   // Signal indicating the encryption process is finished
);

    // State encoding
    localparam idle = 7'b0000_000;
    localparam increment_i = 7'b0001_000;
    localparam read_s_i = 7'b0010_000;
    localparam wait_s_i = 7'b0011_000;
    localparam update_j = 7'b0100_000;
    localparam read_s_j = 7'b0101_000;
    localparam wait_s_j = 7'b0110_000;
    localparam swap1 = 7'b0111_000;
    localparam swap2 = 7'b1000_010;
    localparam read_for_f = 7'b1001_010;
    localparam wait_for_f = 7'b1010_000;
    localparam read_from_rom = 7'b1011_000;
    localparam wait_for_rom = 7'b1100_000;
    localparam compute_and_output = 7'b1101_000;
    localparam check_if_valid = 7'b1110_100;
    localparam done = 7'b1111_001;

    // State and data registers
    logic [6:0] state = idle;
    logic [7:0] i, data_at_i, j, data_at_j, f;
    logic [7:0] temp = 8'b0;

    // Parameter for message length
    parameter message_length = 32;
    logic [7:0] k = 8'b0;

    // Assignments for output signals based on state
    assign finish = state[0];
    assign s_wren = state[1];
    assign d_wren = state[2];

    // Sequential logic for state transitions and output assignments
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) 
            state <= idle; // Reset state to idle
        else 
            case (state)
                idle: 
                    if (start) begin
                        // Initialize variables and transition to increment_i state
                        state <= increment_i;
                        i <= 8'b0;
                        j <= 8'b0;
                        k <= 8'b0;
                        invalid_ascii <= 1'b0;
                    end else begin    
                        // Remain in idle state
                        state <= idle;
                    end

                increment_i: 
                    begin
                        // Increment index i and transition to read_s_i state
                        state <= read_s_i;
                        i <= i + 1;
                    end

                read_s_i: 
                    begin
                        // Set s_address to i and transition to wait_s_i state
                        state <= wait_s_i;
                        s_address <= i;
                    end

                wait_s_i: 
                    // Wait for read operation and transition to update_j state
                    state <= update_j;

                update_j: 
                    begin
                        // Update j and data_at_i, then transition to read_s_j state
                        state <= read_s_j;
                        data_at_i <= s_q;
                        j <= j + s_q;
                    end

                read_s_j: 
                    begin
                        // Set s_address to j and transition to wait_s_j state
                        state <= wait_s_j;
                        s_address <= j;
                    end

                wait_s_j: 
                    // Wait for read operation and transition to swap1 state
                    state <= swap1;

                swap1: 
                    begin
                        // Swap data and transition to swap2 state
                        state <= swap2;
                        data_at_j <= s_q;
                        s_address <= i;
                        s_data <= s_q;
                        temp <= data_at_i;
                    end

                swap2: 
                    begin
                        // Complete swapping and transition to read_for_f state
                        state <= read_for_f;
                        data_at_i <= s_q;
                        s_address <= j;
                        s_data <= temp;
                    end

                read_for_f: 
                    begin
                        // Prepare for read and transition to wait_for_f state
                        state <= wait_for_f;
                        data_at_j <= s_q;
                        s_address <= temp + data_at_i;
                    end

                wait_for_f: 
                    // Wait for read operation and transition to read_from_rom state
                    state <= read_from_rom;

                read_from_rom: 
                    begin
                        // Read from ROM and transition to wait_for_rom state
                        state <= wait_for_rom;
                        f <= s_q;
                        e_address <= k;
                    end

                wait_for_rom: 
                    // Wait for ROM read and transition to compute_and_output state
                    state <= compute_and_output;

                compute_and_output: 
                    begin   
                        // Compute the encrypted byte and transition to check_if_valid state
                        state <= check_if_valid;
                        d_address <= k;
                        d_data <= f ^ e_q; // XOR operation for encryption
                    end
                
                check_if_valid: 
                    begin
                        // Check if the encrypted byte is a valid ASCII character
                        if ((d_data < 8'd97 || d_data > 8'd122) && (d_data != 8'd32)) begin
                            invalid_ascii <= 1'b1; // Set invalid_ascii if character is invalid
                            state <= done;
                        end else begin
                            invalid_ascii <= 1'b0;
                            if (k == message_length - 1) 
                                state <= done;
                            else begin
                                k <= k + 1;
                                state <= increment_i;
                            end
                        end     
                    end 

                done: 
                    begin
                        // Transition to idle state and clear variables
                        state <= idle;
                        s_address <= 8'b0;
                        s_data <= 8'b0;
                        d_address <= 8'b0;
                        d_data <= 8'b0;
                    end

                default: 
                    // Default case to handle unexpected states
                    state <= idle;
            endcase
    end
endmodule
