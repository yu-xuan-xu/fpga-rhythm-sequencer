module top(
    output logic tm_strobe,      // TM1638 Strobe
    output logic tm_clock,       // TM1638 Clock
    inout  logic tm_dio          // TM1638 Data
);

    // ! ***** Leave the part below alone (setup)
    // 6MHz clock
    /**/    logic clock;
    /**/    SB_HFOSC #(.CLKHF_DIV("0b11")) inthosc(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clock));
    /**/
    /**/    // Startup reset for one clock
    /**/    logic reset = 1;
    /**/    always_ff @(posedge clock) begin
    /**/        reset = 0;
    /**/    end
    // ! ***** Leave the part above alone (setup)

    logic [7:0] display0, display1, display2, display3, display4, display5, display6, display7, leds;
    logic [7:0] keys;

    //    +-a-+
    //    |   |
    //    f   b
    //    |   |
    //    +-g-+
    //    |   |
    //    e   c
    //    |   |
    //    +-d-+ h
    //

             //        hgfe dcba
    logic [7:0] zero = 8'b0011_1111; // 0
    logic [7:0] one  =  8'b0000_0110; // 1

    // // ************************************************
    ledandkey ledAndKey(.clock(clock), .reset(reset),
                        .tm_strobe(tm_strobe), .tm_clock(tm_clock), .tm_dio(tm_dio),
                        .display0(display0),
                        .display1(display1),
                        .display2(display2),
                        .display3(display3),
                        .display4(display4),
                        .display5(display5),
                        .display6(display6),
                        .display7(display7),
                        .leds(leds),
                        .keys(keys));

    assign display0 = y?one:zero;
    assign display1 = 8'b0110_1110;  // Lower case y (like)
    assign display2 = c?one:zero;
    assign display3 = 8'b0011_1001;
    assign display4 = b?one:zero;
    assign display5 = 8'b0111_1100;; // b
    assign display6 = a?one:zero;
    assign display7 = 8'b0111_0111;; // A
    assign leds = {0,a,0,b,0,c,0,y};

    logic a = keys[6];
    logic b = keys[4];
    logic c = keys[2];
    logic y;

    simple_comb simple_comb(
        .a(a),
        .b(b),
        .c(c),
        .y(y)
    );

endmodule
