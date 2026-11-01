## Version `M-4`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

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
