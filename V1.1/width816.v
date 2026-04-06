module width_8to16 (
    input        clk,
    input        rst_n,
    input        valid_in,
    input  [7:0] data_in,
    output reg       valid_out,
    output reg [15:0] data_out
);

    reg       flag;
    reg [7:0] data_lock;

    // flag toggles on each valid input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            flag <= 1'b0;
        else if (valid_in)
            flag <= ~flag;
    end

    // store first byte
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_lock <= 8'd0;
        else if (valid_in && !flag)
            data_lock <= data_in;
    end

    // output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            data_out  <= 16'd0;
        end else if (valid_in && flag) begin
            valid_out <= 1'b1;
            data_out  <= {data_lock, data_in};
        end else begin
            valid_out <= 1'b0;
            data_out  <= 16'd0;
        end
    end

endmodule