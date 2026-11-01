## Version `M-14`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 265.0 ps (slack -15.0) |
| 250 ps after gate sizing | 257.4 ps (slack -7.4) |
| 200 ps (5 GHz), synthesis only | 262.5 ps (slack -62.5) |
| area | 11807 um2 |

Failing groups at 200 ps (worst first):

```
    16 endpoints  worst    -62.5 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    16 endpoints  worst    -62.5 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    23 endpoints  worst    -62.5 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
   462 endpoints  worst    -62.5 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
     8 endpoints  worst    -59.2 ps  g_entry[].u_entry.busy_r$_SDFF_PP0_/D
    58 endpoints  worst    -57.9 ps  refill_token_line_addr[]
    72 endpoints  worst    -55.2 ps  response_packet[]
     8 endpoints  worst    -54.5 ps  g_entry[].u_entry.p_rd_wr$_DFFE_PP_/D
  4089 endpoints  worst    -53.7 ps  g_entry[].u_entry.buf_r[]$_DFFE_PP_/D
    24 endpoints  worst    -51.3 ps  g_entry[].u_entry.p_idx[]$_DFFE_PP_/D
     6 endpoints  worst    -50.9 ps  u_tk_arb.mask_r[]$_SDFFE_PP0P_/D
     7 endpoints  worst    -50.9 ps  m7_tk_mask[]$_SDFFE_PP0P_/D
    58 endpoints  worst    -50.5 ps  axi_read_req_line_addr[]
     3 endpoints  worst    -49.7 ps  response_seat[]
```
