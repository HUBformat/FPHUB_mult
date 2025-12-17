// fpnew_hub_multiplier_wrapper.sv

// Wrapper para el módulo de multiplicación en formato HUB, adaptado a la interfaz de FPnew.
module fpnew_hub_multiplier_wrapper #(
  parameter fpnew_pkg::fp_format_e FpFormat = fpnew_pkg::FP16,
  parameter int unsigned WIDTH = fpnew_pkg::fp_width(FpFormat),
  parameter int unsigned M = fpnew_pkg::man_bits(FpFormat),
  parameter int unsigned E = fpnew_pkg::exp_bits(FpFormat)
)(
  // Interfaz de entrada de FPnew
  input  logic clk_i,
  input  logic rst_ni,
  input  logic [2:0][WIDTH-1:0] operands_i,
  input  fpnew_pkg::operation_e op_i,
  input  logic op_mod_i,
  input  logic in_valid_i,
  output logic in_ready_o,
  input  logic flush_i,
  // Interfaz de salida de FPnew
  output logic [WIDTH-1:0] result_o,
  output fpnew_pkg::status_t status_o,
  output logic out_valid_o,
  input  logic out_ready_i
);

  // Señales internas para tu módulo FPHUB_mult
  logic [E+M:0] hub_X;
  logic [E+M:0] hub_Y;
  logic [E+M:0] hub_Z;

  FPHUB_mult #(
    .M(M),
    .E(E)
  ) i_hub_multiplier (
    .X(hub_X),
    .Y(hub_Y),
    .Z(hub_Z)
  );

  // Mapeo de los operandos del FPnew al formato de HUB
  // El FPnew usa op[0] y op[1] para la multiplicación
  assign hub_X = operands_i[0];
  assign hub_Y = operands_i[1];

  // Lógica de Handshake
  // in_ready_o está activo cuando la FPU está lista para recibir una nueva operación de multiplicación
  assign in_ready_o = 1'b1;
  // out_valid_o se activa cuando la entrada es válida
  assign out_valid_o = in_valid_i && out_ready_i;

  // El resultado de la multiplicación se asigna directamente a la salida
  assign result_o = hub_Z;

  // Señales para casos especiales
  logic x_is_zero, y_is_zero, z_is_zero;
  logic x_is_inf,  y_is_inf, z_is_inf;

  // Comprobaciones para activación de flags de estado
  assign z_is_inf       = (hub_Z[E+M-1:0] == '1);
  assign z_is_zero      = (hub_Z[E+M-1:0] == '0);
  assign x_is_zero      = (hub_X[E+M-1:0] == '0);
  assign y_is_zero      = (hub_Y[E+M-1:0] == '0);
  assign x_is_inf       = (hub_X[E+M-1:0] == '1);
  assign y_is_inf       = (hub_Y[E+M-1:0] == '1);

  always_comb begin
    // Valor por defecto: todo a 0 para evitar 'X'
    status_o = '0; 
    
    // Solo calculamos flags si la salida es válida
    if (out_valid_o) begin
      status_o.NV = ((x_is_zero && y_is_inf) || (x_is_inf && y_is_zero));
      status_o.DZ = 1'b0;
      status_o.OF = (z_is_inf && !x_is_inf && !y_is_inf); // Si hub_Z es X, esto será X, pero solo cuando valid es 1
      status_o.UF = (z_is_zero && !x_is_zero && !y_is_zero); // Si z=0 y x e y no son cero y si son diferentes
      status_o.NX = 1'b1;
    end
  end

endmodule