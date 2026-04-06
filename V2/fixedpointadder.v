module fixed_point_adder #(
    parameter Q = 15,
    parameter N = 32
) (
    input  [N-1:0] a,
    input  [N-1:0] b,
    output [N-1:0] c
);

    reg [N-1:0] res;

    assign c = res;

    always @(a, b) begin
        if (a[N-1] == b[N-1]) begin
            // Same sign: add absolute values, keep the sign
            res[N-2:0] = a[N-2:0] + b[N-2:0];
            res[N-1]   = a[N-1];
        end else begin
            // Different signs: subtract smaller absolute value from larger
            if (a[N-2:0] > b[N-2:0]) begin
                res[N-2:0] = a[N-2:0] - b[N-2:0];
                res[N-1]   = a[N-1];
            end else begin
                res[N-2:0] = b[N-2:0] - a[N-2:0];
                if (res[N-2:0] == 0)
                    res[N-1] = 1'b0;
                else
                    res[N-1] = b[N-1];
            end
        end
    end

endmodule