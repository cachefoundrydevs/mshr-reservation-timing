## Version `R-2`: timing of `l1d_reservation_unit` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 246.5 ps (slack 3.5) |
| 250 ps after gate sizing | 246.5 ps (slack 3.5) |
| 200 ps (5 GHz), synthesis only | 244.0 ps (slack -44.0) |
| area | 143 um2 |

Failing groups at 200 ps (worst first):

```
     1 endpoints  worst    -44.0 ps  amo_lock_snoop_hold$_SDFF_PP0_/D
     1 endpoints  worst    -29.9 ps  reservation_valid$_SDFF_PP0_/D
     1 endpoints  worst    -22.1 ps  amo_lock_valid$_SDFFE_PP0P_/D
     1 endpoints  worst    -15.9 ps  sc_reservation_matches
     1 endpoints  worst     -6.7 ps  amo_lock_timeout_pulse$_SDFF_PP0_/D
     2 endpoints  worst     -4.3 ps  to_cnt[]$_SDFFE_PP0P_/D

```
