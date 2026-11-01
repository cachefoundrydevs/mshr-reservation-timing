## Version `M-17`: timing of `l1d_mshr_entry` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 220.4 ps (slack 29.6) |
| 250 ps after gate sizing | 220.4 ps (slack 29.6) |
| 200 ps (5 GHz), synthesis only | 217.9 ps (slack -17.9) |
| area | 1414 um2 |

Failing groups at 200 ps (worst first):

```
   509 endpoints  worst    -17.9 ps  buf_r[]$_DFFE_PP_/D
   120 endpoints  worst     -3.1 ps  ld_beat_r[]$_DFFE_PP_/D

```
