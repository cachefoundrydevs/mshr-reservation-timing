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

To be filled from the first Actions run (rows `ref` and `opt`).
