module display_ctrl (
    input logic clk,
    input logic reset,
    input logic [1:0] state,
    input logic [2:0] bpm_index,
    input logic [2:0] sig_index,
    input logic [2:0] beat_count,
    input logic [2:0] edit_cursor,
    input logic [7:0] pattern,
    output logic [7:0] display7, // BPM hundreds
    output logic [7:0] display6, // BPM tens
    output logic [7:0] display5, // BPM ones
    output logic [7:0] display4, // time signature index
    output logic [7:0] display3, // beat slot 0
    output logic [7:0] display2, // beat slot 1
    output logic [7:0] display1, // beat slot 2
    output logic [7:0] display0 // beat slot 3
);
    // BPM hundreds/tens/ones digit lookup, each digit requires a separate display
    logic [3:0] bpm_h, bpm_t, bpm_o;

    always_comb begin
        case (bpm_index)
            3'd0: begin bpm_h = 4'd0; bpm_t = 4'd6; bpm_o = 4'd0; end  // 60
            3'd1: begin bpm_h = 4'd0; bpm_t = 4'd8; bpm_o = 4'd0; end  // 80
            3'd2: begin bpm_h = 4'd1; bpm_t = 4'd0; bpm_o = 4'd0; end  // 100
            3'd3: begin bpm_h = 4'd1; bpm_t = 4'd2; bpm_o = 4'd0; end  // 120
            3'd4: begin bpm_h = 4'd1; bpm_t = 4'd4; bpm_o = 4'd0; end  // 140
            3'd5: begin bpm_h = 4'd1; bpm_t = 4'd6; bpm_o = 4'd0; end  // 160
            default: begin bpm_h = 4'd0; bpm_t = 4'd6; bpm_o = 4'd0; end // default to 60
        endcase
    end

    //seven-segment encodings
    logic [7:0] seg_bpm_h, seg_bpm_t, seg_bpm_o, seg_sig;
    logic [7:0] seg_beat [3:0];  // beat slots 0-3
    logic [7:0] seg_edit_slot;

    seven_segments_hex enc_bpm_h (.hex(bpm_h), .digit(seg_bpm_h));
    seven_segments_hex enc_bpm_t (.hex(bpm_t), .digit(seg_bpm_t));
    seven_segments_hex enc_bpm_o (.hex(bpm_o), .digit(seg_bpm_o));
    seven_segments_hex enc_sig (.hex({1'b0, sig_index}), .digit(seg_sig));
    seven_segments_hex enc_beat0 (.hex({2'b00, pattern[1:0]}), .digit(seg_beat[0]));
    seven_segments_hex enc_beat1 (.hex({2'b00, pattern[3:2]}), .digit(seg_beat[1]));
    seven_segments_hex enc_beat2 (.hex({2'b00, pattern[5:4]}), .digit(seg_beat[2]));
    seven_segments_hex enc_beat3 (.hex({2'b00, pattern[7:6]}), .digit(seg_beat[3]));
    seven_segments_hex enc_edit_slot (.hex(edit_slot_digit), .digit(seg_edit_slot));

    // current edit-slot value
    logic [1:0] edit_slot;
    always_comb begin
        case (edit_cursor)
            3'd0: edit_slot = pattern[1:0];
            3'd1: edit_slot = pattern[3:2];
            3'd2: edit_slot = pattern[5:4];
            3'd3: edit_slot = pattern[7:6];
            default: edit_slot = pattern[1:0];
        endcase
    end

    // edit slot digit: maps edit_slot to 0/1/2 for display
    logic [3:0] edit_slot_digit;
    always_comb begin
        case (edit_slot)
            2'b00: edit_slot_digit = 4'd0; // rest
            2'b01: edit_slot_digit = 4'd1; // normal
            2'b10: edit_slot_digit = 4'd2; // accent
            default: edit_slot_digit = 4'd0;
        endcase
    end


    // beat display: dot encodes pattern state; display[3-i] = slot i
    // rest(00)=dot off, normal(01)=dot blinks, accent(10)=dot on
    logic [7:0] beat_disp [3:0];

    always_comb begin
        // slot 0: display[3]
        if (state == 2'b10 && edit_cursor == 3'd0) // EDIT, cursor at beat slot 0
            beat_disp[0] = seg_edit_slot; // show slot value
        else if (state == 2'b01 && beat_count == 3'd0) begin
            case (pattern[1:0]) // RUNNING
                2'b01: beat_disp[0] = 8'h80; // normal: dot only
                2'b10: beat_disp[0] = 8'hFF; // accent: full 8
                default: beat_disp[0] = 8'h00; // rest: blank
            endcase
        end else
            beat_disp[0] = 8'h00; // IDLE, blank

        // slot 1: display[2]
        if (state == 2'b10 && edit_cursor == 3'd1)
            beat_disp[1] = seg_edit_slot;
        else if (state == 2'b01 && beat_count == 3'd1) begin
            case (pattern[3:2])
                2'b01: beat_disp[1] = 8'h80;
                2'b10: beat_disp[1] = 8'hFF;
                default: beat_disp[1] = 8'h00;
            endcase
        end else
            beat_disp[1] = 8'h00;

        // slot 2: display[1]
        if (state == 2'b10 && edit_cursor == 3'd2)
            beat_disp[2] = seg_edit_slot;
        else if (state == 2'b01 && beat_count == 3'd2) begin
            case (pattern[5:4])
                2'b01: beat_disp[2] = 8'h80;
                2'b10: beat_disp[2] = 8'hFF;
                default: beat_disp[2] = 8'h00;
            endcase
        end else
            beat_disp[2] = 8'h00;

        // slot 3: display[0]
        if (state == 2'b10 && edit_cursor == 3'd3)
            beat_disp[3] = seg_edit_slot;
        else if (state == 2'b01 && beat_count == 3'd3) begin
            case (pattern[7:6])
                2'b01: beat_disp[3] = 8'h80;
                2'b10: beat_disp[3] = 8'hFF;
                default: beat_disp[3] = 8'h00;
            endcase
        end else
            beat_disp[3] = 8'h00;
    end


    // registered outputs
    always_ff @(posedge clk) begin
        if (reset) begin
            display7 <= 8'h00; display6 <= 8'h00;
            display5 <= 8'h00; display4 <= 8'h00;
            display3 <= 8'h00; display2 <= 8'h00;
            display1 <= 8'h00; display0 <= 8'h00;
        end else begin
            display7 <= (bpm_index >= 3'd2) ? seg_bpm_h : 8'h00; // if BPM hundreds digit is 0, show blank; otherwise, show 1
            display6 <= seg_bpm_t; // BPM tens
            display5 <= seg_bpm_o; // BPM ones
            display4 <= seg_sig; // time-signature index
            display3 <= beat_disp[0];
            display2 <= beat_disp[1];
            display1 <= beat_disp[2];
            display0 <= beat_disp[3];
        end
    end
endmodule
