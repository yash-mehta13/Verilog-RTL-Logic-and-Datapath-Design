# References

**URL status:** this repository was built in an environment whose network allow-list blocked most sites. Reachability was tested; the *Checked* column states what was actually confirmed. "Not reachable here" means the link was **not** verified (it may still be valid) and no technical claim in this repo depends on its content - the notes were written from standard textbook knowledge and verified by simulation.

## Tools
| Resource | Use | Checked |
|---|---|---|
| Icarus Verilog - <https://steveicarus.github.io/iverilog/> | simulator (`iverilog`, `vvp`) | not reachable here; tool installed from the OS package (v12.0) and used |
| GTKWave - <https://gtkwave.sourceforge.net/> | waveform viewer | HTTP 200 on 2026-10-20 |
| Intel Quartus Prime Lite (Intel/Altera product page) | FPGA flow named in the course sheet | not reachable here; no claim depends on it |
| Terasic DE10 board documentation (board manual for **your** variant) | device, pins | not reachable here; take pin data from your own manual |
| Yosys - <https://yosyshq.net/yosys/> | optional lint | package installed from the OS repository; URL not tested |

## Language and algorithms (textbooks / standards, cited by title only)
* IEEE Std 1364-2001, *Verilog Hardware Description Language* (IEEE) - Verilog-2001 semantics used by the RTL.
* M. Morris Mano and Michael D. Ciletti, *Digital Design* (Pearson) - adders, decoders, MUX, K-maps, ALU.
* Sarah L. Harris and David Harris, *Digital Design and Computer Architecture* (Morgan Kaufmann) - Verilog style, adders, multipliers, RISC/CISC.
* Andrew D. Booth, "A signed binary multiplication technique", *The Quarterly Journal of Mechanics and Applied Mathematics* 4(2), 1951 - original Booth algorithm.
* W. V. Quine (1952) and E. J. McCluskey (1956) - the tabulation method implemented in `tools/boolean_design`.

No IEEE-Xplore/Scopus paper is cited: none could be retrieved and checked in this environment, and no citation is invented. The Task IV sheet asks for such references in the student's own report; add them yourself after reading them.

## Course material
The four Task sheets (BECE102P) define the requirements; their requirements are summarized, not copied, in [requirements-traceability.md](requirements-traceability.md). The original PDFs are not part of this repository (see [LICENSE-STATUS.md](../LICENSE-STATUS.md)). Sources listed inside the sheets could not be fully read in the build environment and are therefore not repeated.
