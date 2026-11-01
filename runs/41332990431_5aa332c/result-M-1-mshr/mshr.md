## Version `M-1`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 296.2 ps (slack -46.2) |
| 250 ps after gate sizing | 287.3 ps (slack -37.3) |
| 200 ps (5 GHz), synthesis only | 293.7 ps (slack -93.7) |
| area | 11718 um2 |

Failing groups at 200 ps (worst first):

```
    72 endpoints  worst    -93.7 ps  response_packet[]
    58 endpoints  worst    -91.2 ps  axi_read_req_line_addr[]
    58 endpoints  worst    -88.1 ps  refill_token_line_addr[]
     1 endpoints  worst    -80.1 ps  axi_read_req_unique
     3 endpoints  worst    -71.2 ps  response_seat[]
   459 endpoints  worst    -67.4 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
    15 endpoints  worst    -66.8 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    15 endpoints  worst    -66.8 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    23 endpoints  worst    -66.8 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
     1 endpoints  worst    -66.0 ps  lookup_entry_has_data
     3 endpoints  worst    -63.8 ps  refill_token_entry_id[]
     8 endpoints  worst    -62.7 ps  g_entry[].u_entry.busy_r$_SDFF_PP0_/D
    48 endpoints  worst    -60.7 ps  g_entry[].u_entry.state[]$_DFF_P_/D
     8 endpoints  worst    -60.2 ps  g_entry[].u_entry.tk_arb_q$_DFF_P_/D
```
