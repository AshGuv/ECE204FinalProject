module ClockDivider#( // Converts from high to low freq
    parameter int DIVISOR = 2; // 
) (
    input logic clk_in,
    input logic rst_n,

    output logic clk_out
);
    // Declare local parameters
    localparam int TICK_COUNT_WIDTH = $clog2(DIVISOR);

    // Declare internal logic
    logic [TICK_COUNT_WIDTH-1:0] count;

    // Store # of ticks by input clock
    always_ff @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
            clk_out = 1'b0;
        end else if (count == (DIVISOR - 1)) begin
            count <= '0;
            clk_out <= 1'b1;
        end else begin
            count <= count + 1'b1;
            clk_out <= 1'b0;
        end
    end
endmodule
