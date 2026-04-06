module ring_counter (
    input        clk,
    input        reset,
    output [7:0] out
);

    reg [7:0] out_reg;

    always @(posedge clk) begin
        if (reset)
            out_reg <= 8'b0000_0001;
        else
            out_reg <= {out_reg[6:0], out_reg[7]};
    end

    assign out = out_reg;

endmodule