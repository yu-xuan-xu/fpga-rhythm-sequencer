
// Error expansion macro
`define E(m) $sformatf("ERROR: %s:%0d: %s", `__FILE__, `__LINE__, m)


    integer error_count = 0;
    integer total_tests = 0;
    logic   next_error = 0;

    // Device to test and related signals
    logic        clock = 0, reset = 0;  // inputs
    logic [31:0] PC; //output
    logic [31:0] Instr = 0 ; // Input
    logic        MemWrite; // Output
    logic [31:0] ALUResult, WriteData; // Output
    logic [31:0] ReadData = 0; // Input
    riscvsingle dut(clock,reset, PC, Instr, MemWrite, ALUResult, WriteData, ReadData);

    // Reset the DUT
    task reset_dut;
        next_error = 0;
        Instr = 0;
        clock = 0;
        reset = 1; #10;
        clock = 1; #10;
        reset = 0; #10;
        clock = 1; #10;
        clock = 0; #10;
    endtask

    //*** Major checks for state changes: reg_check, memwrite_check, pc_check, aluresult_check, writedata_check

    // Check a register has a specific value
    task reg_check;
        input string name;
        input logic [4:0] rd;
        input logic [31:0] expected;
        total_tests = total_tests + 1;
        assert(dut.dp.rf.rf[rd] == expected) else
        begin
            error_count = error_count + 1;
            $display("%s - Reg[%X] is not correct! Expected %X, got %X", name, rd, expected, dut.dp.rf.rf[rd]);
            next_error = 1; #10;
        end
    endtask

    // Check that memwrite has a designated value
    task memwrite_check;
        input string name;
        input logic expected;
        total_tests = total_tests + 1;
        assert(MemWrite == expected) else
        begin
            error_count = error_count + 1;
            $display("%s - MemWrite incorrect", name);
            next_error = 1; #10;
        end
    endtask

    // Check that memwrite has a designated value
    task writedata_check;
        input string name;
        input logic [31:0] expected;
        total_tests = total_tests + 1;
        assert(WriteData == expected) else
        begin
            error_count = error_count + 1;
            $display("%s - WriteData incorrect", name);
            next_error = 1; #10;
        end
    endtask

    // Check that regwrite has a designated value
    task regwrite_check;
        input string name;
        input logic expected;
        total_tests = total_tests + 1;
        assert(dut.c.md.RegWrite == expected) else
        begin
            error_count = error_count + 1;
            $display("%s - RegWrite incorrect", name);
            next_error = 1; #10;
        end
    endtask

    // Check that the PC has a designated value
    task pc_check;
        input string name;
        input logic [31:0] expected;
        total_tests = total_tests + 1;
        assert(dut.dp.pcreg.q == expected) else
        begin
            error_count = error_count + 1;
            next_error = 1; #10;
            $display("%s - PC is not correct! Expected %X, got %X", name, expected, dut.dp.pcreg.q);
        end
    endtask

    task aluresult_check;
        input string name;
        input logic [31:0] expected;
        total_tests = total_tests + 1;
        assert(ALUResult == expected) else
        begin
            error_count = error_count + 1;
            $display("%s - ALUResult is not correct! Expected %X, got %X", name, expected, ALUResult);
            next_error = 1; #10;
        end
    endtask



    // Check instruction that writes a register (apply instruction and confirm expected result)
    // Can be used to confirm behavior of any instruction that changes only register contents
    task check_reg_inst;
        input string name;
        input logic [31:0] instr;
        input logic [4:0] rd;
        input logic [31:0] rd_init;
        input logic [31:0] rd_final;

        logic [31:0] initial_pc;

        reset_dut();
        // Arbitrary PC start value
        initial_pc = 32'h00000020;
        dut.dp.pcreg.q = initial_pc;

        dut.dp.rf.rf[rd] = rd_init; // reg[rd] = init value

        // Set the instruction to be a LUI
        Instr = instr;
        #10;
        // Clock cycle
        clock = 1; #10;

        // Confirm that memory is not written
        memwrite_check(name, 0);
        clock = 0; #10;
        pc_check(name, initial_pc+4);

        // Check that rd has the expected value
        if(rd!==0) begin
          reg_check(name, rd, rd_final);
        end
        #10;
    endtask

    task check_lui;
        input string name;
        input logic [4:0] rd;
        input logic [19:0] upimm;  // 20 bit immediate value
        input logic [31:0] rd_init;
                    // name, instruction, rd initial, rd final
        check_reg_inst(name, {upimm, rd, 7'b0110111}, rd, rd_init, {upimm, 12'b0});
    endtask

    // Generic check for R-format instructions
    task check_rformat;
        input string name;
        input logic [6:0] funct7;
        input logic [4:0] rs2;
        input logic [4:0] rs1;
        input logic [2:0] funct3;
        input logic [4:0] rd;
        input logic [6:0] op;
        input logic [31:0] rd_init;
        input logic [31:0] rd_expected;
        input logic [31:0] rs1_init;
        input logic [31:0] rs2_init;

        // Use only first init if rs1 and rs2 are the same
        if(rs1 == rs2) begin
            rs2_init = rs1_init;
        end
        dut.dp.rf.rf[rs1] = rs1_init; // reg[rd] = init value
        dut.dp.rf.rf[rs2] = rs2_init; // reg[rd] = init value
        check_reg_inst(name, {funct7, rs2, rs1, funct3, rd, op}, rd, rd_init, rd_expected);
    endtask


    // Check for jalr (modifies both register and PC)
    task check_jalr;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [11:0] imm;
        input logic [31:0] rs_init;
        input logic [31:0] initial_pc;

        reset_dut();
        dut.dp.pcreg.q = initial_pc;
        dut.dp.rf.rf[rd] = 32'h0BADBAD0; // reg[rd] = Sentinel
        dut.dp.rf.rf[rs1] = rs_init;
        // Set the instruction to be a JALR
        Instr = { imm, rs1, 3'b000, rd, 7'b1100111};
        #10;
        // Clock cycle
        clock = 1; #10;

        // Confirm that memory is not written
        memwrite_check(name, 0);
        clock = 0; #10;
        // Check the PC
        pc_check(name, { {20{imm[11]}}, imm} + rs_init);
        // Check the register
        reg_check(name, rd, initial_pc + 4); // Check that rd is not written
        #10;
    endtask


    // Check for jal (modifies both register and PC)
    task check_jal;
        input string name;
        input logic [4:0] rd;
        input logic [19:0] imm;
        input logic [31:0] initial_pc;

        reset_dut();
        dut.dp.pcreg.q = initial_pc;
        dut.dp.rf.rf[rd] = 32'h0BADBAD0; // reg[rd] = Sentinel

        // Set the instruction to be a JALR
        Instr = { imm[19], imm[9:0], imm[10], imm[18:11], rd, 7'b1101111};
        #10;
        // Clock cycle
        clock = 1; #10;

        // Confirm that memory is not written
        memwrite_check(name, 0);
        clock = 0; #10;
        // Check the PC
        pc_check(name, { initial_pc + {{11{imm[19]}}, imm, 1'b0} });
        // Check the register
        reg_check(name, rd, initial_pc + 4); // Check that rd is not written
        #10;
    endtask


    task finish_tests;
        input string name;
        // Summarize results
        if(error_count !== 0) begin
            $display("%s *** %0d of %0d tests failed! ***",name,error_count, total_tests);
        end
        else begin
            $display("%s All (%0d) tests passed!",name, total_tests);
        end
    endtask


    task check_add;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [4:0] rs2;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;
        input logic [31:0] rs2_init;

        check_rformat(name, 7'b0000000, rs2, rs1, 3'b000, rd, 7'b0110011, rd_init, rs1_init+rs2_init, rs1_init, rs2_init);
    endtask

    task check_sub;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [4:0] rs2;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;
        input logic [31:0] rs2_init;

        check_rformat(name, 7'b0100000, rs2, rs1, 3'b000, rd, 7'b0110011, rd_init, rs1_init-rs2_init, rs1_init, rs2_init);
    endtask

    task check_and;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [4:0] rs2;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;
        input logic [31:0] rs2_init;

        check_rformat(name, 7'b0000000, rs2, rs1, 3'b111, rd, 7'b0110011, rd_init, rs1_init&rs2_init, rs1_init, rs2_init);
    endtask

    task check_or;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [4:0] rs2;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;
        input logic [31:0] rs2_init;

        check_rformat(name, 7'b0000000, rs2, rs1, 3'b110, rd, 7'b0110011, rd_init, rs1_init|rs2_init, rs1_init, rs2_init);
    endtask

    task check_xor;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [4:0] rs2;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;
        input logic [31:0] rs2_init;

        check_rformat(name, 7'b0000000, rs2, rs1, 3'b100, rd, 7'b0110011, rd_init, rs1_init^rs2_init, rs1_init, rs2_init);
    endtask

    task check_slt;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [4:0] rs2;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;
        input logic [31:0] rs2_init;
        check_rformat(name, 7'b0000000, rs2, rs1, 3'b010, rd, 7'b0110011, rd_init, {31'b0, $signed(rs1_init)<$signed(rs2_init) ? 1'b1 : 1'b0}, rs1_init, rs2_init);
    endtask

    task check_sll;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [4:0] rs2;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;
        input logic [31:0] rs2_init;
          check_rformat(name, 7'b0000000, rs2, rs1, 3'b001, rd, 7'b0110011, rd_init, rs1_init<<rs2_init, rs1_init, rs2_init);
    endtask

    task check_srl;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [4:0] rs2;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;
        input logic [31:0] rs2_init;
          check_rformat(name, 7'b0000000, rs2, rs1, 3'b101, rd, 7'b0110011, rd_init, rs1_init>>rs2_init, rs1_init, rs2_init);
    endtask

    // Generic check for I-format instructions that change a register
    task check_iformat;
        input string name;
        input logic [11:0] imm;
        input logic [4:0] rs1;
        input logic [2:0] funct3;
        input logic [4:0] rd;
        input logic [6:0] op;
        input logic [31:0] rd_init;
        input logic [31:0] rd_expected;
        input logic [31:0] rs1_init;

        dut.dp.rf.rf[rs1] = rs1_init; // reg[rd] = init value
        check_reg_inst(name, {imm, rs1, funct3, rd, op}, rd, rd_init, rd_expected);
    endtask


    task check_addi;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [11:0] imm;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;

        check_iformat(name, imm, rs1, 3'b000, rd, 7'b0010011, rd_init, rs1_init+{{20{imm[11]}},imm}, rs1_init);
    endtask

    task check_andi;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [11:0] imm;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;

        check_iformat(name, imm, rs1, 3'b111, rd, 7'b0010011, rd_init, rs1_init&{{20{imm[11]}},imm}, rs1_init);
    endtask

    task check_ori;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [11:0] imm;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;

        check_iformat(name, imm, rs1, 3'b110, rd, 7'b0010011, rd_init, rs1_init|{{20{imm[11]}},imm}, rs1_init);
    endtask

    task check_xori;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [11:0] imm;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;

        check_iformat(name, imm, rs1, 3'b100, rd, 7'b0010011, rd_init, rs1_init^{{20{imm[11]}},imm}, rs1_init);
    endtask

    task check_slli;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [11:0] imm;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;

        check_iformat(name, imm, rs1, 3'b001, rd, 7'b0010011, rd_init, rs1_init<<imm, rs1_init);
    endtask

    task check_srli;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [11:0] imm;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;

        check_iformat(name, imm, rs1, 3'b101, rd, 7'b0010011, rd_init, rs1_init>>imm, rs1_init);
    endtask

    task check_slti;
        input string name;
        input logic [4:0] rd;
        input logic [4:0] rs1;
        input logic [11:0] imm;
        input logic [31:0] rd_init;
        input logic [31:0] rs1_init;
        check_iformat(name, imm, rs1, 3'b010, rd, 7'b0010011, rd_init, {31'b0, ($signed(rs1_init)<$signed({{20{imm[11]}},imm})) ? 1'b1 : 1'b0}, rs1_init);
    endtask

    task check_beq;
        input string name;
        input logic [4:0] rs1;
        input logic [4:0] rs2;
        input logic [11:0] imm;
        input logic [31:0] initial_pc;
        input logic [31:0] rs1_init;
        input logic [31:0] rs2_init;

        logic [31:0] expected_pc;
        reset_dut();
        dut.dp.pcreg.q = initial_pc;
        if(rs1 == rs2) begin
            rs2_init = rs1_init;
        end
        dut.dp.rf.rf[rs1] = rs1_init;
        dut.dp.rf.rf[rs2] = rs2_init;

        // Set the instruction to be a beq
        Instr = {imm[11], imm[9:4], rs2, rs1, 3'b000, imm[3:0], imm[10],  7'b1100011};
        #10;
        // Check that registers aren't being written
        regwrite_check(name, 0);
        // Clock cycle
        clock = 1; #10;

        // Confirm that memory is not written
        memwrite_check(name, 0);
        clock = 0; #10;
        if(rs1_init == rs2_init) begin
            expected_pc = initial_pc + {{20{imm[11]}}, imm[9:4], imm[3:0], 1'b0};
        end else begin
            expected_pc = initial_pc + 4;
        end

        // Check the PC
        pc_check(name, expected_pc); // Check that the PC is correct
    endtask

    task check_bne;
        input string name;
        input logic [4:0] rs1;
        input logic [4:0] rs2;
        input logic [11:0] imm;
        input logic [31:0] initial_pc;
        input logic [31:0] rs1_init;
        input logic [31:0] rs2_init;

        logic [31:0] expected_pc;
        reset_dut();
        dut.dp.pcreg.q = initial_pc;
        if(rs1 == rs2) begin
            rs2_init = rs1_init;
        end
        dut.dp.rf.rf[rs1] = rs1_init;
        dut.dp.rf.rf[rs2] = rs2_init;

        // Set the instruction to be a beq
        Instr = {imm[11], imm[9:4], rs2, rs1, 3'b001, imm[3:0], imm[10],  7'b1100011};
        #10;
        // Check that registers aren't being written
        regwrite_check(name, 0);
        // Clock cycle
        clock = 1; #10;

        // Confirm that memory is not written
        memwrite_check(name, 0);
        clock = 0; #10;
        if(rs1_init !== rs2_init) begin
            expected_pc = initial_pc + {{20{imm[11]}}, imm[9:4], imm[3:0], 1'b0};
        end else begin
            expected_pc = initial_pc + 4;
        end

        // Check the PC
        pc_check(name, expected_pc); // Check that the PC is correct
    endtask


    task check_lw;
        input string name;
        input logic [4:0] rd;
        input logic [11:0] imm;
        input logic [4:0] rs1;
        input logic [31:0] rs1_init;

        // ALUResult will be the read address
        // MemWrite should be 0
        // RD should be written
        // Should confirm the requested address and write to reg
        logic [31:0] initial_pc;
        initial_pc = 32'h00000020;

        reset_dut();
        dut.dp.pcreg.q = initial_pc;
        dut.dp.rf.rf[rs1] = rs1_init; // reg[rd] = init value
        dut.dp.rf.rf[rd] = 32'h0BAD0BAD; // reg[rd] = init value / Force to sentinel

        // Set the memory to be read based on getting the expected index
        ReadData = 32'h0AAA0AAA; // Set the memory to be read

        // Set the instruction to be an lw
        Instr = {imm,  rs1, 3'b010, rd,  7'b0000011};
        #10;
        // Check that the address (ALUResult) is correct (address to read)
        aluresult_check(name, rs1_init+{{20{imm[11]}},imm});
        // Clock cycle
        clock = 1; #10;

        // Confirm that rd is written with the expected value
        reg_check(name, rd, ReadData); // Check that rd is written with the expected value

        // Confirm that memory is not written
        memwrite_check(name, 0);

        // Check the PC
        pc_check(name, initial_pc + 4); // Check that the PC is correct
    endtask

    task check_sw;
        input string name;
        input logic [4:0] rs2;
        input logic [11:0] imm;
        input logic [4:0] rs1;
        input logic [31:0] rs1_init;

        // ALUResult will be the read address
        // MemWrite should be 0
        // RD should be written
        // Should confirm the requested address and write to reg
        logic [31:0] initial_pc;
        logic [31:0] expected;
        initial_pc = 32'h00000020;

        reset_dut();
        dut.dp.pcreg.q = initial_pc;
        dut.dp.rf.rf[rs1] = rs1_init; // reg[rd] = init value
        if(rs1==rs2)
            expected = rs1_init;
        else
            expected = 32'h0AAA0AAA; // reg[rd] = init value / Force to sentinel;

        dut.dp.rf.rf[rs2] = expected;

        // Set the instruction to be an lw
        Instr = {imm[11:5], rs2, rs1, 3'b010, imm[4:0],  7'b0100011};
        #10;
        // Check that the address (ALUResult) is correct (address to write)
        aluresult_check(name, rs1_init+{{20{imm[11]}},imm});
        // Clock cycle
        clock = 1; #10;

        writedata_check(name, expected); // Check that the data to write is correct

        // Confirm that memory is written
        memwrite_check(name, 1);

        // Check the PC
        pc_check(name, initial_pc + 4); // Check that the PC is correct
    endtask

    // Check for aiupc (modifies rd only)
    task check_auipc;
        input string name;
        input logic [4:0] rd;
        input logic [19:0] imm;
        input logic [31:0] rd_init;
        input logic [31:0] initial_pc;

        logic [19:0] upimm;

        reset_dut();
        // Set the initial PC and RD values
        dut.dp.pcreg.q = initial_pc;
        dut.dp.rf.rf[rd] = rd_init; // reg[rd] = init value

        // Set the instruction to be a aiupc
        Instr = {imm, rd, 7'b0010111};
        #10;
        // Clock cycle
        clock = 1; #10;

        // Confirm that memory is not written
        memwrite_check(name, 0);
        clock = 0; #10;
        // Check the PC's update
        pc_check(name, initial_pc+4);

        // Check that rd has the expected value
        if(rd!==0) begin
          reg_check(name, rd, initial_pc+{imm, 12'b0});
        end
        #10;

    endtask
