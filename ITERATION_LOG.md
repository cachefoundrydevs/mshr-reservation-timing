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


## Iteration 4 (2026-11-01)

Branch: timing/iteration-4-response, created from timing/iteration-1-r1 at
7c89d0c98fd024afbea47bccc81ada9365f74596. Latest baseline evidence is Actions
41293960919 on that exact promotion commit: opt 275.6 / 263.7 / 273.1 ps,
entry 230.5 / 230.5 / 228.0, reservation 242.9 / 242.9 / 240.4. Compile,
12/12 lockstep and all bounded formal checks pass. Read latest/RUN.txt,
latest/comparison.md and the full opt t250 violations report from results.

A: rs_arb_q -> masked/wraparound round-robin pick -> response mux/buffers
-> response_packet[70], -25.6 ps slack at 250. Response seat follows at
-25.5, token line at -22.1, entry line/seat/size at -20.1, token flags at
-18.6, AXI line at -18.4. The response request flop has fanout 7 and
47.8 ps clock-to-Q; the path includes two output-buffer stages totaling
42.8 ps. A response-only improvement can expose the token/address paths.

| id | module | idea | target | expected gain (estimate) | expected area | risk |
|---|---|---|---|---|---|---|
| M-1 | l1d_mshr | per-slice response control/request copies and arbitration | response packet/seat | response group 10-25 ps; module 0-8 ps | +1-5% vs 11643 | control input fanout, duplicated arbitration, unrelated remapping |
| M-6 | l1d_mshr | parallel masked/wraparound payload outcomes, round select last | response packet/seat | response group 5-20 ps; module 0-8 ps | +2-6% | round-select fanout and larger mux cone |
| M-3 | l1d_mshr via entry control | compute response-taken/not-taken flag updates in parallel | busy_r, tk_q and copies | module 1-10 ps | near unchanged | ABC may refactor identically or worsen other paths |

Exactness and self-review (before verification):

M-1, complete file variants/M-1/l1d_mshr.v:
* Baseline has request flops, not registered grants. Preserve every port by
  copying just dat/mrg/response-request control locally, not whole entries.
  For each entry and each slice, dat_copy has the original dat_q recurrence
  using e_ar == ar_q and the original accepted and beat-valid handshakes;
  mrg_copy is its last-beat pulse; rs_copy has the original response-request
  recurrence. All reset to zero at the same synchronous edge. Induction
  proves equality with dat_q, mrg_q and rs_arb_q after every edge.
* Each slice arbiter sees equal requests, the same reset and response_taken,
  hence equal masks and grants in every cycle. Its select has the identical
  entry-0 fallback. Only response_packet and response_seat use copied grants;
  original arbitration still drives valid/control, so no new feedback path.
  All response payload values are identical even when invalid. Every lookup,
  allocation, AXI, refill, install, busy and freed output is unchanged.
* Added: localparams M1_SLICES=AXI_BEATS, M1_SLICE_W=ceil(RESP_W/slices);
  RESP_W-bit m1_packet; N-bit m1_seat_sel; genvars ms/mg/mb; per-slice
  N-bit requests/grants/select_bits, RESP_W-bit combinational packet,
  integer k, and an unchanged l1d_arb_rr instance (its mask is N bits);
  per-entry scalar dat_copy/mrg_copy/rs_copy flops and beat_valid/last_copy
  wires. rs_pkt becomes wire, same RESP_W width. Default: 4 slices, 18 bits,
  96 scalar control copies plus the arbiters' masks. No buffer/data flops
  are copied. No old width/reset, parameter, port or latency changes.
* L1D_CHECK_M1 enables additional tb_mshr_equiv checks only for this shape:
  every copy against original dat/mrg/response flag, every slice mask,
  grant and fallback select against original arbitration. m1_bad is checked
  before input drive and adds to existing errors with TEST FAILED. The
  original comparisons are untouched. A local elaboration issue in the new
  checker was fixed before testing by using the test's AXI_BEATS constant
  rather than a hierarchical constant in generate bounds; RTL did not change.

M-6, complete file variants/M-6/l1d_mshr.v:
* m6_mask resets to the same zero mask and, only when a response is taken
  and valid, loads OR of the lower original grant bits. This is precisely
  the original next-mask function, so m6_mask == u_rs_arb.mask_r by induction.
  Masked and wraparound lowest picks are the same original gm/gu functions.
* Distribute selection over the two payload mux outcomes, then select with
  any masked request: mux(use, mux(gm,data), mux(gu,data)) equals the original
  mux(mux(use,gm,gu),data). Each outcome retains the entry-0 fallback. This
  changes only packet/seat cones. Valid, control and every other MSHR output
  use unchanged logic and state; no extra cycle or output-valid exception.
* Added: N-bit kept m6_mask state, zero reset; N-bit m6_mask_next/m6_masked/
  m6_gm/m6_gu/m6_sm/m6_su wires, scalar m6_use, genvar m6j, integer m6k,
  RESP_W-bit combinational m6_pm/m6_pu, SEAT_W-bit m6_tm/m6_tu.
  rs_pkt/rs_seat become wires with unchanged widths. No old reset, width,
  parameter, port or latency changes. No data-register copies.
* L1D_CHECK_M6 enables the new mask-equality, pick-equality and fallback
  one-hot checks in tb_mshr_equiv; the existing binary mux checker also
  checks actual payloads including invalid cycles. Failures add to errors
  and print TEST FAILED. Existing comparisons remain untouched.

M-3, complete file variants/M-3/l1d_mshr_entry.v:
* Shannon expansion on response_taken computes exactly F(0) and F(1) for
  busy_r, rs_n and tk_n, then selects the same-cycle result. This is a pure
  Boolean identity, including error/free and install priorities. State case,
  flag flop reset/update blocks and payload blocks otherwise stay unchanged.
* Added scalar wires m3_install_free, m3_busy_wait/m3_busy_taken,
  m3_tk_wait/m3_tk_taken. Existing rs_n/tk_n and busy_r D functions are
  rewritten but remain identical. No new flops, changed widths/reset,
  parameters, ports or latency. All entry output pins (busy, requests,
  unique, response/seat, buffer/has-data, install state, swap/slot, freed)
  therefore preserve the original same-cycle function by induction; all
  containing MSHR output pins also preserve their functions.
* L1D_CHECK_M3 enables an extra tb_mshr_entry_equiv checker comparing each
  rewritten next function directly with the old Boolean expression. It
  adds to errors, prints TEST FAILED, and does not alter old comparisons.

Local pre-checks: all three pass Verilog-2005 RTL compile, Verilator lint,
and 100000-cycle whole-MSHR lockstep with the new invariant checkers. M-3
also passes 150000-cycle entry lockstep and the six-cycle bounded entry
proof (FORMAL: ALL EQUIVALENT (mshr_entry)). No TEST FAILED or MISMATCH.
Local results are preliminary only. Actions on one source commit must
provide lint, 12/12 and all five formal results before any promotion.
Actions evidence: 41332990431 on commit
5aa332cffdd62e74a940b2e0e5d039aae865344c; results published 2026-11-01T18:29:45Z.
Fetched results and checked latest/RUN.txt, latest/comparison.md and the
complete latest/PASTE_TO_CHATGPT.md, including its empty failure-log section.
All candidates pass Icarus compile, 12/12 lockstep with their new checkers,
and all five bounded formal checks. No FAIL / MISMATCH / NOT PROVEN or first
differing cycle exists. Local checks remain preliminary, not the evidence
for the keep decision.

## Comparison (critical delay in ps, ASAP7, ideal clock, no wires; smaller is faster)

| version | lint | lockstep | formal | mshr 250 | mshr 250 sized | mshr 200 | entry 250 | entry 250 sized | entry 200 | rsv 250 | rsv 250 sized | rsv 200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| M-1 | iverilog | 12/12 | EQUIVALENT | 296.2 | 287.3 | 293.7 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| M-3 | iverilog | 12/12 | EQUIVALENT | 282.1 | 267.9 | 279.6 | 221.5 | 221.5 | 219.0 | 242.9 | 242.9 | 240.4 |
| M-6 | iverilog | 12/12 | EQUIVALENT | 279.1 | 273.8 | 276.6 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| R-2 | iverilog | 12/12 | EQUIVALENT | 275.6 | 263.7 | 273.1 | 230.5 | 230.5 | 228.0 | 246.5 | 246.5 | 244.0 |
| opt | iverilog | 12/12 | EQUIVALENT | 275.6 | 263.7 | 273.1 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| ref |  |  |  | 542.3 | 463.0 | 539.8 | 476.6 | 418.5 | 474.1 | 258.0 | 251.5 | 255.5 |

A version may replace rtl/opt only if lint passes, lockstep is 12/12, formal is EQUIVALENT, and it is faster (see PROMPT_ITERATION.md).

Decision: all three LOSE on timing; no promotion. First consecutive iteration
without a win. Do not spend iterations 6-10 if iteration 5 also has no win.

* M-1: MSHR +20.6 / +23.6 / +20.6 ps vs opt. Area 11718 vs 11643 (+75).
  Worst 250 ps path starts at g_m1_slice[3].g_copy[2].rs_copy and ends at
  response_packet[61], -46.2 ps. The copied request still has fanout 7 and
  47.6 ps clock-to-Q; arbitration and buffering remain. AXI line is -43.7
  and token line -40.6. Copies did not remove the limiting dependency.
* M-3: MSHR +6.5 / +4.2 / +6.5 ps. Its standalone entry improves by 9.0 ps
  in all three columns (221.5 / 221.5 / 219.0), but that does not offset
  the full-MSHR regression. Area 11650. New worst path line_r[8] -> CAM/
  priority/has-data logic -> lookup_entry_has_data, -32.1 ps at 250.
* M-6: MSHR +3.5 / +10.1 / +3.5 ps. Area 11691. Response group improves
  from -25.6 to -12.6 ps at 250, but AXI address becomes -29.1 and token
  flag D paths -28.3. This partial benefit motivates a fresh candidate
  covering all channels; the losing M-6 is not promoted.

The complete sources (437-line M-1 top, 555-line M-3 entry, 427-line M-6 top)
remain in tested commit 5aa332c. Their variant folders are removed after
this decision. Their exactness arguments and full added-signal inventories
are above. The checker additions are retained; no old comparison is removed.
No opt or protected path changed in this iteration. New baseline stays
275.6 / 263.7 / 273.1 MSHR; 230.5 / 230.5 / 228.0 entry;
242.9 / 242.9 / 240.4 reservation. Goal gap remains 45.6 ps to 230 unsized.
Nothing is merged to main; all work remains a proposal for user re-check.

## Iteration 5 (2026-11-01)

No iteration 4 timing candidate can satisfy the keep rule, so the baseline
remains M-4: MSHR 275.6 / 263.7 / 273.1 ps; entry 230.5 / 230.5 / 228.0;
reservation 242.9 / 242.9 / 240.4. Source is the unchanged opt tuple from
7c89d0c. Current response path remains rs_arb_q -> round-robin pick ->
response mux/buffers -> response_packet[70], -25.6 ps at 250. All estimates
below target the full MSHR. No claim is made from local tests alone.

Iteration 4 guidance: M-6's response group improves to -12.6 ps, but AXI
address becomes -29.1 and token flags -28.3. Generalize late round selection
across the channels rather than promoting the regressing M-6. M-1's copied
request still has fanout 7 and 47.6 ps clock-to-Q, followed by a long mux/
buffer chain; it did not remove that dependency. M-3 exposes a -32.1 ps CAM
path and worsens full-MSHR timing despite the standalone entry gain. M-5 is
deferred: the retained baseline CAM path is 14.9 ps behind its response
maximum, so a CAM-only change does not address the current limiting path.

| id | module | idea | target | expected gain (estimate) | expected area | risk |
|---|---|---|---|---|---|---|
| M-7 | l1d_mshr | parallel masked/wraparound payloads on all three channels, round selects last | AXI/response/token outputs | 5-20 ps | +1-3% vs 11643 | new copy-mask D paths or remaining entry-control paths can dominate |
| M-8 | l1d_arb_rr within MSHR | absorb redundant masked-round gating in grant and mask next | all grants, output muxes and entry control | 2-15 ps | near unchanged, within roughly 1% | synthesis may refactor identically or remap another cone adversely |
| M-9 | l1d_arb_rr within MSHR | parallel circular interval picks with one-hot last-served state | all three grant/mux and control paths | 5-25 ps | +1-5% | request fanout and interval logic area can erase the depth gain |

Exactness and self-review:

M-7, complete file variants/M-7/l1d_mshr.v:
* For each ar/rs/tk channel, the new kept mask resets to zero and loads the
  prefix of the original grant only on the original taken-and-valid enable.
  This is the original next-mask function; induction gives equality with
  the original arbiter mask every cycle. The masked and unmasked lowest
  picks are identical to its gm/gu. Each outcome preserves the entry-0
  fallback. Distribute the unchanged selected payload function across its
  two round choices and select the round last; no cycle is moved.
* AXI line and unique, response packet and seat, and token line therefore
  retain their values in every cycle, including invalid cycles. AXI sub-ID,
  response valid, token ID/valid and all control remain on the original
  arbiters. Lookup, allocation, install state/swap/slot/data, busy and freed
  pins are unchanged. No new feedback into the original control state.
* Added for each channel: N-bit m7_<channel>_mask state (zero reset), N-bit
  m7_<channel>_next/masked/gm/gu/sm/su wires, scalar m7_<channel>_use, and
  genvar m7_<channel>_j. Added combinational LINE_ADDR_W-bit m7_am/au/km/ku,
  scalar m7_um/uu, RESP_W-bit m7_pm/pu, SEAT_W-bit m7_tm/tu, integer m7k.
  ar_line/tk_line/ar_unique/rs_pkt/rs_seat become wires with the same widths;
  procedural integer s is removed. Default widths: N=8, line=58, packet=72,
  seat=3. No old reset value, parameter, port, width or latency changes.
  No payload register or 512-bit buffer is copied.
* L1D_CHECK_M7 enables a new tb_mshr_equiv block for each channel checking
  copied masks, both picks and one-hot fallback selects. Existing raw mux
  checks also compare all affected outputs to independent binary selection.
  Errors add to the existing counter and print TEST FAILED; original
  comparison lines remain intact.

M-8, complete file variants/M-8/l1d_arb_rr.v:
* A nonzero masked winner or masked lower prefix implies use_masked=1.
  Thus use_masked ? gm : gu equals gm OR (gu AND NOT use_masked), and the
  same absorption holds for mm/mu in mask_next. These are exact Boolean
  identities on the original gm/gu/mm/mu functions. Mask reset, width and
  update enable are unchanged. Induction preserves state; grant, index
  and any-request ports are identical, hence every containing MSHR pin is
  unchanged in every cycle. No added signals, flops, widths, resets, ports,
  parameters or latency. Both changed assignments are marked M-8.
* An additional block in check_parallel_pick in tb_arb_rr_equiv checks the
  implication for every existing N=2,3,4,5,8 instance, counts into errors,
  and prints TEST FAILED. No old comparison or checker was removed.

M-9, complete file variants/M-9/l1d_arb_rr.v:
* New invariant m9_last[j] == (reference last == j). Reset sets bit N-1,
  exactly encoding the original last=N-1; a taken valid grant loads its
  one-hot winner, otherwise state holds. For each candidate winner i and
  last j, a constant circular interval covers j+1 through i-1, excluding i.
  A request wins iff its bit is set and that preceding interval is empty.
  Exactly one term is active in the one-hot last vector, so this is the
  original circular priority order. All modulo operations are elaboration
  constants, not runtime arithmetic. Grant is zero with no requests, and
  the unchanged one-hot index encoder returns zero then. any_request is
  unchanged. This proves same port values and turn updates by induction.
* Added N-bit m9_last state (reset highest bit=1, remaining bits=0), N-bit
  m9_grant, genvars m9i/m9j/m9k, per-winner N-bit turns, per-last N-bit
  blockers and localparam BEFORE. mask_r changes from N-bit register to
  N-bit derived wire: its bit j is OR of m9_last below j, exactly the old
  above-last thermometer value (zero at reset). Old mask clocked block is
  removed; no existing externally visible reset behavior, port, parameter,
  width or latency changes. Existing mask/gm/gu/mm/mu probe names remain
  valid; unused compatibility logic is pruned from synthesis.
* L1D_CHECK_M9 enables check_circular_last in tb_arb_rr_equiv, comparing
  every new state bit directly with the corresponding reference binary
  last for N=2,3,4,5,8, thereby checking the one-hot invariant as well.
  It counts into errors and prints TEST FAILED; all old comparisons remain.
  Identical arbiter ports preserve every containing MSHR output function.

Local pre-checks: M-7/M-8/M-9 pass Verilog-2005 RTL compile, Verilator
lint, and 100000-cycle MSHR lockstep. M-8/M-9 also pass 20000-cycle arbiter
lockstep for N=2,3,4,5,8 (including the new invariant checkers) and the
20-cycle N=4 and N=3 bounded arbiter proofs. No TEST FAILED or MISMATCH.
Local evidence is preliminary only. One Actions commit must provide lint,
12/12, all five EQUIVALENT checks and acceptable timing before promotion.
Actions evidence: run 41337210471, source commit
81c1a8396ac77b2215ab0bb00936251daae9e75d, published 2026-11-01T19:18:15Z.
Fetched results and checked latest/RUN.txt, latest/comparison.md, the entire
latest/PASTE_TO_CHATGPT.md (empty failure-log section), and the full M-7
250 ps worst-path report. All candidates pass Icarus compile, 12/12
lockstep, and all five bounded formal checks with their added invariants.
No FAIL / MISMATCH / NOT PROVEN or first differing cycle exists.

## Comparison (critical delay in ps, ASAP7, ideal clock, no wires; smaller is faster)

| version | lint | lockstep | formal | mshr 250 | mshr 250 sized | mshr 200 | entry 250 | entry 250 sized | entry 200 | rsv 250 | rsv 250 sized | rsv 200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| M-7 | iverilog | 12/12 | EQUIVALENT | 270.7 | 264.6 | 268.2 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| M-8 | iverilog | 12/12 | EQUIVALENT | 271.7 | 264.6 | 269.2 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| M-9 | iverilog | 12/12 | EQUIVALENT | 281.3 | 268.9 | 278.8 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| R-2 | iverilog | 12/12 | EQUIVALENT | 275.6 | 263.7 | 273.1 | 230.5 | 230.5 | 228.0 | 246.5 | 246.5 | 244.0 |
| opt | iverilog | 12/12 | EQUIVALENT | 275.6 | 263.7 | 273.1 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| ref |  |  |  | 542.3 | 463.0 | 539.8 | 476.6 | 418.5 | 474.1 | 258.0 | 251.5 | 255.5 |

A version may replace rtl/opt only if lint passes, lockstep is 12/12, formal is EQUIVALENT, and it is faster (see PROMPT_ITERATION.md).

Decision: M-7 and M-8 both WIN under the keep rule. M-7 improves MSHR by
4.9 ps at 250 and 200; M-8 improves by 3.9 ps. Both are 0.9 ps worse sized,
within the explicitly allowed 1.0 ps limit. All entry/reservation columns
are unchanged. Select M-7 for the larger primary gain. M-8 is not promoted;
its combination with M-7 is a fresh iteration 6 candidate, not an assumed gain.
M-7 area is 11801 (+158, about 1.36%); M-8 area is 11635 (-8) vs 11643.
No gain exceeds the 30 ps suspect-result threshold.

New M-7 worst path at 250: g_entry[5].u_entry.rs_c_q -> response control
arbitration -> token next function -> g_entry[4].u_entry.tk_arb_q, -20.7 ps.
Clock-to-Q 42.9 ps, arrival 242.8, required 222.1 (12.5 ps uncertainty and
15.4 ps setup). Busy D follows at -18.8 and state D at -15.4. Payload
outputs no longer dominate. M-8's worst path is token control to token
flags, -21.7 ps. These measurements guide the next control-only changes.

M-9 LOSES: +5.7 / +5.2 / +5.7 ps vs opt, despite passing all functional
checks. Area 11654. Worst path line_r[50] -> compare/priority ->
lookup_entry_has_data, -31.3 ps; lookup ID -30.2, AXI line -26.8 and token
line -25.6. Circular picking helped some arbitration paths but lost globally.

Promoted to rtl/opt: l1d_mshr.v, byte-identical to M-7 in source 81c1a83.
SHA-256: b1aae73a804175162f84a58e0550ec7f5b09c746332588ca8b89ee6193802fae. Other opt files are
identical to that run's M-7 tuple. Removed M-7/M-8/M-9 folders after the
decision; complete files (480 / 133 / 159 lines) remain in commit 81c1a83.
Also removed the stale already rejected R-2 folder from future workflow
matrices; its code and results remain in history and every status row stays.
This cleanup changes no opt behavior.

New baseline (250 / sized / 200): MSHR 270.7 / 264.6 / 268.2; entry
230.5 / 230.5 / 228.0; reservation 242.9 / 242.9 / 240.4 ps. The 4 GHz
target is still NOT met; gap to working goal 230 is 40.7 ps unsized.
The consecutive-no-win counter resets to zero. No main merge or push.
The written arguments, complete added-signal inventories and per-pin
self-review for every candidate are above. All old comparisons and all
protected paths are preserved; this remains a proposal for user re-check.
