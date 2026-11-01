## Version `M-13`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 261.0 ps (slack -11.0) |
| 250 ps after gate sizing | 250.8 ps (slack -0.8) |
| 200 ps (5 GHz), synthesis only | 258.5 ps (slack -58.5) |
| area | 11794 um2 |

Failing groups at 200 ps (worst first):

```
     1 endpoints  worst    -58.5 ps  lookup_entry_has_data
   461 endpoints  worst    -57.6 ps  g_entry[].u_entry.line_r[]$_DFFE_PP_/D
    12 endpoints  worst    -53.4 ps  g_entry[].u_entry.p_size[]$_DFFE_PP_/D
    14 endpoints  worst    -53.3 ps  g_entry[].u_entry.p_mid[]$_DFFE_PP_/D
    21 endpoints  worst    -53.3 ps  g_entry[].u_entry.p_idx[]$_DFFE_PP_/D
    23 endpoints  worst    -53.3 ps  g_entry[].u_entry.p_seat[]$_DFFE_PP_/D
     7 endpoints  worst    -49.8 ps  g_entry[].u_entry.busy_r$_SDFF_PP0_/D
    72 endpoints  worst    -49.4 ps  response_packet[]
  4093 endpoints  worst    -49.4 ps  g_entry[].u_entry.buf_r[]$_DFFE_PP_/D
     3 endpoints  worst    -49.3 ps  response_seat[]
    58 endpoints  worst    -48.2 ps  refill_token_line_addr[]
     3 endpoints  worst    -47.4 ps  lookup_entry_id[]
    58 endpoints  worst    -46.2 ps  axi_read_req_line_addr[]
     4 endpoints  worst    -42.0 ps  g_entry[].u_entry.ar_arb_q$_DFF_P_/D
```
