module pulse_detect(
    input       clk,
    input       rst_n,
    input       data_in,
    output reg  data_out
);

    reg [1:0] state;

    localparam S0 = 2'b00,  // idle, waiting for 0
               S1 = 2'b01,  // seen 0
               S2 = 2'b10;  // seen 0->1

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state    <= S0;
            data_out <= 1'b0;
        end else begin
            case (state)
                S0: begin
                    data_out <= 1'b0;
                    if (data_in == 1'b0)
                        state <= S1;
                    else
                        state <= S0;
                end
                S1: begin
                    data_out <= 1'b0;
                    if (data_in == 1'b1)
                        state <= S2;
                    else
                        state <= S1; // stay, still 0
                end
                S2: begin
                    if (data_in == 1'b0) begin
                        data_out <= 1'b1; // pulse detected
                        state    <= S1;   // this 0 can be start of next pulse
                    end else begin
                        data_out <= 1'b0;
                        state    <= S0;   // two consecutive 1s, not a pulse
                    end
                end
                default: begin
                    state    <= S0;
                    data_out <= 1'b0;
                end
            endcase
        end
    end

endmodule