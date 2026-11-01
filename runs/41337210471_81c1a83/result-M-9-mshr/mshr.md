## Version `M-9`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 281.3 ps (slack -31.3) |
| 250 ps after gate sizing | 268.9 ps (slack -18.9) |
| 200 ps (5 GHz), synthesis only | 278.8 ps (slack -78.8) |
| area | 11654 um2 |

Failing groups at 200 ps (worst first):

```
     1 endpoints  worst    -78.8 ps  lookup_entry_has_data
     3 endpoints  worst    -77.7 ps  lookup_entry_id[]
    58 endpoints  worst    -74.3 ps  axi_read_req_line_addr[]
    58 endpoints  worst    -73.1 ps  refill_token_line_addr[]
   423 endpoints  worst    -71.1 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
    11 endpoints  worst    -70.8 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    11 endpoints  worst    -70.7 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    15 endpoints  worst    -70.7 ps  g_entry[].u_entry.p_idx[]$_DFFE_PP_/D
    19 endpoints  worst    -70.7 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
    72 endpoints  worst    -67.2 ps  response_packet[]
  4088 endpoints  worst    -63.7 ps  g_entry[].u_entry.buf_r[]$_DFFE_PP_/D
     3 endpoints  worst    -60.4 ps  response_seat[]
     1 endpoints  worst    -57.5 ps  axi_read_req_unique
     1 endpoints  worst    -54.1 ps  lookup_hit
```
