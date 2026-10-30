#!/usr/bin/env bash
# Formal equivalence checks (Yosys "sat", bounded model check) of an optimised version against the original one (rtl/ref).
# For each check both designs are read, reset in cycle 1, and then every input is FREE for DEPTH cycles; every output (with the few
# exceptions listed below) must be equal in every cycle after the reset cycle. "EQUIVALENT for N cycles" is a proof for EVERY input
# sequence of that length, not a random test. It is bounded: a difference that needs more than N cycles to show is not covered, which is
# why the lockstep simulations (scripts/run_all.sh) run hundreds of thousands of cycles as well.
#
#   bash formal/run_formal.sh <rtl dir of the version> [output dir] [check ...]
#   checks (default: all):
#     arb_rr      round-robin arbiter, N = 4, 20 cycles
#     arb_rr3     the same with N = 3 (not a power of two), 20 cycles
#     mshr_entry  one MSHR entry inside formal/fv_wrap_mshr_entry.v, 6 cycles. The wrapper keeps only the rules the bank guarantees:
#                 loads naturally aligned, RLAST only on the last beat of a burst, reset only in cycle 1; line_buffer_data compared only
#                 while line_buffer_has_data, entry_swap_vc_slot only while busy, response_packet only while response_request
#     rsv         reservation / AMO-lock unit, 12 cycles, every output every cycle
#     rsv_to      the same with LOCK_TIMEOUT = 3, 16 cycles, so that lock time-outs happen inside the proof
#   env: TMO=<seconds> time limit per check (default 7200)
# The whole l1d_mshr (8 entries) is too large for this bounded proof in reasonable time; it is checked by tb/tb_mshr_equiv.v (lockstep) and
# through its parts (entry, arbiter) here.
# The last line printed is "FORMAL: ALL EQUIVALENT (<list>)" or "FORMAL: NOT PROVEN: <list>"; exit status 1 if any check is not proven.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OPTD=$(cd "$1" && pwd)
mkdir -p "${2:-$ROOT/build/formal}"; OUT=$(cd "${2:-$ROOT/build/formal}" && pwd)
shift; [ $# -gt 0 ] && shift
CHECKS=${*:-arb_rr arb_rr3 mshr_entry rsv rsv_to}
if ! command -v yosys >/dev/null 2>&1; then
    for d in /OpenROAD-flow-scripts/tools/install/yosys/bin; do [ -x "$d/yosys" ] && export PATH="$d:$PATH"; done
fi
command -v yosys >/dev/null 2>&1 || { echo "FORMAL: NOT PROVEN: yosys not found"; exit 1; }
INC="-I$ROOT/rtl/include"
REF=$ROOT/rtl/ref
GEN=$ROOT/rtl/common/l1d_resp_gen.v

# run <name> <depth> <top> <ref files> <new files> [wrapper] [chparam arguments]
run() {
    local N=$1 D=$2 TOP=$3 RF=$4 NF=$5 W=${6:-} P=${7:-}
    local Y="$OUT/$N.ys" L="$OUT/$N.log"
    {
        echo "read_verilog -DSYNTHESIS $INC $RF $W"
        [ -n "$P" ] && echo "chparam $P $TOP"
        echo "hierarchy -top $TOP"
        echo "setattr -mod -unset keep_hierarchy"
        echo "proc; flatten; opt_clean; memory -nomap; memory_map; opt -fast"
        echo "rename $TOP ref_top"
        echo "design -stash ref"
        echo "read_verilog -DSYNTHESIS -DOPT $INC $NF $W"
        [ -n "$P" ] && echo "chparam $P $TOP"
        echo "hierarchy -top $TOP"
        echo "setattr -mod -unset keep_hierarchy"
        echo "proc; flatten; opt_clean; memory -nomap; memory_map; opt -fast"
        echo "rename $TOP opt_top"
        echo "design -stash opt"
        echo "design -copy-from ref -as ref_top ref_top"
        echo "design -copy-from opt -as opt_top opt_top"
        echo "miter -equiv -flatten -make_outputs ref_top opt_top miter"
        echo "hierarchy -top miter"
        echo "opt -fast"
        echo "sat -verify -seq $D -set-at 1 in_rst 1 -set-init-zero -prove trigger 0 -prove-skip 1 -show-ports -timeout ${TMO:-7200} miter"
    } > "$Y"
    local t0; t0=$(date +%s)
    if yosys -q -l "$L" "$Y" > /dev/null 2>&1; then
        echo "$N: EQUIVALENT for $D cycles after reset ($(( $(date +%s) - t0 )) s)"
        return 0
    else
        echo "$N: NOT PROVEN ($(( $(date +%s) - t0 )) s): $(grep -m1 -E 'failed|Timeout|ERROR' "$L")   log: $L"
        return 1
    fi
}

ok=""; bad=""
for c in $CHECKS; do
    case $c in
        arb_rr)     run arb_rr 20 l1d_arb_rr "$REF/l1d_arb_rr.v" "$OPTD/l1d_arb_rr.v" ;;
        arb_rr3)    run arb_rr3 20 l1d_arb_rr "$REF/l1d_arb_rr.v" "$OPTD/l1d_arb_rr.v" "" "-set N 3" ;;
        mshr_entry) run mshr_entry 6 fv_wrap "$REF/l1d_mshr_entry.v $GEN" "$OPTD/l1d_mshr_entry.v $GEN" "$ROOT/formal/fv_wrap_mshr_entry.v" ;;
        rsv)        run rsv 12 l1d_reservation_unit "$REF/l1d_reservation_unit.v" "$OPTD/l1d_reservation_unit.v" ;;
        rsv_to)     run rsv_to 16 l1d_reservation_unit "$REF/l1d_reservation_unit.v" "$OPTD/l1d_reservation_unit.v" "" "-set LOCK_TIMEOUT 3" ;;
        *)          echo "$c: unknown check"; false ;;
    esac && ok="$ok $c" || bad="$bad $c"
done
if [ -z "$bad" ]; then echo "FORMAL: ALL EQUIVALENT ($(echo $ok))"; exit 0
else echo "FORMAL: NOT PROVEN:$bad (equivalent:${ok:- none})"; exit 1; fi
