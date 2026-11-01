## Version `M-16`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 276.3 ps (slack -26.3) |
| 250 ps after gate sizing | 269.0 ps (slack -19.0) |
| 200 ps (5 GHz), synthesis only | 273.8 ps (slack -73.8) |
| area | 11784 um2 |

Failing groups at 200 ps (worst first):

```
     1 endpoints  worst    -73.8 ps  lookup_entry_has_data
   460 endpoints  worst    -71.7 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
    13 endpoints  worst    -70.6 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    14 endpoints  worst    -70.5 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    22 endpoints  worst    -70.5 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
    58 endpoints  worst    -62.5 ps  axi_read_req_line_addr[]
     6 endpoints  worst    -56.1 ps  u_ar_arb.mask_r[]$_SDFFE_PP0P_/D
     7 endpoints  worst    -56.1 ps  m7_ar_mask[]$_SDFFE_PP0P_/D
     8 endpoints  worst    -54.8 ps  g_entry[].u_entry.tk_arb_q$_DFF_P_/D
     8 endpoints  worst    -54.8 ps  g_entry[].u_entry.tk_c_q$_DFF_P_/D
     8 endpoints  worst    -54.8 ps  g_entry[].u_entry.tk_q$_DFF_P_/D
     3 endpoints  worst    -53.1 ps  lookup_entry_id[]
    48 endpoints  worst    -53.0 ps  g_entry[].u_entry.state[]$_DFF_P_/D
     7 endpoints  worst    -51.6 ps  g_entry[].u_entry.ar_arb_q$_DFF_P_/D
```
