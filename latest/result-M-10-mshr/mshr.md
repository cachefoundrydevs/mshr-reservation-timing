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
