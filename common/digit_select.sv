// A module to select a single nibble value via up/down keys shown on a 7-segment display
module digit_select(
    input logic reset,             // reset
    input logic clock,             // clock
    input logic up_key,            // up key
    input logic down_key,          // down key
    output logic [7:0] display,    // 7 segment display
    output logic [3:0] hex_value   // value being displayed
    );

    logic [3:0] val;
    assign hex_value = val;

    seven_segments_hex op_disp(.hex(val), .digit(display));
    logic up_detected, down_detected;
    risingedge_detector up_press(.in(up_key), .detected(up_detected), .clock(clock), .reset(reset));
    risingedge_detector down_press(.in(down_key), .detected(down_detected), .clock(clock), .reset(reset));

    always_ff @(posedge clock, posedge reset) begin
        if(reset==1)
        begin
            val <= 0;
        end
        else
        if(up_detected) begin
            val <= val + 1;
        end else if(down_detected) begin
            val <= val - 1;
        end
    end
endmodule
