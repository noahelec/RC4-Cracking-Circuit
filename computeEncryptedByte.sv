module computeEncryptedByte(
    // Input signals
    input logic start,           // Signal to start the encryption process
    input logic clk,             // Clock signal
    input logic reset_n,         // Active-low reset signal

    // Output signals
    output logic [7:0] e_address = 8'b0, // Address for accessing encryption ROM
    input logic [7:0] e_q,       // Data read from encryption ROM
    output logic [7:0] s_data = 8'b0,    // Data to be written to S memory
    output logic [7:0] s_address = 8'b0, // Address for accessing S memory
    output logic s_wren,         // Write enable signal for S memory
    input logic [7:0] s_q,       // Data read from S memory
    output logic [7:0] d_data = 8'b0,    // Data to be written to D memory
    output logic [7:0] d_address = 8'b0, // Address for accessing D memory
    output logic d_wren,         // Write enable signal for D memory
    output logic invalid_ascii = 1'b0,   // Signal indicating invalid ASCII character
    output logic finish          // Signal indicating the encryption process is finished
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
    
    parameter message_length = 32; // Length of the message to be encrypted
    logic [7:0] k = 8'b0;
    
    // State-dependent output signals
    assign finish = state[0];
    assign s_wren = state[1];
    assign d_wren = state[2];
    
    // State machine
    always_ff @(posedge clk, negedge reset_n) begin
        if (!reset_n) state <= idle; // Reset to idle state
        else 
            case (state)
                idle: if (start) begin
                        state <= increment_i;
                        i <= 8'b0;
                        j <= 8'b0;
                        k <= 8'b0;
                        invalid_ascii <= 1'b0;
                      end else begin	
                        state <= idle;
                      end

                increment_i: begin
                        state <= read_s_i;
                        i <= i + 1;
                    end

                read_s_i: begin
                        state <= wait_s_i;
                        s_address <= i;
                    end

                wait_s_i: begin
                        state <= update_j;
                    end

                update_j: begin
                        state <= read_s_j;
                        data_at_i <= s_q;
                        j <= j + s_q;
                    end

                read_s_j: begin
                        state <= wait_s_j;
                        s_address <= j;
                    end

                wait_s_j: begin
                        state <= swap1;
                    end

                swap1: begin
                        state <= swap2;
                        data_at_j <= s_q;
                        s_address <= i;
                        s_data <= s_q;
                        temp <= data_at_i;
                    end

                swap2: begin
                        state <= read_for_f;
                        data_at_i <= s_q;
                        s_address <= j;
                        s_data <= temp;
                    end

                read_for_f: begin
                        state <= wait_for_f;
                        data_at_j <= s_q;
                        s_address <= temp + data_at_i;
                    end

                wait_for_f: begin
                        state <= read_from_rom;
                    end

                read_from_rom: begin
                        state <= wait_for_rom;
                        f <= s_q;
                        e_address <= k;
                    end

                wait_for_rom: begin
                        state <= compute_and_output;
                    end

                compute_and_output: begin   
                    state <= check_if_valid;
                    d_address <= k;
                    d_data <= f ^ e_q; // XOR operation for encryption
                end
                
                check_if_valid: begin
                        if ((d_data < 8'd97 || d_data > 8'd122) && (d_data != 8'd32)) begin
                            invalid_ascii <= 1'b1;
                            state <= done;
                        end else begin
                            invalid_ascii <= 1'b0;
                            if (k == message_length - 1) state <= done;
                            else begin
                                k <= k + 1;   
                                state <= increment_i;
                            end
                        end     
                    end 

                done: begin
                        state <= idle;
                        s_address <= 8'b0;
                        s_data <= 8'b0;
                        d_address <= 8'b0;
                        d_data <= 8'b0;
                    end

                default: state <= idle; // Default case to handle unexpected states
            endcase
    end
endmodule
