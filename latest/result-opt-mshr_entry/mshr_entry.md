## Version `opt`: timing of `l1d_mshr_entry` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 230.5 ps (slack 19.5) |
| 250 ps after gate sizing | 230.5 ps (slack 19.5) |
| 200 ps (5 GHz), synthesis only | 228.0 ps (slack -28.0) |
| area | 1407 um2 |

Failing groups at 200 ps (worst first):

```
   512 endpoints  worst    -28.0 ps  buf_r[]$_DFFE_PP_/D
   120 endpoints  worst     -6.0 ps  ld_beat_r[]$_DFFE_PP_/D

```
