# Results of run 41341553133, commit d288b0dd3afec51e4eb1f949f56a85e3a97e9736

(Versions: M-10 M-11 M-12 opt ref )

## Comparison (critical delay in ps, ASAP7, ideal clock, no wires; smaller is faster)

| version | lint | lockstep | formal | mshr 250 | mshr 250 sized | mshr 200 | entry 250 | entry 250 sized | entry 200 | rsv 250 | rsv 250 sized | rsv 200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| M-10 | iverilog | 12/12 | EQUIVALENT | 264.9 | 256.6 | 262.4 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| M-11 | iverilog | 12/12 | EQUIVALENT | 259.3 | 253.8 | 256.8 | 215.9 | 215.9 | 213.4 | 242.9 | 242.9 | 240.4 |
| M-12 | iverilog | 12/12 | EQUIVALENT | 260.1 | 254.2 | 257.6 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| opt | iverilog | 12/12 | EQUIVALENT | 270.7 | 264.6 | 268.2 | 230.5 | 230.5 | 228.0 | 242.9 | 242.9 | 240.4 |
| ref |  |  |  | 542.3 | 463.0 | 539.8 | 476.6 | 418.5 | 474.1 | 258.0 | 251.5 | 255.5 |

A version may replace rtl/opt only if lint passes, lockstep is 12/12, formal is EQUIVALENT, and it is faster (see PROMPT_ITERATION.md).

## Details per version and part (function checks, timing, failing groups at 200 ps)

## Version `M-10`: function checks

| check | result |
|---|---|
| lint | iverilog compile only (no verilator) |
| lockstep against the original (12 runs) | 12 passed, 0 failed |
| formal equivalence | FORMAL: ALL EQUIVALENT (arb_rr arb_rr3 mshr_entry rsv rsv_to) |

## Version `M-10`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 264.9 ps (slack -14.9) |
| 250 ps after gate sizing | 256.6 ps (slack -6.6) |
| 200 ps (5 GHz), synthesis only | 262.4 ps (slack -62.4) |
| area | 11807 um2 |

Failing groups at 200 ps (worst first):

```
    15 endpoints  worst    -62.4 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    15 endpoints  worst    -62.4 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    23 endpoints  worst    -62.4 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
   459 endpoints  worst    -62.4 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
     8 endpoints  worst    -59.8 ps  g_entry[].u_entry.busy_r$_SDFF_PP0_/D
    58 endpoints  worst    -59.4 ps  axi_read_req_line_addr[]
     1 endpoints  worst    -59.0 ps  axi_read_req_unique
    22 endpoints  worst    -54.6 ps  g_entry[].u_entry.p_idx[]$_DFFE_PP_/D
     7 endpoints  worst    -52.3 ps  g_entry[].u_entry.p_rd_wr$_DFFE_PP_/D
     6 endpoints  worst    -50.2 ps  m7_rs_mask[]$_SDFFE_PP0P_/D
     6 endpoints  worst    -50.2 ps  u_rs_arb.mask_r[]$_SDFFE_PP0P_/D
    58 endpoints  worst    -50.2 ps  refill_token_line_addr[]
    72 endpoints  worst    -50.0 ps  response_packet[]
    47 endpoints  worst    -49.1 ps  g_entry[].u_entry.state[]$_DFF_P_/D
```

## Version `M-10`: timing of `l1d_mshr_entry` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 230.5 ps (slack 19.5) |
| 250 ps after gate sizing | 230.5 ps (slack 19.5) |
| 200 ps (5 GHz), synthesis only | 228.0 ps (slack -28.0) |
| area | 1407 um2 |

Failing groups at 200 ps (worst first):

```
   512 endpoints  worst    -28.0 ps  buf_r[]$_DFFE_PP_/D
   120 endpoints  worst     -6.0 ps  ld_beat_r[]$_DFFE_PP_/D

```

## Version `M-10`: timing of `l1d_reservation_unit` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 242.9 ps (slack 7.1) |
| 250 ps after gate sizing | 242.9 ps (slack 7.1) |
| 200 ps (5 GHz), synthesis only | 240.4 ps (slack -40.4) |
| area | 142 um2 |

Failing groups at 200 ps (worst first):

```
     1 endpoints  worst    -40.4 ps  amo_lock_snoop_hold$_SDFFE_PP0P_/D
     1 endpoints  worst    -22.3 ps  reservation_valid$_SDFF_PP0_/D
     1 endpoints  worst    -18.4 ps  amo_lock_valid$_SDFFE_PP0P_/D
     1 endpoints  worst    -16.3 ps  sc_reservation_matches
     1 endpoints  worst     -4.4 ps  to_cnt[]$_SDFFE_PP0P_/D
     1 endpoints  worst     -3.1 ps  amo_lock_timeout_pulse$_SDFF_PP0_/D

```

## Version `M-11`: function checks

| check | result |
|---|---|
| lint | iverilog compile only (no verilator) |
| lockstep against the original (12 runs) | 12 passed, 0 failed |
| formal equivalence | FORMAL: ALL EQUIVALENT (arb_rr arb_rr3 mshr_entry rsv rsv_to) |

## Version `M-11`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 259.3 ps (slack -9.3) |
| 250 ps after gate sizing | 253.8 ps (slack -3.8) |
| 200 ps (5 GHz), synthesis only | 256.8 ps (slack -56.8) |
| area | 11797 um2 |

Failing groups at 200 ps (worst first):

```
     8 endpoints  worst    -56.8 ps  g_entry[].u_entry.busy_r$_SDFF_PP0_/D
   440 endpoints  worst    -54.5 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
     8 endpoints  worst    -54.0 ps  g_entry[].u_entry.tk_arb_q$_DFF_P_/D
     8 endpoints  worst    -54.0 ps  g_entry[].u_entry.tk_c_q$_DFF_P_/D
     8 endpoints  worst    -54.0 ps  g_entry[].u_entry.tk_q$_DFF_P_/D
    42 endpoints  worst    -53.6 ps  g_entry[].u_entry.state[]$_DFF_P_/D
     3 endpoints  worst    -51.8 ps  lookup_entry_id[]
    10 endpoints  worst    -51.6 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    20 endpoints  worst    -51.6 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
     1 endpoints  worst    -49.4 ps  lookup_entry_has_data
     3 endpoints  worst    -48.6 ps  response_seat[]
    72 endpoints  worst    -48.6 ps  response_packet[]
    12 endpoints  worst    -47.5 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
     8 endpoints  worst    -46.9 ps  g_entry[].u_entry.ar_arb_q$_DFF_P_/D
```

## Version `M-11`: timing of `l1d_mshr_entry` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 215.9 ps (slack 34.1) |
| 250 ps after gate sizing | 215.9 ps (slack 34.1) |
| 200 ps (5 GHz), synthesis only | 213.4 ps (slack -13.4) |
| area | 1410 um2 |

Failing groups at 200 ps (worst first):

```
   278 endpoints  worst    -13.4 ps  buf_r[]$_DFFE_PP_/D
    40 endpoints  worst     -2.9 ps  ld_beat_r[]$_DFFE_PP_/D

```

## Version `M-11`: timing of `l1d_reservation_unit` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 242.9 ps (slack 7.1) |
| 250 ps after gate sizing | 242.9 ps (slack 7.1) |
| 200 ps (5 GHz), synthesis only | 240.4 ps (slack -40.4) |
| area | 142 um2 |

Failing groups at 200 ps (worst first):

```
     1 endpoints  worst    -40.4 ps  amo_lock_snoop_hold$_SDFFE_PP0P_/D
     1 endpoints  worst    -22.3 ps  reservation_valid$_SDFF_PP0_/D
     1 endpoints  worst    -18.4 ps  amo_lock_valid$_SDFFE_PP0P_/D
     1 endpoints  worst    -16.3 ps  sc_reservation_matches
     1 endpoints  worst     -4.4 ps  to_cnt[]$_SDFFE_PP0P_/D
     1 endpoints  worst     -3.1 ps  amo_lock_timeout_pulse$_SDFF_PP0_/D

```

## Version `M-12`: function checks

| check | result |
|---|---|
| lint | iverilog compile only (no verilator) |
| lockstep against the original (12 runs) | 12 passed, 0 failed |
| formal equivalence | FORMAL: ALL EQUIVALENT (arb_rr arb_rr3 mshr_entry rsv rsv_to) |

## Version `M-12`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 260.1 ps (slack -10.1) |
| 250 ps after gate sizing | 254.2 ps (slack -4.2) |
| 200 ps (5 GHz), synthesis only | 257.6 ps (slack -57.6) |
| area | 11806 um2 |

Failing groups at 200 ps (worst first):

```
     5 endpoints  worst    -57.6 ps  u_rs_arb.mask_r[]$_SDFFE_PP0P_/D
     6 endpoints  worst    -57.6 ps  m7_rs_mask[]$_SDFFE_PP0P_/D
     6 endpoints  worst    -56.2 ps  u_ar_arb.mask_r[]$_SDFFE_PP0P_/D
     7 endpoints  worst    -56.2 ps  m7_ar_mask[]$_SDFFE_PP0P_/D
     1 endpoints  worst    -53.0 ps  lookup_entry_has_data
    58 endpoints  worst    -52.8 ps  axi_read_req_line_addr[]
    58 endpoints  worst    -48.9 ps  refill_token_line_addr[]
    72 endpoints  worst    -48.2 ps  response_packet[]
   461 endpoints  worst    -47.2 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
    15 endpoints  worst    -46.7 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    15 endpoints  worst    -46.7 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    23 endpoints  worst    -46.6 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
     3 endpoints  worst    -45.5 ps  response_seat[]
     5 endpoints  worst    -44.1 ps  u_tk_arb.mask_r[]$_SDFFE_PP0P_/D
```

## Version `M-12`: timing of `l1d_mshr_entry` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 230.5 ps (slack 19.5) |
| 250 ps after gate sizing | 230.5 ps (slack 19.5) |
| 200 ps (5 GHz), synthesis only | 228.0 ps (slack -28.0) |
| area | 1407 um2 |

Failing groups at 200 ps (worst first):

```
   512 endpoints  worst    -28.0 ps  buf_r[]$_DFFE_PP_/D
   120 endpoints  worst     -6.0 ps  ld_beat_r[]$_DFFE_PP_/D

```

## Version `M-12`: timing of `l1d_reservation_unit` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 242.9 ps (slack 7.1) |
| 250 ps after gate sizing | 242.9 ps (slack 7.1) |
| 200 ps (5 GHz), synthesis only | 240.4 ps (slack -40.4) |
| area | 142 um2 |

Failing groups at 200 ps (worst first):

```
     1 endpoints  worst    -40.4 ps  amo_lock_snoop_hold$_SDFFE_PP0P_/D
     1 endpoints  worst    -22.3 ps  reservation_valid$_SDFF_PP0_/D
     1 endpoints  worst    -18.4 ps  amo_lock_valid$_SDFFE_PP0P_/D
     1 endpoints  worst    -16.3 ps  sc_reservation_matches
     1 endpoints  worst     -4.4 ps  to_cnt[]$_SDFFE_PP0P_/D
     1 endpoints  worst     -3.1 ps  amo_lock_timeout_pulse$_SDFF_PP0_/D

```

## Version `opt`: function checks

| check | result |
|---|---|
| lint | iverilog compile only (no verilator) |
| lockstep against the original (12 runs) | 12 passed, 0 failed |
| formal equivalence | FORMAL: ALL EQUIVALENT (arb_rr arb_rr3 mshr_entry rsv rsv_to) |

## Version `opt`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 270.7 ps (slack -20.7) |
| 250 ps after gate sizing | 264.6 ps (slack -14.6) |
| 200 ps (5 GHz), synthesis only | 268.2 ps (slack -68.2) |
| area | 11801 um2 |

Failing groups at 200 ps (worst first):

```
     8 endpoints  worst    -68.2 ps  g_entry[].u_entry.tk_arb_q$_DFF_P_/D
     8 endpoints  worst    -68.2 ps  g_entry[].u_entry.tk_c_q$_DFF_P_/D
     8 endpoints  worst    -68.2 ps  g_entry[].u_entry.tk_q$_DFF_P_/D
     8 endpoints  worst    -66.3 ps  g_entry[].u_entry.busy_r$_SDFF_PP0_/D
    48 endpoints  worst    -62.9 ps  g_entry[].u_entry.state[]$_DFF_P_/D
     8 endpoints  worst    -59.9 ps  g_entry[].u_entry.inst_q$_SDFF_PP0_/D
   462 endpoints  worst    -59.8 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
    14 endpoints  worst    -57.8 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    15 endpoints  worst    -57.7 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    23 endpoints  worst    -57.7 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
     8 endpoints  worst    -57.5 ps  g_entry[].u_entry.rs_arb_q$_DFF_P_/D
     8 endpoints  worst    -57.5 ps  g_entry[].u_entry.rs_c_q$_DFF_P_/D
     8 endpoints  worst    -57.5 ps  g_entry[].u_entry.rs_q$_DFF_P_/D
    21 endpoints  worst    -56.7 ps  g_entry[].u_entry.p_idx[]$_DFFE_PP_/D
```

## Version `opt`: timing of `l1d_mshr_entry` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 230.5 ps (slack 19.5) |
| 250 ps after gate sizing | 230.5 ps (slack 19.5) |
| 200 ps (5 GHz), synthesis only | 228.0 ps (slack -28.0) |
| area | 1407 um2 |

Failing groups at 200 ps (worst first):

```
   512 endpoints  worst    -28.0 ps  buf_r[]$_DFFE_PP_/D
   120 endpoints  worst     -6.0 ps  ld_beat_r[]$_DFFE_PP_/D

```

## Version `opt`: timing of `l1d_reservation_unit` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 242.9 ps (slack 7.1) |
| 250 ps after gate sizing | 242.9 ps (slack 7.1) |
| 200 ps (5 GHz), synthesis only | 240.4 ps (slack -40.4) |
| area | 142 um2 |

Failing groups at 200 ps (worst first):

```
     1 endpoints  worst    -40.4 ps  amo_lock_snoop_hold$_SDFFE_PP0P_/D
     1 endpoints  worst    -22.3 ps  reservation_valid$_SDFF_PP0_/D
     1 endpoints  worst    -18.4 ps  amo_lock_valid$_SDFFE_PP0P_/D
     1 endpoints  worst    -16.3 ps  sc_reservation_matches
     1 endpoints  worst     -4.4 ps  to_cnt[]$_SDFFE_PP0P_/D
     1 endpoints  worst     -3.1 ps  amo_lock_timeout_pulse$_SDFF_PP0_/D

```

## Version `ref`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 542.3 ps (slack -292.3) |
| 250 ps after gate sizing | 463.0 ps (slack -213.0) |
| 200 ps (5 GHz), synthesis only | 539.8 ps (slack -339.8) |
| area | 8762 um2 |

Failing groups at 200 ps (worst first):

```
  4096 endpoints  worst   -339.8 ps  g_entry[].u_entry.buf_r[]$_DFFE_PP_/D
    24 endpoints  worst   -336.1 ps  g_entry[].u_entry.state[]$_SDFFE_PP0P_/D
    58 endpoints  worst   -329.5 ps  axi_read_req_line_addr[]
     3 endpoints  worst   -324.2 ps  u_ar_arb.last[]$_SDFFE_PP1P_/D
     1 endpoints  worst   -321.8 ps  axi_read_req_unique
    72 endpoints  worst   -315.3 ps  response_packet[]
     3 endpoints  worst   -312.3 ps  response_seat[]
     3 endpoints  worst   -311.6 ps  u_rs_arb.last[]$_SDFFE_PP1P_/D
    58 endpoints  worst   -311.5 ps  refill_token_line_addr[]
     3 endpoints  worst   -311.0 ps  u_tk_arb.last[]$_SDFFE_PP1P_/D
     3 endpoints  worst   -284.1 ps  axi_read_req_sub_id[]
     3 endpoints  worst   -273.8 ps  refill_token_entry_id[]
     8 endpoints  worst   -264.5 ps  entry_freed_pulses[]
    48 endpoints  worst   -117.6 ps  g_entry[].u_entry.p_off[]$_DFFE_PP_/D
```

## Version `ref`: timing of `l1d_mshr_entry` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 476.6 ps (slack -226.6) |
| 250 ps after gate sizing | 418.5 ps (slack -168.5) |
| 200 ps (5 GHz), synthesis only | 474.1 ps (slack -274.1) |
| area | 957 um2 |

Failing groups at 200 ps (worst first):

```
   512 endpoints  worst   -274.1 ps  buf_r[]$_DFFE_PP_/D
    64 endpoints  worst    -53.2 ps  response_packet[]
     6 endpoints  worst    -36.2 ps  p_off[]$_DFFE_PP_/D
    58 endpoints  worst    -36.2 ps  line_r[]$_DFFE_PP_/D
    64 endpoints  worst    -36.2 ps  p_wdata[]$_DFFE_PP_/D
     2 endpoints  worst    -34.8 ps  p_mid[]$_DFFE_PP_/D
     2 endpoints  worst    -34.8 ps  p_size[]$_DFFE_PP_/D
     3 endpoints  worst    -34.8 ps  p_idx[]$_DFFE_PP_/D
     3 endpoints  worst    -34.8 ps  p_seat[]$_DFFE_PP_/D
     3 endpoints  worst    -34.8 ps  slot_r[]$_DFFE_PP_/D
     1 endpoints  worst    -18.0 ps  p_rd_wr$_DFFE_PP_/D
     2 endpoints  worst    -10.7 ps  state[]$_SDFFE_PP0P_/D
     1 endpoints  worst     -1.2 ps  shared_r$_SDFFE_PP0P_/D

```

## Version `ref`: timing of `l1d_reservation_unit` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 258.0 ps (slack -8.0) |
| 250 ps after gate sizing | 251.5 ps (slack -1.5) |
| 200 ps (5 GHz), synthesis only | 255.5 ps (slack -55.5) |
| area | 147 um2 |

Failing groups at 200 ps (worst first):

```
    11 endpoints  worst    -55.5 ps  to_cnt[]$_SDFFE_PP0P_/D
     1 endpoints  worst    -51.4 ps  amo_lock_snoop_hold$_SDFFE_PP0P_/D
     1 endpoints  worst    -41.4 ps  to_last$_SDFFE_PP0P_/D
     1 endpoints  worst    -40.6 ps  amo_lock_timeout_pulse$_SDFF_PP0_/D
     1 endpoints  worst    -40.1 ps  amo_lock_valid$_SDFFE_PP0P_/D
     1 endpoints  worst    -20.8 ps  reservation_valid$_SDFF_PP0_/D

```

## First lines of every log that shows a failure (empty = no failure)
