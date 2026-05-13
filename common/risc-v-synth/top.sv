(* top *)
module top(
    output logic tm_strobe,  // TM1638 Strobe
    output logic tm_clock,       // TM1638 Clock
    inout  logic tm_dio          // TM1638 Data
);

    // ***** Leave the part below (everything above the "TODO" area) alone
    // 6MHz clock
    logic clock;
    SB_HFOSC #(.CLKHF_DIV("0b11")) inthosc(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clock));

    // Startup reset for one clock
    logic reset = 1;
    always_ff @(posedge clock) begin
        reset = 0;
    end

  logic [31:0] PC, Instr, ReadData;
  logic [31:0] WriteData, DataAdr;
  logic        MemWrite;

  // instantiate processor and memories
  riscvsingle rvsingle(.clock(clock),
                       .reset(reset),
                       .PC(PC),
                       .Instr(Instr),
                       .MemWrite(MemWrite),
                       .ALUResult(DataAdr),  // ALU Compute address to use for memory
                       .WriteData(WriteData),
                       .ReadData(ReadData));

  imem imem(.address(PC),
            .instruction(Instr));

  logic [31:0] MemData;
  dmem dmem(.clock(clock),
            .write_enable(MemWrite && DataAdr[15]===0),
            .address(DataAdr),
            .write_data(WriteData),
            .read_data(MemData));

  logic [31:0] IOData;
  io io(.clock(clock),
        .reset(reset),
        .write_enable(MemWrite && DataAdr[15]===1),
        .address(DataAdr),
        .write_data(WriteData),
        .read_data(IOData),
        .tm_strobe(tm_strobe),
        .tm_clock(tm_clock),
        .tm_dio(tm_dio));
  assign ReadData = (DataAdr[15]===1'b0) ? MemData : IOData;

endmodule
