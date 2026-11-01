# Status: l1d_mshr against 4 GHz

4 GHz target (250 ps): l1d_mshr 278.0 ps (271.3 sized), NOT met, slack -28.0 ps (-21.3 sized). Working goal 230 ps.

Critical delay in ps, ASAP7, ideal clock, no wires. Smaller is faster.

## Table 1: l1d_mshr candidates

| iteration | date (UTC) | candidate | idea | lint | lockstep | formal | mshr 250 | mshr 250 sized | mshr 200 | slack at 250 | decision | promoted |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 2026-10-30 | opt (baseline) | first optimised version | iverilog | 12/12 | EQUIVALENT | 278.0 | 271.3 | 275.5 | -28.0 | baseline | - |
| 1 | 2026-10-30 | R-1 | rsv timeout predecessor compare | iverilog | 12/12 | EQUIVALENT | 278.0 | 271.3 | 275.5 | -28.0 | WIN (rsv only, mshr unchanged) | yes |
| 2 | 2026-10-30 | R-2 | rsv snoop-hold factoring | iverilog | 12/12 | EQUIVALENT | 278.0 | 271.3 | 275.5 | -28.0 | LOSE (rsv 244.0 vs 240.4 at 200) | no |

## Table 2: all modules, opt after each iteration (250 / 250 sized / 200)

| iteration | mshr | entry | rsv | commit | Actions run |
|---|---|---|---|---|---|
| 0 | 278.0 / 271.3 / 275.5 | 230.5 / 230.5 / 228.0 | 252.3 / 248.2 / 249.8 | bb49958 | first run |
| 1 | 278.0 / 271.3 / 275.5 | 230.5 / 230.5 / 228.0 | 242.9 / 242.9 / 240.4 | d136d8c | 41054567569 |
| 2 | 278.0 / 271.3 / 275.5 | 230.5 / 230.5 / 228.0 | 242.9 / 242.9 / 240.4 | db9ae18 | 41061877208 |

## Table 3: open ideas

| id | idea | status | reason |
|---|---|---|---|
| R-1 | rsv timeout predecessor compare | won | rsv -9.4 ps at 200 |
| R-2 | rsv snoop-hold factoring | lost | 3.6 ps slower than opt |
| M-1 | per-slice parallel copies of the grant flops for the output muxes | untried | targets axi_read_req_line_addr path |
| M-2 | flat AND-OR output muxes | running | iteration 3: independent per-bit reductions; expected 2-15 ps, unmeasured |
| M-3 | compute granted / not-granted next state in parallel, grant selects last | untried | targets entry tk_q, busy_r, state |
| M-4 | parallel-prefix pick in arb_rr | running | iteration 3: request-prefix reductions and parallel index encoding; expected 5-20 ps, unmeasured |
| M-5 | one CAM match vector per consumer | untried | targets lookup_* pins |
