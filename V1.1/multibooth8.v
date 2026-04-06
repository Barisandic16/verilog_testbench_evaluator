module multi_booth_8bit(
    input        clk,
    input        reset,
    input  [7:0] a,
    input  [7:0] b,
    output [15:0] p,
    output       rdy
);

    reg [15:0] multiplier;
    reg [15:0] multiplicand;
    reg [15:0] p_reg;
    reg [4:0]  ctr;
    reg        rdy_reg;

    assign p   = p_reg;
    assign rdy = rdy_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ctr         <= 5'b0;
            rdy_reg     <= 1'b0;
            p_reg       <= 16'b0;
            multiplier  <= {{8{a[7]}}, a};
            multiplicand <= {{8{b[7]}}, b};
        end else begin
            if (ctr < 16) begin
                if (multiplier[ctr] == 1'b1) begin
                    p_reg <= p_reg + multiplicand;
                end
                multiplicand <= multiplicand << 1;
                ctr <= ctr + 1;
            end else begin
                rdy_reg <= 1'b1;
            end
        end
    end

endmodule