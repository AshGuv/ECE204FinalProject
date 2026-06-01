/*
    PROJECT NAME:
        Smart Traffic Light Controller

    AUTHORS:
        Leslie Koopmann, Travis Koyama, Ashton Guvenir

    DESCRIPTION:
        This project implements a smart traffic light controller for a
        two-road intersection with a main road and a side road.

        The main road has priority, so it stays green when there are no
        requests. When a request is detected, the controller starts a
        10-second main green timer before safely switching states.

        The side road only gets a green light when side_sensor is active.
        Side-road requests are stored so a short sensor signal is not missed.
        Pedestrian requests are stored so a button press is not missed.
        Emergency vehicle inputs override the normal sequence.

    ASSUMPTIONS:
        - reset is active HIGH.
        - side_sensor is active HIGH.
        - ped_button is active HIGH.
        - emergency_main is active HIGH.
        - emergency_side is active HIGH.
        - 1 clock cycle = 1 second.
*/

module SmartTrafficLightController (
    input logic clk,
    input logic reset,

    input logic side_sensor,
    input logic ped_button,
    input logic emergency_main,
    input logic emergency_side,

    output logic main_red,
    output logic main_yellow,
    output logic main_green,

    output logic side_red,
    output logic side_yellow,
    output logic side_green,

    output logic ped_walk,
    output logic ped_wait,

    output logic [3:0] countdown,
    output logic [6:0] seg7_tens,
    output logic [6:0] seg7_ones
);

    // ========================================================
    // Timing values
    // ========================================================

    localparam logic [3:0] MAIN_GREEN_TIME = 4'd10;
    localparam logic [3:0] YELLOW_TIME     = 4'd3;
    localparam logic [3:0] SIDE_GREEN_TIME = 4'd7;
    localparam logic [3:0] ALL_RED_TIME    = 4'd2;
    localparam logic [3:0] PED_TIME        = 4'd6;

    // ========================================================
    // State definitions
    // ========================================================

    typedef enum logic [3:0] {
        S0_MAIN_GREEN_IDLE,
        S1_MAIN_GREEN_TIMED,

        S2_MAIN_YELLOW,
        S3_ALL_RED_AFTER_MAIN,

        S4_SIDE_GREEN,
        S5_SIDE_YELLOW,
        S6_ALL_RED_AFTER_SIDE,

        S7_PED_THEN_SIDE,
        S8_PED_THEN_MAIN,

        S9_EMERGENCY_MAIN,
        S10_EMERGENCY_SIDE
    } State;

    State cur_state, next_state;

    // ========================================================
    // Internal signals
    // ========================================================

    // Stores a pedestrian request so a short button press is not missed.
    logic ped_pending;

    // Stores a side-road vehicle request so a short side_sensor pulse
    // is not missed before the FSM reaches the all-red decision state.
    logic side_pending;

    // Stores the countdown value that should be loaded when entering a new state.
    logic [3:0] next_countdown;

    // Digits for the 7-segment displays.
    logic [3:0] tens_digit;
    logic [3:0] ones_digit;

    // ========================================================
    // Base FSM state register
    // ========================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cur_state <= S0_MAIN_GREEN_IDLE;
        end else begin
            cur_state <= next_state;
        end
    end

    // ========================================================
    // Countdown timer logic
    // ========================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            countdown <= MAIN_GREEN_TIME;
        end else if (next_state != cur_state) begin
            countdown <= next_countdown;
        end else if (cur_state == S0_MAIN_GREEN_IDLE) begin
            countdown <= MAIN_GREEN_TIME;
        end else if (countdown > 4'd0) begin
            countdown <= countdown - 4'd1;
        end
    end

    // ========================================================
    // Pedestrian pending logic
    // ========================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            ped_pending <= 1'b0;
        end else begin

            // Store the pedestrian request whenever the button is pressed.
            if (ped_button) begin
                ped_pending <= 1'b1;
            end

            // Clear the pedestrian request after either pedestrian state finishes.
            if ((cur_state == S7_PED_THEN_SIDE || cur_state == S8_PED_THEN_MAIN)
                && countdown == 4'd0) begin
                ped_pending <= 1'b0;
            end
        end
    end

    // ========================================================
    // Side-road pending logic
    // ========================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            side_pending <= 1'b0;
        end else begin

            // Store the side-road request whenever side_sensor is active.
            if (side_sensor) begin
                side_pending <= 1'b1;
            end

            // Clear the side-road request once the side road actually gets green.
            if (cur_state == S4_SIDE_GREEN) begin
                side_pending <= 1'b0;
            end
        end
    end

    // ========================================================
    // Next countdown value logic
    // ========================================================

    always_comb begin
        case (next_state)
            S0_MAIN_GREEN_IDLE:    next_countdown = MAIN_GREEN_TIME;
            S1_MAIN_GREEN_TIMED:   next_countdown = MAIN_GREEN_TIME;

            S2_MAIN_YELLOW:        next_countdown = YELLOW_TIME;
            S3_ALL_RED_AFTER_MAIN: next_countdown = ALL_RED_TIME;

            S4_SIDE_GREEN:         next_countdown = SIDE_GREEN_TIME;
            S5_SIDE_YELLOW:        next_countdown = YELLOW_TIME;
            S6_ALL_RED_AFTER_SIDE: next_countdown = ALL_RED_TIME;

            S7_PED_THEN_SIDE:      next_countdown = PED_TIME;
            S8_PED_THEN_MAIN:      next_countdown = PED_TIME;

            S9_EMERGENCY_MAIN:     next_countdown = 4'd0;
            S10_EMERGENCY_SIDE:    next_countdown = 4'd0;

            default:               next_countdown = MAIN_GREEN_TIME;
        endcase
    end

    // ========================================================
    // Next-state logic
    // ========================================================
    // Priority order:
    //      1. emergency_main
    //      2. emergency_side
    //      3. pedestrian request
    //      4. side road sensor
    //      5. normal main road priority

    always_comb begin
        next_state = cur_state;

        case (cur_state)

            // Main road stays green forever when there are no requests.
            // When a request is detected, start the timed main green state.
            S0_MAIN_GREEN_IDLE: begin
                if (emergency_main)
                    next_state = S9_EMERGENCY_MAIN;
                else if (emergency_side)
                    next_state = S10_EMERGENCY_SIDE;
                else if (side_sensor || side_pending || ped_pending || ped_button)
                    next_state = S1_MAIN_GREEN_TIMED;
                else
                    next_state = S0_MAIN_GREEN_IDLE;
            end

            // Main road stays green for the full 10 seconds after a request.
            S1_MAIN_GREEN_TIMED: begin
                if (emergency_main)
                    next_state = S9_EMERGENCY_MAIN;
                else if (emergency_side)
                    next_state = S10_EMERGENCY_SIDE;
                else if (countdown == 4'd0)
                    next_state = S2_MAIN_YELLOW;
                else
                    next_state = S1_MAIN_GREEN_TIMED;
            end

            // Main road yellow before stopping.
            S2_MAIN_YELLOW: begin
                if (emergency_main)
                    next_state = S9_EMERGENCY_MAIN;
                else if (emergency_side)
                    next_state = S10_EMERGENCY_SIDE;
                else if (countdown == 4'd0)
                    next_state = S3_ALL_RED_AFTER_MAIN;
                else
                    next_state = S2_MAIN_YELLOW;
            end

            // Both roads red after main road yellow.
            S3_ALL_RED_AFTER_MAIN: begin
                if (emergency_main)
                    next_state = S9_EMERGENCY_MAIN;
                else if (emergency_side)
                    next_state = S10_EMERGENCY_SIDE;

                // If pedestrian AND side-road request are both waiting:
                // pedestrian walks first, then side road gets green.
                else if (countdown == 4'd0 &&
                         (ped_pending || ped_button) &&
                         (side_pending || side_sensor))
                    next_state = S7_PED_THEN_SIDE;

                // If pedestrian request is waiting but no side car is waiting:
                // pedestrian walks, then return to main green.
                else if (countdown == 4'd0 &&
                         (ped_pending || ped_button))
                    next_state = S8_PED_THEN_MAIN;

                // If only the side road is waiting:
                // give side road green.
                else if (countdown == 4'd0 &&
                         (side_sensor || side_pending))
                    next_state = S4_SIDE_GREEN;

                // If nothing is waiting, return to main green.
                else if (countdown == 4'd0)
                    next_state = S0_MAIN_GREEN_IDLE;
                else
                    next_state = S3_ALL_RED_AFTER_MAIN;
            end

            // Side road green.
            S4_SIDE_GREEN: begin
                if (emergency_main)
                    next_state = S9_EMERGENCY_MAIN;
                else if (emergency_side)
                    next_state = S10_EMERGENCY_SIDE;
                else if (countdown == 4'd0)
                    next_state = S5_SIDE_YELLOW;
                else
                    next_state = S4_SIDE_GREEN;
            end

            // Side road yellow before stopping.
            S5_SIDE_YELLOW: begin
                if (emergency_main)
                    next_state = S9_EMERGENCY_MAIN;
                else if (emergency_side)
                    next_state = S10_EMERGENCY_SIDE;
                else if (countdown == 4'd0)
                    next_state = S6_ALL_RED_AFTER_SIDE;
                else
                    next_state = S5_SIDE_YELLOW;
            end

            // Both roads red after side road yellow.
            S6_ALL_RED_AFTER_SIDE: begin
                if (emergency_main)
                    next_state = S9_EMERGENCY_MAIN;
                else if (emergency_side)
                    next_state = S10_EMERGENCY_SIDE;
                else if (countdown == 4'd0 && (ped_pending || ped_button))
                    next_state = S8_PED_THEN_MAIN;
                else if (countdown == 4'd0)
                    next_state = S0_MAIN_GREEN_IDLE;
                else
                    next_state = S6_ALL_RED_AFTER_SIDE;
            end

            // Pedestrian walk, then side road green.
            S7_PED_THEN_SIDE: begin
                if (emergency_main)
                    next_state = S9_EMERGENCY_MAIN;
                else if (emergency_side)
                    next_state = S10_EMERGENCY_SIDE;
                else if (countdown == 4'd0)
                    next_state = S4_SIDE_GREEN;
                else
                    next_state = S7_PED_THEN_SIDE;
            end

            // Pedestrian walk, then main road green.
            S8_PED_THEN_MAIN: begin
                if (emergency_main)
                    next_state = S9_EMERGENCY_MAIN;
                else if (emergency_side)
                    next_state = S10_EMERGENCY_SIDE;
                else if (countdown == 4'd0)
                    next_state = S0_MAIN_GREEN_IDLE;
                else
                    next_state = S8_PED_THEN_MAIN;
            end

            // Emergency main.
            S9_EMERGENCY_MAIN: begin
                if (emergency_main)
                    next_state = S9_EMERGENCY_MAIN;
                else if (emergency_side)
                    next_state = S10_EMERGENCY_SIDE;
                else
                    next_state = S0_MAIN_GREEN_IDLE;
            end

            // Emergency side.
            S10_EMERGENCY_SIDE: begin
                if (emergency_main)
                    next_state = S9_EMERGENCY_MAIN;
                else if (emergency_side)
                    next_state = S10_EMERGENCY_SIDE;
                else
                    next_state = S0_MAIN_GREEN_IDLE;
            end

            default: begin
                next_state = S0_MAIN_GREEN_IDLE;
            end

        endcase
    end

    // ========================================================
    // Output encoding logic
    // ========================================================
    // Emergency outputs are checked first so they override the
    // normal state outputs immediately.
    //
    // This prevents a case where emergency_side turns on while the
    // current FSM state is still main green for one clock cycle.

    always_comb begin
        // Safe default values.
        main_red    = 1'b1;
        main_yellow = 1'b0;
        main_green  = 1'b0;

        side_red    = 1'b1;
        side_yellow = 1'b0;
        side_green  = 1'b0;

        ped_walk = 1'b0;
        ped_wait = 1'b1;

        // Emergency main has highest priority.
        if (emergency_main) begin
            main_red    = 1'b0;
            main_yellow = 1'b0;
            main_green  = 1'b1;

            side_red    = 1'b1;
            side_yellow = 1'b0;
            side_green  = 1'b0;

            ped_walk = 1'b0;
            ped_wait = 1'b1;
        end

        // Emergency side has second priority.
        // This explicitly forces main green OFF and side green ON.
        else if (emergency_side) begin
            main_red    = 1'b1;
            main_yellow = 1'b0;
            main_green  = 1'b0;

            side_red    = 1'b0;
            side_yellow = 1'b0;
            side_green  = 1'b1;

            ped_walk = 1'b0;
            ped_wait = 1'b1;
        end

        // Normal state output logic.
        else begin
            case (cur_state)

                S0_MAIN_GREEN_IDLE,
                S1_MAIN_GREEN_TIMED: begin
                    main_red   = 1'b0;
                    main_green = 1'b1;
                    side_red   = 1'b1;
                end

                S2_MAIN_YELLOW: begin
                    main_red    = 1'b0;
                    main_yellow = 1'b1;
                    side_red    = 1'b1;
                end

                S3_ALL_RED_AFTER_MAIN: begin
                    main_red = 1'b1;
                    side_red = 1'b1;
                end

                S4_SIDE_GREEN: begin
                    main_red   = 1'b1;
                    side_red   = 1'b0;
                    side_green = 1'b1;
                end

                S5_SIDE_YELLOW: begin
                    main_red    = 1'b1;
                    side_red    = 1'b0;
                    side_yellow = 1'b1;
                end

                S6_ALL_RED_AFTER_SIDE: begin
                    main_red = 1'b1;
                    side_red = 1'b1;
                end

                S7_PED_THEN_SIDE: begin
                    main_red = 1'b1;
                    side_red = 1'b1;
                    ped_walk = 1'b1;
                    ped_wait = 1'b0;
                end

                S8_PED_THEN_MAIN: begin
                    main_red = 1'b1;
                    side_red = 1'b1;
                    ped_walk = 1'b1;
                    ped_wait = 1'b0;
                end

                S9_EMERGENCY_MAIN: begin
                    main_red   = 1'b0;
                    main_green = 1'b1;
                    side_red   = 1'b1;
                end

                S10_EMERGENCY_SIDE: begin
                    main_red   = 1'b1;
                    side_red   = 1'b0;
                    side_green = 1'b1;
                end

                default: begin
                    main_red = 1'b1;
                    side_red = 1'b1;
                end

            endcase
        end
    end

    // ========================================================
    // 7-segment display logic
    // ========================================================

    assign tens_digit = countdown / 4'd10;
    assign ones_digit = countdown % 4'd10;

    SevenSegmentDecoder tens_display (
        .digit(tens_digit),
        .segments(seg7_tens)
    );

    SevenSegmentDecoder ones_display (
        .digit(ones_digit),
        .segments(seg7_ones)
    );

endmodule


// ============================================================
// Seven-segment decoder
// ============================================================

module SevenSegmentDecoder (
    input logic [3:0] digit,
    output logic [6:0] segments
);

    always_comb begin
        case (digit)
            4'd0: segments = 7'b1000000;
            4'd1: segments = 7'b1111001;
            4'd2: segments = 7'b0100100;
            4'd3: segments = 7'b0110000;
            4'd4: segments = 7'b0011001;
            4'd5: segments = 7'b0010010;
            4'd6: segments = 7'b0000010;
            4'd7: segments = 7'b1111000;
            4'd8: segments = 7'b0000000;
            4'd9: segments = 7'b0010000;
            default: segments = 7'b1111111;
        endcase
    end

endmodule
