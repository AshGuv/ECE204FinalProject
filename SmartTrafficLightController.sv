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
	input logic clk, // 1Hz FPGA clock, active HIGH
	input logic reset, // Asynchronous, top button on FPGA, active LOW
	input logic side_sensor, // Switch on FPGA, active HIGH
	input logic ped_button, // Bottom button on FPGA, active LOW
	input logic emergency_main, // Asynchronous, switch on FPGA, active HIGH
	input logic emergency_side, // Asynchronous, switch on FPGA, active HIGH

	// Outputs (busses not specified yet, no FPGA imp.)
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
		// Main cycle
		S0, // m: green, s: red
		S1, // m: yellow, s: red
		S2, // m: red, s: red
		S3, // m: red, s: green
		S4, // m: red, s: yellow
		S5, // m: red, s: red
		// Ped signals
		S6, // m: red, s: red
		S7  // m: red, s: red
	} State;
	State cur_state, next_state;
	
	// FSM logic
	// Asynchronous resets/triggers: reset, emergency_main + side
	always_ff @(posedge clk or posedge reset or edge emergency_main or
		edge emergency_side
	) begin
		if (reset) begin
			cur_state <= S0;
		end else if (emergency_main) begin // Takes prio over e_side
			cur_state <= S0;
		end else if (emergency_side) begin
			cur_state <= S3;
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
