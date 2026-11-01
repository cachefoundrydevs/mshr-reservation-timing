## Comparison (critical delay in ps, ASAP7, ideal clock, no wires; smaller is faster)

| version | lint | lockstep | formal | mshr 250 | mshr 250 sized | mshr 200 | entry 250 | entry 250 sized | entry 200 | rsv 250 | rsv 250 sized | rsv 200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| M-16 | iverilog | 12/12 | EQUIVALENT | 276.3 | 269.0 | 273.8 | 225.9 | 225.9 | 223.4 | 242.9 | 242.9 | 240.4 |
| M-17 | iverilog | 12/12 | EQUIVALENT | 257.1 | 253.8 | 254.6 | 220.4 | 220.4 | 217.9 | 242.9 | 242.9 | 240.4 |
| M-18 | iverilog | 12/12 | EQUIVALENT | 277.3 | 262.4 | 274.8 | 215.9 | 215.9 | 213.4 | 242.9 | 242.9 | 240.4 |
| opt | iverilog | 12/12 | EQUIVALENT | 259.3 | 253.8 | 256.8 | 215.9 | 215.9 | 213.4 | 242.9 | 242.9 | 240.4 |
| ref |  |  |  | 542.3 | 463.0 | 539.8 | 476.6 | 418.5 | 474.1 | 258.0 | 251.5 | 255.5 |

A version may replace rtl/opt only if lint passes, lockstep is 12/12, formal is EQUIVALENT, and it is faster (see PROMPT_ITERATION.md).
