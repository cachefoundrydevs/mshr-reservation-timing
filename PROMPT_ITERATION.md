# Prompt: 10 timing-optimisation iterations of the MSHR and the reservation unit

How to use this file:

1. Open a new ChatGPT conversation (a model with file reading and code skills; web browsing helps if you give the repository link).
2. Paste everything between the two lines `===== PROMPT START =====` and `===== PROMPT END =====` as your first message.
3. Attach (or paste) these files, so the assistant sees the real code. Attaching the whole repository as a zip also works:
   `rtl/opt/l1d_mshr.v`, `rtl/opt/l1d_mshr_entry.v`, `rtl/opt/l1d_arb_rr.v`, `rtl/opt/l1d_reservation_unit.v`,
   `rtl/ref/` (the same four originals), `rtl/common/*.v`, `rtl/include/*.vh`, `tb/*.v`, `formal/fv_wrap_mshr_entry.v`.
4. Follow the loop the assistant drives: it gives you files for `variants/<name>/`; you commit and push them; GitHub Actions runs
   (30-90 minutes); you paste the results back (what to paste is described in the prompt, section 7). Repeat until 10 iterations are done.

You need: a GitHub account, this repository (public, so Actions minutes are free), and git on your computer (or the GitHub web editor:
"Add file" -> "Create new file", type `variants/<name>/l1d_mshr.v` as the name, paste the content, "Commit changes").

---

===== PROMPT START =====

## 0. Repository and how results reach you

The repository is https://github.com/cachefoundrydevs/mshr-reservation-timing (public). I attach it as a zip; the files you need are
`rtl/opt/*.v`, `rtl/ref/*.v`, `rtl/common/*.v`, `rtl/include/*.vh`, `tb/*.v`, `formal/fv_wrap_mshr_entry.v`, `formal/run_formal.sh`,
`scripts/run_all.sh`, `.github/workflows/mshr_rsv.yml`.

If you cannot reach `api.github.com`, do not try: after every Actions run the workflow writes its results to the git branch `results`,
which you can read with plain git (`git fetch origin results`, then `git show origin/results:latest/comparison.md`; `latest/RUN.txt` names the
run and commit, older runs are in `runs/<run id>_<commit>/`). Most of the time I simply paste the file `PASTE_TO_CHATGPT.md` of that branch to you: it holds the comparison table, the details per version and the first lines of every failing log, i.e. everything section 7 lists.

## 1. Your role and the goal

You are a senior digital-design engineer who specialises in **timing closure at the RTL level**. You will run **10 iterations** of timing
optimisation on two Verilog blocks of an L1 data cache, together with me. I run the tools (GitHub Actions does all simulation, formal
checking and synthesis); you read the results I paste and decide.

The goal is a **lower critical delay** (faster logic) of these three modules, with the targets 250 ps (4 GHz) and 200 ps (5 GHz) in the
open ASAP7 7 nm library:

| Module | File | What it is |
|---|---|---|
| `l1d_mshr` | `rtl/opt/l1d_mshr.v` (uses `l1d_mshr_entry`, `l1d_arb_rr`, `l1d_cam`, `l1d_pri_enc`) | 8 miss entries, CAM lookup, free-entry pick, 3 round-robin arbiters with output muxes |
| `l1d_mshr_entry` | `rtl/opt/l1d_mshr_entry.v` | one miss entry: allocation, AXI read, 4 beats into a 512-bit line buffer, merge of the primary store, response packet, refill token, install |
| `l1d_reservation_unit` | `rtl/opt/l1d_reservation_unit.v` | LR/SC reservation and AMO lock with snoop hold and a time-out counter |

`l1d_arb_rr` (`rtl/opt/l1d_arb_rr.v`) may be changed too; it is checked on its own and inside the MSHR.

## 2. The rule that is never broken: exact equivalence

Every version you propose must be **exactly equivalent** to the original in `rtl/ref/`:

1. **Same value on every output pin in every clock cycle**, for every input sequence after reset. The only exceptions are the ones the
   tests already list (payload pins compared only while their valid bit is 1, e.g. `response_packet` only while `response_valid`,
   `lookup_entry_has_data` only while `lookup_hit`, `line_buffer_data` only while `line_buffer_has_data`). Do not add new exceptions.
2. **Same number of clock cycles** for everything. Do not add a register stage in any path from an input to an output, do not delay any
   output by a cycle, do not make any decision one cycle later. Moving work between cycles is allowed only if the result is still identical
   in every cycle (see section 5, "computing the next value early").
3. **Same ports**: names, widths, directions, parameters. Same module names. One module per file.
4. **Do not edit** `rtl/ref/`, `rtl/common/`, `rtl/include/`, the tests' comparisons, the formal wrapper or the scripts to make a version
   pass. A test may only be changed to follow a renamed internal probe (section 4), never to compare less.

For every change you propose, write a short **exactness argument**: why the new logic gives the same value in every cycle (an invariant:
"flop X always equals expression Y, because it is loaded with Y's next value wherever Y's inputs change"; or "the two forms are the same
Boolean function"; or "this value is used only when ..., and then ...").

## 3. Coding rules

* Verilog-2005 only (no SystemVerilog in `rtl/`). Synchronous reset `rst`, active high. No latches (every combinational `always @*`
  assigns every output on every path). No `initial` blocks in RTL. No `#` delays.
* Parameterise every width; derive widths from the existing parameters (`$clog2`, the localparams in `rtl/include/l1d_fields.vh`);
  no new numeric size literals. Put the value at the default configuration in a comment where a width is declared, for example
  `reg [N-1:0] free_q; // N = 8 bits`.
* Keep the existing comment style: a short `// TIMING OPT (<id>): ...` comment at each change saying what changed and why it is exact.
* Name each candidate with an id: `M-1`, `M-2`, ... for the MSHR, `E-1`, ... for the entry, `R-1`, ... for the reservation unit, `A-1`,
  ... for the arbiter. Never reuse an id.
* Duplicated flops that synthesis could merge need `(* keep *)` on the `always` block (the existing code does this, see `l1d_mshr_entry.v`).

## 4. Internal names the tests read (keep them, or tell me to update the test)

The tests look inside the optimised modules at a few internal signals:

| Test | Reads | Purpose |
|---|---|---|
| `tb/tb_mshr_equiv.v` | `dut_opt.ar_g`, `ar_gc`, `rs_g`, `rs_gc`, `tk_g`, `tk_gc` of `l1d_mshr` | checks that the control copies of the 3 arbiters always grant the same as the output arbiters |
| `tb/tb_mshr_entry_equiv.v` | `dut_opt.state` of `l1d_mshr_entry` | only printed in a mismatch message |

If a candidate removes or renames one of them, give me the matching one-line change of the test as well (only the probe name, never the
comparison).

## 5. Where the time goes now, what helps and what did not

### Baseline (critical delay in ps, synthesis only, ASAP7, ideal clock, no wires)

| Module | 250 ps | 200 ps | Worst endpoint groups at 200 ps (slack in ps) |
|---|---|---|---|
| `l1d_mshr` | 278.0 (271.3 after gate sizing) | 275.5 | `axi_read_req_line_addr` -75.5 (58 endpoints), `refill_token_line_addr` -75.4, entry `tk_arb_q` / `tk_c_q` / `tk_q` -71.6, entry `busy_r` -71.4, `response_packet` -67.8 (72), `response_seat` -67.7, `axi_read_req_unique` -64.6, `entry_freed_pulses` -63.8, `lookup_entry_has_data` -59.9, entry `state` -59.0 (47), entry `inst_q` -55.3, entry `line_r` -55.2 (457) |
| `l1d_mshr_entry` | 230.5 (230.5 sized) | 228.0 | `buf_r` -28.0 (512 endpoints), `ld_beat_r` -6.0 |
| `l1d_reservation_unit` | 252.3 (248.2 sized) | 249.8 | `to_last` -49.8, `to_cnt` -42.9, `amo_lock_snoop_hold` -30.7, `amo_lock_valid` -22.1, `reservation_valid` -19.0, `sc_reservation_matches` -18.0, `amo_lock_timeout_pulse` -16.8 |

(Measured in the first Actions run of this repository, 2026-10-30: all checks passed, lockstep 12/12, formal EQUIVALENT. For the original, `ref`: mshr 542.3 / 463.0 sized / 539.8, entry 476.6 / 418.5 / 474.1, rsv 258.0 / 251.5 / 255.5. From now on use the `opt`
row of the newest comparison table as the baseline.)

### Structure of the slow paths (read the code to confirm)

* `l1d_mshr`, outputs: entry request flops -> `l1d_arb_rr` grant -> one-hot AND-OR over 8 entries x 58 / 72 bits -> output pin. Three
  leaf blocks in series in one cycle.
* `l1d_mshr`, lookup: entry line flops -> `l1d_cam` (8 x 58-bit compare) -> `l1d_pri_enc` / lowest-match one-hot -> `lookup_*` pins.
* `l1d_mshr` -> entry next state: arbiter grant -> entry handshake (accepted / taken / granted) -> entry state and flags. A control copy of
  each arbiter (`*_gc`) already drives these, so the output muxes do not load that path.
* `l1d_mshr_entry`, `buf_r`: the 512-bit line buffer is written from 4 sources (idle load, swap data, AXI beat, store merge).
* `l1d_reservation_unit`, `to_last` / `to_cnt`: the time-out counter and its "last value" flag, loaded under the lock-set / clear
  conditions that come from the Stage 2 inputs.

### Patterns that worked in this design (all exact)

* **One-hot instead of binary**: select a winner's data with an AND-OR of the one-hot grant, not with `data[index*W +: W]`; keep one-hot
  pointers / levels instead of counters with adders.
* **A flag in a flop instead of a compare**: `x_q` that always equals `(cnt == LAST)`, loaded with the compare of the next value.
* **The late signal last**: build the two results (with / without the late event) in parallel from flops and let the late signal only
  select between them in the last 2:1 (a FIFO level with the pop as the last select made two blocks 50 ps faster).
* **Copies for fan-out**: a second copy of a flop (with `(* keep *)`) that drives only one group of loads (the control arbiter copies).
* **Idle loading**: a register that is never read while its owner is free may load the incoming value in every idle cycle, so the load
  enable no longer waits for the "allocate" decision (exact only if nobody reads it while free: check every reader).

### Ideas that were measured and made it SLOWER (do not repeat them unchanged)

* MSHR "P5": payload registers loaded in idle cycles without the entry-0 fallback: the target paths vanished but the rest of the module
  was mapped 15-30 ps slower (296.9 vs 274.6 ps at 250).
* MSHR "P11": arbiter requests pre-masked in flops (`request & mask` registered): outputs 5-13 ps faster, grant -> next state 10-20 ps
  slower (284.3 vs 274.6).
* Computing a whole arbitration or oldest-pick **one cycle early** from next-state values (in other blocks of this design): the
  next-state side became 30-130 ps slower than the path it removed. If you try this, keep the next-state logic very small.
* Gate sizing is not a design change: it recovers 3-10 ps; the gaps above are real.

Synthesis (ABC) is not monotonic: a change can make an unrelated path slower. That is why **every candidate is measured** and only a
measured improvement is kept.

## 6. The iteration loop (10 iterations)

Run exactly this loop. One iteration = one round of candidates, one Actions run, one decision.

**Step A: analyse.** From the latest results (section 7), name the worst endpoint groups of each module and read the code that drives
them. State in one or two sentences what the worst path is (start flop -> logic -> end flop) and how much it must lose.

**Step B: propose 1 to 3 candidates.** Each candidate is ONE idea (so a result can be traced to it), for ONE module where possible.
Different candidates may target different modules. For each candidate give:
* id and name, target module and target endpoint group, expected gain (an estimate, say so);
* the exactness argument (section 2);
* the risk (which other path could get slower).

**Step C: give me the files.** For each candidate, the **complete** content of every changed file (never a diff, never "..." or "rest
unchanged"), each in its own code block, with the path it goes to: `variants/<id>/<file name>`. Only the changed files; the others are
taken from `rtl/opt/` automatically. Check before you answer: the file compiles in your head (declarations before use, widths match,
every `begin` has its `end`), ports are unchanged, no latch, no new size literal.

**Step D: I push.** I create the folders, commit and push. GitHub Actions runs every version (`ref`, `opt`, and each `variants/<id>`).

**Step E: I paste the results** (section 7). You read them.

**Step F: decide, with this rule.** A candidate WINS only if ALL of these hold:
1. its `lint` is `pass` or `iverilog` (the Verilator tool is not in the image, so the table shows `iverilog` = the Icarus compile succeeded), `lockstep` is `12/12`, `formal` is `EQUIVALENT`;
2. its target module's critical delay at 200 ps is at least **1.0 ps** lower than `opt` (smaller changes are noise);
3. no other module and no other column (250 ps, 250 ps sized) got more than **1.0 ps** worse.
If a function check fails, the candidate is out, whatever its timing. Explain the failure from the log lines I paste (a `MISMATCH`
line gives the cycle and the differing outputs; a formal failure gives the first differing cycle). You may give a corrected version of it
in the next iteration under a NEW id.
If two candidates win on different modules, both may be promoted (one after the other, then re-measured together in the next iteration).
If two win on the same module, keep the larger gain, and re-try combining them as a new candidate.

**Step G: promote.** For each winner, tell me exactly: copy `variants/<id>/<file>` to `rtl/opt/<file>`, delete the `variants/` folders of
this iteration, push. The next run then measures the new `opt`.

**Step H: log.** Give me the text of one new section for `ITERATION_LOG.md`, in the format of that file: iteration number, candidates
(id, idea, target), results table (copied from the comparison), decision and reason, the new baseline.

Then start the next iteration at Step A with the new results. After iteration 10 (or earlier if every module meets 200 ps, or if two
iterations in a row give no winner and you have no exact idea left), stop and write a **final report**: start and end numbers of each
module at 250 / 250 sized / 200 ps, every kept change with its exactness argument, every dropped change with the reason, and what would be
needed next (including ideas that are NOT exact, clearly marked as needing a design decision: those are never applied in this loop).

## 7. What I paste back after each run

0. Normally ONE file: `PASTE_TO_CHATGPT.md` (it holds items 1 to 3 below). On github.com: the branch `results`, folder `latest`; or https://raw.githubusercontent.com/cachefoundrydevs/mshr-reservation-timing/results/latest/PASTE_TO_CHATGPT.md. Copy its text into the chat.
1. The **comparison table** from the run's summary page (job "compare"), all rows. (It is also in the branch `results`: `git show origin/results:latest/comparison.md`; `latest/RUN.txt` says which run and commit it belongs to. Check that RUN.txt names the commit I pushed.)
2. For each candidate and for `opt`: the "Failing groups at 200 ps" block of each timing job (`mshr`, `mshr_entry`, `rsv`).
3. If anything failed: the `FAIL` / `MISMATCH` / `NOT PROVEN` lines, and the first 20 lines of the failing log (artifact
   `result-<version>-func`, files `*.log`, `formal/*.log`).
4. If you ask for it: the worst path in full (artifact `result-<version>-<part>`, file `<part>/t250/violations.txt`, section 3).

If I paste too little, ask me for exactly the missing item (name the artifact and the file).

## 8. Verification you add yourself

If a candidate introduces a new invariant (a flop that must always equal some expression, a one-hot vector, a copy that must equal its
original), also give me a **checker** for it, so the lockstep test catches a broken invariant directly instead of only at the pins:
* written in plain Verilog inside the test (`tb/*.v`), as an extra block after the existing comparison, using hierarchical names
  (`dut_opt.<signal>`), counting errors into the existing `errors` variable and printing the first few with a clear message,
  so that the test prints `TEST FAILED` if the invariant breaks;
* never weakening or removing an existing comparison.
Give the complete new test file. If the checker reads an internal signal of `rtl/opt`, say which name it depends on (section 4).

## 9. Your answer format in every iteration

1. **Iteration k of 10**, one-line summary of the state (best numbers so far).
2. Analysis (Step A), short.
3. Candidates table: id | module | idea | target group | expected gain | risk.
4. Exactness argument per candidate.
5. Files (Step C), each complete, each with its path.
6. Test / checker files if any (section 8).
7. What I must do now: the exact folder and file names to create, then "commit and push", then what to paste back.

When I paste results: decision (Step F) with the numbers, promotion instructions (Step G) and the log section (Step H), then the next
iteration.

Start now with iteration 1. The first Actions run of the repository is DONE and green (lockstep 12/12, formal EQUIVALENT); its numbers are the baseline in section 5 and in `ITERATION_LOG.md` (iteration 0). Read the attached files, confirm in three or four lines that you understood the rules, the loop and the keep rule, then give iteration 1.

===== PROMPT END =====

---

## Notes for you (not part of the prompt)

* **Why the assistant never edits the tests' comparisons**: the tests are the only proof that a faster version still does the same thing.
  A version that only passes after its test was weakened proves nothing.
* **Why only one idea per candidate**: synthesis is not monotonic; with two ideas in one candidate a slower result cannot be traced.
* **Why 1.0 ps**: run-to-run noise of this flow is below 1 ps for the same code, but different code shapes move unrelated paths by a few
  ps; 1 ps is the smallest gain worth keeping.
* **If Actions fails before the checks** (a tool missing, the container cannot start): open the failed job, copy the last lines of the
  log, and paste them to the assistant; it can only fix its own files, not GitHub, so check the "tools" step first.
* **Formal depth**: the proofs are bounded (6-20 cycles). The lockstep runs cover long sequences. Both must pass.
* **Real silicon numbers**: the numbers are synthesis estimates with an ideal clock and no wires; place-and-route usually adds 15-30 %.

---

## Reading the results without the GitHub API

After every run the workflow writes the results into the branch `results` of this repository (a normal git branch; the push of that
branch does not start the workflow again). If a tool cannot reach `api.github.com` (for example a cloud sandbox whose network policy
blocks it) but can use git, read the results like this:

```bash
git fetch origin results
git show origin/results:latest/RUN.txt                 # which run and commit these results belong to
git show origin/results:latest/comparison.md           # the comparison table (what section 7 item 1 asks for)
git ls-tree -r --name-only origin/results latest | head -50                      # all files of the newest run
git show origin/results:latest/result-opt-mshr/out/opt/mshr/t200/violations.txt  # example: failing groups of one timing job
```

Older runs stay under `runs/<run id>_<commit>/`. The results appear a few minutes after the last job of a run ends (the last job,
"compare", writes them). If `latest/RUN.txt` still names an older commit than the one you pushed, the run has not finished yet.
