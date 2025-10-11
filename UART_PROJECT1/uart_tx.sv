// uart transmitter (parameterized data width)
`timescale 1ns/1ps
module uart_tx #(
    parameter int DATA_BITS = 3
)(
    input  logic              clk,
    input  logic              rst,       // active high reset
    input  logic              tx_start,
    input  logic [DATA_BITS-1:0] tx_data, // parameterized data width
    input  logic              baud_tick,
    output logic              tx_serial,
    output logic              tx_done,
    output logic              tx_busy
);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t current_state, next_state;

    // bit index must be wide enough to hold DATA_BITS-1
    localparam int IDX_W = (DATA_BITS <= 1) ? 1 : $clog2(DATA_BITS);
    logic [IDX_W-1:0] bit_index;
    logic [DATA_BITS-1:0] shift_reg;

    // sequential: state, outputs, registers
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            shift_reg     <= '0;
            tx_serial     <= 1'b1; // line idle high
            tx_done       <= 1'b0;
            bit_index     <= '0;
        end
        else begin
            current_state <= next_state;

            case (current_state)
                IDLE: begin
                    tx_done <= 1'b0;
                    tx_serial <= 1'b1;
                    if (tx_start) begin
                        // sample data on start
                        shift_reg <= tx_data;
                        bit_index <= '0;
                    end
                end

                START: begin
                    // hold start bit low until baud_tick
                    tx_serial <= 1'b0;
                end

                DATA: begin
                    // output data bit at each baud tick
                    if (baud_tick) begin
                        tx_serial <= shift_reg[bit_index];
                        // increment index
                        bit_index <= bit_index + 1;
                    end
                end

                STOP: begin
                    // drive stop bit(s) high for one baud tick
                    if (baud_tick) begin
                        tx_serial <= 1'b1;
                        tx_done   <= 1'b1;
                    end
                end
            endcase
        end
    end

    // combinational next-state + busy
    always_comb begin
        next_state = current_state;
        tx_busy = 1'b1; // default busy

        case (current_state)
            IDLE: begin
                tx_busy = 1'b0;
                if (tx_start)
                    next_state = START;
            end

            START: begin
                if (baud_tick)
                    next_state = DATA;
            end

            DATA: begin
                // when last data bit was just output we move to STOP
                if (baud_tick && (bit_index == (DATA_BITS - 1)))
                    next_state = STOP;
            end

            STOP: begin
                if (baud_tick)
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
