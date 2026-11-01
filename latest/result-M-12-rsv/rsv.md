## Version `M-12`: timing of `l1d_reservation_unit` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 242.9 ps (slack 7.1) |
| 250 ps after gate sizing | 242.9 ps (slack 7.1) |
| 200 ps (5 GHz), synthesis only | 240.4 ps (slack -40.4) |
| area | 142 um2 |

Failing groups at 200 ps (worst first):

```
     1 endpoints  worst    -40.4 ps  amo_lock_snoop_hold$_SDFFE_PP0P_/D
     1 endpoints  worst    -22.3 ps  reservation_valid$_SDFF_PP0_/D
     1 endpoints  worst    -18.4 ps  amo_lock_valid$_SDFFE_PP0P_/D
     1 endpoints  worst    -16.3 ps  sc_reservation_matches
     1 endpoints  worst     -4.4 ps  to_cnt[]$_SDFFE_PP0P_/D
     1 endpoints  worst     -3.1 ps  amo_lock_timeout_pulse$_SDFF_PP0_/D

```
