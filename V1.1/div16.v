module div_16bit(
    input  [15:0] A,
    input  [7:0]  B,
    output [15:0] result,
    output [15:0] odd
);

    reg [15:0] a_reg;
    reg [7:0]  b_reg;
    reg [15:0] temp_a;
    reg [15:0] temp_b;
    reg [15:0] quotient;
    reg [15:0] remainder;

    // First always block: register inputs
    always @(*) begin
        a_reg = A;
        b_reg = B;
    end

    // Second always block: iterative shift-subtract division
    always @(*) begin
        temp_a = a_reg;
        temp_b = {8'b0, b_reg};
        quotient = 16'b0;
        remainder = 16'b0;

        // Bit 15
        remainder = {15'b0, temp_a[15]};
        if (remainder >= temp_b) begin
            quotient[15] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[15] = 1'b0;
        end

        // Bit 14
        remainder = {remainder[14:0], temp_a[14]};
        if (remainder >= temp_b) begin
            quotient[14] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[14] = 1'b0;
        end

        // Bit 13
        remainder = {remainder[14:0], temp_a[13]};
        if (remainder >= temp_b) begin
            quotient[13] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[13] = 1'b0;
        end

        // Bit 12
        remainder = {remainder[14:0], temp_a[12]};
        if (remainder >= temp_b) begin
            quotient[12] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[12] = 1'b0;
        end

        // Bit 11
        remainder = {remainder[14:0], temp_a[11]};
        if (remainder >= temp_b) begin
            quotient[11] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[11] = 1'b0;
        end

        // Bit 10
        remainder = {remainder[14:0], temp_a[10]};
        if (remainder >= temp_b) begin
            quotient[10] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[10] = 1'b0;
        end

        // Bit 9
        remainder = {remainder[14:0], temp_a[9]};
        if (remainder >= temp_b) begin
            quotient[9] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[9] = 1'b0;
        end

        // Bit 8
        remainder = {remainder[14:0], temp_a[8]};
        if (remainder >= temp_b) begin
            quotient[8] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[8] = 1'b0;
        end

        // Bit 7
        remainder = {remainder[14:0], temp_a[7]};
        if (remainder >= temp_b) begin
            quotient[7] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[7] = 1'b0;
        end

        // Bit 6
        remainder = {remainder[14:0], temp_a[6]};
        if (remainder >= temp_b) begin
            quotient[6] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[6] = 1'b0;
        end

        // Bit 5
        remainder = {remainder[14:0], temp_a[5]};
        if (remainder >= temp_b) begin
            quotient[5] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[5] = 1'b0;
        end

        // Bit 4
        remainder = {remainder[14:0], temp_a[4]};
        if (remainder >= temp_b) begin
            quotient[4] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[4] = 1'b0;
        end

        // Bit 3
        remainder = {remainder[14:0], temp_a[3]};
        if (remainder >= temp_b) begin
            quotient[3] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[3] = 1'b0;
        end

        // Bit 2
        remainder = {remainder[14:0], temp_a[2]};
        if (remainder >= temp_b) begin
            quotient[2] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[2] = 1'b0;
        end

        // Bit 1
        remainder = {remainder[14:0], temp_a[1]};
        if (remainder >= temp_b) begin
            quotient[1] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[1] = 1'b0;
        end

        // Bit 0
        remainder = {remainder[14:0], temp_a[0]};
        if (remainder >= temp_b) begin
            quotient[0] = 1'b1;
            remainder = remainder - temp_b;
        end else begin
            quotient[0] = 1'b0;
        end
    end

    assign result = quotient;
    assign odd    = remainder;

endmodule