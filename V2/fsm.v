module fsm(
    input  IN,
    input  CLK,
    input  RST,
    output reg MATCH
);

    // State encoding
    parameter S0 = 3'd0,  // Initial state
              S1 = 3'd1,  // Detected "1"
              S2 = 3'd2,  // Detected "10"
              S3 = 3'd3,  // Detected "100"
              S4 = 3'd4;  // Detected "1001"

    reg [2:0] current_state, next_state;

    // State register: sequential logic
    always @(posedge CLK or posedge RST) begin
        if (RST)
            current_state <= S0;
        else
            current_state <= next_state;
    end

    // Next state logic and output logic (Mealy: output depends on state + input)
    always @(*) begin
        // Default values
        next_state = S0;
        MATCH = 1'b0;

        case (current_state)
            S0: begin
                if (IN)
                    next_state = S1;  // Got "1"
                else
                    next_state = S0;
            end

            S1: begin
                if (~IN)
                    next_state = S2;  // Got "10"
                else
                    next_state = S1;  // Stay, "1" is still valid prefix
            end

            S2: begin
                if (~IN)
                    next_state = S3;  // Got "100"
                else
                    next_state = S1;  // Got "1", restart partial match
            end

            S3: begin
                if (IN)
                    next_state = S4;  // Got "1001"
                else
                    next_state = S0;  // "1000", no valid prefix
            end

            S4: begin
                if (IN) begin
                    next_state = S1;  // Got "10011" -> MATCH! 
                    MATCH = 1'b1;     // Last "1" also starts new potential "1..."
                end
                else
                    next_state = S2;  // Got "10010" -> "10" is valid prefix
            end

            default: begin
                next_state = S0;
            end
        endcase
    end

endmodule