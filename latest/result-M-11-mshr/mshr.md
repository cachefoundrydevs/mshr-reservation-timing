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
