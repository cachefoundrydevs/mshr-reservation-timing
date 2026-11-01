## Comparison (critical delay in ps, ASAP7, ideal clock, no wires; smaller is faster)

| version | lint | lockstep | formal | mshr 250 | mshr 250 sized | mshr 200 | entry 250 | entry 250 sized | entry 200 | rsv 250 | rsv 250 sized | rsv 200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| M-13 | iverilog | 12/12 | EQUIVALENT | 261.0 | 250.8 | 258.5 | 215.9 | 215.9 | 213.4 | 242.9 | 242.9 | 240.4 |
| M-14 | iverilog | 12/12 | EQUIVALENT | 265.0 | 257.4 | 262.5 | 215.9 | 215.9 | 213.4 | 242.9 | 242.9 | 240.4 |
| M-15 | iverilog | 12/12 | EQUIVALENT | 269.4 | 254.9 | 266.9 | 215.9 | 215.9 | 213.4 | 242.9 | 242.9 | 240.4 |
| opt | iverilog | 12/12 | EQUIVALENT | 259.3 | 253.8 | 256.8 | 215.9 | 215.9 | 213.4 | 242.9 | 242.9 | 240.4 |
| ref |  |  |  | 542.3 | 463.0 | 539.8 | 476.6 | 418.5 | 474.1 | 258.0 | 251.5 | 255.5 |

A version may replace rtl/opt only if lint passes, lockstep is 12/12, formal is EQUIVALENT, and it is faster (see PROMPT_ITERATION.md).
