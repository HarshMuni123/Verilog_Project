// uart receiver (parameterized data width)
`timescale 1ns/1ps
module uart_rx #(
    parameter int DATA_BITS = 3
)(
    input  logic              clk,
    input  logic              rst,
    input  logic              rx_serial,
    input  logic              baud_tick,
    output logic [DATA_BITS-1:0] data_out,
    output logic              rx_done
);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t current_state, next_state;

    localparam int IDX_W = (DATA_BITS <= 1) ? 1 : $clog2(DATA_BITS);
    logic [IDX_W-1:0] bit_index;
    logic [DATA_BITS-1:0] shift_reg;

    // single synchronous block: update state and registers
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            rx_done       <= 1'b0;
            shift_reg     <= '0;
            bit_index     <= '0;
        end
        else begin
            current_state <= next_state;

            case (current_state)
                IDLE: begin
                    rx_done <= 1'b0;
                    // wait for start (line goes low)
                    // sampling handled by combinational next_state using rx_serial
                end

                START: begin
                    // wait one baud tick to align to first data bit
                    if (baud_tick) begin
                        bit_index <= '0;
                    end
                end

                DATA: begin
                    if (baud_tick) begin
                        // capture LSB-first into shift_reg[bit_index]
                        shift_reg[bit_index] <= rx_serial;
                        bit_index <= bit_index + 1;
                    end
                end

                STOP: begin
                    if (baud_tick) begin
                        // expect rx_serial == 1 for proper stop
                        if (rx_serial == 1'b1) begin
                            data_out <= shift_reg;
                            rx_done  <= 1'b1;
                        end
                        else begin
                            // framing error: ignore (rx_done stays 0)
                            rx_done <= 1'b0;
                        end
                    end
                end

                default: ;
            endcase
        end
    end

    // combinational next-state logic
    always_comb begin
        next_state = current_state;

        case (current_state)
            IDLE: begin
                if (rx_serial == 1'b0) // start bit detected
                    next_state = START;
            end

            START: begin
                // move to DATA once a baud_tick arrives (aligned to first data bit)
                if (baud_tick)
                    next_state = DATA;
            end

            DATA: begin
                // when we've captured the last data bit, go to STOP
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
