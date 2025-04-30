# FPHUB_mult

## Overview

`FPHUB_mult` is a floating-point multiplier implemented using the custom HUB format.  
It computes **Z = X × Y** using a simple combinational architecture and handles special cases such as ±zero, ±infinity, and ±one.

The module is designed to provide a normalized and rounded result in HUB format and is compatible with downstream modules like FPHUB_adder or FPHUB_FMA.

---

## HUB Format

Each operand follows the HUB floating-point layout:

- 1-bit **sign**
- E-bit **exponent** (with a bias of 2<sup>E-1</sup>)
- M-bit **mantissa** (excluding the implicit leading 1)

Subnormal numbers are not supported in this format.

---

## Key Features

- **Full Mantissa Multiplication**: Computes a wide (2×(M+2)) mantissa product.
- **Normalization**: Adjusts the exponent and mantissa if the result overflows by one bit.
- **Special Case Handling**: Predefined behavior for ±infinity, ±zero, and ±one inputs.
- **Compact Output**: The result is formatted back to standard HUB layout.

---

## Ports

| Name         | Direction | Description                                              |
|--------------|-----------|----------------------------------------------------------|
| X            | Input     | First operand (HUB format)                               |
| Y            | Input     | Second operand (HUB format)                              |
| Z            | Output    | Result of X × Y in HUB format                            |

---

## Internal Process

1. **Special Case Detection**  
   Uses the `special_cases_detector` and `special_result_for_multiplier` modules to detect if either operand is a special value.  
   If so, the output is overridden with the corresponding result.

2. **Sign Calculation**  
   The output sign is the XOR of the input signs.

3. **Exponent Calculation**  
   The exponents are added and corrected by subtracting the bias (2<sup>E-1</sup>), following standard floating-point logic.

4. **Mantissa Multiplication**  
   Both mantissas are extended by:
   - A leading 1 (implicit bit)
   - A trailing 1 (rounding support)

   The product is stored in a wide register and normalized accordingly.

5. **Rounding and Normalization**  
   If the product overflows into an extra bit, the exponent is incremented and the mantissa is right-shifted to normalize.

---

## Usage

Instantiate with the desired mantissa and exponent widths:

```systemverilog
FPHUB_mult #(
    .M(23),
    .E(8)
) multiplier (
    .X(X_in),
    .Y(Y_in),
    .Z(Z_out)
);
```

- The default configuration corresponds to 32-bit floating-point format: 1 + 8 + 23.

---

## Example

```verilog
// Example input: X = +2.0, Y = -1.5
// Expected output: Z = -3.0

logic [31:0] X = 32'b01000000000000000000000000000000; // +2
logic [31:0] Y = 32'b11000000010000000000000000000000; // -1.5
logic [31:0] Z;

FPHUB_mult #(23, 8) uut (
    .X(X),
    .Y(Y),
    .Z(Z)
);
```

---

## License

This module is provided for educational and research purposes.  
You are free to modify, adapt, and integrate it into your own designs.
