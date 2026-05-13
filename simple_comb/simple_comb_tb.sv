
module simple_comb_tb();
    logic a, b, c, d, y, x;
    integer i;
    logic error;
    integer total_tests;
    integer error_count;
    logic expected;
    simple_comb dut(.a(a),.b(b),.c(c), .y(y));
    assign a = i[2];
    assign b = i[1];
    assign c = i[0];


    initial begin
        $dumpfile("simple_comb_tb.vcd");
        $dumpvars(0, dut);

        total_tests = 0;
        error_count = 0;
        error = 0;

        for(i=0; i<8;i=i+1) begin
            $display("a = %d, b = %d, c = %d",a,b,c);
            error = 0;
            total_tests = total_tests + 1;
            #10;
            expected = (i==1 | i==4);
            assert(y === expected)
            else begin
                $error("Error on a = %d, b = %d, c = %d;  expected=%d but got %d", a,b,c,expected, y);
                error = 1;
                error_count = error_count + 1;
            end
            #10;
        end
        error = 0;
        if(error_count !== 0) begin
            $error("*** %d of %d tests failed! -- 'PROBLEMS' tab shows the first error.  Others can be seen where 'error' is true in the signal trace. ***", error_count, total_tests);
        end
        else begin
            $display("simple_comb_tb.sv:01:All tests passed!");
        end

        #10 $finish;
    end
endmodule
