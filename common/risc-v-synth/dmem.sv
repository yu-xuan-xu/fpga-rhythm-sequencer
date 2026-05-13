module dmem(input  logic        clock, write_enable,
            input  logic [31:0] address, write_data,
            output logic [31:0] read_data);

// Structured and infer
  logic [31:0] RAM[2047:0];
  always_ff @(posedge clock)
   	if (write_enable) RAM[address[12:2]] <= write_data;

  always_ff @(negedge clock)
	  read_data <= RAM[address[12:2]];

endmodule
