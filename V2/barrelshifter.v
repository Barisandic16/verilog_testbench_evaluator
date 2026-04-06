module mux2X1(
    input a,
    input b,
    input sel,
    output out
);
    assign out = sel ? b : a;
endmodule

module barrel_shifter(
    input  [7:0] in,
    input  [2:0] ctrl,
    output [7:0] out
);
    wire [7:0] stage1, stage2;

    // Stage 1: shift by 4 if ctrl[2] is high
    mux2X1 mux_s1_0 (.a(in[0]), .b(in[4]), .sel(ctrl[2]), .out(stage1[0]));
    mux2X1 mux_s1_1 (.a(in[1]), .b(in[5]), .sel(ctrl[2]), .out(stage1[1]));
    mux2X1 mux_s1_2 (.a(in[2]), .b(in[6]), .sel(ctrl[2]), .out(stage1[2]));
    mux2X1 mux_s1_3 (.a(in[3]), .b(in[7]), .sel(ctrl[2]), .out(stage1[3]));
    mux2X1 mux_s1_4 (.a(in[4]), .b(in[0]), .sel(ctrl[2]), .out(stage1[4]));
    mux2X1 mux_s1_5 (.a(in[5]), .b(in[1]), .sel(ctrl[2]), .out(stage1[5]));
    mux2X1 mux_s1_6 (.a(in[6]), .b(in[2]), .sel(ctrl[2]), .out(stage1[6]));
    mux2X1 mux_s1_7 (.a(in[7]), .b(in[3]), .sel(ctrl[2]), .out(stage1[7]));

    // Stage 2: shift by 2 if ctrl[1] is high
    mux2X1 mux_s2_0 (.a(stage1[0]), .b(stage1[2]), .sel(ctrl[1]), .out(stage2[0]));
    mux2X1 mux_s2_1 (.a(stage1[1]), .b(stage1[3]), .sel(ctrl[1]), .out(stage2[1]));
    mux2X1 mux_s2_2 (.a(stage1[2]), .b(stage1[4]), .sel(ctrl[1]), .out(stage2[2]));
    mux2X1 mux_s2_3 (.a(stage1[3]), .b(stage1[5]), .sel(ctrl[1]), .out(stage2[3]));
    mux2X1 mux_s2_4 (.a(stage1[4]), .b(stage1[6]), .sel(ctrl[1]), .out(stage2[4]));
    mux2X1 mux_s2_5 (.a(stage1[5]), .b(stage1[7]), .sel(ctrl[1]), .out(stage2[5]));
    mux2X1 mux_s2_6 (.a(stage1[6]), .b(stage1[0]), .sel(ctrl[1]), .out(stage2[6]));
    mux2X1 mux_s2_7 (.a(stage1[7]), .b(stage1[1]), .sel(ctrl[1]), .out(stage2[7]));

    // Stage 3: shift by 1 if ctrl[0] is high
    mux2X1 mux_s3_0 (.a(stage2[0]), .b(stage2[1]), .sel(ctrl[0]), .out(out[0]));
    mux2X1 mux_s3_1 (.a(stage2[1]), .b(stage2[2]), .sel(ctrl[0]), .out(out[1]));
    mux2X1 mux_s3_2 (.a(stage2[2]), .b(stage2[3]), .sel(ctrl[0]), .out(out[2]));
    mux2X1 mux_s3_3 (.a(stage2[3]), .b(stage2[4]), .sel(ctrl[0]), .out(out[3]));
    mux2X1 mux_s3_4 (.a(stage2[4]), .b(stage2[5]), .sel(ctrl[0]), .out(out[4]));
    mux2X1 mux_s3_5 (.a(stage2[5]), .b(stage2[6]), .sel(ctrl[0]), .out(out[5]));
    mux2X1 mux_s3_6 (.a(stage2[6]), .b(stage2[7]), .sel(ctrl[0]), .out(out[6]));
    mux2X1 mux_s3_7 (.a(stage2[7]), .b(stage2[0]), .sel(ctrl[0]), .out(out[7]));

endmodule