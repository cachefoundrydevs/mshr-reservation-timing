## Version `M-15`: timing of `l1d_mshr_entry` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 215.9 ps (slack 34.1) |
| 250 ps after gate sizing | 215.9 ps (slack 34.1) |
| 200 ps (5 GHz), synthesis only | 213.4 ps (slack -13.4) |
| area | 1410 um2 |

Failing groups at 200 ps (worst first):

```
   278 endpoints  worst    -13.4 ps  buf_r[]$_DFFE_PP_/D
    40 endpoints  worst     -2.9 ps  ld_beat_r[]$_DFFE_PP_/D

```
