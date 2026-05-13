// Module for memory-mapped I/O (to the display)
module io(
        output logic tm_strobe,  // TM1638 Strobe
        output logic tm_clock,       // TM1638 Clock
        inout  logic tm_dio,          // TM1638 Data
        input logic reset,
        input logic clock,
        input logic write_enable,
        input logic [31:0] address, write_data,
        output logic [31:0] read_data
);

   logic [7:0] display0, display1, display2, display3, display4, display5, display6, display7, leds;
   logic [7:0] keys;

    logic [7:0] digits [0:15];

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

    // Stored values for output
    logic [31:0] segments1;  // Right 4 digits
    logic [31:0] segments2;  // Next 4 digits
    logic [7:0] lights;      // Lights (8 bits)
    always_ff @(posedge clock)
        if(write_enable)
            if(address === 32'h8000)
                segments1 <= write_data;
            else if(address === 32'h8004)
                segments2 <= write_data;
            else if(address === 32'h8008)
                lights <= write_data[7:0];

    always_comb
        if(address === 32'h8000)
            read_data = segments1;
        else if(address === 32'h8004)
            read_data = segments2;
        else if(address === 32'h8008)
            read_data = {24'b0, lights};
        else if(address === 32'h800C)
            read_data = {24'b0, keys};
        else
            read_data = 32'h0;

    assign display0 = segments1[7:0];
    assign display1 = segments1[15:8];
    assign display2 = segments1[23:16];
    assign display3 = segments1[31:24];
    assign display4 = segments2[7:0];
    assign display5 = segments2[15:8];
    assign display6 = segments2[23:16];
    assign display7 = segments2[31:24];
    assign leds = lights;
endmodule

