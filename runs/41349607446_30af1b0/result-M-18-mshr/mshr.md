## Version `M-18`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 277.3 ps (slack -27.3) |
| 250 ps after gate sizing | 262.4 ps (slack -12.4) |
| 200 ps (5 GHz), synthesis only | 274.8 ps (slack -74.8) |
| area | 11800 um2 |

Failing groups at 200 ps (worst first):

```
     8 endpoints  worst    -74.8 ps  g_entry[].u_entry.tk_arb_q$_DFF_P_/D
     8 endpoints  worst    -74.8 ps  g_entry[].u_entry.tk_c_q$_DFF_P_/D
     8 endpoints  worst    -74.8 ps  g_entry[].u_entry.tk_q$_DFF_P_/D
   457 endpoints  worst    -70.1 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
     8 endpoints  worst    -68.6 ps  g_entry[].u_entry.inst_q$_SDFF_PP0_/D
     8 endpoints  worst    -68.1 ps  m18_allocation_busy[]$_SDFF_PP0_/D
    48 endpoints  worst    -68.1 ps  g_entry[].u_entry.state[]$_DFF_P_/D
     8 endpoints  worst    -68.0 ps  g_entry[].u_entry.busy_r$_SDFF_PP0_/D
    14 endpoints  worst    -67.2 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    22 endpoints  worst    -67.2 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
     1 endpoints  worst    -64.8 ps  lookup_entry_has_data
    13 endpoints  worst    -63.1 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
     6 endpoints  worst    -61.8 ps  u_rs_arb.mask_r[]$_SDFFE_PP0P_/D
     7 endpoints  worst    -61.8 ps  m7_rs_mask[]$_SDFFE_PP0P_/D
```
