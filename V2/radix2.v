module radix2_div (
    input        clk,
    input        rst,
    input        sign,
    input  [7:0] dividend,
    input  [7:0] divisor,
    input        opn_valid,
    output reg       res_valid,
    output reg [15:0] result
);

    reg [16:0] SR;          // Shift register: {partial_remainder, quotient_bits}
    reg  [8:0] NEG_DIVISOR; // Negated absolute divisor (9-bit for subtraction)
    reg  [8:0] cnt;         // One-hot counter (bit 8 signals completion)
    reg        start_cnt;   // Division in progress flag

    reg        dividend_sign; // Sign of original dividend
    reg        divisor_sign;  // Sign of original divisor
    reg  [7:0] abs_dividend;
    reg  [7:0] abs_divisor;

    wire [8:0] sub_result;  // Result of partial_remainder - abs_divisor
    wire       carry_out;   // 1 if partial_remainder >= abs_divisor

    // Subtraction: top 9 bits of SR + NEG_DIVISOR
    assign sub_result = SR[16:8] + NEG_DIVISOR;
    assign carry_out  = sub_result[8]; // Carry out means no borrow, i.e., >= divisor

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            SR           <= 17'd0;
            NEG_DIVISOR  <= 9'd0;
            cnt          <= 9'd0;
            start_cnt    <= 1'b0;
            res_valid    <= 1'b0;
            result       <= 16'd0;
            dividend_sign <= 1'b0;
            divisor_sign  <= 1'b0;
            abs_dividend  <= 8'd0;
            abs_divisor   <= 8'd0;
        end else begin
            // --- Operation Start ---
            if (opn_valid && !res_valid && !start_cnt) begin
                // Determine signs
                dividend_sign <= sign & dividend[7];
                divisor_sign  <= sign & divisor[7];

                // Compute absolute values
                abs_dividend <= (sign & dividend[7]) ? (~dividend + 1'b1) : dividend;
                abs_divisor  <= (sign & divisor[7])  ? (~divisor  + 1'b1) : divisor;

                // Initialize shift register: absolute dividend shifted left by 1
                // SR = {1'b0, abs_dividend, 0} -- 17 bits total
                SR <= {1'b0, ((sign & dividend[7]) ? (~dividend + 1'b1) : dividend), 1'b0};

                // NEG_DIVISOR = negated absolute divisor (9-bit two's complement)
                NEG_DIVISOR <= ~{1'b0, ((sign & divisor[7]) ? (~divisor + 1'b1) : divisor)} + 1'b1;

                cnt       <= 9'd1;
                start_cnt <= 1'b1;
            end

            // --- Division Process ---
            if (start_cnt) begin
                if (cnt[8]) begin
                    // Division complete
                    cnt       <= 9'd0;
                    start_cnt <= 1'b0;
                    res_valid <= 1'b1;

                    // Final remainder is in SR[16:9], quotient in SR[7:0]
                    // Apply sign correction
                    if (dividend_sign ^ divisor_sign) begin
                        // Quotient is negative
                        if (dividend_sign) begin
                            // Remainder takes sign of dividend
                            result <= {(~SR[16:9] + 1'b1), (~SR[7:0] + 1'b1)};
                        end else begin
                            result <= {SR[16:9], (~SR[7:0] + 1'b1)};
                        end
                    end else begin
                        if (dividend_sign) begin
                            // Both negative: quotient positive, remainder negative
                            result <= {(~SR[16:9] + 1'b1), SR[7:0]};
                        end else begin
                            result <= {SR[16:9], SR[7:0]};
                        end
                    end
                end else begin
                    // Increment counter
                    cnt <= {cnt[7:0], 1'b0}; // Shift left (one-hot advance)

                    // Perform subtraction and conditional update
                    if (carry_out) begin
                        // Subtraction successful: use sub_result, shift left, insert 1
                        SR <= {sub_result[7:0], SR[7:0], 1'b1};
                    end else begin
                        // Subtraction failed: keep SR, shift left, insert 0
                        SR <= {SR[15:0], 1'b0};
                    end
                end
            end

            // --- Clear res_valid when new operation starts or result consumed ---
            if (res_valid && opn_valid) begin
                res_valid <= 1'b0;
            end
        end
    end

endmodule