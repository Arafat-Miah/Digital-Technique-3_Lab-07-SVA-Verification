# SystemVerilog Assertions for I²S Unit (Lab 07)

## Repository
**Recommended name:** `Digital-Technique-3_Lab-07-SVA-Verification`

## Overview
This repository contains the **SystemVerilog Assertions (SVA)** developed for **Digital Technique 3 – Lab 07**. 

Before implementing the physical RTL hardware, this phase focused on Assertion-Based Verification (ABV). By defining strict mathematical and temporal properties for the I²S transmitter, we established a robust "contract" that the future RTL must satisfy. This includes both protocol-level constraints (Blackbox) and internal structural rules (Whitebox).

## Files Included
- `i2s_unit_svamod.sv` — The SystemVerilog module containing all properties, assertions, assumptions, and covergroups.

---

## 7.1 Assertion Strategy

The verification environment was split into two distinct categories to ensure both external compliance and internal stability.

### 1) Blackbox Assertions (Protocol Compliance)
These assertions act as the strict, unchangeable rules of the I²S protocol. They only monitor the external input/output ports (`play_in`, `tick_in`, `sck_out`, `ws_out`, `sdo_out`, `req_out`).
- **Timing Alignment:** Enforcing that `ws_out` transitions and `sdo_out` data shifts occur exactly on the falling edge of `sck_out` (`$fell(sck_out)`).
- **Handshaking:** Ensuring `req_out` generates a clean, one-cycle pulse to request the next audio frame perfectly in sync with the data boundary.

### 2) Whitebox Assertions (Internal Hardware Rules)
These properties were custom-written to govern the internal RTL architecture, specifically targeting the data path and state machine.
- **`r_in_reg_standby_zero`:** Ensures the internal 48-bit buffer clears to zero when the unit enters standby.
- **`r_in_reg_load`:** Verifies that the internal buffer successfully captures the `{audio0_in, audio1_in}` concatenation precisely one cycle after `tick_in` is asserted.
- **`r_in_reg_hold`:** Guarantees data stability, ensuring the input register does not mutate during playback unless a new `tick_in` event occurs or the system transitions to standby.
- **`r_sdo_out_conn`:** Asserts that the serial data output pin is continuously, combinationally driven by the MSB (bit 47) of the shift register.

---

## 7.2 Observations and Learning
### What I observed
- Writing assertions *before* the RTL design forces you to deeply understand the hardware timing. For instance, realizing that an assertion demanding a register `$stable` might conflict with a rule demanding it clear to zero during a state change.
- The distinction between `|->` (overlapping implication) and `|=>` (non-overlapping implication) is critical for accurately modeling hardware clock cycles.

### What I learned
- Practical application of **SystemVerilog Assertion (SVA)** syntax, including properties, sequence delays (`##1`), and system functions (`$past`, `$stable`, `$rose`, `$fell`).
- The conceptual difference between `assert` (proving the design works), `assume` (constraining the testbench/formal tool), and `cover` (ensuring a specific state is reachable).

---

## Notes
When I got stuck, I used AI as a guidance tool to clarify concepts and validate my approach; however, the SVA code and report content were written by me.

## Author
Arafat Miah
