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
