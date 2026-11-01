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


## Iteration 3 (2026-11-01): proposals awaiting Actions

Baseline evidence: run 41061877208, commit db9ae18df94f90b84f049e3620f407a6436af11a.
MSHR 250 / sized / 200: 278.0 / 271.3 / 275.5 ps. The 250 ps worst
path is ar_arb_q -> masked round-robin pick -> fallback one-hot mux ->
axi_read_req_line_addr[52], slack -28.0 ps. Token addresses follow at -27.9 ps;
token flags and busy follow at -24.1 / -23.9 ps. At 250 ps the entry and
reservation blocks already pass (230.5 / 242.9 ps).

| id | module | idea | target group | expected gain (estimate) | risk |
|---|---|---|---|---|---|
| M-2 | l1d_mshr | transpose output muxes into per-bit AND terms and reduction OR | AXI/token line addresses, response packet/seat | 2-15 ps | ABC may normalize to the old circuit or worsen select fanout |
| M-4 | l1d_arb_rr within l1d_mshr | independent prefix reductions for both picks and next masks; parallel OR encoding | request flop through grant to mux and entry handshakes | 5-20 ps | higher prefix input fanout; index path or unrelated mapping may worsen |

Exactness and self-review:

* M-2 adds only combinational generate scopes g_m2_line/g_m2_packet/g_m2_seat,
  vectors ar_terms/tk_terms/terms (N bits per output bit), and elaboration
  indices mb/me. ar_line, tk_line, ar_unique, rs_pkt, rs_seat change from reg
  to wire with the same widths; procedural index s is removed. Each bit is
  OR_i(select_i AND data_i), identical by associativity to the old loop.
  ar_sel/rs_sel/tk_sel are unchanged, including entry 0 for no grant.
  Only AXI address/unique, token address, response packet/seat cones change;
  their values match in every cycle, including invalid cycles. All other
  output pins and all state updates use unchanged logic. No added flops,
  changed reset values, width changes, ports, parameters, or latency.
  Expected area near the baseline 11644 flow units: no additional state;
  actual combinational area must be measured.
* M-4 removes combinational im/iu, seen_m/seen_u, bm/bu, and procedural
  indices i/m. It retains gm/gu/mm/mu as N-bit wires instead of regs;
  adds IDX_W-bit picked_index, N-bit terms per encoded bit, and elaboration
  indices j/ib/ie. gm[j] = masked[j] AND NOT OR(masked[j-1:0]); gu likewise
  on unmasked requests. These are exactly the old lowest-set picks.
  OR of the lowest-set pick below j equals OR of its input below j, so
  mm/mu equal the old next masks, including zero requests. mask_r reset,
  update enable, mask_next selection, and width are unchanged; induction
  gives the same round-robin state after every edge. grant_onehot and
  any_request are unchanged functions; grant_index OR-encodes the same
  one-hot grant and is zero with no requests. Every containing MSHR pin
  therefore retains its same-cycle function. No added flops, changed
  reset values, ports, parameters, latency, or signal widths. Expected
  area near baseline, with possible combinational duplication; measure it.
* New tb_mshr_equiv checker checks one-hot selects, idle entry-0 fallback,
  and all mux outputs against independent binary selection, without valid
  masking. New tb_arb_rr_equiv checker scans both request sets and checks
  gm/gu and mm/mu for N=2,3,4,5,8. Both count into errors and print
  TEST FAILED on violation. Existing comparisons remain unchanged.
* M-1 deferred: baseline has request flops, not registered grants; copies
  need a carefully proved topology within the unchanged port contract.
  M-3 remains untried. Existing R-2 is retained unchanged from the branch.

Decision: pending. Neither candidate is claimed verified or promoted.
The same-commit Actions compile, 12/12 lockstep, five bounded formal checks,
and all timing columns are required before deciding. Nothing is merged to main.
