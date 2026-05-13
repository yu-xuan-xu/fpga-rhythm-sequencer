module top (
    // TM1638 pins (connect to ledandkey instance)
    output logic tm_clock,
    output logic tm_strobe,
    inout logic tm_dio
);
    // internal 6 MHz oscillator (48 MHz / 8)
    logic clk;
    SB_HFOSC #(.CLKHF_DIV("0b11")) inthosc (
        .CLKHFPU(1'b1),
        .CLKHFEN(1'b1),
        .CLKHF(clk)
    );

    // power-on reset: por_cnt starts at 0 on iCE40; reset is HIGH
    // while por_cnt[3]==0 (first 8 cycles), then deasserts
    logic [3:0] por_cnt = 4'h0;
    logic reset;

    assign reset = !por_cnt[3];

    always_ff @(posedge clk)
        por_cnt <= (por_cnt == 4'hF) ? 4'hF : por_cnt + 4'd1;

    // ledandkey wiring
    logic [7:0] display_arr [7:0];
    logic [7:0] keys;

    logic tm_clock_w, tm_strobe_w;

    ledandkey lk (
        .clock (clk),
        .reset (reset),
        .display0(display_arr[0]),
        .display1(display_arr[1]),
        .display2(display_arr[2]),
        .display3(display_arr[3]),
        .display4(display_arr[4]),
        .display5(display_arr[5]),
        .display6(display_arr[6]),
        .display7(display_arr[7]),
        .leds (8'h00),
        .keys (keys),
        .tm_strobe (tm_strobe_w),
        .tm_clock (tm_clock_w),
        .tm_dio (tm_dio)
    );

    // map top-level TM1638 output ports from ledandkey
    assign tm_clock = tm_clock_w;
    assign tm_strobe = tm_strobe_w;

    // button pulses, sequence_fsm sets state, top updates bpm_index/sig_index
    // bpm_divider fires beat_en, beat_counter tracks beat_count, pattern_reg stores pattern and edit_cursor
    // display_ctrl drives display_arr, ledandkey sends to physical board

    // rising-edge detectors for all 8 keys
    // keys[7]=BPM up, keys[6]=BPM down, keys[5]=sig up, keys[4]=sig down
    // keys[3]=START, keys[2]=EDIT, keys[1]=CURSOR NEXT, keys[0]=CYCLE
    logic re7, re6, re5, re4, re3, re2, re1, re0;

    risingedge_detector red7(.in(keys[7]), .detected(re7), .clock(clk), .reset(reset));
    risingedge_detector red6(.in(keys[6]), .detected(re6), .clock(clk), .reset(reset));
    risingedge_detector red5(.in(keys[5]), .detected(re5), .clock(clk), .reset(reset));
    risingedge_detector red4(.in(keys[4]), .detected(re4), .clock(clk), .reset(reset));
    risingedge_detector red3(.in(keys[3]), .detected(re3), .clock(clk), .reset(reset));
    risingedge_detector red2(.in(keys[2]), .detected(re2), .clock(clk), .reset(reset));
    risingedge_detector red1(.in(keys[1]), .detected(re1), .clock(clk), .reset(reset));
    risingedge_detector red0(.in(keys[0]), .detected(re0), .clock(clk), .reset(reset));

    // BPM index and time-signature index registers
    logic [2:0] bpm_index;
    logic [2:0] sig_index;

    always_ff @(posedge clk) begin
        if (reset) begin
            bpm_index <= 3'd2; // default to 100 BPM
            sig_index <= 3'd2; // default to 4/4
        end else begin
            // clamping, so that bpm_index (0-5: 60/80/100/120/140/160 BPM) and sig_index (0-2: 2/4, 3/4, 4/4)
            if (re7 && bpm_index < 3'd5) bpm_index <= bpm_index + 3'd1;
            if (re6 && bpm_index > 3'd0) bpm_index <= bpm_index - 3'd1;
            if (re5 && sig_index < 3'd2) sig_index <= sig_index + 3'd1;
            if (re4 && sig_index > 3'd0) sig_index <= sig_index - 3'd1;
        end
    end

    // submodule instantiations
    // FSM
    // state flows out to every other module
    logic [1:0] state;

    sequencer_fsm fsm (
        .clk (clk),
        .reset (reset),
        .start_btn (re3), // rising edge pulse from START
        .edit_btn (re2), // rising edge pulse from EDIT
        .state (state)
    );

    // BPM divider: beat pulse
    // takes in bpm_index, produces beat_en pulses at correct tempo
    logic beat_en;

    bpm_divider bpm_div (
        .clk (clk),
        .reset (reset),
        .bpm_index (bpm_index),
        .beat_en (beat_en)
    );

    // beat counter
    // takes in beat_en pulses, counts beats, wrapping based on sig_index
    logic [2:0] beat_count;

    beat_counter bc (
        .clk (clk),
        .reset (reset),
        .beat_en (beat_en),
        .sig_index (sig_index),
        .state (state),
        .beat_count (beat_count)
    );

    // pattern register
    // outputs edit_cursor and pattern to display_ctrl
    logic [2:0] edit_cursor;
    logic [7:0] pattern;

    pattern_reg pr (
        .clk (clk),
        .reset (reset),
        .state (state),
        .next_btn (re1), // NEXT button
        .cycle_btn (re0), // CYCLE button
        .sig_index (sig_index),
        .edit_cursor(edit_cursor),
        .pattern (pattern)
    );

    // display controller
    // takes everything and drives the 8 displays via display_arr
    display_ctrl dc (
        .clk (clk),
        .reset (reset),
        .state (state),
        .bpm_index (bpm_index),
        .sig_index (sig_index),
        .beat_count (beat_count),
        .edit_cursor (edit_cursor),
        .pattern (pattern),
        .display7 (display_arr[7]),
        .display6 (display_arr[6]),
        .display5 (display_arr[5]),
        .display4 (display_arr[4]),
        .display3 (display_arr[3]),
        .display2 (display_arr[2]),
        .display1 (display_arr[1]),
        .display0 (display_arr[0])
    );

endmodule
