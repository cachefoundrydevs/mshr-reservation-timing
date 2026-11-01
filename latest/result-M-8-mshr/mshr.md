## Version `M-8`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 271.7 ps (slack -21.7) |
| 250 ps after gate sizing | 264.6 ps (slack -14.6) |
| 200 ps (5 GHz), synthesis only | 269.2 ps (slack -69.2) |
| area | 11635 um2 |

Failing groups at 200 ps (worst first):

```
     8 endpoints  worst    -69.2 ps  g_entry[].u_entry.tk_arb_q$_DFF_P_/D
     8 endpoints  worst    -69.2 ps  g_entry[].u_entry.tk_c_q$_DFF_P_/D
     8 endpoints  worst    -69.2 ps  g_entry[].u_entry.tk_q$_DFF_P_/D
   378 endpoints  worst    -68.1 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
    47 endpoints  worst    -64.6 ps  g_entry[].u_entry.state[]$_DFF_P_/D
    58 endpoints  worst    -64.0 ps  axi_read_req_line_addr[]
    58 endpoints  worst    -62.6 ps  refill_token_line_addr[]
     3 endpoints  worst    -62.0 ps  response_seat[]
    72 endpoints  worst    -62.0 ps  response_packet[]
    11 endpoints  worst    -57.9 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    12 endpoints  worst    -57.9 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    18 endpoints  worst    -57.9 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
     1 endpoints  worst    -56.8 ps  axi_read_req_unique
     8 endpoints  worst    -52.1 ps  g_entry[].u_entry.inst_q$_SDFF_PP0_/D
```
