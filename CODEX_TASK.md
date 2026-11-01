# Task for the coding agent: l1d_mshr above 4 GHz

Read this file first. The long background is in PROMPT_ITERATION.md (sections 1 to 8); where the two differ, this file wins.

## Part 1: access and verification rules


## A. Where you may work (access scope)

You have write access to ONE repository only: https://github.com/cachefoundrydevs/mshr-reservation-timing (public).

* Work only on branches named `timing/<short-name>` (for example `timing/iteration-3-m1`). Never commit or push to `main`.
  I merge into `main` myself, after I have re-checked your work.
* You may change only: `variants/<id>/*.v`, `rtl/opt/*.v` (only when promoting a verified winner, on your `timing/` branch),
  `STATUS.md`, `ITERATION_LOG.md`, and new checker blocks added to `tb/*.v` (section C.4).
* You must NOT change: `rtl/ref/`, `rtl/common/`, `rtl/include/`, the existing comparisons in `tb/`, `formal/`, `flow/`, `scripts/`,
  `.github/workflows/`. If you think one of them is wrong, stop and tell me; do not edit it.
* The data-cache project this block came from is a different, private repository. You have no access to it and must not ask for it, copy
  from it, or refer to it. Nothing you write may name it, its owners or any person. Commit identity: `cachefoundrydevs`, noreply address.
* Do not create other repositories, forks, secrets, tokens or workflow files. If an action is not covered above, ask me first.

## B. Nothing is final until I have re-checked it

Your output is a proposal on a `timing/` branch. At the end of each iteration, give me a **review package**:
1. the list of files changed against `main`, with line counts;
2. for each changed file the exactness argument per change (section 2 of the first prompt);
3. the verification evidence of section C, copied from the Actions run (run id and commit).
I decide what is merged into `main` and what later goes anywhere else. Never say a version is "verified" without the evidence below.

## C. Functional verification: the new code must behave exactly like the original

A version counts as functionally the same as `rtl/ref/` only if ALL of the following hold in the same Actions run on the same commit:

1. **Compile**: lint column is `pass` or `iverilog`.
2. **Lockstep simulation**: `12/12` tests pass (`ref` and the candidate run side by side; every output compared every cycle, with
   the documented payload-valid exceptions only).
3. **Formal equivalence**: the bounded checks in `formal/run_formal.sh` all report `EQUIVALENT`.
4. **A checker for every new invariant** (a flop that must equal an expression, a copy of a flop, a one-hot vector). Add it to the
   matching `tb/*.v` as an extra block that counts into `errors` and prints `TEST FAILED` when broken. Never weaken or remove an
   existing comparison.
5. **No new exceptions** to the output comparison and no change to the reset behaviour, port list, parameters or latency.
6. If any item fails, the candidate is out regardless of timing: quote the `FAIL` / `MISMATCH` / `NOT PROVEN` lines and the first
   differing cycle, and explain the cause. A corrected version gets a NEW id.

Before you hand over a candidate, also do a written **self-review**: list every signal you added, every signal whose width or reset value
changed, and confirm per output pin that its value in every cycle is the same function of the same inputs and state as in `rtl/ref/`.

If a result looks too good (a gain over 30 ps from a small change), treat it as suspect: say so and ask me for the failing-group list and the
full worst path before promoting it.

## D. When you are unsure

Stop and ask. A slower correct version is always better than a faster version I cannot trust.


## Part 2: iteration 3 update


## Update since iterations 1 and 2 (2026-10-30)

Iteration 1: R-1 (reservation time-out predecessor compare) WON and is in `rtl/opt` (rsv 249.8 -> 240.4 ps at 200).
Iteration 2: R-2 (snoop-hold factoring) did NOT win (rsv 244.0 vs 240.4 at 200, 246.5 vs 242.9 at 250). Dropped.
2 of 10 iterations are used; 8 remain (iterations 3 to 10).

### New baseline (critical delay in ps, synthesis, ASAP7, ideal clock, no wires)

| Module | 250 ps | 250 sized | 200 ps |
|---|---|---|---|
| `l1d_mshr` | 278.0 | 271.3 | 275.5 |
| `l1d_mshr_entry` | 230.5 | 230.5 | 228.0 |
| `l1d_reservation_unit` | 242.9 | 242.9 | 240.4 |

## New goal: `l1d_mshr` must run above 4 GHz

4 GHz = 250 ps period. `l1d_mshr` is now the only module above 250 ps: slack at 250 ps is -28.0 ps (-21.3 ps after sizing).
The entry (228.0) and reservation unit (240.4) already pass 250 ps. A real design needs margin for skew, uncertainty and wires, so the
working goal in this flow is **l1d_mshr <= 230 ps at the 250 ps column**. Spend iterations 3 to 10 on `l1d_mshr` (and `l1d_arb_rr`
and `l1d_mshr_entry` where they feed its worst paths). Touch `l1d_reservation_unit` only if you have a clear idea worth more than 3 ps.
The keep rule of section 6 is unchanged (exact, lint, 12/12, EQUIVALENT, >= 1.0 ps better, nothing else > 1.0 ps worse), but judge the
win on the **250 ps and 250 ps sized columns first**, then on 200.

### Measured worst path of `l1d_mshr` (200 ps run)

`g_entry[1].u_entry.ar_arb_q` (DFFHQNx1, fanout 9, 47.8 ps clk-to-Q) -> OA222 one-hot select (39.3) -> AND3 (22.1) -> BUFx6f (15.7)
-> ... -> output `axi_read_req_line_addr[52]` (58-bit output, 8:1 one-hot mux). Slack -75.5 ps at 200.

Groups right behind it (200 ps): `refill_token_line_addr` -75.4, entry `tk_arb_q`/`tk_c_q`/`tk_q` -71.6, entry `busy_r` -71.4,
`response_packet` -67.8, `response_seat` -67.7, `axi_read_req_unique` -64.6, `entry_freed_pulses` -63.8, `lookup_entry_has_data` -59.9,
entry `state[]` -59.0, entry `line_r[]` -55.2 (457 endpoints), entry `buf_r[]` -49.8 (4093 endpoints), arbiter `mask_r` -43.5.
5905 endpoints fail at 200 ps. The pattern: **a grant (flop -> arbiter) drives a wide 8:1 mux, whose result goes to an output pin or into
entry state flops.** One structural change on this pattern fixes many endpoints at once.

## Design direction: make the leaf cells work in parallel

Think in terms of logic depth and fan-out per cycle. The leaf blocks (`l1d_cam`, `l1d_pri_enc`, `l1d_arb_rr`, the entry's data muxes)
currently sit in series on the worst paths. Use these exact-preserving ways to run them side by side (order = my expectation of value):

1. **Per-bit-slice parallel copies of the grant.** The 58/72-bit output muxes are driven by ONE grant flop set (fanout 9, weak flop,
   buffer tree). Give each slice of the output (for example 4 slices of ~15 bits) its own `(* keep *)` copy of the one-hot grant flops,
   loaded with the same next value. Each copy drives 1/4 of the AND-OR, so the buffer stage disappears. (Pattern "copies for fan-out",
   already used for the `*_gc` control copies.)
2. **Flat AND-OR instead of nested selects.** Build each output as one level AND of (grant_i & data_i) per entry and one OR over the 8
   entries, with the data side coming straight from flops. No binary decode, no OA222-AND3-BUF chain.
3. **Compute all candidates in parallel, select late.** For the arbiter grant -> entry next state path: compute the entry's next state for
   "granted" and for "not granted" in parallel from flops, and let the grant only drive the final 2:1 (pattern "the late signal last").
4. **Two-level / parallel-prefix pick** instead of a ripple priority chain in `l1d_pri_enc` and `l1d_arb_rr` (8 requests: 3 levels of
   prefix, not 7 in series), if the baseline code is a chain. Check the code first.
5. **Replicate the CAM compare per consumer.** `lookup_hit`, `lookup_entry_id`, `lookup_entry_has_data` share one match vector. If the
   match fan-out is on the path, compute the match twice (two `l1d_cam` instances or two reductions) so each consumer has its own.
6. **Fan-out limit for the entry-state flops** (`tk_q`, `busy_r`, `state`): one `(* keep *)` copy per consumer group.

Everything in section 2 stays: same outputs every cycle, same latency. Do NOT add a register stage between inputs and outputs. Moving a
mux select into a flop is allowed only with the "flop always equals expression" invariant (section 2), and remember the measured warnings
of section 5: "P5", "P11" and the "one cycle early" arbitration made the whole module slower. Parallel copies cost area, not cycles; say
how much area you expect (the baseline `l1d_mshr` area is 11644 in the flow's units) and avoid copies of the 512-bit buffer.

How to test several ideas at the same time: the workflow already builds every folder in `variants/` as its own job, in parallel. Propose
**up to 3 candidates per iteration, each on a different idea above**, so one Actions run measures them all; later combine winners as a
new candidate.

## Keep a status table (new standing instruction)

After every decision (Step F) also give me the complete new content of the file `STATUS.md` in the repository root. Rules:
* Plain Markdown tables only, newest iteration LAST in each table; never delete old rows.
* Table 1, `l1d_mshr` against 4 GHz: iteration | date (UTC) | candidate id | idea | lint | lockstep | formal | mshr 250 | mshr 250 sized |
  mshr 200 | slack at 250 (250 - value) | decision (WIN / LOSE / FAILED CHECK) | promoted to rtl/opt (yes/no).
* Table 2, all modules, one row per iteration: iteration | opt mshr 250 / 250 sized / 200 | opt entry 250 / 250 sized / 200 |
  opt rsv 250 / 250 sized / 200 | commit | Actions run id.
* Table 3, open ideas: id | idea | status (untried / running / won / lost / dropped) | reason.
* One line at the top: "4 GHz target (250 ps): l1d_mshr <value> ps, <met / NOT met>, working goal 230 ps".
* The first row of each table is the baseline above (iteration 0 = first run, iteration 2 = state after R-1 and R-2).
I commit `STATUS.md` together with `ITERATION_LOG.md`.

## Commit identity (public repo)

Do not put names, e-mail addresses or links to personal accounts in any file or commit message. I commit as `cachefoundrydevs` with the
noreply address only.

## Start now

Do Step A and Step B of iteration 3 with this goal: analyse the worst `l1d_mshr` path above in the code, name the leaf blocks in series,
and propose up to 3 candidates (ids `M-1`, `M-2`, `M-3`, ...), each with its exactness argument, risk and expected gain, followed by the
complete files (Step C) and the first version of `STATUS.md`.

