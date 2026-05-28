module SmartTrafficLightController #(
        localparam CLK_FREQ = 1 // Hz
) (
        input logic clk,
        input logic reset,
        input logic side_sensor,
        input logic ped_button,
        input logic emergency_main,
        input logic emergency_side
);
	// Define custom type "State"
	typedef enum logic [2:0] {
		S0, S1, S2, S3, S4, S5, S6, S7
	} State;
	State cur_state, next_state;
	
	// Base FSM logic
	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			cur_state <= S0;
		end else begin
			cur_state <= next_state;
		end
	end

	// Counter logic
	always_ff @(posedge clk or posedge reset) begin

	end

	// Next-state logic
	always_comb begin
        	case (cur_state)
        
        		endcase
        	end
	
	// Output encoding logic
	always_comb begin		
		case (cur_state)

		endcase
	end
endmodule     
