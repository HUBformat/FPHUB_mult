`timescale 1ns / 1ps

module tb_multHUB;

  // Parámetros del módulo
  parameter int M = 23;  // Tamaño de la mantisa
  parameter int E = 8;   // Tamaño del exponente

  // Señales de entrada/salida
  logic [E+M:0] X, Y;    // Entradas
  logic [E+M:0] Z;       // Salida

  // Instancia del módulo multHUB
  multHUB #(M, E) uut (
    .X(X),
    .Y(Y),
    .Z(Z)
  );

  // Función para formatear un número IEEE 754 en "signo | exponente | mantisa"
  function string format_ieee(input logic [E+M:0] num);
    return $sformatf("%b %b %b", num[31], num[30:23], num[22:0]);
  endfunction

  // Inicialización
  initial begin
    // Caso 1: 2.5 * 3.2 = 8.0
    X = 32'b0_10000001_01000000000000000000000; // 2.5 en formato con sesgo 128 (exponente: 1 + 128 = 129)
    Y = 32'b0_10000001_10011001100110011001101; // 3.2 en formato con sesgo 128 (exponente: 1 + 128 = 129)
    #10;
    $display("Caso 1: 2.5 * 3.2 = %0.6f (%s)", $bitstoshortreal(Z), format_ieee(Z));
    $display("Se espera 8");

    // Caso 2: 1.25 * 4.0 = 5.0
    X = 32'b0_10000000_01000000000000000000000; // 1.25 en formato con sesgo 128 (exponente: 0 + 128 = 128)
    Y = 32'b0_10000010_00000000000000000000000; // 4.0 en formato con sesgo 128 (exponente: 2 + 128 = 130)
    #10;
    $display("Caso 2: 1.25 * 4.0 = %0.6f (%b %b %b)", $bitstoshortreal(Z), Z[31], Z[30:23], Z[22:0]);
    $display("Se espera 5");

    // Caso 3: 0.75 * 0.75 = 0.5625
    X = 32'b0_01111111_10000000000000000000000; // 0.75 en formato con sesgo 128 (exponente: -1 + 128 = 127)
    Y = 32'b0_01111111_10000000000000000000000; // 0.75 en formato con sesgo 128 (exponente: -1 + 128 = 127)
    #10;
    $display("Caso 3: 0.75 * 0.75 = %0.6f (%s)", $bitstoshortreal(Z), format_ieee(Z));
    $display("Se espera 0.5625");

    // Caso 4: 123.456 * 0.001 = 0.123456
    X = 32'b0_10000110_11101101110100101111001; // 123.456 en formato con sesgo 128 (exponente: 6 + 128 = 134)
    Y = 32'b0_01110110_00000110001001001101110; // 0.001 en formato con sesgo 128 (exponente: -10 + 128 = 118)
    #10;
    $display("Caso 4: 123.456 * 0.001 = %0.6f (%s)", $bitstoshortreal(Z), format_ieee(Z));
    $display("Se espera 0.123456");

    // Caso 5: -2.0 * 3.0 = -6.0
    X = 32'b1_10000001_00000000000000000000000; // -2.0 en formato con sesgo 128 (exponente: 1 + 128 = 129)
    Y = 32'b0_10000001_10000000000000000000000; // 3.0 en formato con sesgo 128 (exponente: 2 + 128 = 130)
    #10;
    $display("Caso 5: -2.0 * 3.0 = %0.6f (%s)", $bitstoshortreal(Z), format_ieee(Z));
    $display("Se espera -6");

    // Caso 6: 1.5 * 2.5 = 3.75
    X = 32'b0_01111111_11100000000000000000000; // 1.5 en formato con sesgo 128 (exponente: 0 + 128 = 128)
    Y = 32'b0_10000001_01000000000000000000000; // 2.5 en formato con sesgo 128 (exponente: 1 + 128 = 129)
    #10;
    $display("Caso 6: 1.5 * 2.5 = %0.6f (%s)", $bitstoshortreal(Z), format_ieee(Z));
    $display("Se espera 3.75");

    // Caso 7: 10.0 * 0.1 = 1.0
    X = 32'b0_10000010_11000000000000000000000; // 10.0 en formato con sesgo 128 (exponente: 3 + 128 = 131)
    Y = 32'b0_01111011_11100110011001100110011; // 0.1 en formato con sesgo 128 (exponente: -4 + 128 = 124)
    #10;
    $display("Caso 7: 10.0 * 0.1 = %0.6f (%s)", $bitstoshortreal(Z), format_ieee(Z));
    $display("Se espera 1");

    // Caso 8: 0.5 * 0.5 = 0.25
    X = 32'b0_01111110_01000000000000000000000; // 0.5 en formato con sesgo 128 (exponente: -1 + 128 = 127)
    Y = 32'b0_01111110_01000000000000000000000; // 0.5 en formato con sesgo 128 (exponente: -1 + 128 = 127)
    #10;
    $display("Caso 8: 0.5 * 0.5 = %0.6f (%s)", $bitstoshortreal(Z), format_ieee(Z));
    $display("Se espera 0.25");

    // Caso 9: -1.25 * 4.0 = -5.0
    X = 32'b1_01111111_11000000000000000000000; // -1.25 en formato con sesgo 128 (exponente: 0 + 128 = 128)
    Y = 32'b0_10000010_00000000000000000000000; // 4.0 en formato con sesgo 128 (exponente: 2 + 128 = 130)
    #10;
    $display("Caso 9: -1.25 * 4.0 = %0.6f (%s)", $bitstoshortreal(Z), format_ieee(Z));
    $display("Se espera -5");

    // Caso 10: 3.141592 * 2.718281 = 8.539734
    X = 32'b0_10000001_10010010000111111011011; // 3.141592 en formato con sesgo 128 (exponente: 1 + 128 = 129)
    Y = 32'b0_10000001_01011011111100001010100; // 2.718281 en formato con sesgo 128 (exponente: 1 + 128 = 129)
    #10;
    $display("Caso 10: 3.141592 * 2.718281 = %0.6f (%s)", $bitstoshortreal(Z), format_ieee(Z));
    $display("Se espera 8.539734");

    // Finalizar la simulación
    $finish;
  end
endmodule