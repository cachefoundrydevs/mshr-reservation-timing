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


## Iteration 3 (2026-11-01)

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

Actions evidence: run 41290245424, source commit
75074d07075ebd5891abc699821562acd4ae28af. Results published 2026-11-01T09:35:47Z.
Read using git fetch origin results, then latest/RUN.txt, latest/comparison.md,
and latest/PASTE_TO_CHATGPT.md. All four tested non-reference versions passed
Icarus compile, 12/12 lockstep tests (including the added checkers), and all
five bounded formal checks: arb_rr / arb_rr3 (20 cycles), mshr_entry (6),
rsv (12), rsv_to (16). The published failure-log section is empty.

## Comparison (critical delay in ps, ASAP7, ideal clock, no wires; smaller is faster)

| version | lint | lockstep | formal | mshr 250 | mshr 250 sized | mshr 200 | entry 250 | entry 250 sized | entry 200 | rsv 250 | rsv 250 sized | rsv 200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| M-2 | iverilog | 12/12 | EQUIVALENT | 282.9 | 272.4 | 280.4 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| M-4 | iverilog | 12/12 | EQUIVALENT | 275.6 | 263.7 | 273.1 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| R-2 | iverilog | 12/12 | EQUIVALENT | 278.0 | 271.3 | 275.5 | 230.5 | 230.5 | 228.0 | 246.5 | 246.5 | 244.0 |
| opt | iverilog | 12/12 | EQUIVALENT | 278.0 | 271.3 | 275.5 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| ref |  |  |  | 542.3 | 463.0 | 539.8 | 476.6 | 418.5 | 474.1 | 258.0 | 251.5 | 255.5 |

A version may replace rtl/opt only if lint passes, lockstep is 12/12, formal is EQUIVALENT, and it is faster (see PROMPT_ITERATION.md).

Decision: M-4 WINS. MSHR improves by 2.4 ps at 250, 7.6 ps at 250 sized,
and 2.4 ps at 200; entry and reservation columns are identical to opt.
Its MSHR area is 11643 flow units versus 11644 for opt. The gain is below
the 30 ps suspect-result threshold. The original AXI address group improves
by 9.6 ps, but the response packet group worsens by 5.3 ps and becomes the
worst group. This endpoint regression is disclosed; the keep rule compares
module maxima and timing columns, all of which improve or stay unchanged.
New worst 250 ps path: g_entry[1].u_entry.rs_arb_q -> round-robin pick ->
response mux/buffers -> response_packet[70], slack -25.6 ps (200: -73.1 ps).
The 4 GHz target and 230 ps working goal are NOT met; the sized gap is 13.7 ps.

M-2 LOSES on timing despite passing every functional check: +4.9 ps at
250 and 200, +1.1 ps sized. MSHR area 11650. The AXI address group barely
changes (-28.1 vs -28.0 ps at 250), and the new maximum is
rs_c_q -> response/free control -> another entry's busy_r, slack -32.9 ps.
No function-check FAIL / MISMATCH / NOT PROVEN line or differing cycle exists.

Promoted to rtl/opt: l1d_arb_rr.v, copied byte-for-byte from M-4 on this timing
branch only. Source SHA-256: e513301e34c32c7f2cc0f50b7429c6b1374f861ee87047f8ec12c83f01939257.
Removed this iteration's M-2 and M-4 folders; complete sources remain in
commit 75074d0. Existing R-2 is unchanged from the starting branch.
New baseline (250 / sized / 200): mshr 275.6 / 263.7 / 273.1;
entry 230.5 / 230.5 / 228.0; rsv 242.9 / 242.9 / 240.4 ps.
Table 2 in STATUS.md cites the tested M-4 source commit, not a new measurement
of the promotion commit. No other RTL file changed in this iteration; no
ports, latency, parameters, reset values, or signal widths changed. The
added combinational signals and all output-pin arguments are listed above.

Protected files and every original comparison line were preserved. The
complete changes against main also include inherited CODEX_TASK.md, the R-1
reservation promotion, and the old R-2 candidate, none edited in iteration 3.
Inherited R-1 is the TO_W-bit modular predecessor identity described in
iteration 1. Inherited R-2 factors hold/install and release conditions while
retaining the new-read assignment's priority; its function checks also passed
in this run, but its slower timing remains rejected. Documentation has no
hardware behavior; checker additions only strengthen existing verification.

This is a proposal for user re-check. Nothing is merged into main.
