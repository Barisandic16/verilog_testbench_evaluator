// 4-bit Carry Lookahead Adder
module cla_4bit(
    input  [4:1] A,
    input  [4:1] B,
    input        Cin,
    output [4:1] S,
    output       Cout,
    output       PG,  // Group propagate
    output       GG   // Group generate
);
    wire [4:1] P, G;
    wire [4:0] C;

    assign C[0] = Cin;

    // Bitwise propagate and generate
    assign P = A ^ B;
    assign G = A & B;

    // Carry lookahead logic
    assign C[1] = G[1] | (P[1] & C[0]);
    assign C[2] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & C[0]);
    assign C[3] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & C[0]);
    assign C[4] = G[4] | (P[4] & G[3]) | (P[4] & P[3] & G[2]) | (P[4] & P[3] & P[2] & G[1]) | (P[4] & P[3] & P[2] & P[1] & C[0]);

    assign S    = P ^ C[3:0];
    assign Cout = C[4];

    // Group propagate and generate for higher-level lookahead
    assign PG = P[4] & P[3] & P[2] & P[1];
    assign GG = G[4] | (P[4] & G[3]) | (P[4] & P[3] & G[2]) | (P[4] & P[3] & P[2] & G[1]);
endmodule


// 16-bit CLA using four 4-bit CLA blocks + second-level lookahead
module cla_16bit(
    input  [16:1] A,
    input  [16:1] B,
    input         Cin,
    output [16:1] S,
    output        Cout,
    output        PG,
    output        GG
);
    wire [3:0] pg, gg;
    wire [4:0] C;

    assign C[0] = Cin;

    // Second-level carry lookahead
    assign C[1] = gg[0] | (pg[0] & C[0]);
    assign C[2] = gg[1] | (pg[1] & gg[0]) | (pg[1] & pg[0] & C[0]);
    assign C[3] = gg[2] | (pg[2] & gg[1]) | (pg[2] & pg[1] & gg[0]) | (pg[2] & pg[1] & pg[0] & C[0]);
    assign C[4] = gg[3] | (pg[3] & gg[2]) | (pg[3] & pg[2] & gg[1]) | (pg[3] & pg[2] & pg[1] & gg[0]) | (pg[3] & pg[2] & pg[1] & pg[0] & C[0]);

    cla_4bit u0(.A(A[ 4: 1]), .B(B[ 4: 1]), .Cin(C[0]), .S(S[ 4: 1]), .Cout(), .PG(pg[0]), .GG(gg[0]));
    cla_4bit u1(.A(A[ 8: 5]), .B(B[ 8: 5]), .Cin(C[1]), .S(S[ 8: 5]), .Cout(), .PG(pg[1]), .GG(gg[1]));
    cla_4bit u2(.A(A[12: 9]), .B(B[12: 9]), .Cin(C[2]), .S(S[12: 9]), .Cout(), .PG(pg[2]), .GG(gg[2]));
    cla_4bit u3(.A(A[16:13]), .B(B[16:13]), .Cin(C[3]), .S(S[16:13]), .Cout(), .PG(pg[3]), .GG(gg[3]));

    assign Cout = C[4];
    assign PG   = pg[3] & pg[2] & pg[1] & pg[0];
    assign GG   = gg[3] | (pg[3] & gg[2]) | (pg[3] & pg[2] & gg[1]) | (pg[3] & pg[2] & pg[1] & gg[0]);
endmodule


// Top-level 32-bit adder using two 16-bit CLA blocks + third-level lookahead
module adder_32bit(
    input  [32:1] A,
    input  [32:1] B,
    output [32:1] S,
    output        C32
);
    wire [1:0] pg, gg;
    wire       c16;

    // Third-level carry lookahead (Cin = 0)
    assign c16 = gg[0];
    assign C32 = gg[1] | (pg[1] & gg[0]);

    cla_16bit u0(
        .A(A[16: 1]), .B(B[16: 1]), .Cin(1'b0),
        .S(S[16: 1]), .Cout(),
        .PG(pg[0]),   .GG(gg[0])
    );

    cla_16bit u1(
        .A(A[32:17]), .B(B[32:17]), .Cin(c16),
        .S(S[32:17]), .Cout(),
        .PG(pg[1]),   .GG(gg[1])
    );
endmodule
