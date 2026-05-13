// Module to trigger an enable perioidically
module timed_enable
#(parameter clock_count = 6_000_000)
(
 input logic clock,     // clock
 input logic reset,     // reset
 output logic enable);  // the enable (active for 1 clock periodically)

localparam bits = $clog2(clock_count);
localparam time_in_clocks = clock_count;

logic [bits-1:0] count;

always_ff @(posedge clock) begin
    if(reset==1)
    begin
        count <= 0;
        enable <= 0;
    end
    else if(count == time_in_clocks-1)
    begin
        count <= 0;
        enable <= 1;
    end
    else
    begin
        count <= count + 1;
        enable <= 0;
    end
end
endmodule

