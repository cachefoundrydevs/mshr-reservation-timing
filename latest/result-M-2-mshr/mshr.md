## Version `M-2`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 282.9 ps (slack -32.9) |
| 250 ps after gate sizing | 272.4 ps (slack -22.4) |
| 200 ps (5 GHz), synthesis only | 280.4 ps (slack -80.4) |
| area | 11650 um2 |

Failing groups at 200 ps (worst first):

```
     8 endpoints  worst    -80.4 ps  g_entry[].u_entry.busy_r$_SDFF_PP0_/D
   462 endpoints  worst    -79.0 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
    58 endpoints  worst    -75.6 ps  axi_read_req_line_addr[]
    14 endpoints  worst    -74.3 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    14 endpoints  worst    -74.2 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    22 endpoints  worst    -74.1 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
    18 endpoints  worst    -73.2 ps  g_entry[].u_entry.p_idx[]$_DFFE_PP_/D
     8 endpoints  worst    -73.0 ps  g_entry[].u_entry.tk_arb_q$_DFF_P_/D
     8 endpoints  worst    -73.0 ps  g_entry[].u_entry.tk_c_q$_DFF_P_/D
     8 endpoints  worst    -73.0 ps  g_entry[].u_entry.tk_q$_DFF_P_/D
     8 endpoints  worst    -72.9 ps  entry_freed_pulses[]
     1 endpoints  worst    -72.7 ps  axi_read_req_unique
    58 endpoints  worst    -72.7 ps  refill_token_line_addr[]
    46 endpoints  worst    -71.5 ps  g_entry[].u_entry.state[]$_DFF_P_/D
```
