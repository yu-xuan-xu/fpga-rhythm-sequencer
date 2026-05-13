// Module to display a hexadecimal value on a seven segment display
module seven_segments_hex
(
    output logic [7:0] digit,  // Seven segment display segments
    input logic [3:0] hex      // Hexadecimal value to display
);

     logic [7:0] digits [0:15];

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
    assign digits[0] = 8'b0011_1111; // 0
    assign digits[1] = 8'b0000_0110; // 1
    assign digits[2] = 8'b0101_1011; // 2
    assign digits[3] = 8'b0100_1111; // 3
    assign digits[4] = 8'b0110_0110; // 4
    assign digits[5] = 8'b0110_1101; // 5
    assign digits[6] = 8'b0111_1101; // 6
    assign digits[7] = 8'b0000_0111; //7
                //         hgfe dcba
    assign digits[8] =  8'b0111_1111; //8
    assign digits[9] =  8'b0110_0111; //9
    assign digits[10] = 8'b0111_0111; //A
    assign digits[11] = 8'b0111_1100; //b
    assign digits[12] = 8'b0011_1001; //C
    assign digits[13] = 8'b0101_1110; //d
    assign digits[14] = 8'b0111_1001; //E
    assign digits[15] = 8'b0111_0001; //F

    assign digit = digits[hex];

endmodule
