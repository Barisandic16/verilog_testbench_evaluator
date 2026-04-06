module adder_pipe_64bit (
    input         clk,
    input         rst_n,
    input         i_en,
    input  [63:0] adda,
    input  [63:0] addb,
    output [64:0] result,
    output        o_en
);

    // Pipeline stage 1: bits [15:0]
    reg [16:0] sum_s1;       // 16-bit sum + carry out
    reg [47:0] adda_s1;      // remaining bits of A (63:16)
    reg [47:0] addb_s1;      // remaining bits of B (63:16)
    reg        en_s1;

    // Pipeline stage 2: bits [31:16]
    reg [32:0] sum_s2;       // accumulated 32-bit sum + carry out
    reg [31:0] adda_s2;      // remaining bits of A (63:32)
    reg [31:0] addb_s2;      // remaining bits of B (63:32)
    reg        en_s2;

    // Pipeline stage 3: bits [47:32]
    reg [48:0] sum_s3;       // accumulated 48-bit sum + carry out
    reg [15:0] adda_s3;      // remaining bits of A (63:48)
    reg [15:0] addb_s3;      // remaining bits of B (63:48)
    reg        en_s3;

    // Pipeline stage 4: bits [63:48]
    reg [64:0] sum_s4;       // final 65-bit result
    reg        en_s4;

    // Stage 1: Add bits [15:0]
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_s1  <= 17'b0;
            adda_s1 <= 48'b0;
            addb_s1 <= 48'b0;
            en_s1   <= 1'b0;
        end else begin
            sum_s1  <= {1'b0, adda[15:0]} + {1'b0, addb[15:0]};
            adda_s1 <= adda[63:16];
            addb_s1 <= addb[63:16];
            en_s1   <= i_en;
        end
    end

    // Stage 2: Add bits [31:16] with carry from stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_s2  <= 33'b0;
            adda_s2 <= 32'b0;
            addb_s2 <= 32'b0;
            en_s2   <= 1'b0;
        end else begin
            sum_s2[15:0]  <= sum_s1[15:0];
            sum_s2[32:16] <= {1'b0, adda_s1[15:0]} + {1'b0, addb_s1[15:0]} + sum_s1[16];
            adda_s2       <= adda_s1[47:16];
            addb_s2       <= addb_s1[47:16];
            en_s2         <= en_s1;
        end
    end

    // Stage 3: Add bits [47:32] with carry from stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_s3  <= 49'b0;
            adda_s3 <= 16'b0;
            addb_s3 <= 16'b0;
            en_s3   <= 1'b0;
        end else begin
            sum_s3[31:0]  <= sum_s2[31:0];
            sum_s3[48:32] <= {1'b0, adda_s2[15:0]} + {1'b0, addb_s2[15:0]} + sum_s2[32];
            adda_s3       <= adda_s2[31:16];
            addb_s3       <= addb_s2[31:16];
            en_s3         <= en_s2;
        end
    end

    // Stage 4: Add bits [63:48] with carry from stage 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_s4 <= 65'b0;
            en_s4  <= 1'b0;
        end else begin
            sum_s4[47:0]  <= sum_s3[47:0];
            sum_s4[64:48] <= {1'b0, adda_s3[15:0]} + {1'b0, addb_s3[15:0]} + sum_s3[48];
            en_s4         <= en_s3;
        end
    end

    assign result = sum_s4;
    assign o_en   = en_s4;

endmodule