# FPGA vs ASIC

| Aspect | FPGA | ASIC |
|---|---|---|
| Fabric | Pre-built LUTs, flip-flops, routing, RAM/DSP blocks, configured after manufacture | Custom transistor layout fixed at fabrication |
| Up-front cost / NRE | Low (buy a device) | High (masks, verification, tape-out) |
| Unit cost at volume | Higher | Lower per unit at high volume |
| Time to first working design | Short: recompile and reprogram | Long (months) |
| Performance, power, area | Typically lower speed, higher power, larger area for the same logic | Typically best |
| Changes after deployment | Reconfigurable in the field | Not possible (new silicon) |
| Typical use | Prototyping, low/medium volume, evolving standards, education labs | High-volume products, tight power/performance targets |

In this lab the Verilog is the common starting point; on an FPGA it is synthesized into LUT configurations (Quartus), for an ASIC it would be synthesized to standard cells.
