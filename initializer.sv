module initializer (
    input  logic        clk,
    input logic         start,
    input  logic        reset_n,
    input logic  [7:0]  s_q,  
    output logic        s_wren, finish,
    output logic [7:0]  s_address,
    output logic [7:0]  s_data
    
);


    parameter IDLE  = 2'b00;
    parameter WRITE = 2'b01;
    parameter DONE = 2'b10; 

    logic [1:0] state;

    assign finish = state[0];
	assign s_wren = state[1];

    always_ff @(posedge clk, negedge reset_n)
		if(!reset_n) state <= IDLE;
		else
			case(state)
				IDLE: 	if (start) begin
								state <= WRITE;
								s_data <= 0;
								s_address <= 0;
							end
							else begin	
									state <= IDLE;
									s_data <= 0;
									s_address <= 0;
							end
				WRITE: if (s_address >= 8'd255) begin	
								state <= DONE;
								s_data <= 0;
								s_address <= 0;
							end
							else begin
								state <= WRITE;
								s_data <= s_address + 1'b1;
								s_address <= s_address + 1'b1;
							end
				DONE: 	begin
								state <= IDLE;
								s_data <= 0;
								s_address <= 0;
							end
				default: begin 
								state <= IDLE;
								s_data <= 0;
								s_address <= 0;
							end
			endcase
endmodule
