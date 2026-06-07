/*
    TESTBENCH:
        SmartTrafficLightController_tb

    PURPOSE:
        Tests the SmartTrafficLightController.

    MAIN THINGS TESTED:
        1. Reset starts in Main Green Idle.
        2. No input keeps Main Green Idle.
        3. Side request eventually gives Side Green.
        4. Pedestrian-only request returns to Main Green.
        5. Pedestrian + side request goes to Side Green.
        6. Emergency main forces Main Green.
        7. Emergency side forces Side Green and Main Red.
        8. Both emergencies active gives priority to Main.
        9. Main Green and Side Green are never on at the same time.
*/

`timescale 1ns/1ps

module SmartTrafficLightController_tb;

    logic clk;
    logic reset_n;

    logic side_sensor;
    logic ped_button_n;
    logic emergency_main;
    logic emergency_side;

    logic main_red;
    logic main_yellow;
    logic main_green;

    logic side_red;
    logic side_yellow;
    logic side_green;

    logic ped_walk;
    logic ped_wait;

    logic [3:0] countdown;
    logic [6:0] seg7_tens;
    logic [6:0] seg7_ones;

    // ========================================================
    // Instantiate DUT
    // ========================================================

    SmartTrafficLightController dut (
        .clk(clk),
        .reset_n(reset_n),

        .side_sensor(side_sensor),
        .ped_button_n(ped_button_n),
        .emergency_main(emergency_main),
        .emergency_side(emergency_side),

        .main_red(main_red),
        .main_yellow(main_yellow),
        .main_green(main_green),

        .side_red(side_red),
        .side_yellow(side_yellow),
        .side_green(side_green),

        .ped_walk(ped_walk),
        .ped_wait(ped_wait),

        //.countdown(countdown),
        .seg7_tens(seg7_tens),
        .seg7_ones(seg7_ones)
    );

    // ========================================================
    // Clock generation
    // ========================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ========================================================
    // Safety check
    // ========================================================
    // This should never happen.

    always_ff @(posedge clk) begin
        if (main_green && side_green) begin
            $error("SAFETY ERROR: main_green and side_green are both ON.");
        end
    end

    // ========================================================
    // Helper tasks
    // ========================================================

    task wait_clock();
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task wait_cycles(input int num_cycles);
        int i;
        begin
            for (i = 0; i < num_cycles; i = i + 1) begin
                wait_clock();
            end
        end
    endtask

    task do_reset();
        begin
            reset_n = 1'b0;

            side_sensor = 1'b0;
            ped_button_n = 1'b1;
            emergency_main = 1'b0;
            emergency_side = 1'b0;

            wait_cycles(2);

            reset_n = 1'b1;
            wait_clock();
        end
    endtask

    task print_status(input string label);
        begin
            $display("%0t | %s | countdown=%0d | M: R=%0b Y=%0b G=%0b | S: R=%0b Y=%0b G=%0b | PED: walk=%0b wait=%0b",
                     $time, label, countdown,
                     main_red, main_yellow, main_green,
                     side_red, side_yellow, side_green,
                     ped_walk, ped_wait);
        end
    endtask

    task check_outputs(
        input string label,
        input logic exp_main_red,
        input logic exp_main_yellow,
        input logic exp_main_green,
        input logic exp_side_red,
        input logic exp_side_yellow,
        input logic exp_side_green,
        input logic exp_ped_walk,
        input logic exp_ped_wait
    );
        begin
            print_status(label);

            if (main_red    !== exp_main_red    ||
                main_yellow !== exp_main_yellow ||
                main_green  !== exp_main_green  ||
                side_red    !== exp_side_red    ||
                side_yellow !== exp_side_yellow ||
                side_green  !== exp_side_green  ||
                ped_walk    !== exp_ped_walk    ||
                ped_wait    !== exp_ped_wait) begin

                $error("FAILED: %s", label);

            end else begin
                $display("PASSED: %s", label);
            end
        end
    endtask

    // ========================================================
    // Main simulation
    // ========================================================

    initial begin

        reset_n = 1'b1;
        side_sensor = 1'b0;
        ped_button_n = 1'b1;
        emergency_main = 1'b0;
        emergency_side = 1'b0;

        // ----------------------------------------------------
        // TEST 1: Reset and idle
        // ----------------------------------------------------

        $display("\n========== TEST 1: RESET AND IDLE ==========");

        do_reset();

        check_outputs(
            "S0 Main Green Idle after reset",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        if (countdown !== 4'd10) begin
            $error("FAILED: Countdown should be 10 after reset.");
        end else begin
            $display("PASSED: Countdown is 10 after reset.");
        end

        wait_cycles(5);

        check_outputs(
            "S0 Main Green Idle with no inputs",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        if (countdown !== 4'd10) begin
            $error("FAILED: Countdown should stay 10 while idle.");
        end else begin
            $display("PASSED: Countdown stays 10 while idle.");
        end

        // ----------------------------------------------------
        // TEST 2: Side request only
        // ----------------------------------------------------

        $display("\n========== TEST 2: SIDE REQUEST ONLY ==========");

        side_sensor = 1'b1;
        wait_clock();
        side_sensor = 1'b0;

        check_outputs(
            "S1 Main Green Timed starts after side request",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        // 10 main green + 3 yellow + 2 all red + margin
        wait_cycles(18);

        check_outputs(
            "S4 Side Green after side request",
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b0, 1'b1,
            1'b0, 1'b1
        );

        // Wait until it returns to main green
        wait_cycles(15);

        check_outputs(
            "Return to S0 Main Green after side cycle",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        // ----------------------------------------------------
        // TEST 3: Pedestrian only
        // ----------------------------------------------------
        // Important updated behavior:
        // If there is no side car, pedestrian walk should return to main green.

        $display("\n========== TEST 3: PEDESTRIAN ONLY ==========");

        do_reset();

        ped_button_n = 1'b0;
        wait_clock();
        ped_button_n = 1'b1;

        check_outputs(
            "S1 Main Green Timed starts after ped request",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        // 10 main green + 3 yellow + 2 all red + margin
        wait_cycles(18);

        check_outputs(
            "S8 Pedestrian Walk Then Main",
            1'b1, 1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b1, 1'b0
        );

        // 6 pedestrian cycles + margin
        wait_cycles(8);

        check_outputs(
            "Pedestrian only returns to Main Green",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        // ----------------------------------------------------
        // TEST 4: Pedestrian plus side request
        // ----------------------------------------------------
        // Updated behavior:
        // If pedestrian and side car are both waiting,
        // pedestrian walks first, then side gets green.

        $display("\n========== TEST 4: PEDESTRIAN PLUS SIDE REQUEST ==========");

        do_reset();

        ped_button_n = 1'b0;
        side_sensor = 1'b1;
        wait_clock();

        ped_button_n = 1'b1;
        side_sensor = 1'b0;

        check_outputs(
            "S1 Main Green Timed starts after ped + side request",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        // 10 main green + 3 yellow + 2 all red + margin
        wait_cycles(18);

        check_outputs(
            "S7 Pedestrian Walk Then Side",
            1'b1, 1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b1, 1'b0
        );

        // 6 pedestrian cycles + margin
        wait_cycles(8);

        check_outputs(
            "Side Green after pedestrian because side request existed",
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b0, 1'b1,
            1'b0, 1'b1
        );

        // ----------------------------------------------------
        // TEST 5: Pedestrian request during side cycle
        // ----------------------------------------------------
        // This checks S8_PED_THEN_MAIN after the side road is done.

        $display("\n========== TEST 5: PEDESTRIAN DURING SIDE CYCLE ==========");

        // Currently in side green from Test 4.
        ped_button_n = 1'b0;
        wait_clock();
        ped_button_n = 1'b1;

        // Finish side green + side yellow + all red after side
        wait_cycles(15);

        check_outputs(
            "S8 Pedestrian Walk Then Main after side cycle",
            1'b1, 1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b1, 1'b0
        );

        wait_cycles(8);

        check_outputs(
            "Return to Main Green after pedestrian after side",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        // ----------------------------------------------------
        // TEST 6: Emergency main
        // ----------------------------------------------------

        $display("\n========== TEST 6: EMERGENCY MAIN ==========");

        do_reset();

        emergency_main = 1'b1;
        #1;

        check_outputs(
            "Emergency Main forces Main Green",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        emergency_main = 1'b0;
        wait_clock();

        // ----------------------------------------------------
        // TEST 7: Emergency side
        // ----------------------------------------------------
        // This checks the bug you noticed:
        // main and side should NOT both be green.
        // Emergency side should force main red and side green.

        $display("\n========== TEST 7: EMERGENCY SIDE ==========");

        do_reset();

        emergency_side = 1'b1;
        #1;

        check_outputs(
            "Emergency Side forces Side Green and Main Red",
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b0, 1'b1,
            1'b0, 1'b1
        );

        emergency_side = 1'b0;
        wait_clock();

        // ----------------------------------------------------
        // TEST 8: Both emergencies
        // ----------------------------------------------------

        $display("\n========== TEST 8: BOTH EMERGENCIES ==========");

        do_reset();

        emergency_main = 1'b1;
        emergency_side = 1'b1;
        #1;

        check_outputs(
            "Both emergencies active, Main wins",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        emergency_main = 1'b0;
        emergency_side = 1'b0;
        wait_clock();

        // ----------------------------------------------------
        // End simulation
        // ----------------------------------------------------

        $display("\nAll updated tests finished.");
        $stop;
    end

endmodule
