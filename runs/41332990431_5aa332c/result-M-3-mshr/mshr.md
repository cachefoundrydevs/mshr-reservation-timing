## Version `M-3`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 282.1 ps (slack -32.1) |
| 250 ps after gate sizing | 267.9 ps (slack -17.9) |
| 200 ps (5 GHz), synthesis only | 279.6 ps (slack -79.6) |
| area | 11650 um2 |

Failing groups at 200 ps (worst first):

```
     1 endpoints  worst    -79.6 ps  lookup_entry_has_data
    15 endpoints  worst    -77.5 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    12 endpoints  worst    -77.4 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    23 endpoints  worst    -77.4 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
   461 endpoints  worst    -77.4 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
    58 endpoints  worst    -77.1 ps  axi_read_req_line_addr[]
    58 endpoints  worst    -76.3 ps  refill_token_line_addr[]
     3 endpoints  worst    -75.6 ps  lookup_entry_id[]
     3 endpoints  worst    -73.6 ps  response_seat[]
    72 endpoints  worst    -73.6 ps  response_packet[]
     1 endpoints  worst    -72.8 ps  lookup_hit
     1 endpoints  worst    -64.4 ps  axi_read_req_unique
  4095 endpoints  worst    -61.4 ps  g_entry[].u_entry.buf_r[]$_DFFE_PP_/D
     8 endpoints  worst    -52.9 ps  g_entry[].u_entry.busy_r$_SDFF_PP0_/D
```
