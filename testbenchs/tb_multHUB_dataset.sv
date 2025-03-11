`timescale 1ns / 1ps

module testbench;

  localparam int M = 23;  // Bits de la mantisa
  localparam int E = 8;   // Bits del exponente
  localparam int W = 32;  // Ancho total

  logic [W-1:0] X, Y, Z;

  int file, r;
  string line;

  // Instancia del módulo multHUB
  multHUB uut (
    .X(X),
    .Y(Y),
    .Z(Z)
  );

  initial begin
    // Abrir el archivo CSV (asegúrate de que está en la carpeta del proyecto)
    file = $fopen("data.csv", "r");
    if (file == 0) begin
      $display("Error: No se pudo abrir el archivo.");
      $finish;
    end

    // Leer la primera línea (encabezado) y descartarla
    r = $fgets(line, file);

    // Leer cada línea del archivo CSV
    while (!$feof(file)) begin
      r = $fgets(line, file);
      if (r > 0) begin
        r = $sscanf(line, "%h,%h", X, Y);
        if (r == 2) begin
          #10;  // Pequeño delay para la simulación
          $display("X: %b, Y: %b, Z: %b", X, Y, Z);
        end
      end
    end
    
    $fclose(file);
    $finish;
  end

endmodule