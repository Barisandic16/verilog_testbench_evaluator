module radix2_div (
    input            clk,
    input            rst,
    input            sign,
    input      [7:0] dividend,
    input      [7:0] divisor,
    input            opn_valid,
    output reg       res_valid,
    output reg [15:0] result
);

    reg [16:0] SR;           // 17-bit shift register
    reg [8:0]  NEG_DIVISOR;  // negated absolute divisor (9-bit two's complement)
    reg [7:0]  cnt;          // one-hot counter (bit 7 set = 8th iteration)
    reg        start_cnt;    // division-in-progress flag

    reg        dividend_sign;
    reg        divisor_sign;

    // Absolute values for signed operands
    wire [7:0] abs_dividend = (sign && dividend[7]) ? (~dividend + 1'b1) : dividend;
    wire [7:0] abs_divisor  = (sign && divisor[7])  ? (~divisor  + 1'b1) : divisor;

    // Trial subtraction: SR[16:8] + NEG_DIVISOR, using 10 bits to capture carry
    wire [9:0] sub_full = {1'b0, SR[16:8]} + {1'b0, NEG_DIVISOR};
    wire       carry_out  = sub_full[9]; // 1 => subtraction succeeded (remainder >= 0)

    // Restoring mux: use subtracted value if successful, else keep original
    wire [8:0] mux_out = carry_out ? sub_full[8:0] : SR[16:8];

    always @(posedge clk) begin
        if (rst) begin
            SR            <= 17'd0;
            NEG_DIVISOR   <= 9'd0;
            cnt           <= 8'd0;
            start_cnt     <= 1'b0;
            res_valid     <= 1'b0;
            result        <= 16'd0;
            dividend_sign <= 1'b0;
            divisor_sign  <= 1'b0;
        end else begin

            // -----------------------------------------------------------
            // Operation Start
            // -----------------------------------------------------------
            if (opn_valid && !res_valid) begin
                dividend_sign <= sign & dividend[7];
                divisor_sign  <= sign & divisor[7];

                // SR initialised with abs(dividend) shifted left by 1
                SR          <= {9'd0, abs_dividend} << 1;
                // NEG_DIVISOR = two's complement negation of {0, abs_divisor}
                NEG_DIVISOR <= ~{1'b0, abs_divisor} + 1'b1;

                cnt       <= 8'd1;
                start_cnt <= 1'b1;
                res_valid <= 1'b0;
            end

            // -----------------------------------------------------------
            // Division Process (iterative radix-2 restoring division)
            // -----------------------------------------------------------
            if (start_cnt) begin
                if (cnt[7]) begin
                    // 8th (final) iteration — division complete
                    cnt       <= 8'd0;
                    start_cnt <= 1'b0;

                    begin : FINAL_CALC
                        reg [7:0] q;
                        reg [7:0] r;

                        // quotient: accumulated quotient bits {SR[7:1]} plus final carry
                        q = {SR[7:1], carry_out};
                        // remainder: final restored/subtracted upper bits
                        r = mux_out[7:0];

                        // Sign correction for signed division
                        if (dividend_sign ^ divisor_sign)
                            q = ~q + 1'b1;
                        if (dividend_sign)
                            r = ~r + 1'b1;

                        result <= {r, q};
                    end

                    res_valid <= 1'b1;

                end else begin
                    // Not yet done — update SR and advance counter
                    cnt <= cnt << 1;
                    // {mux_out[7:0], SR[7:1], carry_out, 1'b0}
                    // Upper 8 bits: restored/subtracted remainder
                    // Middle 7 bits: old quotient bits shifted
                    // carry_out: new quotient bit
                    // 0: placeholder for next iteration's shift-in
                    SR  <= {mux_out[7:0], SR[7:1], carry_out, 1'b0};
                end
            end

            // -----------------------------------------------------------
            // Result consumed — clear valid flag
            // -----------------------------------------------------------
            if (res_valid && opn_valid) begin
                res_valid <= 1'b0;
            end

        end
    end

endmodule