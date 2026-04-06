module fixed_point_subtractor #(
    parameter Q = 15,
    parameter N = 32
)(
    input  [N-1:0] a,
    input  [N-1:0] b,
    output [N-1:0] c
);

    reg [N-1:0] res;

    assign c = res;

    always @(a, b) begin
        // Both positive
        if (a[N-1] == 0 && b[N-1] == 0) begin
            if (a >= b) begin
                res = a - b;
            end else begin
                res = b - a;
                res[N-1] = 1; // result is negative
            end
        end
        // Both negative
        else if (a[N-1] == 1 && b[N-1] == 1) begin
            if (a[N-2:0] > b[N-2:0]) begin
                // a more negative than b => a - b is negative
                res[N-2:0] = a[N-2:0] - b[N-2:0];
                res[N-1] = 1;
            end else begin
                // b more negative than a => a - b is positive
                res[N-2:0] = b[N-2:0] - a[N-2:0];
                res[N-1] = 0;
            end
        end
        // a positive, b negative => a - b = a + |b| (positive direction)
        else if (a[N-1] == 0 && b[N-1] == 1) begin
            res[N-2:0] = a[N-2:0] + b[N-2:0];
            res[N-1] = 0; // result is positive
        end
        // a negative, b positive => a - b = -(|a| + |b|) (negative direction)
        else begin
            res[N-2:0] = a[N-2:0] + b[N-2:0];
            res[N-1] = 1; // result is negative
        end

        // Handle zero: force sign bit to 0
        if (res[N-2:0] == 0)
            res[N-1] = 0;
    end

endmodule