## Version `ref`: timing of `l1d_reservation_unit` (ASAP7, ideal clock, no wires)

| check | result |
|---|---|
| 250 ps (4 GHz), synthesis only | 258.0 ps (slack -8.0) |
| 250 ps after gate sizing | 251.5 ps (slack -1.5) |
| 200 ps (5 GHz), synthesis only | 255.5 ps (slack -55.5) |
| area | 147 um2 |

Failing groups at 200 ps (worst first):

```
    11 endpoints  worst    -55.5 ps  to_cnt[]$_SDFFE_PP0P_/D
     1 endpoints  worst    -51.4 ps  amo_lock_snoop_hold$_SDFFE_PP0P_/D
     1 endpoints  worst    -41.4 ps  to_last$_SDFFE_PP0P_/D
     1 endpoints  worst    -40.6 ps  amo_lock_timeout_pulse$_SDFF_PP0_/D
     1 endpoints  worst    -40.1 ps  amo_lock_valid$_SDFFE_PP0P_/D
     1 endpoints  worst    -20.8 ps  reservation_valid$_SDFF_PP0_/D

```
