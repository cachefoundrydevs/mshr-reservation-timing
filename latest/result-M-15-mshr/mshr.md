## Version `M-15`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 269.4 ps (slack -19.4) |
| 250 ps after gate sizing | 254.9 ps (slack -4.9) |
| 200 ps (5 GHz), synthesis only | 266.9 ps (slack -66.9) |
| area | 11809 um2 |

Failing groups at 200 ps (worst first):

```
    14 endpoints  worst    -66.9 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    15 endpoints  worst    -66.9 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    23 endpoints  worst    -66.9 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
   462 endpoints  worst    -66.9 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
  4096 endpoints  worst    -62.9 ps  g_entry[].u_entry.buf_r[]$_DFFE_PP_/D
     1 endpoints  worst    -62.2 ps  lookup_entry_has_data
    21 endpoints  worst    -61.1 ps  g_entry[].u_entry.p_idx[]$_DFFE_PP_/D
    58 endpoints  worst    -57.9 ps  refill_token_line_addr[]
     6 endpoints  worst    -54.5 ps  g_entry[].u_entry.p_rd_wr$_DFFE_PP_/D
    58 endpoints  worst    -53.5 ps  axi_read_req_line_addr[]
     3 endpoints  worst    -50.6 ps  lookup_entry_id[]
     3 endpoints  worst    -49.0 ps  response_seat[]
    72 endpoints  worst    -49.0 ps  response_packet[]
     1 endpoints  worst    -44.6 ps  lookup_hit
```
