module initializer(
    input logic start,    // Signal to start the initialization process
    input logic clk,      // Clock signal
    input logic reset_n,  // Active-low reset signal
    input logic [7:0] q,  // Data input (not used in this module)
    output logic [7:0] data,    // Data to be written to memory
    output logic [7:0] address, // Address for accessing memory
    output logic finish,  // Signal indicating the initialization process is finished
    output logic wren     // Write enable signal for memory
);

    // State encoding
    // `state` is a 2-bit signal where:
    // - bit 1 (MSB) represents the `wren` signal
    // - bit 0 (LSB) represents the `finish` signal
    parameter idle = 2'b00;     // Idle state
    parameter writing = 2'b10;  // Writing state (wren is active)
    parameter done = 2'b01;     // Done state (finish is active)

    logic [1:0] state /*synthesis keep*/; // State register

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
                        // If start signal is active, transition to writing state
                        state <= writing;
                        data <= 0;       // Initialize data to 0
                        address <= 0;    // Initialize address to 0
                    end else begin    
                        // Remain in idle state if start signal is not active
                        state <= idle;
                        data <= 0;       // Clear data
                        address <= 0;    // Clear address
                    end

                writing: 
                    if (address >= 8'd255) begin    
                        // If address reaches 255, transition to done state
                        state <= done;
                        data <= 0;       // Clear data
                        address <= 0;    // Clear address
                    end else begin
                        // Continue writing: increment data and address
                        state <= writing;
                        data <= address + 1'b1;  // Set data to current address + 1
                        address <= address + 1'b1; // Increment address
                    end

                done: 
                    begin
                        // Once done, transition back to idle state
                        state <= idle;
                        data <= 0;       // Clear data
                        address <= 0;    // Clear address
                    end

                default: 
                    begin 
                        // Default case to handle unexpected states
                        state <= idle;
                        data <= 0;       // Clear data
                        address <= 0;    // Clear address
                    end
            endcase
endmodule
