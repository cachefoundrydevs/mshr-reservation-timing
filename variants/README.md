# Candidate versions

Each folder `variants/<id>/` is one candidate. It holds only the files it changes, any of:
`l1d_mshr.v`, `l1d_mshr_entry.v`, `l1d_arb_rr.v`, `l1d_reservation_unit.v`.
The workflow copies `rtl/opt/*.v` into a build folder, then the candidate's files over them, and checks and times that set.

After a decision: copy the winner's files to `rtl/opt/`, delete all candidate folders of that iteration, push.
This file keeps the folder in git when there is no candidate.
