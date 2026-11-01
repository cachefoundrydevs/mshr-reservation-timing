## Version `ref`: timing of `l1d_mshr` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 542.3 ps (slack -292.3) |
| 250 ps after gate sizing | 463.0 ps (slack -213.0) |
| 200 ps (5 GHz), synthesis only | 539.8 ps (slack -339.8) |
| area | 8762 um2 |

Failing groups at 200 ps (worst first):

```
  4096 endpoints  worst   -339.8 ps  g_entry[].u_entry.buf_r[]$_DFFE_PP_/D
    24 endpoints  worst   -336.1 ps  g_entry[].u_entry.state[]$_SDFFE_PP0P_/D
    58 endpoints  worst   -329.5 ps  axi_read_req_line_addr[]
     3 endpoints  worst   -324.2 ps  u_ar_arb.last[]$_SDFFE_PP1P_/D
     1 endpoints  worst   -321.8 ps  axi_read_req_unique
    72 endpoints  worst   -315.3 ps  response_packet[]
     3 endpoints  worst   -312.3 ps  response_seat[]
     3 endpoints  worst   -311.6 ps  u_rs_arb.last[]$_SDFFE_PP1P_/D
    58 endpoints  worst   -311.5 ps  refill_token_line_addr[]
     3 endpoints  worst   -311.0 ps  u_tk_arb.last[]$_SDFFE_PP1P_/D
     3 endpoints  worst   -284.1 ps  axi_read_req_sub_id[]
     3 endpoints  worst   -273.8 ps  refill_token_entry_id[]
     8 endpoints  worst   -264.5 ps  entry_freed_pulses[]
    48 endpoints  worst   -117.6 ps  g_entry[].u_entry.p_off[]$_DFFE_PP_/D
```
