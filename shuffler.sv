module shuffler (
    input  logic         clk,
    input  logic         start,
    input  logic         reset_n,
    input  logic [7:0]   s_q,          // s_data read from memory
    input  logic [23:0]  secret_key,   // Secret key for shuffling
    output logic         s_wren, finish ,      // Write enable for memory
    output logic [7:0]   s_address,    // s_address for memory
    output logic [7:0]   s_data      // s_data to be written to memory

);
     logic [7:0]   val_i;
     logic [7:0]   val_j;
     logic [7:0]   addr_i;
     logic [7:0]   addr_j;

    logic [4:0]   state;

    assign fin = state[0];
    assign s_wren = state[1];

    // State encoding
    parameter IDLE              = 5'b000_00;
    parameter WAIT_IS           = 5'b001_00;
    parameter READ_IS           = 5'b010_00;
    parameter WAIT_JS           = 5'b011_00;
    parameter READ_JS           = 5'b100_00;
    parameter WRITE_IJS         = 5'b101_10;
    parameter COUNT             = 5'b110_10;
    parameter DONE              = 5'b111_01;

    always_ff @(posedge clk, negedge reset_n)
		if(!reset_n) state <= IDLE;
		else 
		case(state)
			IDLE: 		if (start) begin
								state <= READ_IS;
								s_data <= 0;
								s_address <= 0;
							end
							else begin	
								state <= IDLE;
								s_data <= 0;
								s_address <= 0;
								val_i <= 0;
								addr_i <= 0;
								val_j <= 0;
								addr_j <= 0;
							end
			WAIT_IS:	state <= READ_IS;
			READ_IS: 	begin
								state <= WAIT_JS;
								val_i <= s_q;
								addr_i <= s_address;
								case(s_address%3)
									8'd0:		begin
													addr_j <= addr_j + s_q + secret_key[23:16]; //change based on secret key
													s_address <= addr_j + s_q + secret_key[23:16];
												end
									8'd1: 	begin
													addr_j <= addr_j + s_q + secret_key[15:8];
													s_address <= addr_j + s_q + secret_key[15:8];
												end
									8'd2: 	begin	
													addr_j <= addr_j + s_q + secret_key[7:0];
													s_address <= addr_j + s_q + secret_key[7:0];
												end
									default:	begin
													addr_j <= addr_j + s_q + 0; //change based on secret key
													s_address <= addr_j + s_q + 0;
												end
								endcase
							end
			WAIT_JS:	state <= READ_JS;
			READ_JS:	begin
								state <= WRITE_IJS; 
								s_data <= val_i;
								val_j <= s_q;
							end
			WRITE_IJS:	begin
								state <= COUNT; 
								s_data <= val_j;
								s_address <= addr_i;
							end	
			COUNT: 	if (s_address >= 8'd255) begin	
								state <= DONE;
								s_data <= 0;
								s_address <= 0;
							end
							else begin
								state <= WAIT_IS;
								s_address <= s_address + 1'b1;
							end
			DONE: 		begin
								state <= IDLE;
								s_data <= 0;
								s_address <= 0;
								val_i <= 0;
								addr_i <= 0;
								val_j <= 0;
								addr_j <= 0;
							end
			default: 	begin 
								state <= IDLE;
								s_data <= 0;
								s_address <= 0;
								val_i <= 0;
								addr_i <= 0;
								val_j <= 0;
								addr_j <= 0;
							end
		endcase
	
endmodule