module LIFObuffer(
    input [3:0] dataIn,
    input RW,
    input EN,
    input Rst,
    input Clk,
    output EMPTY,
    output FULL,
    output reg [3:0] dataOut
);

    reg [3:0] stack_mem [3:0];
    reg [2:0] SP;

    assign EMPTY = (SP == 4);
    assign FULL = (SP == 0);

    always @(posedge Clk) begin
        if (EN) begin
            if (Rst) begin
                SP <= 4;
                stack_mem[0] <= 0;
                stack_mem[1] <= 0;
                stack_mem[2] <= 0;
                stack_mem[3] <= 0;
                dataOut <= 0;
            end else begin
                if (!RW && !FULL) begin
                    SP <= SP - 1;
                    stack_mem[SP - 1] <= dataIn;
                end else if (RW && !EMPTY) begin
                    dataOut <= stack_mem[SP];
                    stack_mem[SP] <= 0;
                    SP <= SP + 1;
                end
            end
        end
    end

endmodule