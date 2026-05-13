# FPGA Rhythm Sequencer

A programmable rhythm sequencer implemented in SystemVerilog on an iCE40 FPGA, built with a fully open-source toolchain.

## Overview

This project implements a beat sequencer with configurable tempo and time signature, displayed and controlled through a TM1638 LED/button interface. Each beat can be set to rest, normal, or accent, and the sequencer plays back the pattern in a continuous loop.

## Features

- **6 tempo options:** 60, 80, 100, 120, 140, 160 BPM
- **3 time signatures:** 2/4, 3/4, 4/4
- **Per-beat editing:** each beat configurable as rest, normal, or accent
- **Real-time playback** with live pattern display on 7-segment digits
- **FSM-based control:** idle → playing ⇄ edit, playing → idle state machine

## Hardware

- **FPGA:** iCE40 (UPduino v3)
- **I/O:** TM1638 LED & key module (8 buttons, 8 7-segment digits)

## Toolchain

Built entirely with open-source tools:

| Step | Tool |
|------|------|
| Synthesis | Yosys |
| Place & Route | nextpnr |
| Flash | iceprog |

## Module Structure

```
top.sv
├── sequencer_fsm.sv   — top-level FSM (idle / playing / edit states)
├── bpm_divider.sv     — clock divider for tempo selection
├── beat_counter.sv    — beat and measure counter
├── pattern_reg.sv     — per-beat pattern storage (rest / normal / accent)
├── display_ctrl.sv    — 7-segment display driver
└── ledandkey.sv       — TM1638 SPI-like serial interface
```

## How to Use

### Controls

| Button | Function |
|--------|----------|
| key[7] / key[6] | Increase / decrease tempo |
| key[5] / key[4] | Cycle through time signatures |
| key[3] | Start playback |
| key[2] | Toggle edit mode |
| key[1] | Move cursor to next beat (edit mode) |
| key[0] | Change beat type: rest → normal → accent (edit mode) |

### Display

- **Digits 0–2 (left):** current BPM
- **Digit 3:** time signature (0 = 2/4, 1 = 3/4, 2 = 4/4)
- **Digits 4–7 (right):** beat pattern — dot = normal, `8` = accent, blank = rest

### Build & Flash

```bash
make        # synthesize, place-and-route, generate bitstream
make flash  # flash to UPduino via iceprog
```

## Skills Demonstrated

- SystemVerilog RTL design and modular hardware architecture
- FSM design for multi-mode interactive systems
- Clock divider and timing logic for variable BPM
- SPI-like serial communication with TM1638
- Full open-source FPGA toolchain (Yosys → nextpnr → iceprog)
- Power-on reset design for reliable FPGA initialization
