## Version `M-16`: timing of `l1d_mshr_entry` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 225.9 ps (slack 24.1) |
| 250 ps after gate sizing | 225.9 ps (slack 24.1) |
| 200 ps (5 GHz), synthesis only | 223.4 ps (slack -23.4) |
| area | 1414 um2 |

Failing groups at 200 ps (worst first):

```
   509 endpoints  worst    -23.4 ps  buf_r[]$_DFFE_PP_/D
   122 endpoints  worst    -10.9 ps  ld_beat_r[]$_DFFE_PP_/D

```
