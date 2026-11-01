## Version `M-17`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 257.1 ps (slack -7.1) |
| 250 ps after gate sizing | 253.8 ps (slack -3.8) |
| 200 ps (5 GHz), synthesis only | 254.6 ps (slack -54.6) |
| area | 11802 um2 |

Failing groups at 200 ps (worst first):

```
     6 endpoints  worst    -54.6 ps  m7_ar_mask[]$_SDFFE_PP0P_/D
     6 endpoints  worst    -54.6 ps  u_ar_arb.mask_r[]$_SDFFE_PP0P_/D
     8 endpoints  worst    -54.2 ps  g_entry[].u_entry.inst_q$_SDFF_PP0_/D
    43 endpoints  worst    -54.2 ps  g_entry[].u_entry.state[]$_DFF_P_/D
   462 endpoints  worst    -51.6 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
     7 endpoints  worst    -49.2 ps  g_entry[].u_entry.ar_arb_q$_DFF_P_/D
     7 endpoints  worst    -49.2 ps  g_entry[].u_entry.ar_c_q$_DFF_P_/D
     7 endpoints  worst    -49.2 ps  g_entry[].u_entry.ar_q$_DFF_P_/D
  4090 endpoints  worst    -48.1 ps  g_entry[].u_entry.buf_r[]$_DFFE_PP_/D
     3 endpoints  worst    -48.0 ps  lookup_entry_id[]
     2 endpoints  worst    -47.7 ps  u_rs_arb.mask_r[]$_SDFFE_PP0P_/D
     3 endpoints  worst    -47.7 ps  m7_rs_mask[]$_SDFFE_PP0P_/D
     8 endpoints  worst    -47.7 ps  g_entry[].u_entry.tk_arb_q$_DFF_P_/D
     8 endpoints  worst    -47.7 ps  g_entry[].u_entry.tk_c_q$_DFF_P_/D
```
