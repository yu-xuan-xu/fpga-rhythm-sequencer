module sequencer_fsm (
    input  logic clk,
    input  logic reset,
    input  logic start_btn, // rising edge
    input  logic edit_btn, // rising edge
    output logic [1:0] state // 00=IDLE, 01=RUNNING, 10=EDIT
);
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        RUNNING = 2'b01,
        EDIT = 2'b10
    } state_t;

    state_t current_state;
    assign state = current_state;

    always_ff @(posedge clk) begin
        if (reset) begin
            current_state <= IDLE; // start from IDLE
        end else begin
            case (current_state)
                IDLE: if (start_btn) current_state <= RUNNING; // IDLE to RUNNING
                RUNNING: if (start_btn) current_state <= IDLE; // start_btn from RUNNING, back to IDLE
                         else if (edit_btn) current_state <= EDIT; // edit_btn from RUNNING, go to EDIT
                EDIT: if (edit_btn) current_state <= RUNNING; // edit_btn from EDIT, back to RUNNING
                default: current_state <= IDLE; // default to IDLE
            endcase
        end
    end
endmodule
