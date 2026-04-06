module freq_divbyfrac (
    input  wire clk,
    input  wire rst_n,
    output wire clk_div
);

    parameter MUL2_DIV_CLK = 7;
    parameter HALF_PERIOD  = MUL2_DIV_CLK / 2; // 3

    reg [3:0] cnt_pos;
    reg [3:0] cnt_neg;
    reg       clk_pos;
    reg       clk_neg;

    // Positive edge counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt_pos <= 4'd0;
        else if (cnt_pos == MUL2_DIV_CLK - 1)
            cnt_pos <= 4'd0;
        else
            cnt_pos <= cnt_pos + 4'd1;
    end

    // Positive edge divided clock generation
    // High for counts 0..3 (4 cycles), low for counts 4..6 (3 cycles)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_pos <= 1'b0;
        else if (cnt_pos == 4'd0)
            clk_pos <= 1'b1;
        else if (cnt_pos == HALF_PERIOD + 1)
            clk_pos <= 1'b0;
    end

    // Negative edge counter
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt_neg <= 4'd0;
        else if (cnt_neg == MUL2_DIV_CLK - 1)
            cnt_neg <= 4'd0;
        else
            cnt_neg <= cnt_neg + 4'd1;
    end

    // Negative edge divided clock generation (phase-shifted by half input clock period)
    // High for counts 0..3 (4 cycles), low for counts 4..6 (3 cycles)
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_neg <= 1'b0;
        else if (cnt_neg == 4'd0)
            clk_neg <= 1'b1;
        else if (cnt_neg == HALF_PERIOD + 1)
            clk_neg <= 1'b0;
    end

    // OR the two phase-shifted clocks to produce the fractional divided output
    assign clk_div = clk_pos | clk_neg;

endmodule