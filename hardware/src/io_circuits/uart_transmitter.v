// module uart_transmitter #(
//     parameter CLOCK_FREQ = 125_000_000,
//     parameter BAUD_RATE = 115_200)
// (
//     input clk,
//     input reset,

//     input [7:0] data_in,
//     input data_in_valid,
//     output data_in_ready,

//     output serial_out
// );
//     // See diagram in the lab guide
//     localparam  SYMBOL_EDGE_TIME    =   CLOCK_FREQ / BAUD_RATE;
//     localparam  CLOCK_COUNTER_WIDTH =   $clog2(SYMBOL_EDGE_TIME);

//     // State registers
//     reg [1:0] state;
//     reg [1:0] next_state;
//     reg [2:0] data_idx;
//     reg [2:0] next_data_idx;
//     reg [CLOCK_COUNTER_WIDTH - 1:0] clock_counter;
//     reg [CLOCK_COUNTER_WIDTH - 1:0] next_clock_counter;
//     reg [7:0] data_in_copy;
//     reg [7:0] next_data_in_copy;
    
//     // State names
//     localparam IDLE = 2'b00;
//     localparam TRANSMITTING_START = 2'b01;
//     localparam TRANSMITTING_DATA = 2'b10;
//     localparam TRANSMITTING_STOP = 2'b11;

//     // Output regs
//     reg serial_out_int;
//     assign serial_out = serial_out_int;

//     reg data_in_ready_int;
//     assign data_in_ready = data_in_ready_int;

//     // State assignment
//     always @(posedge clk) begin
//         state <= next_state;
//         data_idx <= next_data_idx;
//         data_in_copy <= next_data_in_copy;
//         clock_counter <= next_clock_counter;
//     end

//     always @(*) begin

//         next_state = state;
//         next_data_idx = data_idx;
//         next_data_in_copy = data_in_copy;
//         next_clock_counter = clock_counter;
//         data_in_ready_int = 1'b1;

//         if (reset) begin
//             next_state = IDLE;
//             next_data_idx = 'b0;
//             next_data_in_copy = 'b0;
//             next_clock_counter = 'b0;
//             data_in_ready_int = 1'b1;
//             serial_out_int = 1'b1;
//         end else begin
//             case(state)
//                 IDLE: begin
//                     data_in_ready_int = 1'b1;
//                     serial_out_int = 1'b1;
//                     if (data_in_valid) begin
//                         next_clock_counter = 'b0;
//                         next_state = TRANSMITTING_START;
//                         next_data_in_copy = data_in;
//                     end
//                 end
//                 TRANSMITTING_START: begin
//                     data_in_ready_int = 1'b0;
//                     serial_out_int = 1'b0;
//                     if (clock_counter < SYMBOL_EDGE_TIME - 1) begin 
//                         next_clock_counter = clock_counter + 1;
//                     end else begin
//                         next_state = TRANSMITTING_DATA;
//                         next_clock_counter = 'b0;
//                     end
//                 end
//                 TRANSMITTING_DATA: begin
//                     data_in_ready_int = 1'b0;
//                     serial_out_int = data_in_copy[data_idx];
//                     if (clock_counter < SYMBOL_EDGE_TIME - 1) begin 
//                         next_clock_counter = clock_counter + 1;
//                     end else begin
//                         if (data_idx == 7) begin
//                             next_data_idx = 'b0;
//                             next_state = TRANSMITTING_STOP;
//                         end else begin
//                             next_data_idx = data_idx + 1;
//                         end
//                         next_clock_counter = 'b0;
//                     end
//                 end
//                 TRANSMITTING_STOP: begin
//                     data_in_ready_int = 1'b0;
//                     serial_out_int = 1'b1;
//                     next_data_in_copy = 'b0;
//                     if (clock_counter < SYMBOL_EDGE_TIME - 1) begin 
//                         next_clock_counter = clock_counter + 1;
//                     end else begin
//                         next_state = IDLE;
//                         next_clock_counter = 'b0;
//                     end
//                 end
//             endcase
//         end
//     end
//     /*
//     // SYSTEM VERILOG ASSERTIONS
//     serial_out_data_in_ready_high_on_idle:
//         assert
//             property (
//                 @(posedge clk) disable iff (reset)
//                 (state == IDLE) |-> (serial_out && data_in_ready)
//             )
//             else
//                 $error("%m serial_out and data_in_ready should be high when idle!");
//     data_in_ready_low_for_ten_cycles_when_transmitting:
//         assert
//             property (
//                 @(posedge clk) disable iff (reset)
//                 (state == TRANSMITTING_START) |=> (!data_in_ready)[*10]
//             )
//             else
//                 $error("%m data_in_ready should be low for exactly 10 cycles when transmitting!");
//     */
// endmodule

module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input reset,

    input [7:0] data_in,
    input data_in_valid,
    output reg data_in_ready,

    output reg serial_out
);

    localparam  SYMBOL_EDGE_TIME    =   CLOCK_FREQ / BAUD_RATE;
    localparam  CLOCK_COUNTER_WIDTH =   $clog2(SYMBOL_EDGE_TIME);
   
    reg [9:0] shift_reg = 0;
    reg [3:0] bits_remaining = 0;

    reg [CLOCK_COUNTER_WIDTH-1:0] symbol_edge_counter = 0;
    // wire symbol_edge_clk = symbol_edge_counter == 0;

    always @(posedge clk) begin
        if (bits_remaining > 0) begin
            data_in_ready <= 1'b0;
            serial_out <= shift_reg[0];
            if (symbol_edge_counter == SYMBOL_EDGE_TIME - 1) begin
                bits_remaining <= bits_remaining - 1;
                shift_reg <= { 1'b1, shift_reg[9:1] };
                symbol_edge_counter <= 0;
            end else begin
                symbol_edge_counter <= symbol_edge_counter + 1;
            end
        end else begin
            data_in_ready <= 1'b1;
            serial_out <= 1;
            if (data_in_valid) begin
                shift_reg <= { 1'b1, data_in, 1'b0 };
                bits_remaining <= 10;
                symbol_edge_counter <= 0;
                data_in_ready <= 1'b0;
            end
        end
    end

endmodule