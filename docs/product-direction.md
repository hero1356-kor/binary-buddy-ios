# DebugBuddy Product Direction

## Concept

DebugBuddy is an ad-free iOS programmer calculator and RTL utility toolbox.

The app starts from a simple need: iPhone does not have a built-in programmer calculator mode like the Windows Calculator.

The first version should feel like a clean, lightweight programmer calculator for iPhone. Later versions can expand into tools for RTL, FPGA, HLS, firmware, register maps, bit fields, Q-format, and fixed-point workflows.

## Target Users

- RTL engineers
- FPGA engineers
- Firmware engineers
- HLS users
- Students learning digital logic
- Developers who often convert between decimal, hexadecimal, and binary values

## Product Principles

1. No ads
2. Fast launch
3. Simple input flow
4. Easy copy and paste
5. Hardware-friendly output formatting
6. One-handed iPhone usability
7. Useful before beautiful

## Phase 1: Programmer Calculator MVP

Goal: Build the first usable app.

Features:

- Decimal input
- Hexadecimal input
- Binary input
- Automatic base conversion
- 8-bit, 16-bit, 32-bit, and 64-bit modes
- Signed and unsigned interpretation
- Binary grouping for readability
- Copy buttons
- Clean SwiftUI layout

Success criteria:

- User can enter a number in one base and immediately see the other bases.
- User can switch bit width and see the output update correctly.
- User can copy the result and paste it into notes, code, or documents.

## Phase 2: Bit Tools

Goal: Add tools that make register and bit-level debugging easier.

Features:

- Bit toggle view
- Bit mask generator
- Bit field extraction
- Shift operations
- Basic bitwise operations

## Phase 3: RTL Helper

Goal: Make outputs friendlier for hardware design workflows.

Features:

- Verilog literal formatting
- Width-aware decimal, hexadecimal, and binary formatting
- Signed value interpretation
- Two's complement helper

## Phase 4: Q-Format and Fixed-Point

Goal: Add fixed-point calculation for DSP, image processing, and HLS workflows.

Features:

- Decimal to fixed-point conversion
- Fixed-point to decimal conversion
- Total bit and fractional bit settings
- Signed and unsigned mode
- Overflow detection
- Quantization error display

## Phase 5: Register Map Calculator

Goal: Build a register value from field definitions.

Features:

- Field range input
- Field value insertion
- Field extraction
- Mask calculation
- Final register value generation

## Initial App Tabs

Recommended first structure:

- Calculator
- Bit Fields
- Q-Format
- Register Map
- Settings

The MVP can start with only Calculator and Settings. Other tabs can be added later.
