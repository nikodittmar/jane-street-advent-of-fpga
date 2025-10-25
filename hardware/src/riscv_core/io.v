`include "control_sel.vh"

module io #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200
) (
    input clk,
    input rst,
    input [31:0] addr, 
    input [31:0] din,
    input io_en,
    input br_inst, 
    input br_suc,
    input serial_in,
    output serial_out,
    output reg [31:0] dout
);

reg [7:0] uart_tx_data_in;
reg [7:0] next_uart_tx_data_in;
reg uart_tx_data_in_valid;
reg next_uart_tx_data_in_valid;
wire uart_tx_data_in_ready;

wire [7:0] uart_rx_data_out;
wire uart_rx_data_out_valid;
reg uart_rx_data_out_ready;
reg next_uart_rx_data_out_ready;

uart #(
    .CLOCK_FREQ(CLOCK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) uart (
    .clk(clk),
    .reset(rst),

    .data_in(uart_tx_data_in),
    .data_in_valid(uart_tx_data_in_valid),
    .data_in_ready(uart_tx_data_in_ready),

    .data_out(uart_rx_data_out),
    .data_out_valid(uart_rx_data_out_valid),
    .data_out_ready(uart_rx_data_out_ready),

    .serial_in(serial_in),
    .serial_out(serial_out)
);
/*
module uart #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200
) (
    input clk,
    input reset,

    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    output [7:0] data_out,
    output data_out_valid,
    input data_out_ready,

    input serial_in,
    output serial_out
);
*/
reg [31:0] cycle_cnt;
reg [31:0] inst_cnt;

reg [31:0] br_inst_cnt;
reg [31:0] br_suc_cnt;

reg [31:0] next_dout;

reg [31:0] next_cycle_cnt;
reg [31:0] next_inst_cnt;

reg [31:0] next_br_inst_cnt;
reg [31:0] next_br_suc_cnt;

always @ (posedge clk) begin
    if (rst) begin 
        cycle_cnt <= 32'b0;
        inst_cnt <= 32'b0;

        br_inst_cnt <= 32'b0;
        br_suc_cnt <= 32'b0;
    end else begin 
        cycle_cnt <= next_cycle_cnt;
        inst_cnt <= next_inst_cnt;

        br_inst_cnt <= next_br_inst_cnt;
        br_suc_cnt <= next_br_suc_cnt;
        
        dout <= next_dout;

        uart_tx_data_in <= next_uart_tx_data_in;
        uart_tx_data_in_valid <= next_uart_tx_data_in_valid;
        uart_rx_data_out_ready <= next_uart_rx_data_out_ready;
    end
end

always @(*) begin
    next_cycle_cnt = cycle_cnt + 32'b1;
    next_inst_cnt = inst_cnt + 32'b1; // TODO: ignore for now, not needed for initial tests

    next_br_inst_cnt = br_inst ? br_inst_cnt + 1 : br_inst_cnt;
    next_br_suc_cnt = br_suc ? br_suc_cnt + 1 : br_suc_cnt;
    next_dout = 32'b0;

    next_uart_tx_data_in = uart_tx_data_in;
    next_uart_tx_data_in_valid = uart_tx_data_in_valid;

    next_uart_rx_data_out_ready = 1'b1;

    if (uart_tx_data_in_valid && uart_tx_data_in_ready) begin
        next_uart_tx_data_in_valid = 1'b0;
    end

    if (io_en) begin
        case(addr)
        `MEM_IO_UART_CTRL: begin
            next_dout = { 30'b0, uart_rx_data_out_valid, uart_tx_data_in_ready };
        end
        `MEM_IO_UART_RDATA: begin
            next_dout = { 24'b0, uart_rx_data_out };
        end
        `MEM_IO_UART_TDATA: begin
            next_uart_tx_data_in = din[7:0];
            next_uart_tx_data_in_valid = 1'b1;
        end
        `MEM_IO_CYCLE_CNT: begin
            next_dout = cycle_cnt;
        end
        `MEM_IO_INST_CNT: begin
            next_dout = inst_cnt;
        end
        `MEM_IO_RST_CNT: begin 
            next_cycle_cnt = 32'b0;
            next_inst_cnt = 32'b0;

            next_br_inst_cnt = 32'b0;
            next_br_suc_cnt = 32'b0;
        end 
        `MEM_IO_BR_INST_CNT: begin 
            next_dout = br_inst_cnt;
        end
        `MEM_IO_BR_SUC_CNT: begin 
            next_dout = br_suc_cnt;
        end
        endcase
    end
end
endmodule