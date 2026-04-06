module comparator_4bit (
    input  [3:0] A,
    input  [3:0] B,
    output       A_greater,
    output       A_equal,
    output       A_less
);

    wire [4:0] sub_result;

    assign sub_result = {1'b0, A} - {1'b0, B};

    assign A_less    = sub_result[4];
    assign A_equal   = ~sub_result[4] & (sub_result[3:0] == 4'b0000);
    assign A_greater = ~sub_result[4] & (sub_result[3:0] != 4'b0000);

endmodule