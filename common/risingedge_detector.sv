// Module to detect a rising edge and trigger an indicator for one cycle
module risingedge_detector(
    input  logic  in,          // input signal to check
    output logic  detected,    // detected a rising edge (will be active for just 1 cycle)
    input  logic  clock,       // clock
    input  logic  reset        // reset
    );

    logic lastValue;

    always_ff @(posedge clock, posedge reset) begin
        if(reset==1)
        begin
            lastValue <= 0;
        end
        else
        begin
            if(in==1 && in != lastValue)
                detected <= 1;
            else
                detected <= 0;
            lastValue <= in;
        end
    end
endmodule
