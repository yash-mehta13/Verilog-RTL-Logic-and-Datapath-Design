# Changelog

All entries describe changes actually made in this repository.

## Unreleased
* Initial repository content: Verilog-2001 RTL for Tasks I-IV (arithmetic, multipliers, mux, decoder, encoder, demux, datapath, ALU, CLA, Booth, FPGA top levels).
* Self-checking testbenches for every block (exhaustive where practical) and a portable Python test runner.
* Config-driven Boolean-function toolchain with three demonstration configs, generated RTL/testbenches/reports.
* Generated truth tables, NAND/NOR gate-count report, SVG diagrams, VCD-derived waveform SVGs.
* Documentation for all four tasks, theory notes, simulation and FPGA guides, references, requirements traceability.
* Makefile, GitHub Actions workflow (not yet run on GitHub), issue/PR templates, Yosys latch lint.
* Added 4-bit/n-bit ripple subtractor, restoring divider, parity generator/checker with exhaustive testbenches.
* Added zero-to-hero learning path and a submission checklist mapping the sheets' contents index to repository artifacts.
* Fixed during development: `mux2_nor` contained an extra output inverter (found by `tb_mux`).
