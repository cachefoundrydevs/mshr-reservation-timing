4 GHz target (250 ps): l1d_mshr 270.7 ps, NOT met, working goal 230 ps

| iteration | date (UTC) | candidate | idea | lint | lockstep | formal | mshr 250 | mshr 250 sized | mshr 200 | slack at 250 | decision | promoted |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 2026-10-30 | opt (baseline) | first optimised version | iverilog | 12/12 | EQUIVALENT | 278.0 | 271.3 | 275.5 | -28.0 | baseline | - |
| 1 | 2026-10-30 | R-1 | rsv timeout predecessor compare | iverilog | 12/12 | EQUIVALENT | 278.0 | 271.3 | 275.5 | -28.0 | WIN (rsv only, mshr unchanged) | yes |
| 2 | 2026-10-30 | R-2 | rsv snoop-hold factoring | iverilog | 12/12 | EQUIVALENT | 278.0 | 271.3 | 275.5 | -28.0 | LOSE (rsv 244.0 vs 240.4 at 200) | no |
| 3 | 2026-11-01 | M-2 | per-bit flat AND-OR output muxes | iverilog | 12/12 | EQUIVALENT | 282.9 | 272.4 | 280.4 | -32.9 | LOSE | no |
| 3 | 2026-11-01 | M-4 | parallel arbiter pick and next-mask prefixes | iverilog | 12/12 | EQUIVALENT | 275.6 | 263.7 | 273.1 | -25.6 | WIN | yes |
| 4 | 2026-11-01 | M-1 | per-slice response request/control copies | iverilog | 12/12 | EQUIVALENT | 296.2 | 287.3 | 293.7 | -46.2 | LOSE | no |
| 4 | 2026-11-01 | M-3 | response grant selects flag updates last | iverilog | 12/12 | EQUIVALENT | 282.1 | 267.9 | 279.6 | -32.1 | LOSE | no |
| 4 | 2026-11-01 | M-6 | parallel response round outcomes, select last | iverilog | 12/12 | EQUIVALENT | 279.1 | 273.8 | 276.6 | -29.1 | LOSE | no |
| 5 | 2026-11-01 | M-7 | all-channel round selects last | iverilog | 12/12 | EQUIVALENT | 270.7 | 264.6 | 268.2 | -20.7 | WIN | yes |
| 5 | 2026-11-01 | M-8 | absorb redundant masked-round gating | iverilog | 12/12 | EQUIVALENT | 271.7 | 264.6 | 269.2 | -21.7 | WIN (smaller gain) | no |
| 5 | 2026-11-01 | M-9 | parallel circular one-hot last pick | iverilog | 12/12 | EQUIVALENT | 281.3 | 268.9 | 278.8 | -31.3 | LOSE | no |

| iteration | mshr | entry | rsv | commit | Actions run |
|---|---|---|---|---|---|
| 0 | 278.0 / 271.3 / 275.5 | 230.5 / 230.5 / 228.0 | 252.3 / 248.2 / 249.8 | bb49958 | first run |
| 1 | 278.0 / 271.3 / 275.5 | 230.5 / 230.5 / 228.0 | 242.9 / 242.9 / 240.4 | d136d8c | 41054567569 |
| 2 | 278.0 / 271.3 / 275.5 | 230.5 / 230.5 / 228.0 | 242.9 / 242.9 / 240.4 | db9ae18 | 41061877208 |
| 3 | 275.6 / 263.7 / 273.1 | 230.5 / 230.5 / 228.0 | 242.9 / 242.9 / 240.4 | 75074d0 (M-4 source) | 41290245424 |
| 4 | 275.6 / 263.7 / 273.1 | 230.5 / 230.5 / 228.0 | 242.9 / 242.9 / 240.4 | 5aa332c (opt unchanged) | 41332990431 |
| 5 | 270.7 / 264.6 / 268.2 | 230.5 / 230.5 / 228.0 | 242.9 / 242.9 / 240.4 | 81c1a83 (M-7 source) | 41337210471 |

| id | idea | status | reason |
|---|---|---|---|
| R-1 | rsv timeout predecessor compare | won | rsv -9.4 ps at 200 |
| R-2 | rsv snoop-hold factoring | lost | 3.6 ps slower than opt |
| M-1 | per-slice parallel copies of the grant flops for the output muxes | untried | targets axi_read_req_line_addr path |
| M-2 | flat AND-OR output muxes | lost | +4.9 ps at 250/200; +1.1 ps sized |
| M-3 | compute granted / not-granted next state in parallel, grant selects last | untried | targets entry tk_q, busy_r, state |
| M-4 | parallel-prefix pick in arb_rr | won | -2.4 ps at 250/200; -7.6 ps sized; promoted on timing branch |
| M-5 | one CAM match vector per consumer | untried | targets lookup_* pins |
| M-1 | per-slice response control/request copies and arbitration | running | iteration 4; same-cycle flags/masks/grants checked; estimate +1-5% area |
| M-6 | parallel response payload outcomes, arbitration round selects last | running | iteration 4; copied-mask invariant; estimate +2-6% area |
| M-3 | granted/not-granted response flag updates in parallel | running | iteration 4; exact Shannon expansion; near unchanged area |
| M-1 | per-slice response request/control copies | lost | iteration 4: +20.6 ps at 250; buffer chain remains |
| M-3 | response grant selects flag updates last | lost | iteration 4: entry -9 ps but full MSHR +6.5 ps |
| M-6 | parallel response round outcomes, select last | lost | iteration 4: response improves but full MSHR +3.5 ps |
| M-7 | all-channel parallel payload outcomes, round selects last | running | iteration 5; extends the measured response benefit without promoting M-6 |
| M-8 | absorb redundant masked-round grant and next-mask gating | running | iteration 5; exact Boolean absorption, no new state |
| M-9 | parallel circular pick with one-hot last-served state | running | iteration 5; each last bit checked directly against reference last |
| M-7 | all-channel parallel payload outcomes, round selects last | won | iteration 5: -4.9 ps at 250/200, +0.9 sized allowed; promoted |
| M-8 | absorb redundant masked-round gating | won | iteration 5: -3.9 ps; smaller gain, combine in fresh candidate |
| M-9 | parallel circular pick with one-hot last-served state | lost | iteration 5: +5.7 ps at 250; CAM becomes critical |
| M-10 | combine M-7 payload factoring and M-8 arbiter absorption | running | iteration 6; fresh combined measurement, not assumed additive |
| M-11 | state-local token next value | running | iteration 6; decoder invariant and old-equation checker |
| M-12 | circular arbitration for control copies only | running | iteration 6; new control state decoded against original data masks |
