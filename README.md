# MSHR and reservation unit: timing optimisation with proof

This repository holds two blocks of an L1 data cache, written in Verilog-2005, and everything needed to make them faster **without changing
what they do or when they do it**:

| Block | What it does |
|---|---|
| `l1d_mshr` (+ `l1d_mshr_entry`, `l1d_arb_rr`) | the miss-status holding registers: 8 entries, each tracks one cache line being fetched from memory (AXI read, beats into a line buffer, response to the CPU, refill token, install); a CAM lookup ("is this line already being fetched?"), a free-entry pick and three round-robin arbiters (AXI read address, CPU response, refill token) |
| `l1d_reservation_unit` | the LR/SC reservation (one line address, cleared by stores, snoops, evictions, maintenance) and the AMO lock (one line locked between the read and the write half of an atomic, with snoop hold and a time-out) |

Two versions of each file are kept:

| Folder | Content |
|---|---|
| `rtl/ref/` | the **original** files: the reference. Never edited. |
| `rtl/opt/` | the **optimised** files: the current best version. Same ports, same behaviour in every clock cycle. |
| `rtl/common/` | shared cells used unchanged by both (CAM, priority encoder, load-data aligner) |
| `rtl/include/` | the three include files (sizes, encodings, field widths) |
| `variants/<name>/` | candidate versions: any of the four files `l1d_mshr.v`, `l1d_mshr_entry.v`, `l1d_arb_rr.v`, `l1d_reservation_unit.v`; the missing ones are taken from `rtl/opt/` |

## What "the same" means here

A new version is accepted only if it is **exactly equivalent** to the original at its ports:

* every output pin has the same value in every clock cycle, for every input sequence (a few payload pins are compared only while their
  valid bit is 1, exactly as the surrounding design reads them; the tests list them);
* the number of clock cycles of every operation is unchanged (no extra pipeline stage, no extra latency);
* the ports (names, widths, directions) are unchanged.

Three independent checks prove this for every version, automatically, in GitHub Actions:

| Check | Tool | What it does |
|---|---|---|
| lint | Verilator (`--lint-only`) if installed, else the Icarus compile | syntax, widths, undriven signals |
| lockstep simulation | Icarus Verilog, `tb/*.v` | the new version and the original side by side, the same random inputs, **every output compared in every cycle**, 12 runs of 200 000 to 800 000 cycles |
| formal equivalence | Yosys `sat` (bounded model check), `formal/run_formal.sh` | a proof for **every possible input sequence** of 6 to 20 cycles after reset: arbiter (N = 4 and 3), MSHR entry, reservation unit (also with a 3-cycle lock time-out) |

The tests:

| Test | Compares | Runs |
|---|---|---|
| `tb/tb_arb_rr_equiv.v` | `l1d_arb_rr` for N = 2, 3, 4, 5, 8 | 2 |
| `tb/tb_mshr_entry_equiv.v` | one `l1d_mshr_entry` | 3 |
| `tb/tb_mshr_equiv.v` | the whole `l1d_mshr` (entries, CAM, arbiters, output muxes); also checks that the control copies of the arbiters (`ar_gc` / `rs_gc` / `tk_gc`) always equal the output arbiters (`ar_g` / `rs_g` / `tk_g`) | 3 |
| `tb/tb_reservation_unit_equiv.v` | `l1d_reservation_unit`, also with LOCK_TIMEOUT = 3 and 5 (many time-outs) | 4 |

Every test prints a coverage line (how often each interesting situation happened), then `TEST PASSED` or `TEST FAILED: <n> mismatching
cycles` with the first mismatches.

## Timing

`flow/run_timing.sh` synthesizes one module with Yosys + ABC for the open ASAP7 7 nm library (through OpenROAD-flow-scripts) and runs
OpenSTA on the netlist: ideal clock, no wires, input / output delays 0, clock uncertainty 5 % of the period. It reports the **critical
delay** (period minus worst slack), the failing endpoint groups and the worst path. At 250 ps it also runs OpenROAD gate sizing (still no
placement). Real post-route numbers are expected 15-30 % slower; the numbers are for comparing versions with each other.

Targets: **250 ps (4 GHz)** and **200 ps (5 GHz)**.

## GitHub Actions

`.github/workflows/mshr_rsv.yml` runs on every push (except pushes that only change `.md` files) and by hand ("Run workflow"):

* one parallel job per version and part: versions `ref` (the original, timing only), `opt`, and every `variants/<name>/`; parts `func`
  (lint + lockstep + formal), `mshr`, `mshr_entry`, `rsv` (timing at 250 and 200 ps);
* a last job **compare** writes one table with every version (also on the run's summary page and as the artifact `comparison`);
* each job uploads its logs (`result-<version>-<part>`).

The whole run takes about 30-90 minutes (the timing of `l1d_mshr` is the longest part).

## Run it on your own machine

Everything runs in the public Docker image `openroad/orfs` (Yosys, OpenROAD, OpenSTA and the ASAP7 library inside):

```bash
docker run --rm -it -v "$PWD":/w -w /w openroad/orfs:latest bash
apt-get update && apt-get install -y iverilog          # inside the container, once
bash scripts/run_all.sh opt rtl/opt out/opt            # all parts for rtl/opt
bash scripts/run_all.sh opt rtl/opt out/opt func       # only lint + lockstep + formal
bash formal/run_formal.sh rtl/opt out/formal rsv       # one formal check
bash flow/run_timing.sh l1d_mshr rtl/opt 200 out/t     # one timing run
```

## Iterating

`PROMPT_ITERATION.md` is a complete, self-contained prompt for an AI assistant (written for ChatGPT) that runs **10 optimisation
iterations** with this repository: it proposes candidate versions in `variants/`, you push them, Actions checks and times them, you paste the
results back, and only a version that passes every check and is faster replaces `rtl/opt`. `ITERATION_LOG.md` records every iteration.

## Getting the results into the chat (no GitHub access needed by the assistant)

After every run the workflow publishes one file with everything the assistant needs:
`https://github.com/cachefoundrydevs/mshr-reservation-timing/blob/results/latest/PASTE_TO_CHATGPT.md` (open it, copy the text, paste it into the chat).
`latest/RUN.txt` in the same folder says which run and commit it belongs to; check that it names the commit you pushed (the file is
replaced when the run ends, 30-90 minutes after the push).
