# Iteration log

One section per iteration (written by the assistant in Step H of `PROMPT_ITERATION.md`, pasted here by you). Newest at the bottom.

Format:

```
## Iteration <k> (<date>)
Candidates:
| id | module | idea | target group | expected |
|---|---|---|---|---|
Results (from the comparison table, critical delay in ps):
| version | lint | lockstep | formal | mshr 250 | mshr 250 sized | mshr 200 | entry 250 | entry 250 sized | entry 200 | rsv 250 | rsv 250 sized | rsv 200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
Decision: <which candidate won and why / why none won>
Promoted to rtl/opt: <files> (or none)
New baseline (opt): mshr <x> / entry <y> / rsv <z> ps at 200
```

## Iteration 0: baseline

First Actions run (2026-10-30, commit `bb49958`, all 9 jobs green). Critical delay in ps, ASAP7, ideal clock, no wires:

| version | lint | lockstep | formal | mshr 250 | mshr 250 sized | mshr 200 | entry 250 | entry 250 sized | entry 200 | rsv 250 | rsv 250 sized | rsv 200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| opt | iverilog | 12/12 | EQUIVALENT | 278.0 | 271.3 | 275.5 | 230.5 | 230.5 | 228.0 | 252.3 | 248.2 | 249.8 |
| ref | - | - | - | 542.3 | 463.0 | 539.8 | 476.6 | 418.5 | 474.1 | 258.0 | 251.5 | 255.5 |

Baseline for iteration 1: mshr 275.5 / entry 228.0 / rsv 249.8 ps at 200.
