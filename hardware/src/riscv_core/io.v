module io (
    input clk,
    input [31:0] addr, wdata,
    input iorw,
    output reg [31:0] rdata,

    input br_inst, br_pred,

    input uart_rx_data_out_valid,
    output uart_rx_data_out_ready,
    input [7:0] uart_rx_data_out,

    output [7:0] uart_tx_data_in,
    output uart_tx_data_in_valid,
    input uart_tx_data_in_ready
);

reg [31:0] cycle_ctr, inst_ctr;
reg [31:0] br_inst_ctr, br_pred_ctr;

always @ (posedge clk) begin

    cycle_ctr <= cycle_ctr + 1;
    br_inst_ctr <= br_inst ? br_inst_ctr + 1 : br_inst_ctr;
    br_pred_ctr <= br_pred ? br_pred_ctr + 1 : br_pred_ctr;

    // TODO: verify data_out_ready logic
    uart_tx_data_in_valid <= 1'b0;
    uart_rx_data_out_ready <= 1'b0;

    case(addr)
        32'h80000000: begin
            rdata <= {30'b0, uart_rx_data_out_valid, uart_tx_data_in_ready};
        end
        32'h80000004: begin
            rdata <= {24'b0, uart_rx_data_out};
            uart_rx_data_out_ready <= 1'b1;
        end
        32'h80000008: begin
            uart_tx_data_in <= wdata[7:0];
            uart_tx_data_in_valid <= 1'b1;
        end
        32'h80000010: begin
            rdata <= cycle_ctr;
        end
        32'h80000014: begin
            rdata <= inst_ctr;
        end
        32'h80000018: begin
            cycle_ctr <= 0;
            inst_ctr <= 0;
        end
        32'h8000001c: begin
            rdata <= br_inst_ctr;
        end
        32'h80000020: begin
            rdata <= br_pred_ctr;
        end
    endcase

/*
32'h80000000: UART control	Read	{30'b0, uart_rx_data_out_valid, uart_tx_data_in_ready}
32'h80000004: UART receiver data	Read	{24'b0, uart_rx_data_out}
32'h80000008: UART transmitter data	Write	{24'b0, uart_tx_data_in}
32'h80000010: Cycle counter	Read	Clock cycles elapsed
32'h80000014: Instruction counter	Read	Number of instructions executed
32'h80000018: Reset counters to 0	Write	N/A
32'h8000001c: Total branch instruction counter	Read	Number of branch instructions encounted
32'h80000020: Correct branch prediction counter	Read	Number of branches successfully predicted
*/
end

endmodule