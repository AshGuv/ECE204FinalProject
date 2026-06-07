`timescale 1ns/1ps

module SmartTrafficLightController_tb;

    // ========================================================
    // Testbench signals
    // ========================================================

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

    logic [6:0] seg7_tens;
    logic [6:0] seg7_ones;

    // ========================================================
    // Instantiate DUT
    // ========================================================
    // CLK_FREQ is set to 2 so the simulation runs fast.
    // In hardware, the default value is 50_000_000.

    SmartTrafficLightController #(
        .CLK_FREQ(2)
    ) dut (
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

        .seg7_tens(seg7_tens),
        .seg7_ones(seg7_ones)
    );

    // ========================================================
    // Clock
    // ========================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ========================================================
    // Safety check
    // ========================================================

    always @(posedge clk) begin
        if (main_green && side_green) begin
            $error("SAFETY ERROR: main_green and side_green are both ON.");
        end
    end

    // ========================================================
    // Helper tasks
    // ========================================================

    task wait_clock;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // Waits for one one_sec_tick and then one extra clock edge
    // so the FSM has time to consume the tick.
    task wait_second;
        begin
            @(posedge dut.one_sec_tick);
            wait_clock();
        end
    endtask

    task wait_seconds(input int num_seconds);
        int i;
        begin
            for (i = 0; i < num_seconds; i = i + 1) begin
                wait_second();
            end
        end
    endtask

    task do_reset;
        begin
            reset_n = 1'b0;

            side_sensor = 1'b0;
            ped_button_n = 1'b1; // active-low, so 1 means not pressed
            emergency_main = 1'b0;
            emergency_side = 1'b0;

            repeat (3) wait_clock();

            reset_n = 1'b1;
            wait_clock();
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
            $display("%0t | %s | countdown=%0d", $time, label, dut.countdown);

            if (main_red    !== exp_main_red    ||
                main_yellow !== exp_main_yellow ||
                main_green  !== exp_main_green  ||
                side_red    !== exp_side_red    ||
                side_yellow !== exp_side_yellow ||
                side_green  !== exp_side_green  ||
                ped_walk    !== exp_ped_walk    ||
                ped_wait    !== exp_ped_wait) begin

                $error("FAILED: %s", label);
            end
            else begin
                $display("PASSED: %s", label);
            end
        end
    endtask

    // ========================================================
    // Main test sequence
    // ========================================================

    initial begin

        // Initial values
        reset_n = 1'b1;
        side_sensor = 1'b0;
        ped_button_n = 1'b1;
        emergency_main = 1'b0;
        emergency_side = 1'b0;

        // ----------------------------------------------------
        // Test 1: Reset
        // ----------------------------------------------------

        $display("\nTEST 1: Reset");

        do_reset();

        check_outputs(
            "Reset starts in main green idle",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        // ----------------------------------------------------
        // Test 2: No input
        // ----------------------------------------------------

        $display("\nTEST 2: No input");

        wait_seconds(3);

        check_outputs(
            "No input keeps main green",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        // ----------------------------------------------------
        // Test 3: Side request only
        // ----------------------------------------------------

        $display("\nTEST 3: Side request only");

        side_sensor = 1'b1;
        wait_clock();
        side_sensor = 1'b0;

        // Wait long enough for main timed, yellow, all-red, then side green.
        wait_seconds(20);

        check_outputs(
            "Side request reaches side green",
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b0, 1'b1,
            1'b0, 1'b1
        );

        // ----------------------------------------------------
        // Test 4: Pedestrian only
        // ----------------------------------------------------

        $display("\nTEST 4: Pedestrian only");

        do_reset();

        ped_button_n = 1'b0; // press active-low button
        wait_clock();
        ped_button_n = 1'b1;

        // Wait long enough to reach pedestrian walk.
        wait_seconds(20);

        check_outputs(
            "Pedestrian-only reaches walk",
            1'b1, 1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b1, 1'b0
        );

        // Wait for pedestrian state to finish and return to main green.
        wait_seconds(8);

        check_outputs(
            "Pedestrian-only returns to main green",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        // ----------------------------------------------------
        // Test 5: Pedestrian plus side request
        // ----------------------------------------------------

        $display("\nTEST 5: Pedestrian plus side request");

        do_reset();

        ped_button_n = 1'b0;
        side_sensor = 1'b1;
        wait_clock();
        ped_button_n = 1'b1;
        side_sensor = 1'b0;

        // Wait long enough to reach pedestrian walk.
        wait_seconds(20);

        check_outputs(
            "Pedestrian plus side reaches walk first",
            1'b1, 1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b1, 1'b0
        );

        // After pedestrian walk, side road should get green.
        wait_seconds(8);

        check_outputs(
            "After pedestrian, side road gets green",
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b0, 1'b1,
            1'b0, 1'b1
        );

        // ----------------------------------------------------
        // Test 6: Emergency main
        // ----------------------------------------------------

        $display("\nTEST 6: Emergency main");

        do_reset();

        emergency_main = 1'b1;
        #1;

        check_outputs(
            "Emergency main forces main green",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        emergency_main = 1'b0;
        wait_clock();

        // ----------------------------------------------------
        // Test 7: Emergency side
        // ----------------------------------------------------

        $display("\nTEST 7: Emergency side");

        do_reset();

        emergency_side = 1'b1;
        #1;

        check_outputs(
            "Emergency side forces side green",
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b0, 1'b1,
            1'b0, 1'b1
        );

        emergency_side = 1'b0;
        wait_clock();

        // ----------------------------------------------------
        // Test 8: Both emergencies
        // ----------------------------------------------------

        $display("\nTEST 8: Both emergencies");

        do_reset();

        emergency_main = 1'b1;
        emergency_side = 1'b1;
        #1;

        check_outputs(
            "Both emergencies active, main wins",
            1'b0, 1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0, 1'b1
        );

        emergency_main = 1'b0;
        emergency_side = 1'b0;
        wait_clock();

        // ----------------------------------------------------
        // End
        // ----------------------------------------------------

        $display("\nAll simple tests finished.");
        $stop;
    end

endmodule
