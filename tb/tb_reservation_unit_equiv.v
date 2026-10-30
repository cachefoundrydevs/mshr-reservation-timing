// tb_reservation_unit_equiv.v  (testbench)
// Lockstep test of the LR/SC reservation and AMO-lock unit: the timing-optimised l1d_reservation_unit (rtl/opt or a variant) against the
// ORIGINAL one of rtl/ref (renamed l1d_reservation_unit_ref by scripts/run_all.sh).
//
// Both get the same random inputs in every cycle. At every falling clock edge after reset ALL outputs must be equal:
//   sc_reservation_matches, reservation_valid, reservation_line_addr, amo_lock_valid, amo_lock_snoop_hold, amo_lock_line,
//   amo_lock_timeout_pulse.
// The stimulus has no protocol (both units see the same values), so every combination of events in one cycle is exercised:
//   - every line address comes from a pool of 4 lines, so LR / SC / store / AMO / install / snoop-clear hit the reserved or the locked
//     line very often;
//   - the event rates change every 4000 cycles between BUSY (each event about 1 in 4 cycles) and QUIET (about 1 in 64, AMO writes
//     about 1 in 8192), so that an AMO lock also runs into its time-out;
//   - a reset pulse comes now and then.
// The test prints how often each interesting situation happened (coverage) and fails if any output differs in any cycle.
//
// Options (iverilog -D):   NCYC=<n> cycles (default 300000)   SEED=<n> random seed (default 1)
//                          LOCKTO=<n> LOCK_TIMEOUT of both units (default: the configured value, 1024; small values give many time-outs)

`timescale 1ns/1ps
`include "l1d_defines.vh"

module tb_reservation_unit_equiv #(`L1D_PARAMS) ();
    `include "l1d_encodings.vh"
    `include "l1d_fields.vh"

`ifdef NCYC
    localparam NCYC = `NCYC;
`else
    localparam NCYC = 300000;
`endif
`ifdef SEED
    localparam SEED0 = `SEED;
`else
    localparam SEED0 = 1;
`endif
`ifdef LOCKTO
    localparam LT = `LOCKTO;
`else
    localparam LT = LOCK_TIMEOUT;
`endif

    reg clk = 1'b0;
    reg rst = 1'b1;
    always #5 clk = ~clk;

    // ---- inputs (the same for both units) ----
    reg  [LINE_ADDR_W-1:0] sc_check_line_addr;
    reg  [LINE_ADDR_W-1:0] s2_line_addr;
    reg                    s2_lr_completed, s2_sc_completed, s2_write_completed;
    reg                    s2_amo_read_completed, s2_amo_read_was_hit, s2_amo_write_completed;
    reg                    s2_install_valid;
    reg  [LINE_ADDR_W-1:0] s2_install_line_addr;
    reg                    s1_clear_valid;
    reg  [LINE_ADDR_W-1:0] s1_clear_line_addr;
    reg                    maint_clear;

    // ---- outputs: o_* = optimised, r_* = original ----
    wire                   o_match, r_match;
    wire                   o_rv, r_rv;
    wire [LINE_ADDR_W-1:0] o_rl, r_rl;
    wire                   o_lv, r_lv;
    wire                   o_lh, r_lh;
    wire [LINE_ADDR_W-1:0] o_ll, r_ll;
    wire                   o_to, r_to;

    l1d_reservation_unit #(.LOCK_TIMEOUT(LT)) dut_opt (
        .clk(clk), .rst(rst),
        .sc_check_line_addr(sc_check_line_addr), .sc_reservation_matches(o_match),
        .s2_line_addr(s2_line_addr), .s2_lr_completed(s2_lr_completed), .s2_sc_completed(s2_sc_completed),
        .s2_write_completed(s2_write_completed), .s2_amo_read_completed(s2_amo_read_completed),
        .s2_amo_read_was_hit(s2_amo_read_was_hit), .s2_amo_write_completed(s2_amo_write_completed),
        .s2_install_valid(s2_install_valid), .s2_install_line_addr(s2_install_line_addr),
        .s1_clear_valid(s1_clear_valid), .s1_clear_line_addr(s1_clear_line_addr), .maint_clear(maint_clear),
        .reservation_valid(o_rv), .reservation_line_addr(o_rl), .amo_lock_valid(o_lv), .amo_lock_snoop_hold(o_lh),
        .amo_lock_line(o_ll), .amo_lock_timeout_pulse(o_to)
    );
    l1d_reservation_unit_ref #(.LOCK_TIMEOUT(LT)) dut_ref (
        .clk(clk), .rst(rst),
        .sc_check_line_addr(sc_check_line_addr), .sc_reservation_matches(r_match),
        .s2_line_addr(s2_line_addr), .s2_lr_completed(s2_lr_completed), .s2_sc_completed(s2_sc_completed),
        .s2_write_completed(s2_write_completed), .s2_amo_read_completed(s2_amo_read_completed),
        .s2_amo_read_was_hit(s2_amo_read_was_hit), .s2_amo_write_completed(s2_amo_write_completed),
        .s2_install_valid(s2_install_valid), .s2_install_line_addr(s2_install_line_addr),
        .s1_clear_valid(s1_clear_valid), .s1_clear_line_addr(s1_clear_line_addr), .maint_clear(maint_clear),
        .reservation_valid(r_rv), .reservation_line_addr(r_rl), .amo_lock_valid(r_lv), .amo_lock_snoop_hold(r_lh),
        .amo_lock_line(r_ll), .amo_lock_timeout_pulse(r_to)
    );

    // ---- random numbers and the pool of lines ----
    integer seed;
    function integer rnd;                                 // a non-negative random number
        input integer dummy;
        begin
            rnd = $random(seed);
            if (rnd < 0) rnd = -rnd;
        end
    endfunction
    reg [LINE_ADDR_W-1:0] pool [0:3];
    function [LINE_ADDR_W-1:0] pick;                      // one of the 4 pool lines, now and then a fresh random line
        input integer dummy;
        integer k;
        begin
            k = rnd(0) % 16;
            if (k == 0) pick = {$random(seed), $random(seed)};
            else        pick = pool[k % 4];
        end
    endfunction

    // ---- the stimulus: new values just after every falling edge (after the compare) ----
    integer cyc, errors, phase;
    integer n_lr, n_rv, n_match, n_lock, n_hold, n_to, n_amow_lock, n_rst;
    function ev;                                          // an event with probability 1 / div
        input integer div;
        begin
            ev = ((rnd(0) % div) == 0);
        end
    endfunction
    task drive;
        integer dv, dw;
        begin
            dv = phase ? 4 : 64;                          // busy : quiet
            dw = phase ? 4 : 8192;                        // AMO writes are rare in the quiet phase (time-outs)
            sc_check_line_addr     = pick(0);
            s2_line_addr           = pick(0);
            s2_lr_completed        = ev(dv);
            s2_sc_completed        = ev(dv);
            s2_write_completed     = ev(dv);
            s2_amo_read_completed  = ev(dv);
            s2_amo_read_was_hit    = ev(2);
            s2_amo_write_completed = ev(dw);
            s2_install_valid       = ev(dv);
            s2_install_line_addr   = pick(0);
            s1_clear_valid         = ev(dv);
            s1_clear_line_addr     = pick(0);
            maint_clear            = ev(phase ? 64 : 4096);
        end
    endtask

    initial begin
        seed = SEED0;
        pool[0] = {$random(seed), $random(seed)};
        pool[1] = {$random(seed), $random(seed)};
        pool[2] = {$random(seed), $random(seed)};
        pool[3] = {$random(seed), $random(seed)};
        errors = 0; phase = 1;
        n_lr = 0; n_rv = 0; n_match = 0; n_lock = 0; n_hold = 0; n_to = 0; n_amow_lock = 0; n_rst = 0;
        drive;
        rst = 1'b1;
        repeat (3) @(posedge clk);
        @(negedge clk) rst = 1'b0;
        for (cyc = 0; cyc < NCYC; cyc = cyc + 1) begin
            @(negedge clk);
            // compare (rst is low in this cycle's first half for at least one cycle after every reset pulse)
            if (!rst) begin
                if (o_match !== r_match || o_rv !== r_rv || o_rl !== r_rl || o_lv !== r_lv || o_lh !== r_lh ||
                    o_ll !== r_ll || o_to !== r_to) begin
                    errors = errors + 1;
                    if (errors <= 10)
                        $display("MISMATCH cycle %0d: match %b/%b  res_valid %b/%b  res_line %h/%h  lock %b/%b  hold %b/%b  lock_line %h/%h  timeout %b/%b",
                                 cyc, o_match, r_match, o_rv, r_rv, o_rl, r_rl, o_lv, r_lv, o_lh, r_lh, o_ll, r_ll, o_to, r_to);
                end
                // coverage (counted on the original unit)
                if (s2_lr_completed)                        n_lr = n_lr + 1;
                if (r_rv)                                   n_rv = n_rv + 1;
                if (r_match)                                n_match = n_match + 1;
                if (r_lv)                                   n_lock = n_lock + 1;
                if (r_lh)                                   n_hold = n_hold + 1;
                if (r_to)                                   n_to = n_to + 1;
                if (r_lv && s2_amo_write_completed && s2_line_addr == r_ll) n_amow_lock = n_amow_lock + 1;
            end
            // next inputs
            if ((cyc % 4000) == 0) phase = (rnd(0) % 2);
            drive;
            if (rnd(0) % 20000 == 0) begin rst = 1'b1; n_rst = n_rst + 1; end
            else rst = 1'b0;
        end
        $display("cycles %0d  LOCK_TIMEOUT %0d  LR %0d  reservation-valid cycles %0d  SC match cycles %0d  lock cycles %0d  snoop-hold cycles %0d  time-outs %0d  AMO writes on the locked line %0d  resets %0d",
                 NCYC, LT, n_lr, n_rv, n_match, n_lock, n_hold, n_to, n_amow_lock, n_rst);
        if (n_match == 0 || n_lock == 0 || n_amow_lock == 0)
            $display("WARNING: a coverage counter is 0 (the stimulus did not reach that situation): try another SEED or more cycles");
        if (LT <= 64 && n_to == 0)
            $display("WARNING: no AMO-lock time-out happened although LOCK_TIMEOUT is small");
        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d mismatching cycles", errors);
        $finish;
    end
endmodule
