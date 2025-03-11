`timescale 1ns / 1ps

module special_result_for_multiplier #(
    parameter int M = 23,                                       // Mantissa size
    parameter int E = 8,                                        // Exponent size
    parameter int special_case = 7                              // Number of special cases (including no special case)
)(              
    input logic [E+M:0] X,                                      // Entrada X
    input logic [E+M:0] Y,                                      // Entrada Y
    input logic [$clog2(special_case)-1:0] X_special_case,      // Indicador del caso especial de X (0 si no es especial)
    input logic [$clog2(special_case)-1:0] Y_special_case,      // Indicador del caso especial de Y (0 si no es especial)
    output logic [E+M:0] special_result                         // Resultado especial
    );

/*-----------------------------------------------
Definición de casos especiales:
-----------------------------------------------*/
localparam logic [$clog2(special_case)-1:0] 
        CASE_NONE = 0,       // Ningún caso especial
        CASE_INF_P = 1,      // +inf (0 11111111 11111111111111111111111)
        CASE_INF_N = 2,      // -inf (1 11111111 11111111111111111111111)
        CASE_ZERO_P = 3,     // +0   (0 00000000 00000000000000000000000)
        CASE_ZERO_N = 4,     // -0   (1 00000000 00000000000000000000000)
        CASE_ONE_P = 5,      // +1   (0 10000000 00000000000000000000000)
        CASE_ONE_N = 6;      // -1   (1 10000000 00000000000000000000000)

localparam logic [E+M:0] 
        POS_INF = {1'b0, {E{1'b1}}, {M{1'b1}}},      // +inf (0 11111111 00000000000000000000000)
        NEG_INF = {1'b1, {E{1'b1}}, {M{1'b1}}},      // -inf (1 11111111 00000000000000000000000)
        POS_ZERO = {1'b0, {E+M{1'b0}}},               // +0   (0 00000000 00000000000000000000000)
        NEG_ZERO = {1'b1, {E+M{1'b0}}},               // -0   (1 00000000 00000000000000000000000)
        POS_ONE = {1'b0, 1'b1, {E+M-1{1'b0}}},        // +1   (0 10000000 00000000000000000000000)
        NEG_ONE = {1'b1, 1'b1, {E+M-1{1'b0}}};        // -1   (1 10000000 00000000000000000000000)


always_comb begin
    // Casos con infinito
    // Si X es +/-∞, el resultado es ∞ y el signo del de cada número
    if (X_special_case == CASE_INF_P || X_special_case == CASE_INF_N || Y_special_case == CASE_INF_P || Y_special_case == CASE_INF_N) begin
        special_result = POS_INF;
    end
    // Casos con cero
    else if ((X_special_case == CASE_ZERO_P) || (X_special_case == CASE_ZERO_N) || (Y_special_case == CASE_ZERO_P) || (Y_special_case == CASE_ZERO_N)) begin
        special_result = POS_ZERO;
    end
    else if ((X_special_case == CASE_ONE_P) || (X_special_case == CASE_ONE_N)) begin
        special_result = Y;
    end
    else if ((Y_special_case == CASE_ONE_P) || (Y_special_case == CASE_ONE_N)) begin
        special_result = X;
    end
    else begin
        special_result = 0;
    end
    special_result[E+M] = X[E+M] ^ Y[E+M];
end
endmodule