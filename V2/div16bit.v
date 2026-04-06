module div_16bit(
    input  [15:0] A,
    input  [7:0]  B,
    output [15:0] result,
    output [15:0] odd
);

    reg [15:0] a_reg;
    reg [7:0]  b_reg;
    reg [15:0] result_reg;
    reg [15:0] odd_reg;

    // First always block: register inputs
    always @(*) begin
        a_reg = A;
        b_reg = B;
    end

    // Second always block: iterative division
    always @(*) begin
        reg [15:0] temp_a;
        reg [15:0] temp_b;
        integer i;

        temp_a = a_reg;
        temp_b = {8'b0, b_reg};
        result_reg = 16'b0;
        odd_reg = 16'b0;

        for (i = 15; i >= 0; i = i - 1) begin
            odd_reg = odd_reg << 1;
            odd_reg[0] = temp_a[i];
            if (odd_reg >= temp_b) begin
                result_reg[i] = 1'b1;
                odd_reg = odd_reg - temp_b;
            end else begin
                result_reg[i] = 1'b0;
            end
        end
    end

    assign result = result_reg;
    assign odd    = odd_reg;

endmodule
