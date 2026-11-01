## Comparison (critical delay in ps, ASAP7, ideal clock, no wires; smaller is faster)

| version | lint | lockstep | formal | mshr 250 | mshr 250 sized | mshr 200 | entry 250 | entry 250 sized | entry 200 | rsv 250 | rsv 250 sized | rsv 200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| M-1 | iverilog | 12/12 | EQUIVALENT | 296.2 | 287.3 | 293.7 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| M-3 | iverilog | 12/12 | EQUIVALENT | 282.1 | 267.9 | 279.6 | 221.5 | 221.5 | 219.0 | 242.9 | 242.9 | 240.4 |
| M-6 | iverilog | 12/12 | EQUIVALENT | 279.1 | 273.8 | 276.6 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| R-2 | iverilog | 12/12 | EQUIVALENT | 275.6 | 263.7 | 273.1 | 230.5 | 230.5 | 228.0 | 246.5 | 246.5 | 244.0 |
| opt | iverilog | 12/12 | EQUIVALENT | 275.6 | 263.7 | 273.1 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| ref |  |  |  | 542.3 | 463.0 | 539.8 | 476.6 | 418.5 | 474.1 | 258.0 | 251.5 | 255.5 |

A version may replace rtl/opt only if lint passes, lockstep is 12/12, formal is EQUIVALENT, and it is faster (see PROMPT_ITERATION.md).
