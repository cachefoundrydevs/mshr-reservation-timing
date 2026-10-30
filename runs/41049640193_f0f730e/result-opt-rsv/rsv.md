## Version `opt`: timing of `l1d_reservation_unit` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 252.3 ps (slack -2.3) |
| 250 ps after gate sizing | 248.2 ps (slack 1.8) |
| 200 ps (5 GHz), synthesis only | 249.8 ps (slack -49.8) |
| area | 144 um2 |

Failing groups at 200 ps (worst first):

```
     1 endpoints  worst    -49.8 ps  to_last$_SDFFE_PP0P_/D
     2 endpoints  worst    -42.9 ps  to_cnt[]$_SDFFE_PP0P_/D
     1 endpoints  worst    -30.7 ps  amo_lock_snoop_hold$_SDFFE_PP0P_/D
     1 endpoints  worst    -22.1 ps  amo_lock_valid$_SDFFE_PP0P_/D
     1 endpoints  worst    -19.0 ps  reservation_valid$_SDFF_PP0_/D
     1 endpoints  worst    -18.0 ps  sc_reservation_matches
     1 endpoints  worst    -16.8 ps  amo_lock_timeout_pulse$_SDFF_PP0_/D

```
