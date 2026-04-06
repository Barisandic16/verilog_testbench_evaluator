module edge_detect (
    input  clk,
    input  rst_n,
    input  a,
    output rise,
    output down
);

    reg a_delay;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            a_delay <= 1'b0;
        else
            a_delay <= a;
    end

    assign rise = ~a_delay & a;
    assign down = a_delay & ~a;

endmodule