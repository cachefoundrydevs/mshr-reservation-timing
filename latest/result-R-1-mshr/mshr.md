## Version `R-1`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 278.0 ps (slack -28.0) |
| 250 ps after gate sizing | 271.3 ps (slack -21.3) |
| 200 ps (5 GHz), synthesis only | 275.5 ps (slack -75.5) |
| area | 11644 um2 |

Failing groups at 200 ps (worst first):

```
    58 endpoints  worst    -75.5 ps  axi_read_req_line_addr[]
    58 endpoints  worst    -75.4 ps  refill_token_line_addr[]
     8 endpoints  worst    -71.6 ps  g_entry[].u_entry.tk_arb_q$_DFF_P_/D
     8 endpoints  worst    -71.6 ps  g_entry[].u_entry.tk_c_q$_DFF_P_/D
     8 endpoints  worst    -71.6 ps  g_entry[].u_entry.tk_q$_DFF_P_/D
     8 endpoints  worst    -71.4 ps  g_entry[].u_entry.busy_r$_SDFF_PP0_/D
    72 endpoints  worst    -67.8 ps  response_packet[]
     3 endpoints  worst    -67.7 ps  response_seat[]
     1 endpoints  worst    -64.6 ps  axi_read_req_unique
     8 endpoints  worst    -63.8 ps  entry_freed_pulses[]
     1 endpoints  worst    -59.9 ps  lookup_entry_has_data
    47 endpoints  worst    -59.0 ps  g_entry[].u_entry.state[]$_DFF_P_/D
     7 endpoints  worst    -55.3 ps  g_entry[].u_entry.inst_q$_SDFF_PP0_/D
   457 endpoints  worst    -55.2 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
```
