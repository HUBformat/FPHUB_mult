/*
Module: special_result_for_multiplier

Summary:
    Handles special floating-point cases for multiplication in HUB format.
    Produces predefined results when operands are special values like ±infinity, ±zero, or ±one.

Parameters:
    M - Mantissa width (excluding the implicit bit).
    E - Exponent width.
    special_case - Number of recognized special cases.

Ports:
    X - Operand X in HUB format.
    Y - Operand Y in HUB format.
    X_special_case - Encoded special case identifier for operand X.
    Y_special_case - Encoded special case identifier for operand Y.
    special_result - Output result for special case detection.
*/
module special_result_for_multiplier #(
    parameter int M = 23,
    parameter int E = 8,
    parameter int special_case = 7
)(
    input logic [E+M:0] X,
    input logic [E+M:0] Y,
    input logic [$clog2(special_case)-1:0] X_special_case,
    input logic [$clog2(special_case)-1:0] Y_special_case,
    output logic [E+M:0] special_result
);

/*
Section: Special Case Constants

Defines symbolic constants for recognized special cases and their corresponding HUB representations.
*/
localparam logic [$clog2(special_case)-1:0] 
    CASE_NONE = 0,
    CASE_INF_P = 1,
    CASE_INF_N = 2,
    CASE_ZERO_P = 3,
    CASE_ZERO_N = 4,
    CASE_ONE_P = 5,
    CASE_ONE_N = 6;

localparam logic [E+M:0] 
    POS_INF = {1'b0, {E{1'b1}}, {M{1'b1}}},
    NEG_INF = {1'b1, {E{1'b1}}, {M{1'b1}}},
    POS_ZERO = {1'b0, {E+M{1'b0}}},
    NEG_ZERO = {1'b1, {E+M{1'b0}}},
    POS_ONE = {1'b0, 1'b1, {E+M-1{1'b0}}},
    NEG_ONE = {1'b1, 1'b1, {E+M-1{1'b0}}};

/*
Section: Special Case Handling Logic

Determines the final result based on the detected special cases:
- If either operand is ±infinity, the result is +infinity.
- If either operand is ±zero, the result is +zero.
- If one operand is ±one, the result is the other operand.
- Otherwise, the result is set to 0.
In all cases, the output sign is determined by XOR-ing the input signs.
*/
always_comb begin
    if (X_special_case == CASE_INF_P || X_special_case == CASE_INF_N ||
        Y_special_case == CASE_INF_P || Y_special_case == CASE_INF_N) begin
        special_result = POS_INF;
    end
    else if ((X_special_case == CASE_ZERO_P) || (X_special_case == CASE_ZERO_N) ||
             (Y_special_case == CASE_ZERO_P) || (Y_special_case == CASE_ZERO_N)) begin
        special_result = POS_ZERO;
    end
    else if ((X_special_case == CASE_ONE_P) || (X_special_case == CASE_ONE_N)) begin
        special_result = Y;
    end
    else if ((Y_special_case == CASE_ONE_P) || (Y_special_case == CASE_ONE_N)) begin
        special_result = X;
    end
    else begin
        special_result = {1'b0, {(E+M){1'b0}}};
    end

    // Set the correct sign based on the XOR of input signs
    special_result[E+M] = X[E+M] ^ Y[E+M];
end

endmodule
