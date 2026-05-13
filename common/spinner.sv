module spinner( input logic enable,
                input logic reset,
                input logic clock,
                output logic [7:0] display);

    parameter clock_count = 3_000_000;

    logic [7:0] display_internal;
    logic rotate_enable;

    timed_enable #(.clock_count(clock_count)) timer(.clock(clock), .reset(reset), .enable(rotate_enable));

    always_ff @(posedge clock) begin
        if(reset==1)
        begin
            display_internal <= 8'b1;
        end
        else
        begin
            if(rotate_enable)
                if(display_internal != 8'b0010_0000)
                    display_internal <= display_internal << 1;
                else
                    display_internal <= 8'b1;
        end
    end

    always_comb begin
        display = enable === 1 & reset === 0 ? display_internal : 0;
    end
endmodule
