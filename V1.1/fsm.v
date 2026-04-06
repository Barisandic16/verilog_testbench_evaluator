module fsm (
    input  IN,
    input  CLK,
    input  RST,
    output reg MATCH
);

    // State encoding
    parameter S0 = 3'd0;  // Initial state
    parameter S1 = 3'd1;  // Detected "1"
    parameter S2 = 3'd2;  // Detected "10"
    parameter S3 = 3'd3;  // Detected "100"
    parameter S4 = 3'd4;  // Detected "1001"

    reg [2:0] current_state, next_state;

    // State register: sequential logic
    always @(posedge CLK or posedge RST) begin
        if (RST)
            current_state <= S0;
        else
            current_state <= next_state;
    end

    // Next state logic and output logic (Mealy FSM)
    always @(*) begin
        // Default values
        next_state = S0;
        MATCH = 1'b0;

        case (current_state)
            S0: begin
                if (IN) begin
                    next_state = S1;
                    MATCH = 1'b0;
                end else begin
                    next_state = S0;
                    MATCH = 1'b0;
                end
            end

            S1: begin // Got "1"
                if (IN) begin
                    next_state = S1;  // Stay, "1" could be new start
                    MATCH = 1'b0;
                end else begin
                    next_state = S2;  // Got "10"
                    MATCH = 1'b0;
                end
            end

            S2: begin // Got "10"
                if (IN) begin
                    next_state = S1;  // "1" is new start
                    MATCH = 1'b0;
                end else begin
                    next_state = S3;  // Got "100"
                    MATCH = 1'b0;
                end
            end

            S3: begin // Got "100"
                if (IN) begin
                    next_state = S4;  // Got "1001"
                    MATCH = 1'b0;
                end else begin
                    next_state = S0;  // "1000", reset
                    MATCH = 1'b0;
                end
            end

            S4: begin // Got "1001"
                if (IN) begin
                    next_state = S1;  // Got "10011" -> MATCH! 
                    MATCH = 1'b1;     // Last "1" could start new "1..."
                end else begin
                    next_state = S2;  // Got "10010" -> "10" overlap
                    MATCH = 1'b0;
                end
            end

            default: begin
                next_state = S0;
                MATCH = 1'b0;
            end
        endcase
    end

endmodule