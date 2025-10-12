module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 32,
    parameter POINTER_WIDTH = $clog2(DEPTH)
) (
    input clk, rst,

    // Write side
    input wr_en,
    input [WIDTH-1:0] din,
    output full,

    // Read side
    input rd_en,
    output [WIDTH-1:0] dout,
    output empty
);
    // Define variables
    reg [WIDTH-1:0] data [DEPTH-1:0];

    reg [POINTER_WIDTH:0] read_ptr; // Leave an extra bit for status flag
    reg [POINTER_WIDTH:0] write_ptr; // Leave an extra bit for status flag

    // Assign outputs
    assign full = (read_ptr[POINTER_WIDTH-1:0] == write_ptr[POINTER_WIDTH-1:0] && read_ptr[POINTER_WIDTH] == ~write_ptr[POINTER_WIDTH]);
    assign empty = (read_ptr == write_ptr);

    reg [WIDTH-1:0] dout_int;
    assign dout = dout_int;

    // Update
    always @(posedge clk) begin
        if (rst) begin
            read_ptr <= 'b0;
            write_ptr <= 'b0;
            dout_int <= 'b0;
        end else begin 
            if (rd_en && !empty) begin
                dout_int <= data[read_ptr[POINTER_WIDTH-1:0]];
                read_ptr <= read_ptr + 1;
            end

            if (wr_en && (!full || rd_en)) begin 
                data[write_ptr[POINTER_WIDTH-1:0]] <= din;
                write_ptr <= write_ptr + 1;
            end
        end
    end
    /*
    // System Verilog Assertions
    write_ptr_unchanged_when_full:
        assert
            property (
                @(posedge clk) disable iff (rst)
                (wr_en && full && !rd_en) |=> $stable(write_ptr)
            )
            else
                $error("%m write pointer changed when full!");
    read_ptr_unchanged_when_empty:
        assert
            property (
                @(posedge clk) disable iff (rst)
                (rd_en && empty) |=> $stable(read_ptr)
            )
            else
                $error("%m read pointer changed when empty!");
    read_write_are_zero_and_not_full_when_reset:
        assert
            property (
                @(posedge clk)
                (rst) |=> (read_ptr == 0 && write_ptr == 0 && !full)
            )
            else
                $error("%m read and write are not zero or full is high when reset!");
    */
endmodule
