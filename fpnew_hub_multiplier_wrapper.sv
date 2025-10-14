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
  logic [E+M:0] hub_X_input;
  logic [E+M:0] hub_Y_input;
  logic [E+M:0] hub_Z_output;

  // Instancia de tu módulo FPHUB_mult sin modificar
  FPHUB_mult #(
    .M(M),
    .E(E)
  ) i_hub_multiplier (
    .X(hub_X_input),
    .Y(hub_Y_input),
    .Z(hub_Z_output)
  );

  // Mapeo de los operandos del FPnew al formato de HUB
  // El FPnew usa op[0] y op[1] para la multiplicación
  assign hub_X_input = operands_i[0];
  assign hub_Y_input = operands_i[1];

  // Lógica de Handshake
  // in_ready_o está activo cuando la FPU está lista para recibir una nueva operación de multiplicación
  assign in_ready_o = 1'b1;
  // out_valid_o se activa cuando la entrada es válida y el op_i es de multiplicación
  assign out_valid_o = in_valid_i && out_ready_i;

  // El resultado de la multiplicación se asigna directamente a la salida
  assign result_o = hub_Z_output;

  // Lógica de flags de estado de FPnew (status_t)
  // Basado en el formato de HUB
  logic is_inf_output;
  logic is_zero_output;

  // Comprueba si la salida es Infinito (todos los bits del exponente y la mantisa son 1)
  assign is_inf_output = (hub_Z_output[E+M-1:0] == {(E+M){1'b1}});

  // Comprueba si la salida es Cero (todos los bits del exponente y la mantisa son 0)
  assign is_zero_output = (hub_Z_output[E+M-1:0] == {(E+M){1'b0}});

  // Asignación de flags de estado (simplificada)
  assign status_o.NV = 1'b0; // No se detectan operaciones inválidas por la multiplicación
  assign status_o.DZ = 1'b0; // No aplica para multiplicación
  assign status_o.OF = is_inf_output;
  assign status_o.UF = is_zero_output;
  assign status_o.NX = 1'b0; // Pendiente de implementar

endmodule