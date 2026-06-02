vsim -gui work.ClockDivider
add wave *

force rst_n 1
force clk_in 0 0 ps, 1 10 ps -repeat 20 ps
run 200 ps