## Comparison (critical delay in ps, ASAP7, ideal clock, no wires; smaller is faster)

| version | lint | lockstep | formal | mshr 250 | mshr 250 sized | mshr 200 | entry 250 | entry 250 sized | entry 200 | rsv 250 | rsv 250 sized | rsv 200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| opt |  |  |  | 278.0 | 271.3 | 275.5 | 230.5 | 230.5 | 228.0 | 252.3 | 248.2 | 249.8 |
| ref |  |  |  | 542.3 | 463.0 | 539.8 | 476.6 | 418.5 | 474.1 | 258.0 | 251.5 | 255.5 |

A version may replace rtl/opt only if lint passes, lockstep is 12/12, formal is EQUIVALENT, and it is faster (see PROMPT_ITERATION.md).
