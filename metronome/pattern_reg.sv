module pattern_reg (
    input logic clk,
    input logic reset,
    input logic [1:0] state, // from FSM
    input logic next_btn, // rising edge, advance edit cursor
    input logic cycle_btn, // rising edge, cycle slot value
    input logic [2:0] sig_index, // max slots = beats in time signature
    output logic [2:0] edit_cursor, // which beat slot is selected in EDIT state
    output logic [7:0] pattern // full 8-bit pattern register
);
    logic [2:0] max_beats;

    // same lookup table as in beat_counter.sv
    // edit cursor needs to know when to wrap
    always_comb begin
        case (sig_index)
            3'd0: max_beats = 3'd2;
            3'd1: max_beats = 3'd3;
            3'd2: max_beats = 3'd4;
            default: max_beats = 3'd4;
        endcase
    end

    // current slot value at edit cursor
    logic [1:0] cur_slot;
    always_comb begin
        case (edit_cursor)
            3'd0: cur_slot = pattern[1:0]; // beat slot 0, extract 1:0 to determine whether its rest, normal, or accent
            3'd1: cur_slot = pattern[3:2]; // beat slot 1
            3'd2: cur_slot = pattern[5:4]; // beat slot 2
            3'd3: cur_slot = pattern[7:6]; // beat slot 3
            default: cur_slot = pattern[1:0]; // default to beat slot 0
        endcase
    end

    // next pattern with cycled slot
    logic [7:0] next_pattern;
    logic [1:0] next_slot;

    always_comb begin
        // pattern FSM, start at rest, cycle through rest, normal, accent, rest...
        case (cur_slot)
            2'b00: next_slot = 2'b01; // rest to normal
            2'b01: next_slot = 2'b10; // normal to accent
            default: next_slot = 2'b00; // accent to rest (2'b11 never used so also goes to rest)
        endcase
        next_pattern = pattern; // copy current pattern
        // change the pattern by extracting the correct slot and advance the pattern to next state
        case (edit_cursor)
            3'd0: next_pattern[1:0] = next_slot;
            3'd1: next_pattern[3:2] = next_slot;
            3'd2: next_pattern[5:4] = next_slot;
            3'd3: next_pattern[7:6] = next_slot;
            default: next_pattern[1:0] = next_slot;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin // sync reset
            pattern <= 8'h00; // all rest
            edit_cursor <= 3'd0; // cursor at beat 0
        end else if (state != 2'b10) begin  // not EDIT state, keep cursor reset for clean re-entry
            edit_cursor <= 3'd0;
        end else begin  // EDIT state
            // next_btn determines which slot is being editted
            if (next_btn) begin
                if (edit_cursor >= max_beats - 3'd1) // wrap cursor around according to max_beats
                    edit_cursor <= 3'd0;
                else
                    edit_cursor <= edit_cursor + 3'd1; // otherwise, point cursor to next beat
            end
            // cycle_btn determines which state the beat is in
            if (cycle_btn)
                pattern <= next_pattern;
        end
    end
endmodule
