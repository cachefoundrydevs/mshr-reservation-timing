# Results of run 41337210471, commit 81c1a8396ac77b2215ab0bb00936251daae9e75d

(Versions: M-7 M-8 M-9 R-2 opt ref )

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

## Details per version and part (function checks, timing, failing groups at 200 ps)

## Version `M-7`: function checks

| check | result |
|---|---|
| lint | iverilog compile only (no verilator) |
| lockstep against the original (12 runs) | 12 passed, 0 failed |
| formal equivalence | FORMAL: ALL EQUIVALENT (arb_rr arb_rr3 mshr_entry rsv rsv_to) |

## Version `M-7`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

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

## Version `M-7`: timing of `l1d_mshr_entry` (ASAP7, ideal clock, no wires)

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

## Version `M-7`: timing of `l1d_reservation_unit` (ASAP7, ideal clock, no wires)

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

## Version `M-8`: function checks

| check | result |
|---|---|
| lint | iverilog compile only (no verilator) |
| lockstep against the original (12 runs) | 12 passed, 0 failed |
| formal equivalence | FORMAL: ALL EQUIVALENT (arb_rr arb_rr3 mshr_entry rsv rsv_to) |

## Version `M-8`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 271.7 ps (slack -21.7) |
| 250 ps after gate sizing | 264.6 ps (slack -14.6) |
| 200 ps (5 GHz), synthesis only | 269.2 ps (slack -69.2) |
| area | 11635 um2 |

Failing groups at 200 ps (worst first):

```
     8 endpoints  worst    -69.2 ps  g_entry[].u_entry.tk_arb_q$_DFF_P_/D
     8 endpoints  worst    -69.2 ps  g_entry[].u_entry.tk_c_q$_DFF_P_/D
     8 endpoints  worst    -69.2 ps  g_entry[].u_entry.tk_q$_DFF_P_/D
   378 endpoints  worst    -68.1 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
    47 endpoints  worst    -64.6 ps  g_entry[].u_entry.state[]$_DFF_P_/D
    58 endpoints  worst    -64.0 ps  axi_read_req_line_addr[]
    58 endpoints  worst    -62.6 ps  refill_token_line_addr[]
     3 endpoints  worst    -62.0 ps  response_seat[]
    72 endpoints  worst    -62.0 ps  response_packet[]
    11 endpoints  worst    -57.9 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    12 endpoints  worst    -57.9 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    18 endpoints  worst    -57.9 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
     1 endpoints  worst    -56.8 ps  axi_read_req_unique
     8 endpoints  worst    -52.1 ps  g_entry[].u_entry.inst_q$_SDFF_PP0_/D
```

## Version `M-8`: timing of `l1d_mshr_entry` (ASAP7, ideal clock, no wires)

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

## Version `M-8`: timing of `l1d_reservation_unit` (ASAP7, ideal clock, no wires)

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

## Version `M-9`: function checks

| check | result |
|---|---|
| lint | iverilog compile only (no verilator) |
| lockstep against the original (12 runs) | 12 passed, 0 failed |
| formal equivalence | FORMAL: ALL EQUIVALENT (arb_rr arb_rr3 mshr_entry rsv rsv_to) |

## Version `M-9`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 281.3 ps (slack -31.3) |
| 250 ps after gate sizing | 268.9 ps (slack -18.9) |
| 200 ps (5 GHz), synthesis only | 278.8 ps (slack -78.8) |
| area | 11654 um2 |

Failing groups at 200 ps (worst first):

```
     1 endpoints  worst    -78.8 ps  lookup_entry_has_data
     3 endpoints  worst    -77.7 ps  lookup_entry_id[]
    58 endpoints  worst    -74.3 ps  axi_read_req_line_addr[]
    58 endpoints  worst    -73.1 ps  refill_token_line_addr[]
   423 endpoints  worst    -71.1 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
    11 endpoints  worst    -70.8 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    11 endpoints  worst    -70.7 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    15 endpoints  worst    -70.7 ps  g_entry[].u_entry.p_idx[]$_DFFE_PP_/D
    19 endpoints  worst    -70.7 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
    72 endpoints  worst    -67.2 ps  response_packet[]
  4088 endpoints  worst    -63.7 ps  g_entry[].u_entry.buf_r[]$_DFFE_PP_/D
     3 endpoints  worst    -60.4 ps  response_seat[]
     1 endpoints  worst    -57.5 ps  axi_read_req_unique
     1 endpoints  worst    -54.1 ps  lookup_hit
```

## Version `M-9`: timing of `l1d_mshr_entry` (ASAP7, ideal clock, no wires)

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

## Version `M-9`: timing of `l1d_reservation_unit` (ASAP7, ideal clock, no wires)

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

## Version `R-2`: function checks

| check | result |
|---|---|
| lint | iverilog compile only (no verilator) |
| lockstep against the original (12 runs) | 12 passed, 0 failed |
| formal equivalence | FORMAL: ALL EQUIVALENT (arb_rr arb_rr3 mshr_entry rsv rsv_to) |

## Version `R-2`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 275.6 ps (slack -25.6) |
| 250 ps after gate sizing | 263.7 ps (slack -13.7) |
| 200 ps (5 GHz), synthesis only | 273.1 ps (slack -73.1) |
| area | 11643 um2 |

Failing groups at 200 ps (worst first):

```
    72 endpoints  worst    -73.1 ps  response_packet[]
     3 endpoints  worst    -73.0 ps  response_seat[]
    58 endpoints  worst    -69.6 ps  refill_token_line_addr[]
    14 endpoints  worst    -67.6 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    23 endpoints  worst    -67.6 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
   460 endpoints  worst    -67.6 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
     8 endpoints  worst    -66.1 ps  g_entry[].u_entry.tk_arb_q$_DFF_P_/D
     8 endpoints  worst    -66.1 ps  g_entry[].u_entry.tk_c_q$_DFF_P_/D
     8 endpoints  worst    -66.1 ps  g_entry[].u_entry.tk_q$_DFF_P_/D
    58 endpoints  worst    -65.9 ps  axi_read_req_line_addr[]
    47 endpoints  worst    -63.9 ps  g_entry[].u_entry.state[]$_DFF_P_/D
     8 endpoints  worst    -61.0 ps  g_entry[].u_entry.inst_q$_SDFF_PP0_/D
    14 endpoints  worst    -58.6 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    20 endpoints  worst    -58.6 ps  g_entry[].u_entry.p_idx[]$_DFFE_PP_/D
```

## Version `R-2`: timing of `l1d_mshr_entry` (ASAP7, ideal clock, no wires)

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

## Version `R-2`: timing of `l1d_reservation_unit` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 246.5 ps (slack 3.5) |
| 250 ps after gate sizing | 246.5 ps (slack 3.5) |
| 200 ps (5 GHz), synthesis only | 244.0 ps (slack -44.0) |
| area | 143 um2 |

Failing groups at 200 ps (worst first):

```
     1 endpoints  worst    -44.0 ps  amo_lock_snoop_hold$_SDFF_PP0_/D
     1 endpoints  worst    -29.9 ps  reservation_valid$_SDFF_PP0_/D
     1 endpoints  worst    -22.1 ps  amo_lock_valid$_SDFFE_PP0P_/D
     1 endpoints  worst    -15.9 ps  sc_reservation_matches
     1 endpoints  worst     -6.7 ps  amo_lock_timeout_pulse$_SDFF_PP0_/D
     2 endpoints  worst     -4.3 ps  to_cnt[]$_SDFFE_PP0P_/D

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
| 250 ps (4 GHz), synthesis only | 275.6 ps (slack -25.6) |
| 250 ps after gate sizing | 263.7 ps (slack -13.7) |
| 200 ps (5 GHz), synthesis only | 273.1 ps (slack -73.1) |
| area | 11643 um2 |

Failing groups at 200 ps (worst first):

```
    72 endpoints  worst    -73.1 ps  response_packet[]
     3 endpoints  worst    -73.0 ps  response_seat[]
    58 endpoints  worst    -69.6 ps  refill_token_line_addr[]
    14 endpoints  worst    -67.6 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    23 endpoints  worst    -67.6 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
   460 endpoints  worst    -67.6 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
     8 endpoints  worst    -66.1 ps  g_entry[].u_entry.tk_arb_q$_DFF_P_/D
     8 endpoints  worst    -66.1 ps  g_entry[].u_entry.tk_c_q$_DFF_P_/D
     8 endpoints  worst    -66.1 ps  g_entry[].u_entry.tk_q$_DFF_P_/D
    58 endpoints  worst    -65.9 ps  axi_read_req_line_addr[]
    47 endpoints  worst    -63.9 ps  g_entry[].u_entry.state[]$_DFF_P_/D
     8 endpoints  worst    -61.0 ps  g_entry[].u_entry.inst_q$_SDFF_PP0_/D
    14 endpoints  worst    -58.6 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    20 endpoints  worst    -58.6 ps  g_entry[].u_entry.p_idx[]$_DFFE_PP_/D
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
