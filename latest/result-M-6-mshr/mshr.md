## Version `M-6`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 279.1 ps (slack -29.1) |
| 250 ps after gate sizing | 273.8 ps (slack -23.8) |
| 200 ps (5 GHz), synthesis only | 276.6 ps (slack -76.6) |
| area | 11691 um2 |

Failing groups at 200 ps (worst first):

```
    58 endpoints  worst    -76.6 ps  axi_read_req_line_addr[]
     8 endpoints  worst    -75.8 ps  g_entry[].u_entry.tk_arb_q$_DFF_P_/D
     8 endpoints  worst    -75.8 ps  g_entry[].u_entry.tk_c_q$_DFF_P_/D
     8 endpoints  worst    -75.8 ps  g_entry[].u_entry.tk_q$_DFF_P_/D
    58 endpoints  worst    -75.4 ps  refill_token_line_addr[]
    13 endpoints  worst    -71.7 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    13 endpoints  worst    -71.7 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    20 endpoints  worst    -71.7 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
   402 endpoints  worst    -71.7 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
    48 endpoints  worst    -70.5 ps  g_entry[].u_entry.state[]$_DFF_P_/D
     1 endpoints  worst    -68.3 ps  axi_read_req_unique
    72 endpoints  worst    -60.1 ps  response_packet[]
     8 endpoints  worst    -59.4 ps  g_entry[].u_entry.inst_q$_SDFF_PP0_/D
    19 endpoints  worst    -59.1 ps  g_entry[].u_entry.p_idx[]$_DFFE_PP_/D
```
