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
    reg [15:0] sum_stage1;
    reg        carry_stage1;
    reg [47:0] adda_stage1;  // remaining bits of adda [63:16]
    reg [47:0] addb_stage1;  // remaining bits of addb [63:16]
    reg        en_stage1;

    // Pipeline stage 2: bits [31:16]
    reg [31:0] sum_stage2;
    reg        carry_stage2;
    reg [31:0] adda_stage2;  // remaining bits of adda [63:32]
    reg [31:0] addb_stage2;  // remaining bits of addb [63:32]
    reg        en_stage2;

    // Pipeline stage 3: bits [47:32]
    reg [47:0] sum_stage3;
    reg        carry_stage3;
    reg [15:0] adda_stage3;  // remaining bits of adda [63:48]
    reg [15:0] addb_stage3;  // remaining bits of addb [63:48]
    reg        en_stage3;

    // Pipeline stage 4: bits [63:48] + final carry
    reg [64:0] sum_stage4;
    reg        en_stage4;

    // Stage 1: Add bits [15:0]
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage1   <= 16'b0;
            carry_stage1 <= 1'b0;
            adda_stage1  <= 48'b0;
            addb_stage1  <= 48'b0;
            en_stage1    <= 1'b0;
        end else begin
            {carry_stage1, sum_stage1} <= adda[15:0] + addb[15:0];
            adda_stage1 <= adda[63:16];
            addb_stage1 <= addb[63:16];
            en_stage1   <= i_en;
        end
    end

    // Stage 2: Add bits [31:16] with carry from stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage2   <= 32'b0;
            carry_stage2 <= 1'b0;
            adda_stage2  <= 32'b0;
            addb_stage2  <= 32'b0;
            en_stage2    <= 1'b0;
        end else begin
            {carry_stage2, sum_stage2[31:16]} <= adda_stage1[15:0] + addb_stage1[15:0] + carry_stage1;
            sum_stage2[15:0] <= sum_stage1;
            adda_stage2 <= adda_stage1[47:16];
            addb_stage2 <= addb_stage1[47:16];
            en_stage2   <= en_stage1;
        end
    end

    // Stage 3: Add bits [47:32] with carry from stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage3   <= 48'b0;
            carry_stage3 <= 1'b0;
            adda_stage3  <= 16'b0;
            addb_stage3  <= 16'b0;
            en_stage3    <= 1'b0;
        end else begin
            {carry_stage3, sum_stage3[47:32]} <= adda_stage2[15:0] + addb_stage2[15:0] + carry_stage2;
            sum_stage3[31:0] <= sum_stage2;
            adda_stage3 <= adda_stage2[31:16];
            addb_stage3 <= addb_stage2[31:16];
            en_stage3   <= en_stage2;
        end
    end

    // Stage 4: Add bits [63:48] with carry from stage 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage4 <= 65'b0;
            en_stage4  <= 1'b0;
        end else begin
            sum_stage4[47:0]  <= sum_stage3;
            sum_stage4[64:48] <= adda_stage3 + addb_stage3 + carry_stage3;
            en_stage4         <= en_stage3;
        end
    end

    // Output assignments
    assign result = sum_stage4;
    assign o_en   = en_stage4;

endmodule