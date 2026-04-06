module dual_port_RAM #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input                       wclk,
    input                       wenc,
    input  [$clog2(DEPTH)-1:0]  waddr,
    input  [WIDTH-1:0]          wdata,
    input                       rclk,
    input                       renc,
    input  [$clog2(DEPTH)-1:0]  raddr,
    output reg [WIDTH-1:0]      rdata
);

    reg [WIDTH-1:0] RAM_MEM [0:DEPTH-1];

    always @(posedge wclk) begin
        if (wenc)
            RAM_MEM[waddr] <= wdata;
    end

    always @(posedge rclk) begin
        if (renc)
            rdata <= RAM_MEM[raddr];
    end

endmodule


module asyn_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input                   wclk,
    input                   rclk,
    input                   wrstn,
    input                   rrstn,
    input                   winc,
    input                   rinc,
    input  [WIDTH-1:0]      wdata,
    output                  wfull,
    output                  rempty,
    output [WIDTH-1:0]      rdata
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    // Write and read binary pointers (one extra bit for full/empty detection)
    reg [ADDR_WIDTH:0] waddr_bin, raddr_bin;
    // Gray code pointers
    reg [ADDR_WIDTH:0] wptr, rptr;

    // Synchronizer registers (two-stage)
    reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;
    reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;

    // Internal signals
    wire wen, ren;
    wire [ADDR_WIDTH-1:0] waddr, raddr;
    wire [ADDR_WIDTH:0] waddr_bin_next, raddr_bin_next;
    wire [ADDR_WIDTH:0] wptr_next, rptr_next;

    // -------------------------------------------------------
    // Write pointer logic
    // -------------------------------------------------------
    assign waddr_bin_next = waddr_bin + (winc & ~wfull);
    assign wptr_next      = waddr_bin_next ^ (waddr_bin_next >> 1); // binary to gray

    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            waddr_bin <= 0;
            wptr      <= 0;
        end else begin
            waddr_bin <= waddr_bin_next;
            wptr      <= wptr_next;
        end
    end

    // -------------------------------------------------------
    // Read pointer logic
    // -------------------------------------------------------
    assign raddr_bin_next = raddr_bin + (rinc & ~rempty);
    assign rptr_next      = raddr_bin_next ^ (raddr_bin_next >> 1); // binary to gray

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            raddr_bin <= 0;
            rptr      <= 0;
        end else begin
            raddr_bin <= raddr_bin_next;
            rptr      <= rptr_next;
        end
    end

    // -------------------------------------------------------
    // Synchronize read pointer into write clock domain (two-stage)
    // -------------------------------------------------------
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            rptr_buff <= 0;
            rptr_syn  <= 0;
        end else begin
            rptr_buff <= rptr;
            rptr_syn  <= rptr_buff;
        end
    end

    // -------------------------------------------------------
    // Synchronize write pointer into read clock domain (two-stage)
    // -------------------------------------------------------
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            wptr_buff <= 0;
            wptr_syn  <= 0;
        end else begin
            wptr_buff <= wptr;
            wptr_syn  <= wptr_buff;
        end
    end

    // -------------------------------------------------------
    // Full and empty generation
    // -------------------------------------------------------
    // Full: top two bits of gray codes are opposite, rest are equal
    assign wfull  = (wptr == {~rptr_syn[ADDR_WIDTH:ADDR_WIDTH-1], rptr_syn[ADDR_WIDTH-2:0]});
    // Empty: gray code pointers are equal
    assign rempty = (rptr == wptr_syn);

    // -------------------------------------------------------
    // RAM address and enable
    // -------------------------------------------------------
    assign waddr = waddr_bin[ADDR_WIDTH-1:0];
    assign raddr = raddr_bin[ADDR_WIDTH-1:0];
    assign wen   = winc & ~wfull;
    assign ren   = rinc & ~rempty;

    // -------------------------------------------------------
    // Dual-port RAM instantiation
    // -------------------------------------------------------
    dual_port_RAM #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) u_dual_port_RAM (
        .wclk  (wclk),
        .wenc  (wen),
        .waddr (waddr),
        .wdata (wdata),
        .rclk  (rclk),
        .renc  (ren),
        .raddr (raddr),
        .rdata (rdata)
    );

endmodule