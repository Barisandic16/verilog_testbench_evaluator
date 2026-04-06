module float_multi(
    input             clk,
    input             rst,
    input      [31:0] a,
    input      [31:0] b,
    output reg [31:0] z
);

    reg [2:0]  counter;
    reg [23:0] a_mantissa, b_mantissa, z_mantissa;
    reg [9:0]  a_exponent, b_exponent, z_exponent;
    reg        a_sign, b_sign, z_sign;
    reg [49:0] product;
    reg        guard_bit, round_bit, sticky;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 3'd0;
        end else begin
            case (counter)
                // --------------------------------------------------------
                // Cycle 0: Extract fields from IEEE-754 inputs
                // --------------------------------------------------------
                3'd0: begin
                    a_sign     <= a[31];
                    b_sign     <= b[31];
                    a_exponent <= {2'b0, a[30:23]};
                    b_exponent <= {2'b0, b[30:23]};
                    a_mantissa <= {1'b0, a[22:0]};
                    b_mantissa <= {1'b0, b[22:0]};
                    counter    <= 3'd1;
                end

                // --------------------------------------------------------
                // Cycle 1: Handle special cases (NaN, Inf, Zero, Denorm)
                //          and prepare normalized mantissas
                // --------------------------------------------------------
                3'd1: begin
                    z_sign <= a_sign ^ b_sign;

                    // --- a is NaN or Inf ---
                    if (a_exponent == 10'd255) begin
                        if (a_mantissa[22:0] != 23'd0) begin
                            // a is NaN -> result is NaN
                            z[31]    <= 1'b1;
                            z[30:23] <= 8'hFF;
                            z[22:0]  <= 23'h7FFFFF;
                            counter  <= 3'd0;
                        end else begin
                            // a is Inf
                            if ((b_exponent == 10'd0) && (b_mantissa[22:0] == 23'd0)) begin
                                // Inf * 0 = NaN
                                z[31]    <= 1'b1;
                                z[30:23] <= 8'hFF;
                                z[22:0]  <= 23'h7FFFFF;
                                counter  <= 3'd0;
                            end else begin
                                // Inf * finite or Inf * Inf = Inf
                                z[31]    <= a_sign ^ b_sign;
                                z[30:23] <= 8'hFF;
                                z[22:0]  <= 23'd0;
                                counter  <= 3'd0;
                            end
                        end
                    // --- b is NaN or Inf ---
                    end else if (b_exponent == 10'd255) begin
                        if (b_mantissa[22:0] != 23'd0) begin
                            // b is NaN -> result is NaN
                            z[31]    <= 1'b1;
                            z[30:23] <= 8'hFF;
                            z[22:0]  <= 23'h7FFFFF;
                            counter  <= 3'd0;
                        end else begin
                            // b is Inf
                            if ((a_exponent == 10'd0) && (a_mantissa[22:0] == 23'd0)) begin
                                // 0 * Inf = NaN
                                z[31]    <= 1'b1;
                                z[30:23] <= 8'hFF;
                                z[22:0]  <= 23'h7FFFFF;
                                counter  <= 3'd0;
                            end else begin
                                // finite * Inf = Inf
                                z[31]    <= a_sign ^ b_sign;
                                z[30:23] <= 8'hFF;
                                z[22:0]  <= 23'd0;
                                counter  <= 3'd0;
                            end
                        end
                    // --- a is zero or denormalized ---
                    end else if (a_exponent == 10'd0) begin
                        if (a_mantissa[22:0] == 23'd0) begin
                            // a is zero -> result is zero
                            z[31]    <= a_sign ^ b_sign;
                            z[30:23] <= 8'd0;
                            z[22:0]  <= 23'd0;
                            counter  <= 3'd0;
                        end else begin
                            // a is denormalized: keep implicit bit = 0, set exponent to 1
                            a_exponent <= 10'd1;
                            // mantissa already has leading 0 from extraction
                            counter <= 3'd2;
                        end
                    // --- b is zero or denormalized ---
                    end else if (b_exponent == 10'd0) begin
                        if (b_mantissa[22:0] == 23'd0) begin
                            // b is zero -> result is zero
                            z[31]    <= a_sign ^ b_sign;
                            z[30:23] <= 8'd0;
                            z[22:0]  <= 23'd0;
                            counter  <= 3'd0;
                        end else begin
                            // b is denormalized: keep implicit bit = 0, set exponent to 1
                            b_exponent <= 10'd1;
                            // a is normal: restore implicit leading 1
                            a_mantissa[23] <= 1'b1;
                            counter <= 3'd2;
                        end
                    end else begin
                        // Both a and b are normal numbers: restore implicit leading 1
                        a_mantissa[23] <= 1'b1;
                        b_mantissa[23] <= 1'b1;
                        counter <= 3'd2;
                    end
                end

                // --------------------------------------------------------
                // Cycle 2: Normalize denormalized mantissa (shift left
                //          until bit 23 is set), then perform multiplication
                // --------------------------------------------------------
                3'd2: begin
                    // Normalize a if denormalized
                    if (a_mantissa[23] == 1'b0) begin
                        a_mantissa <= a_mantissa << 1;
                        a_exponent <= a_exponent - 10'd1;
                    // Normalize b if denormalized
                    end else if (b_mantissa[23] == 1'b0) begin
                        b_mantissa <= b_mantissa << 1;
                        b_exponent <= b_exponent - 10'd1;
                    end else begin
                        // Both mantissas normalized — perform multiplication
                        // product is 48 bits (24 x 24), stored in 50-bit reg
                        product    <= a_mantissa * b_mantissa;
                        // Combined exponent: ea + eb - bias(127)
                        z_exponent <= a_exponent + b_exponent - 10'd127;
                        counter    <= 3'd3;
                    end
                end

                // --------------------------------------------------------
                // Cycle 3: Normalize product and extract rounding bits
                // --------------------------------------------------------
                3'd3: begin
                    // If product bit 47 is set, the product is in [2,4)
                    // so we need to shift right by 1 and increment exponent
                    if (product[47] == 1'b1) begin
                        z_mantissa <= product[47:24];
                        guard_bit  <= product[23];
                        round_bit  <= product[22];
                        sticky     <= |product[21:0];
                        z_exponent <= z_exponent + 10'd1;
                    end else begin
                        // product is in [1,2), already normalized
                        z_mantissa <= product[46:23];
                        guard_bit  <= product[22];
                        round_bit  <= product[21];
                        sticky     <= |product[20:0];
                    end
                    counter <= 3'd4;
                end

                // --------------------------------------------------------
                // Cycle 4: Rounding (round-to-nearest-even) and
                //          overflow/underflow handling, output generation
                // --------------------------------------------------------
                3'd4: begin
                    // Round to nearest even
                    if (guard_bit && (round_bit | sticky | z_mantissa[0])) begin
                        z_mantissa <= z_mantissa + 24'd1;
                        // Check if rounding caused mantissa overflow (carry out)
                        if (z_mantissa == 24'hFFFFFF) begin
                            z_exponent <= z_exponent + 10'd1;
                        end
                    end
                    counter <= 3'd5;
                end

                3'd5: begin
                    // Overflow -> Infinity
                    if (z_exponent >= 10'd255) begin
                        z[31]    <= z_sign;
                        z[30:23] <= 8'hFF;
                        z[22:0]  <= 23'd0;
                    // Underflow -> Zero (exponent <= 0 after bias removal)
                    end else if (z_exponent <= 10'd0) begin
                        z[31]    <= z_sign;
                        z[30:23] <= 8'd0;
                        z[22:0]  <= 23'd0;
                    end else begin
                        // Normal result: strip implicit leading 1
                        z[31]    <= z_sign;
                        z[30:23] <= z_exponent[7:0];
                        z[22:0]  <= z_mantissa[22:0];
                    end
                    counter <= 3'd0;
                end

                default: begin
                    counter <= 3'd0;
                end
            endcase
        end
    end

endmodule