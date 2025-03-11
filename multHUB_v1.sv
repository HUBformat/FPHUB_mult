`timescale 1ns / 1ps

module multHUB #(
    parameter int M = 23,  // Mantissa size (including the implicit 1)
    parameter int E = 8,   // Exponent size
    parameter int special_case = 7  
)(
    input  logic [E+M:0] X,  // Formato: [Sign, Exponent (E bits), Mantissa (M bits)]
    input  logic [E+M:0] Y,
    output logic [E+M:0] Z
);

  // Se asume que el exponente está en exceso (2^E - 1)
  // El resultado de la multiplicación de las mantissas se almacena en "multfull"
  // que tiene 2*M+2 bits (índices: 2*M+1 downto 0)
  logic [2*(M+2)-1:0] multfull;

  // -------------------------------------------------------------------
  // 0. Detección de casos especiales
  // -------------------------------------------------------------------
  // Se detectan los casos especiales de X e Y
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

  
  // -------------------------------------------------------------------
  // 1. Cálculo del signo del resultado
  // -------------------------------------------------------------------
  // El signo del resultado es la XOR de los signos de X y Y.
  // En X, el bit de signo es el bit [E+M]
  assign Z[E+M] = X[E+M] ^ Y[E+M];

  // -------------------------------------------------------------------
  // 2. Cálculo del exponente del resultado
  // -------------------------------------------------------------------
  // Se suman los exponentes (X[E+M-1:M] y Y[E+M-1:M]) y se añade la señal de acarreo
  // proveniente de la multiplicación de mantissas (multfull[2*M+1]).
  // Los exponentes están en exceso, así que la suma directa (con la corrección)
  // es suficiente para la multiplicación.
  logic [E:0] expSum;
  assign expSum = {1'b0, X[E+M-1:M]} + {1'b0, Y[E+M-1:M]} - 9'b0_1000_0000;         // Se suman los exponentes y se resta el sesgo, que en el caso del formato HUB es 128
  // Se asigna el campo de exponente al resultado (tomando los E bits menos significativos)
//  assign Z[E+M-1:M] = expSum[E-1:0];

  // -------------------------------------------------------------------
  // 3. Multiplicación de las mantissas (con bit implícito '1')
  // -------------------------------------------------------------------
  // Se extienden las mantissas agregando el bit implícito '1' en el LSB.
  // En VHDL se hacía: (X(M-1 downto 0) & '1') * (Y(M-1 downto 0) & '1')
  // En SystemVerilog se concatena de la siguiente forma:
  //assign 
  always_comb begin
      multfull = {1'b1, X[M-1:0], 1'b1} * {1'b1, Y[M-1:0], 1'b1};
      // -------------------------------------------------------------------
      // 4. Normalización de la mantisa (selección del campo de mantissa final)
      // -------------------------------------------------------------------
      // Se selecciona el campo de mantisa final en función de si el producto
      // tuvo un acarreo extra (es decir, si multfull[2*M+1] es 1).
      // - Si multfull[2*M+1] == 1, el producto está "sobredimensionado" y se deben
      //   tomar los bits [2*M+1 downto M+2] (lo que equivale a un desplazamiento a la derecha de 1 bit).
      // - En caso contrario, se toman los bits [2*M downto M+1].
      if (X_special_case == 0 && Y_special_case == 0) begin
        Z[M-1:0] = (multfull[2*(M+2)-1] == 1'b1) ? multfull[2*(M+2)-2 : M+3] : multfull[2*(M+2)-3:M+2];
        if (multfull[2*(M+2)-1] == 1'b1) begin
          Z[E+M-1:M] = expSum[E-1:0] + 1;       
        end else begin
          Z[E+M-1:M] = expSum[E-1:0];
        end
      end else begin
        Z = special_result;
      end
  end
endmodule