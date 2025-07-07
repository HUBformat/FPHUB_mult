/*
Module: FPHUB_mult

Summary:
    Multiplies two floating-point operands in custom HUB format. Handles exponent addition,
    mantissa multiplication, and result normalization. Also detects special cases such as ±0 and ±∞.

Parameters:
    M - Mantissa width (excluding the implicit bit).
    E - Exponent width.
    special_case - Number of special cases supported.

Input:
    X - Operand X in HUB format (1 + E + M bits).
    Y - Operand Y in HUB format (1 + E + M bits).

Output:
    Z - Result of the multiplication in HUB format (1 + E + M bits).
*/
module FPHUB_mult #(
    parameter int M = 23,
    parameter int E = 8,
    parameter int special_case = 7
)(
    input logic clk,
    input logic rst_l,
    input logic start,
    input  logic [E+M:0] X,
    input  logic [E+M:0] Y,
    output logic [E+M:0] Z
);

/*
Section: Special Case Detection

Detects whether either operand is a special case (±zero, ±infinity, ±one). This is essential
for ensuring that exceptional conditions are handled correctly before proceeding with normal
multiplication logic. If a special case is found, the final result is delegated to a dedicated
result generation module.
*/
logic [$clog2(special_case)-1:0] X_special_case, Y_special_case;
logic [E+M:0] special_result;

special_cases_detector #(E, M, special_case) special_cases_inst (
    .X(X),
    .Y(Y),
    .X_special_case(X_special_case),
    .Y_special_case(Y_special_case)
);

special_result_for_multiplier #(E, M, special_case) special_result_inst (
    .X(X),
    .Y(Y),
    .X_special_case(X_special_case),
    .Y_special_case(Y_special_case),
    .special_result(special_result)
);

/*
Section: Sign Calculation

The sign of the result is computed by XOR-ing the sign bits of both operands.
This is consistent with the sign rules for multiplication of signed numbers.
*/
/* Variable: Z[E+M]
   Sign bit of the result. It is the XOR of the sign bits of X and Y.
*/
//assign Z[E+M] = X[E+M] ^ Y[E+M];

/*
Section: Exponent Calculation

Computes the unbiased exponent of the result by adding the biased exponents of X and Y,
then subtracting the HUB bias. The bias value is 2^(E-1), represented as 1 followed by (E-1) zeros.
This ensures the result is properly scaled.
*/
logic [E:0] expSum;  // Exponent result with one extra bit to handle overflow
/* Variable: expSum
   Holds the sum of the two input exponents minus the bias (2^(E-1)).
*/
assign expSum = {1'b0, X[E+M-1:M]} + {1'b0, Y[E+M-1:M]} - {1'b0, 1'b1, {(E-1){1'b0}}};

/*
Section: Mantissa Multiplication and Normalization

Multiplies the mantissas of X and Y, each extended with an implicit leading one and a fixed LSB of 1
(corresponding to the ILSB in the HUB format). The product is stored in a wider register to accommodate
all significant bits (2*(M+2)).

Normalization is handled based on the MSB of the result:
- If the MSB is 1, it indicates an overflow and the mantissa is right-shifted by 1.
- The exponent is incremented accordingly.
- Otherwise, bits are taken directly without exponent correction.

If either operand is special, the `special_result` is used instead of performing multiplication.
*/
/* Variable: multfull
   Full-width result of multiplying two mantissas, each M bits plus 2 (implicit + ILSB).
   Total width: 2 * (M + 2)
*/
logic [2*(M+2)-1:0] multfull;

always_comb begin
    multfull = {1'b1, X[M-1:0], 1'b1} * {1'b1, Y[M-1:0], 1'b1};
end

always_ff @(posedge clk or negedge rst_l) begin

    if(!rst_l) begin
        Z <= '0;
    end

    else begin
        if(start) begin
            Z[E+M] <= X[E+M] ^ Y[E+M];
            if (X_special_case == 0 && Y_special_case == 0) begin
                // Select normalized mantissa bits based on overflow (MSB)
                Z[M-1:0] <= (multfull[2*(M+2)-1] == 1'b1) ? multfull[2*(M+2)-2 : M+3] : multfull[2*(M+2)-3:M+2];

                // Adjust exponent if overflow occurred
                if (multfull[2*(M+2)-1] == 1'b1) begin
                    Z[E+M-1:M] <= expSum[E-1:0] + 1;
                end else begin
                    Z[E+M-1:M] <= expSum[E-1:0];
                end
            end else begin
                Z <= special_result;
            end

        end else begin
            Z <= '0;
        end
        
    end
end

endmodule
