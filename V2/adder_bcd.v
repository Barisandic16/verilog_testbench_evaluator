module adder_bcd(
    input  [3:0] A,
    input  [3:0] B,
    input        Cin,
    output [3:0] Sum,
    output       Cout
);

    wire [4:0] binary_sum;
    wire [4:0] corrected_sum;
    wire       needs_correction;

    assign binary_sum = A + B + Cin;
    assign needs_correction = (binary_sum > 4'd9);
    assign corrected_sum = needs_correction ? (binary_sum + 4'd6) : binary_sum;
    assign Sum  = corrected_sum[3:0];
    assign Cout = needs_correction;

endmodule