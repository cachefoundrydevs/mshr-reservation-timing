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
