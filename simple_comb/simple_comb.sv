
module simple_comb(
    input  logic a,
    input  logic b,
    input  logic c,
    output logic y
);
// TODO: Create a **behavioral** model of the given circuit for the truth table
// TODO: using the **cannonical sum-of-products** form.:
// TODO:  a b c | y
// TODO:  ------+---
// TODO:  0 0 0 | 0
// TODO:  0 0 1 | 1
// TODO:  0 1 0 | 0
// TODO:  0 1 1 | 0
// TODO:  1 0 0 | 1
// TODO:  1 0 1 | 0
// TODO:  1 1 0 | 0
// TODO:  1 1 1 | 0
// ! This should be super simple --- one line.  There's no need to simplify / etc.

    // ! Solution below:
    assign y = ~a & ~b & c | a & ~b & ~c;
endmodule
