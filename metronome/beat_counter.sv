module beat_counter (
    input  logic clk,
    input  logic reset,
    input  logic beat_en, // take the pulse from bpm_divider
    input  logic [2:0] sig_index, // time signature index
    input  logic [1:0] state, // from FSM (only count in RUNNING state)
    output logic [2:0] beat_count // 0-indexed current beat
);
    logic [2:0] max_beats;

    always_comb begin
        case (sig_index)
            3'd0: max_beats = 3'd2;  // 2/4 (2 beats before wrapping back to 0, beat 1)
            3'd1: max_beats = 3'd3;  // 3/4 (3 beats before wrapping back to 0, beat 2)
            3'd2: max_beats = 3'd4;  // 4/4 (4 beats before wrapping back to 0, beat 3)
            default: max_beats = 3'd4; // default to 4/4
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            beat_count <= 3'd0; // set back to beat 0
        end else if (state == 2'b00) begin // IDLE state, hold at beat 0 (so when START is pressed, always begin from beat 0)
            beat_count <= 3'd0;
        end else if (state == 2'b01 && beat_en) begin // RUNNING state, only advance when beat_en pulses
            if (beat_count >= max_beats - 3'd1) // at the last beat, wrap to beat 0
                beat_count <= 3'd0;
            else
                beat_count <= beat_count + 3'd1; // otherwise, increment
        end
        // EDIT state, no condition matches, beat_count is never written, keeps whatever value it had
    end
endmodule
