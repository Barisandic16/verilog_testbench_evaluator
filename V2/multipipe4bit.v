module multi_pipe_4bit #(
    parameter size = 4
)(
    input                       clk,
    input                       rst_n,
    input   [size-1:0]          mul_a,
    input   [size-1:0]          mul_b,
    output  reg [2*size-1:0]    mul_out
);

    // Extended input signals
    wire [2*size-1:0] mul_a_ext;
    wire [2*size-1:0] mul_b_ext;

    assign mul_a_ext = {{size{1'b0}}, mul_a};
    assign mul_b_ext = {{size{1'b0}}, mul_b};

    // Partial products
    wire [2*size-1:0] partial_product [size-1:0];

    genvar i;
    generate
        for (i = 0; i < size; i = i + 1) begin : gen_partial
            assign partial_product[i] = mul_b_ext[i] ? (mul_a_ext << i) : {(2*size){1'b0}};
        end
    endgenerate

    // Pipeline stage 1 registers: store pairwise sums of partial products
    reg [2*size-1:0] sum_reg0;  // partial_product[0] + partial_product[1]
    reg [2*size-1:0] sum_reg1;  // partial_product[2] + partial_product[3]

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_reg0 <= {(2*size){1'b0}};
            sum_reg1 <= {(2*size){1'b0}};
        end else begin
            sum_reg0 <= partial_product[0] + partial_product[1];
            sum_reg1 <= partial_product[2] + partial_product[3];
        end
    end

    // Pipeline stage 2 register: final product output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_out <= {(2*size){1'b0}};
        end else begin
            mul_out <= sum_reg0 + sum_reg1;
        end
    end

endmodule