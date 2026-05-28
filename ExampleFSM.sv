module TrafficController (
	input logic clk,
	input logic reset,
	input logic Ta, // If traffic @ light(s) A
	input logic Tb, // If traffic @ light(s) B
	output logic [3:0] lights /* 3:2 = {La1, La0}
				     1:0 = {Lb1, Lb0} 
				     For each light:
				     00 = green
				     01 = yellow
				     10 = red */		     
);
	// Define custom type "State"
	typedef enum logic [2:0] {
		S0, S1, S2, S3, S4, S5
	} State;
	State cur_state, next_state;
	logic [2:0] delay;
	
	// Base FSM logic
	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			cur_state <= S0;
		end else begin
			cur_state <= next_state;
		end
	end

	// 5 cycle delay when both lights are red (S2, S5) logic
	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			delay <= 0;
		end else if ((cur_state == S2 || cur_state == S5) && delay < 4) begin
			delay <= delay + 1;
		end else begin
			delay <= 0;
		end
	end

	// Next-state logic
	always_comb begin
	case (cur_state)
		S0: begin
			if (Ta == 0) begin
				next_state = S1;
			end else begin
				next_state = S0;
			end
		end
		S1: next_state = S2;
		S2: begin
			if (delay == 4) begin
				next_state = S3;
			end else begin
				next_state = S2;
			end
		end
		S3: begin
			if (Tb == 0) begin
				next_state = S4;
			end else begin
				next_state = S3;
			end
		end
		S4: next_state = S5;
		S5: begin
			if (delay == 4) begin
				next_state = S0;
			end else begin
				next_state = S5;
			end
		end
		default: next_state = S0; // effective reset
		endcase
	end
	
	// Output encoding logic
	always_comb begin
		lights = '0; 		
		case (cur_state)
			S0: lights = 4'b0010;
			S1: lights = 4'b0110;
			S2: lights = 4'b1010;
			S3: lights = 4'b1000;
			S4: lights = 4'b1001;
			S5: lights = 4'b1010;
			default: lights = 4'b1010; // default to all red for safety
		endcase
	end
endmodule
