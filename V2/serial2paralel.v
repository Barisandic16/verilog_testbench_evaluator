module serial2parallel (
    input        clk,
    input        rst_n,
    input        din_serial,
    input        din_valid,
    output reg [7:0] dout_parallel,
    output reg       dout_valid
);

    reg [3:0] cnt;
    reg [7:0] shift_reg;

    // Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 4'd0;
        else if (din_valid) begin
            if (cnt == 4'd7)
                cnt <= 4'd0;
            else
                cnt <= cnt + 4'd1;
        end
    end

    // Shift register: MSB first
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= 8'd0;
        else if (din_valid)
            shift_reg <= {shift_reg[6:0], din_serial};
    end

    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_parallel <= 8'd0;
            dout_valid    <= 1'b0;
        end else if (din_valid && cnt == 4'd7) begin
            dout_parallel <= {shift_reg[6:0], din_serial};
            dout_valid    <= 1'b1;
        end else begin
            dout_valid <= 1'b0;
        end
    end

endmodule