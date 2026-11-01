## Version `M-14`: function checks

| check | result |
|---|---|
| lint | iverilog compile only (no verilator) |
| lockstep against the original (12 runs) | 12 passed, 0 failed |
| formal equivalence | FORMAL: ALL EQUIVALENT (arb_rr arb_rr3 mshr_entry rsv rsv_to) |
