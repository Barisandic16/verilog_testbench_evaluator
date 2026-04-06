module multi_8bit(
    input  [7:0] A,
    input  [7:0] B,
    output [15:0] product
);

    reg [15:0] prod;
    reg [15:0] shifted_a;
    integer i;

    always @(*) begin
        prod = 16'b0;
        shifted_a = {8'b0, A};
        for (i = 0; i < 8; i = i + 1) begin
            if (B[i])
                prod = prod + shifted_a;
            shifted_a = shifted_a << 1;
        end
    end

    assign product = prod;

endmodule