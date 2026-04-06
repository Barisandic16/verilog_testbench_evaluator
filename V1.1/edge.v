module edge_detect (
    input  clk,
    input  rst_n,
    input  a,
    output rise,
    output down
);

    reg a_prev;

    // Store the previous value of 'a'
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            a_prev <= 1'b0;
        else
            a_prev <= a;
    end

    // Rising edge: a was 0, now is 1
    assign rise = ~a_prev & a;
    // Falling edge: a was 1, now is 0
    assign down = a_prev & ~a;

endmodule