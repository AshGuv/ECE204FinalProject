/*  PROJECT NAME: Smart Traffic Light Controller
 	AUTHORS: Leslie Koopmann, Travis Koyama, Ashton Guvenir
 	DESCRIPTION: A smart traffic light controller system for a two-road 
		intersection (main + side road). Features include main road 
		prioritization, pedestrian crossing, and emergency vehicle response.
	SOURCES: Project description off of Canvas
*/

module SmartTrafficLightController #(
	localparam CLK_FREQ = 1, // Hz
	localparam MAIN_GREEN_TIME = 10, // s
	localparam YELLOW_TIME = 3, // s
	localparam SIDE_GREEN_TIME = 7, // s
	localparam ALL_RED_TIME = 2, // s
	localparam PED_TIME = 6 // s
) (
	// Inputs
	input logic clk,
	input logic reset,
	input logic side_sensor,
	input logic ped_button,
	input logic emergency_main,
	input logic emergency_side,

	// Outputs (busses not specified yet)
	output logic main_red,
	output logic main_yellow,
	output logic main_green,
	output logic side_red,
	output logic side_yellow,
	output logic side_green,
	output logic ped_walk,
	output logic ped_wait,
	output logic countdown,
	output logic seg7
);
	// Define custom type "State"
	typedef enum logic [2:0] {
		S0, S1, S2, S3, S4, S5, S6, S7
	} State;
	State cur_state, next_state;
	
	// Base FSM logic
	// Asynchronous resets/triggers: reset, emergency_main + side
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
