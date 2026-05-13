module bpm_divider (
    input  logic clk,
    input  logic reset,
    input  logic [2:0] bpm_index,
    output logic beat_en
);

    logic [22:0] threshold;
    logic [22:0] counter;
// clock frequency: 6,000,000 cycles/second
// BPM (beats per minute)
// calculate "cycles/beat": cycles/beat = (cycles/second) * (seconds/beat)
// BPM = 80: cycles/beat = (6,000,000 cycles/second) * (60 seconds/80 beats) = 4,500,000 cycles/beat
    always_comb begin
        case (bpm_index)
            3'd0: threshold = 23'd6000000; // BPM = 60
            3'd1: threshold = 23'd4500000; // BPM = 80
            3'd2: threshold = 23'd3600000; // BPM = 100
            3'd3: threshold = 23'd3000000; // BPM = 120
            3'd4: threshold = 23'd2571429; // BPM = 140
            3'd5: threshold = 23'd2250000; // BPM = 160
            default: threshold = 23'd6000000; // default to BPM = 60
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin // sync reset
            counter <= threshold;
            beat_en <= 1'b0; // set to starting point, beat_en is off
        end else if (counter == 23'd0) begin // counter hit zero, one beat's worth of time passed, fire beat_en = 1
            counter <= threshold;
            beat_en <= 1'b1;
        end else begin
            counter <= counter - 23'd1; // counting down by subtracting 1, beat_en stays off
            beat_en <= 1'b0;
        end
    end

endmodule
