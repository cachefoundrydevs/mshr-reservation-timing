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

## Iteration 1 (2026-10-30)

Candidate: R-1, reservation timeout predecessor comparison; target `to_last`.
Exactness: TO_W-bit `(to_cnt + 1) == TO_LAST` equals
`to_cnt == (TO_LAST - 1)` modulo 2^TO_W. Reset and update enables are unchanged.

Actions run: 41054567569; source commit: d136d8c87995a93cf3b8f54842c900c31e1c4ab4.
Run succeeded; both opt and R-1 passed Icarus compile, lockstep 12/12, and all five bounded formal checks.

## Comparison (critical delay in ps, ASAP7, ideal clock, no wires; smaller is faster)

| version | lint | lockstep | formal | mshr 250 | mshr 250 sized | mshr 200 | entry 250 | entry 250 sized | entry 200 | rsv 250 | rsv 250 sized | rsv 200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| R-1 | iverilog | 12/12 | EQUIVALENT | 278.0 | 271.3 | 275.5 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| opt | iverilog | 12/12 | EQUIVALENT | 278.0 | 271.3 | 275.5 | 230.5 | 230.5 | 228.0 | 252.3 | 248.2 | 249.8 |
| ref |  |  |  | 542.3 | 463.0 | 539.8 | 476.6 | 418.5 | 474.1 | 258.0 | 251.5 | 255.5 |


Decision: R-1 wins. Reservation timing improves by 9.4 ps at 250 ps,
5.3 ps after sizing, and 9.4 ps at 200 ps. Every MSHR/entry column is unchanged.
Promoted to rtl/opt: l1d_reservation_unit.v, on the timing optimization branch.
The R-1 candidate folder is removed; its complete source remains in Git history.
New baseline (250 / sized / 200 ps): mshr 278.0 / 271.3 / 275.5;
entry 230.5 / 230.5 / 228.0; rsv 242.9 / 242.9 / 240.4.
New worst reservation path: amo_lock_line[14] -> line comparisons and lock-control
logic -> amo_lock_snoop_hold, -40.4 ps slack at 200 ps. The counter path is now -4.4 ps.
