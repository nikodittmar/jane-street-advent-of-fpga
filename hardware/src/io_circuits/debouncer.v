module debouncer #(
    parameter WIDTH              = 1,
    parameter SAMPLE_CNT_MAX     = 62500,
    parameter PULSE_CNT_MAX      = 200,
    parameter WRAPPING_CNT_WIDTH = $clog2(SAMPLE_CNT_MAX),
    parameter SAT_CNT_WIDTH      = $clog2(PULSE_CNT_MAX) + 1
) (
    input clk,
    input [WIDTH-1:0] glitchy_signal,
    output reg [WIDTH-1:0] debounced_signal
);
    // Sample Pulse Generator
    reg sample_pulse = 1'b0;
    reg [WRAPPING_CNT_WIDTH - 1:0] sample_cnt = 1'b0;

    always @(posedge clk) begin
        if (sample_cnt < SAMPLE_CNT_MAX - 1) begin
            sample_pulse <= 1'b0;
            sample_cnt <= sample_cnt + 1'b1;
        end else begin
            sample_pulse <= 1'b1;
            sample_cnt <= 1'b0;
        end
    end

    // Saturating Counter
    genvar i;

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            reg [SAT_CNT_WIDTH - 1:0] pulse_cnt = 1'b0;

            always @(posedge clk) begin 
                if (sample_pulse == 1) begin
                    if (glitchy_signal[i] == 1) begin
                        if (pulse_cnt < PULSE_CNT_MAX - 1) begin
                            pulse_cnt <= pulse_cnt + 1'b1;
                        end else begin 
                            debounced_signal[i] <= 1'b1;
                        end
                    end else begin
                        pulse_cnt <= 1'b0;
                        debounced_signal[i] <= 1'b0;
                    end
                end
            end
        end
    endgenerate
endmodule
