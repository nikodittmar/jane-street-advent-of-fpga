`include "control_sel.vh"

module io #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200
) (
    input clk,
    input rst,

    input [31:0] addr,
    input [31:0] din,
    input [31:0] inst,
    input [31:0] fp_inst,
    input en,
    input br_suc,
    input br_inst,

    input serial_in,
    output serial_out,

    output reg [31:0] dout
);

    reg [27:0] cycle_cnt;
    reg [23:0] inst_cnt;
    reg [23:0] br_inst_cnt;
    reg [23:0] br_suc_cnt;

    reg [7:0] uart_tx_data_in;
    reg uart_tx_data_in_valid;
    wire uart_tx_data_in_ready;

    wire [7:0] uart_rx_data_out;
    wire uart_rx_data_out_valid;
    reg uart_rx_data_out_ready;

    reg can_read;
    reg [7:0] rx_buf;

    wire fp_valid = fp_inst != `NOP;
    wire int_valid = inst != `NOP;
    wire [1:0] inst_inc = int_valid + fp_valid;

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


    always @(posedge clk) begin 
        if (rst) begin 
            cycle_cnt <= 28'b0;
            inst_cnt <= 24'b0;
            br_inst_cnt <= 24'b0;
            br_suc_cnt <= 24'b0;

            uart_tx_data_in <= 8'b0;
            uart_tx_data_in_valid <= 1'b0;
            uart_rx_data_out_ready <= 1'b1;
            can_read <= 1'b0;
            dout <= 32'b0;
            rx_buf <= 8'b0;
        end else begin 
            cycle_cnt <= cycle_cnt + 28'b1;
            inst_cnt <= inst_cnt + { 22'b0, inst_inc };
            br_inst_cnt <= br_inst_cnt + { 23'b0, br_inst };
            br_suc_cnt <= br_suc_cnt + { 23'b0, br_suc };

            if (uart_tx_data_in_valid && uart_tx_data_in_ready) begin 
                uart_tx_data_in_valid <= 1'b0;
            end

            if (uart_rx_data_out_valid && !can_read && uart_rx_data_out_ready) begin
                rx_buf <= uart_rx_data_out;
                can_read <= 1'b1;
                uart_rx_data_out_ready <= 1'b0;
            end

            if (en) begin 
                case(addr)
                `MEM_IO_UART_CTRL: begin
                    dout <= { 30'b0, can_read, uart_tx_data_in_ready };
                end
                `MEM_IO_UART_RDATA: begin
                    dout <= { 24'b0, rx_buf };
                    can_read <= 1'b0;
                    uart_rx_data_out_ready <= 1'b1;
                end
                `MEM_IO_UART_TDATA: begin
                    uart_tx_data_in <= din[7:0];
                    uart_tx_data_in_valid  <= 1'b1;
                end
                `MEM_IO_CYCLE_CNT: begin
                    dout <= { 4'b0, cycle_cnt };
                end
                `MEM_IO_INST_CNT: begin
                    dout <= { 8'b0, inst_cnt }; 
                end
                `MEM_IO_RST_CNT: begin 
                    cycle_cnt <= 28'b0;
                    inst_cnt <= 24'b0;
                    br_inst_cnt <= 24'b0;
                    br_suc_cnt <= 24'b0;
                end  
                `MEM_IO_BR_INST_CNT: begin 
                    dout <= { 8'b0, br_inst_cnt };
                end
                `MEM_IO_BR_SUC_CNT: begin 
                    dout <= { 8'b0, br_suc_cnt };
                end
                endcase
            end
        end
    end

endmodule