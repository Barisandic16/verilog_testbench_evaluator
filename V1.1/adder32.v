// ============================================================================
// 32-bit Carry-Lookahead Adder (CLA)
// Hierarchy: 4-bit CLA -> 16-bit CLA (using CLA lookahead unit) -> 32-bit top
// ============================================================================

// ----------------------------------------------------------------------------
// 4-bit CLA Block
// The fundamental building block. Computes sum, group generate (Gg) and
// group propagate (Gp) for a 4-bit slice.
// ----------------------------------------------------------------------------
module cla_4bit (
    input  [4:1] A,
    input  [4:1] B,
    input        Cin,
    output [4:1] S,
    output       Cout,
    output       Gg,   // Group generate
    output       Gp    // Group propagate
);

    wire [4:1] g, p;   // Bit-level generate and propagate
    wire [4:0] c;      // Internal carries

    // Bit-level generate and propagate
    assign g = A & B;
    assign p = A ^ B;

    // Carry chain via lookahead equations
    assign c[0] = Cin;
    assign c[1] = g[1] | (p[1] & c[0]);
    assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & c[0]);
    assign c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1])
                       | (p[3] & p[2] & p[1] & c[0]);
    assign c[4] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2])
                       | (p[4] & p[3] & p[2] & g[1])
                       | (p[4] & p[3] & p[2] & p[1] & c[0]);

    // Sum
    assign S = p ^ c[3:0];

    // Carry out
    assign Cout = c[4];

    // Group generate and propagate (for higher-level lookahead)
    assign Gg = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2])
                     | (p[4] & p[3] & p[2] & g[1]);
    assign Gp = p[4] & p[3] & p[2] & p[1];

endmodule


// ----------------------------------------------------------------------------
// Carry-Lookahead Unit (CLU)
// Accepts group generate/propagate from four 4-bit blocks and computes
// the carry inputs for each block using second-level lookahead.
// Also produces the overall group generate and propagate.
// ----------------------------------------------------------------------------
module carry_lookahead_unit (
    input  [4:1] Gg,   // Group generates from four blocks
    input  [4:1] Gp,   // Group propagates from four blocks
    input        Cin,
    output [4:1] Cout,  // Carry-in to each of the four blocks (block 1 uses Cin)
    output       Ggo,   // Overall group generate
    output       Gpo    // Overall group propagate
);

    // Second-level lookahead carry equations
    // Cout[1] = carry into block 2
    assign Cout[1] = Gg[1] | (Gp[1] & Cin);

    // Cout[2] = carry into block 3
    assign Cout[2] = Gg[2] | (Gp[2] & Gg[1]) | (Gp[2] & Gp[1] & Cin);

    // Cout[3] = carry into block 4
    assign Cout[3] = Gg[3] | (Gp[3] & Gg[2]) | (Gp[3] & Gp[2] & Gg[1])
                           | (Gp[3] & Gp[2] & Gp[1] & Cin);

    // Cout[4] = carry out of the entire 16-bit block
    assign Cout[4] = Gg[4] | (Gp[4] & Gg[3]) | (Gp[4] & Gp[3] & Gg[2])
                           | (Gp[4] & Gp[3] & Gp[2] & Gg[1])
                           | (Gp[4] & Gp[3] & Gp[2] & Gp[1] & Cin);

    // Overall group generate and propagate
    assign Ggo = Gg[4] | (Gp[4] & Gg[3]) | (Gp[4] & Gp[3] & Gg[2])
                       | (Gp[4] & Gp[3] & Gp[2] & Gg[1]);
    assign Gpo = Gp[4] & Gp[3] & Gp[2] & Gp[1];

endmodule


// ----------------------------------------------------------------------------
// 16-bit CLA Block
// Combines four 4-bit CLA blocks with a Carry-Lookahead Unit.
// ----------------------------------------------------------------------------
module cla_16bit (
    input  [16:1] A,
    input  [16:1] B,
    input         Cin,
    output [16:1] S,
    output        Cout,
    output        Gg,   // Group generate (for third-level lookahead)
    output        Gp    // Group propagate
);

    wire [4:1] block_Gg, block_Gp;
    wire [4:1] block_Cout;
    wire [4:1] carry_in;

    // Carry inputs: block 1 gets Cin, blocks 2-4 get lookahead carries
    assign carry_in[1] = Cin;
    assign carry_in[2] = block_Cout[1];
    assign carry_in[3] = block_Cout[2];
    assign carry_in[4] = block_Cout[3];

    // Instantiate four 4-bit CLA blocks
    cla_4bit u_cla4_1 (
        .A    (A[4:1]),
        .B    (B[4:1]),
        .Cin  (carry_in[1]),
        .S    (S[4:1]),
        .Cout (),               // Not used; CLU provides carries
        .Gg   (block_Gg[1]),
        .Gp   (block_Gp[1])
    );

    cla_4bit u_cla4_2 (
        .A    (A[8:5]),
        .B    (B[8:5]),
        .Cin  (carry_in[2]),
        .S    (S[8:5]),
        .Cout (),
        .Gg   (block_Gg[2]),
        .Gp   (block_Gp[2])
    );

    cla_4bit u_cla4_3 (
        .A    (A[12:9]),
        .B    (B[12:9]),
        .Cin  (carry_in[3]),
        .S    (S[12:9]),
        .Cout (),
        .Gg   (block_Gg[3]),
        .Gp   (block_Gp[3])
    );

    cla_4bit u_cla4_4 (
        .A    (A[16:13]),
        .B    (B[16:13]),
        .Cin  (carry_in[4]),
        .S    (S[16:13]),
        .Cout (),
        .Gg   (block_Gg[4]),
        .Gp   (block_Gp[4])
    );

    // Carry-Lookahead Unit computes carries between 4-bit blocks
    carry_lookahead_unit u_clu (
        .Gg   (block_Gg),
        .Gp   (block_Gp),
        .Cin  (Cin),
        .Cout (block_Cout),
        .Ggo  (Gg),
        .Gpo  (Gp)
    );

    assign Cout = block_Cout[4];

endmodule


// ----------------------------------------------------------------------------
// Top-Level: 32-bit CLA Adder
// Two 16-bit CLA blocks with third-level lookahead for the inter-block carry.
// ----------------------------------------------------------------------------
module adder_32bit (
    input  [32:1] A,
    input  [32:1] B,
    output [32:1] S,
    output        C32
);

    wire c16;           // Carry between low and high halves
    wire Gg_lo, Gp_lo;
    wire Gg_hi, Gp_hi;

    // Lower 16 bits
    cla_16bit u_lo (
        .A    (A[16:1]),
        .B    (B[16:1]),
        .Cin  (1'b0),
        .S    (S[16:1]),
        .Cout (c16),
        .Gg   (Gg_lo),
        .Gp   (Gp_lo)
    );

    // Upper 16 bits — carry-in from lookahead: Gg_lo | (Gp_lo & 0) = Gg_lo
    cla_16bit u_hi (
        .A    (A[32:17]),
        .B    (B[32:17]),
        .Cin  (c16),
        .S    (S[32:17]),
        .Cout (C32),
        .Gg   (Gg_hi),
        .Gp   (Gp_hi)
    );

endmodule