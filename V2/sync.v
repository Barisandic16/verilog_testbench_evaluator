module synchronizer (
    input        clk_a,
    input        clk_b,
    input        arstn,
    input        brstn,
    input  [3:0] data_in,
    input        data_en,
    output reg [3:0] dataout
);

    reg [3:0] data_reg;
    reg       en_data_reg;
    reg       en_clap_one;
    reg       en_clap_two;

    // Data Register - clk_a domain
    always @(posedge clk_a or negedge arstn) begin
        if (!arstn)
            data_reg <= 4'b0;
        else
            data_reg <= data_in;
    end

    // Enable Data Register - clk_a domain
    always @(posedge clk_a or negedge arstn) begin
        if (!arstn)
            en_data_reg <= 1'b0;
        else
            en_data_reg <= data_en;
    end

    // Enable Control Registers (2-FF synchronizer) - clk_b domain
    always @(posedge clk_b or negedge brstn) begin
        if (!brstn) begin
            en_clap_one <= 1'b0;
            en_clap_two <= 1'b0;
        end else begin
            en_clap_one <= en_data_reg;
            en_clap_two <= en_clap_one;
        end
    end

    // Output Assignment - clk_b domain
    always @(posedge clk_b or negedge brstn) begin
        if (!brstn)
            dataout <= 4'b0;
        else if (en_clap_two)
            dataout <= data_reg;
    end

endmodule