/*
 * Author: Bill Siever <bsiever@gmail.com>
 * See: https://github.com/digital-logic-and-computer-design/ice40-ledandkey
 */

module ledandkey
#(parameter CLICK_DIV_X2 = 16, // Clock Divider
            BRIGHTNESS = 5)    // Brightness level: 0-7 (3 bits)
(
    input logic clock,     // Master Clock
    input logic reset,     // Master reset
    input logic [7:0] display0,
    input logic [7:0] display1,
    input logic [7:0] display2,
    input logic [7:0] display3,
    input logic [7:0] display4,
    input logic [7:0] display5,
    input logic [7:0] display6,
    input logic [7:0] display7,
    input logic [7:0] leds,
    output logic [7:0] keys,
    // TM1638 Pins
    output logic tm_strobe,
    output logic tm_clock,
    inout logic  tm_dio
);
    // Configure the I/O pin to be usable as both input and output via internal signals
    logic dio_write_nread; // Read/Write to TM 1638 1=>Write
    logic dio_in; // Data in from TM1638
    logic dio_out; // Data out to TM1638


    logic [7:0] sevens [7:0];
    assign sevens[0] = display7;
    assign sevens[1] = display6;
    assign sevens[2] = display5;
    assign sevens[3] = display4;
    assign sevens[4] = display3;
    assign sevens[5] = display2;
    assign sevens[6] = display1;
    assign sevens[7] = display0;
    logic [7:0] rleds;
    assign rleds[0] = leds[7];
    assign rleds[1] = leds[6];
    assign rleds[2] = leds[5];
    assign rleds[3] = leds[4];
    assign rleds[4] = leds[3];
    assign rleds[5] = leds[2];
    assign rleds[6] = leds[1];
    assign rleds[7] = leds[0];


    /* verilator lint_off PINMISSING */
    SB_IO #(
        //     10 = OUTPUT_ENABLE is active high (1=>Write)
        //     10 = D_OUT_0 is not latched
        //     01 = D_IN_0 is not latched
        .PIN_TYPE(6'b101001),
        .PULLUP(1'b1)
    ) tm_dio_io (
        .PACKAGE_PIN(tm_dio),
        .OUTPUT_ENABLE(dio_write_nread),
        .D_IN_0(dio_in),
        .D_OUT_0(dio_out)
    );
    /* verilator lint_on PINMISSING */


    // Enable counter to enable updates of states
    localparam DIV2COUNTER = $clog2(CLICK_DIV_X2);
    localparam COUNTERMAX = DIV2COUNTER'(DIV2COUNTER-1);
    logic [DIV2COUNTER-1:0] counter;
    logic enable;
    // Update when counter is 0
    always_ff @(posedge clock) begin
        if (reset) begin
            counter <= COUNTERMAX;
        end
        else
            if (counter == 0) begin
                counter <= COUNTERMAX;
                enable <= 1;
            end
            else
            begin
                counter <= counter - 1;
                enable <= 0;
            end
    end

    // Driving state machine / states
    typedef enum bit[3:0] {
        Reset_Idle,              //0
        Turn_On_Start,           //1
        Turn_On_End,             //2
        Auto_Increment_Start,    //3
        Auto_Increment_End,      //4
        Data_Send_Start,         //5
        Data_Send,               //6
        Data_Send_End,           //7
        Data_Read_Start,         //8
        Data_Read,               //9
        Data_Read_Next,          //10
        Data_Read_End,           //11
        Idle
    } state_type;

    state_type state;

    logic [7:0] current_data;    // Internal value to send to byteprocessor
    logic bp_start;
    logic bp_ready;
    logic [7:0] bp_rx;

    logic bit_set;
    logic [4:0] data_index;
    logic [7:0] led;

    byteprocessor bp(  // Timing and startup signals
                      .clock(clock),
                      .reset(reset),
                      .update_enable(enable),
                      // Data Signals
                      .data_in(current_data),
                      .start(bp_start),
                      .ready(bp_ready),
                      .write_nread(dio_write_nread),
                      .data_out(bp_rx),

                      // Pin Connections
                      .tm_dout(dio_out),
                      .tm_din(dio_in),
                      .tm_clock(tm_clock)
                      );

    // State machine to shift out byte of data
    // Reset: Resets the state of the machine; Does an initialization sequence
    // Otherwise cycles displays data in cycles.
    always_ff @(posedge clock) begin
        if (reset) begin
            state <= Reset_Idle;
            tm_strobe <= 1;   // Strobe is active low.
            dio_write_nread <= 1;
            bp_start <= 0;
            current_data <= 8'h00;

        end
        else
        if(enable===1)   // If it's a clock cycle we need to act
        begin
            if(bp_ready===0)   // If the byteprocessor is busy, wait (and disable any start)
                bp_start <= 0;
            else
            begin              // An "act" clock and the byteprocessor is free! Let's do something!
                case (state)
                    Reset_Idle: begin
                        if(reset===0)
                            // Move on to a data-send state
                            state <= Turn_On_Start;
                    end

                    Turn_On_Start: begin
                        tm_strobe <= 0;
                        dio_write_nread <= 1;
                        current_data <= 8'h88|BRIGHTNESS;  // Turn on display and set brightness
                        bp_start <= 1;
                        state <= Turn_On_End;
                    end

                    Turn_On_End: begin
                        state <= Auto_Increment_Start;
                        tm_strobe <= 1;
                    end

                    Auto_Increment_Start: begin
                        tm_strobe <= 0;
                        dio_write_nread <= 1;
                        current_data <= 8'h40;  // Set autoincrement
                        bp_start <= 1;
                        state <= Auto_Increment_End;
                    end

                    Auto_Increment_End: begin
                        state <= Data_Send_Start;
                        tm_strobe <= 1;
                    end

                    Data_Send_Start: begin
                        tm_strobe <= 0;
                        dio_write_nread <= 1;
                        current_data <= 8'hC0;  // Start at address 00
                        bp_start <= 1;
                        data_index <= 0;
                        state <= Data_Send;
                    end

                    Data_Send: begin
                        data_index <= data_index + 1;
                        // current_data <= bytes[data_index];

                        if(data_index[0] === 0)
                            current_data <= sevens[data_index[3:1]];
                        else
                            current_data <= {7'b0, rleds[data_index[3:1]]};

                        bp_start <= 1;
                        if(data_index===15)
                            state <= Data_Send_End;
                    end

                    Data_Send_End: begin
                        state <= Idle;
                        state <= Data_Read_Start;
                        tm_strobe <= 1;
                    end

                    Data_Read_Start:begin
                        tm_strobe <= 0;
                        dio_write_nread <= 1;
                        current_data <= 8'h42;  // Read Mode
                        bp_start <= 1;
                        data_index <= 0;
                        state <= Data_Read;
                    end

                    Data_Read:begin
                        data_index <= data_index + 1;
                        dio_write_nread <= 0;
                        bp_start <= 1;
                        state <= Data_Read_Next;
                    end

                    Data_Read_Next:begin
                        // Save the read values
                        // keys[8-data_index] <= bp_rx[0];
                        // keys[4-data_index] <= bp_rx[4];
                        if(data_index===1) begin
                            keys[7] <= bp_rx[0]; // ok
                            keys[3] <= bp_rx[4]; // ok
                        end
                        else if(data_index===2) begin
                            keys[6] <= bp_rx[0]; // ok
                            keys[2] <= bp_rx[4];
                        end
                        else if(data_index===3) begin
                            keys[5] <= bp_rx[0];  // ok
                            keys[1] <= bp_rx[4];
                        end
                        else if(data_index===4) begin
                            keys[4] <= bp_rx[0];  // ok
                            keys[0] <= bp_rx[4];
                        end
                        // Read the next ones
                        data_index <= data_index + 1;
                        bp_start <= 1;
                        if(data_index===4)
                            state <= Data_Read_End;
                    end


                    Data_Read_End:begin
                        tm_strobe <= 1;
                        dio_write_nread <= 1;
                        state <= Data_Send_Start;
                    end

                    Idle: begin
                        state <= Idle;
                    end

                    default: begin
                        state <= Idle;
                    end
                endcase
            end
        end
    end

endmodule


module byteprocessor
(
    input logic clock,           // Global clock
    input logic reset,           // Global reset
    input logic update_enable,   // Indicates if this is a cycle to move on to new bit (sub-samples global clock)

    input logic [7:0] data_in,   // Data to send
    input logic start,           // Trigger to start sending

    input logic write_nread,     // Writing (1) or reading (0)
    output logic [7:0] data_out, // Read data (if any)

    output logic ready,          // Ready / idle indicator

    input logic tm_din,          // Data In signal from PIN
    output logic tm_dout,        // Data Out signal to PIN
    output logic tm_clock        // Clock to device

);
    // Output clock is half of input clock.
    logic [7:0] current_data;   // Internally stored capture of "data_in" and "data_out" at end of read
    logic [3:0] busy;           // Busy indicator (busy shifting data)

    logic clock_out;            // control for tm_clock
    assign tm_clock = clock_out;

    assign ready = (busy===0);
    assign tm_dout = current_data[0];
    assign data_out = current_data;

    always_ff @(posedge clock) begin
        if (reset) begin
            busy <= 0;
            current_data <= 8'b0;
            clock_out <= 0;
        end
        else
            if(start & ready) begin
                busy <= 8;
                current_data <= data_in;
                clock_out <= 0;
            end
            else
            if(update_enable)   // Transition states if we are in an update cycle
                    begin
                        if(clock_out) begin   // If this data was already clocked, set up next data
                            busy <= busy - 1;
                            current_data <= { write_nread===0 ? tm_din  : 1'b0, 7'(current_data >> 1) };
                            clock_out <= 0;
                        end else
                            if(busy!==0)  // More data to send; Clock it.
                                clock_out <= 1;
                            else
                                clock_out <= 0;
                    end
    end
endmodule
