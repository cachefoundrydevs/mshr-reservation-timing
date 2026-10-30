#!/usr/bin/env bash
# Every check for ONE version of the MSHR + reservation unit, with a summary:
#   func        1. lint / compile check of the version (Verilator if installed, else Icarus compile only)
#               2. lockstep simulations (Icarus Verilog): the version against the original (rtl/ref), every output compared in every cycle
#                  tb_arb_rr_equiv x2, tb_mshr_entry_equiv x3, tb_mshr_equiv x3, tb_reservation_unit_equiv x4
#               3. formal equivalence (Yosys sat, bounded): arb_rr, arb_rr3, mshr_entry, rsv, rsv_to (formal/run_formal.sh)
#   mshr        ASAP7 timing of l1d_mshr            at 250 ps (4 GHz, with gate sizing) and 200 ps (5 GHz)
#   mshr_entry  ASAP7 timing of l1d_mshr_entry      at 250 ps (with gate sizing) and 200 ps
#   rsv         ASAP7 timing of l1d_reservation_unit at 250 ps (with gate sizing) and 200 ps
#
#   bash scripts/run_all.sh <name> <rtl dir of the version: l1d_mshr.v l1d_mshr_entry.v l1d_arb_rr.v l1d_reservation_unit.v> <out dir> [part ...]
#   parts: func mshr mshr_entry rsv (default: all four, one after the other)
# Writes <out dir>/<part>.md (a table) and <out dir>/<part>.txt (key=value lines for the comparison table of the workflow).
# Exit status 1 if a function check fails (lint error, lockstep mismatch, formal not proven). Timing never fails the run: its numbers are
# results to compare, not pass / fail.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
NAME=$1
VD=$(cd "$2" && pwd)
mkdir -p "$3"; OUT=$(cd "$3" && pwd)
shift 3
PARTS=${*:-func mshr mshr_entry rsv}
INC="$ROOT/rtl/include"
CMN="$ROOT/rtl/common/l1d_cam.v $ROOT/rtl/common/l1d_pri_enc.v $ROOT/rtl/common/l1d_resp_gen.v"
status=0

for f in l1d_mshr.v l1d_mshr_entry.v l1d_arb_rr.v l1d_reservation_unit.v; do
    [ -f "$VD/$f" ] || { echo "ERROR: $VD/$f is missing (a version needs all four files)"; exit 1; }
done

part_func() {
    local P="$OUT/func"; mkdir -p "$P/ref"
    local res="" st=0
    # ---- the original modules, renamed *_ref, so that both versions can live in one simulation ----
    sed -E 's/\bl1d_arb_rr\b/l1d_arb_rr_ref/g' "$ROOT/rtl/ref/l1d_arb_rr.v" > "$P/ref/l1d_arb_rr_ref.v"
    sed -E 's/\bl1d_mshr_entry\b/l1d_mshr_entry_ref/g' "$ROOT/rtl/ref/l1d_mshr_entry.v" > "$P/ref/l1d_mshr_entry_ref.v"
    sed -E 's/\bl1d_mshr_entry\b/l1d_mshr_entry_ref/g; s/\bl1d_mshr\b/l1d_mshr_ref/g; s/\bl1d_arb_rr\b/l1d_arb_rr_ref/g' \
        "$ROOT/rtl/ref/l1d_mshr.v" > "$P/ref/l1d_mshr_ref.v"
    sed -E 's/\bl1d_reservation_unit\b/l1d_reservation_unit_ref/g' "$ROOT/rtl/ref/l1d_reservation_unit.v" > "$P/ref/l1d_reservation_unit_ref.v"
    local R="$P/ref"

    # ---- 1. lint ----
    local LINT
    if command -v verilator >/dev/null 2>&1; then
        LINT="pass"
        for top in l1d_mshr l1d_reservation_unit; do
            if ! verilator --lint-only -Wno-fatal -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -I"$INC" --top-module $top \
                    "$VD"/*.v $CMN > "$P/lint_$top.log" 2>&1; then
                LINT="FAIL ($top)"; st=1
            fi
            grep -c "%Warning" "$P/lint_$top.log" | sed "s/^/  verilator warnings ($top): /"
        done
    else
        LINT="iverilog compile only (no verilator)"
    fi
    echo "lint: $LINT"

    # ---- 2. lockstep ----
    # lockstep <test> <files> <defines ...>: one compile + run, prints PASS / FAIL and the last lines
    lockstep() {
        local tb=$1 files=$2; shift 2
        local defs="$*" tag
        tag=$(echo "$tb ${defs:-default}" | tr ' =' '__' | tr -cd 'A-Za-z0-9_')
        local log="$P/$tag.log"
        if iverilog -g2012 -I"$INC" $defs -s "$tb" -o "$P/$tag.vvp" $files "$ROOT/tb/$tb.v" > "$log" 2>&1; then
            timeout 3000 vvp -n "$P/$tag.vvp" >> "$log" 2>&1
        fi
        if grep -q "TEST PASSED" "$log"; then echo "PASS $tb ${defs:-default}"; res="$res P"
        else echo "FAIL $tb ${defs:-default}  (log: $log)"; res="$res F"; st=1; fi
        grep -E "^cycles|WARNING|MISMATCH|error|Error" "$log" | head -6 | sed 's/^/  | /'
    }
    local A="$VD/l1d_arb_rr.v $R/l1d_arb_rr_ref.v"
    local E="$VD/l1d_mshr_entry.v $R/l1d_mshr_entry_ref.v $CMN"
    local M="$VD/l1d_mshr.v $VD/l1d_mshr_entry.v $VD/l1d_arb_rr.v $R/l1d_mshr_ref.v $R/l1d_mshr_entry_ref.v $R/l1d_arb_rr_ref.v $CMN"
    local S="$VD/l1d_reservation_unit.v $R/l1d_reservation_unit_ref.v"
    lockstep tb_arb_rr_equiv "$A"
    lockstep tb_arb_rr_equiv "$A" -DSEED=3
    lockstep tb_mshr_entry_equiv "$E"
    lockstep tb_mshr_entry_equiv "$E" -DSEED=7
    lockstep tb_mshr_entry_equiv "$E" -DSEED=21 -DNCYC=800000
    lockstep tb_mshr_equiv "$M"
    lockstep tb_mshr_equiv "$M" -DSEED=5
    lockstep tb_mshr_equiv "$M" -DSEED=9 -DNCYC=600000
    lockstep tb_reservation_unit_equiv "$S"
    lockstep tb_reservation_unit_equiv "$S" -DSEED=4
    lockstep tb_reservation_unit_equiv "$S" -DSEED=9 -DLOCKTO=3
    lockstep tb_reservation_unit_equiv "$S" -DSEED=13 -DLOCKTO=5 -DNCYC=600000
    local np nf
    np=$(echo "$res" | tr ' ' '\n' | grep -c '^P$'); nf=$(echo "$res" | tr ' ' '\n' | grep -c '^F$')

    # ---- 3. formal ----
    local FM
    FM=$(bash "$ROOT/formal/run_formal.sh" "$VD" "$P/formal" 2>&1 | tee "$P/formal.txt" | tail -1)
    cat "$P/formal.txt"
    case "$FM" in *"ALL EQUIVALENT"*) ;; *) st=1 ;; esac

    {
        echo "## Version \`$NAME\`: function checks"
        echo
        echo "| check | result |"
        echo "|---|---|"
        echo "| lint | $LINT |"
        echo "| lockstep against the original (12 runs) | $np passed, $nf failed |"
        echo "| formal equivalence | $FM |"
    } > "$OUT/func.md"
    echo "lint=$(echo "$LINT" | cut -d' ' -f1) lockstep=$np/$((np+nf)) formal=$(case "$FM" in *"ALL EQUIVALENT"*) echo EQUIVALENT ;; *) echo NOT_PROVEN ;; esac)" > "$OUT/func.txt"
    return $st
}

part_timing() {   # $1 = part name, $2 = module
    local part=$1 mod=$2
    SIZED=1 PATH_LOG=1 bash "$ROOT/flow/run_timing.sh" "$mod" "$VD" 250 "$OUT/$part/t250"
    bash "$ROOT/flow/run_timing.sh" "$mod" "$VD" 200 "$OUT/$part/t200"
    v() { sed -n "s/.* $2=\([^ ]*\).*/\1/p" "$1" 2>/dev/null | head -1; }
    local r250="$OUT/$part/t250/result.txt" r200="$OUT/$part/t200/result.txt"
    {
        echo "## Version \`$NAME\`: timing of \`$mod\` (ASAP7, ideal clock, no wires)"
        echo
        echo "| check | result |"
        echo "|---|---|"
        echo "| 250 ps (4 GHz), synthesis only | $(v "$r250" synth_crit) ps (slack $(v "$r250" synth_slack)) |"
        echo "| 250 ps after gate sizing | $(v "$r250" sized_crit) ps (slack $(v "$r250" sized_slack)) |"
        echo "| 200 ps (5 GHz), synthesis only | $(v "$r200" synth_crit) ps (slack $(v "$r200" synth_slack)) |"
        echo "| area | $(v "$r250" area) um2 |"
        echo
        echo "Failing groups at 200 ps (worst first):"
        echo
        echo '```'
        sed -n '/=== 2. failing groups/,/=== 3. the/p' "$OUT/$part/t200/violations.txt" 2>/dev/null | sed '1d;$d' | head -14
        echo '```'
    } > "$OUT/$part.md"
    echo "module=$mod t250=$(v "$r250" synth_crit) t250sized=$(v "$r250" sized_crit) t200=$(v "$r200" synth_crit) area=$(v "$r250" area)" > "$OUT/$part.txt"
}

for p in $PARTS; do
    echo; echo "################ $NAME: $p ################"
    case $p in
        func)       if [ "${FUNC:-1}" = 1 ]; then part_func || status=1; else echo "function checks skipped (FUNC=0)"; fi ;;
        mshr)       part_timing mshr l1d_mshr ;;
        mshr_entry) part_timing mshr_entry l1d_mshr_entry ;;
        rsv)        part_timing rsv l1d_reservation_unit ;;
        *)          echo "unknown part $p"; status=1 ;;
    esac
    [ -f "$OUT/$p.md" ] && cat "$OUT/$p.md"
done
exit $status
