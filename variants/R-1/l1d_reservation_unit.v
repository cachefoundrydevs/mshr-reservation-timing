// ============================================================================
// l1d_reservation_unit.v  -  LR/SC reservation and AMO line lock of one bank (new in v2)
// ============================================================================
// IN SIMPLE WORDS
//   Atomic instructions need two small memories of "what I am in the middle of". One per bank, no wire between banks.
//
//   1. THE RESERVATION (for LR / SC, "load-reserved / store-conditional")
//        LR  reads a word and RESERVES its line:  "I want to write this soon, tell me if anybody touches it".
//        SC  writes only if the reservation is still intact; the answer tells the CPU whether it worked
//            (0 = success, 1 = fail, delivered in the response data word).
//      The reservation = {valid, line address}:
//        set by    an LR that completes (answered by a hit, or handed to an MSHR entry)
//        cleared by every SC that completes (success or fail); a store or AMO write that completes on the reserved
//                  line; a snoop on the reserved line (hit or not); evicting the reserved line (when
//                  RSV_CLR_ON_EVICT = 1; both in Stage 1); and when a flush / clean starts.
//      Stage 2 events are OLDER than the Stage 1 event of the same cycle, so they are applied first; a Stage 1 clear
//      therefore wins over a same-cycle set.
//
//   2. THE AMO LOCK (for AMO read ... AMO write pairs: an atomic read-modify-write is done in two halves)
//        The lock = {valid, snoop-hold, line address}. It keeps the line PRIVATE between the two halves.
//        set by    an AMO read that completes (amo_lock_snoop_hold = 1 at once if it was a cache hit, i.e. the bank
//                  holds the line in E/M; otherwise as soon as the line is installed)
//        cleared by the AMO write that completes on the locked line, or by a TIME-OUT of LOCK_TIMEOUT (1024) cycles
//                  (amo_lock_timeout_pulse; l1d_top makes it the sticky amo_err pin: the AMO write never came)
//        amo_lock_valid       holds back CPU requests to the line (l1d_inflight_tracker)
//        amo_lock_snoop_hold  holds back snoops to the line (l1d_snoop_buf). A snoop is never held while the line is still
//                             on its way from memory, so the snoop contract (no R data for a line while a snoop on it
//                             is open) cannot deadlock.
//
//   sc_reservation_matches compares the reservation with the line of the SC that is in Stage 1 (the SC check);
//   l1d_bank ANDs it with its own Stage 2 term.
//
// WHAT KIND OF STATE MACHINE IS IT?
//   Two small machines: a 2-state reservation machine (none / reserved) and a 3-state lock machine (free / locked with
//   snoops still allowed / locked with snoops held) plus a time-out counter. Outputs are Moore (register outputs)
//   except sc_reservation_matches, which also depends on the Stage 1 line. 132 flip-flops per bank.
//
// PORTS (new name, old name, meaning)
//   sc_check_line_addr                   (was chk_line)                 line of the SC in Stage 1 (for the reservation check)
//   sc_reservation_matches               (was sc_match)                 a reservation is valid on sc_check_line_addr
//   s2_line_addr                         (was s2_line)                  line address of the request completing in Stage 2
//   s2_lr_completed                      (was ev_lr)                    an LR completed in Stage 2
//   s2_sc_completed                      (was ev_sc)                    an SC completed in Stage 2 (success or fail)
//   s2_write_completed                   (was ev_wr)                    a store completed in Stage 2
//   s2_amo_read_completed                (was ev_amor)                  an AMO read completed in Stage 2
//   s2_amo_read_was_hit                  (was ev_amor_hit)              ... and it was answered by a cache hit
//   s2_amo_write_completed               (was ev_amow)                  an AMO write completed in Stage 2
//   s2_install_valid                     (was inst_valid)               a refill installs a line in Stage 2
//   s2_install_line_addr                 (was inst_line)                line address of that install
//   s1_clear_valid                       (was s1_clr)                   Stage 1 snoop or eviction: clear a reservation on s1_clear_line_addr
//   s1_clear_line_addr                   (was s1_clr_line)              line of that snoop or eviction
//   maint_clear                          (was maint_clr)                a flush/clean starts: clear the reservation
//   reservation_valid                    (was rsv_valid)                an LR reservation is held
//   reservation_line_addr                (was rsv_line)                 line address of the reservation
//   amo_lock_valid                       (was lock_valid)               an AMO lock is held
//   amo_lock_snoop_hold                  (was lock_snp)                 snoops to the locked line are held
//   amo_lock_line                        (was lock_line)                line address of the AMO lock
//   amo_lock_timeout_pulse               (was to_err)                   one-cycle pulse: the lock timed out (the AMO write never came)
//
// VERILOG WORDS USED IN THIS FILE
//   output reg x    a register that holds its value until it is written (flip-flop)
//   always @*       the "next value" logic (v_s2, l_s2) written like a program, no clock
//   rel_amow, rel_to  wires: "release by the AMO write" and "release by the time-out"
// ============================================================================

`default_nettype none
`include "l1d_defines.vh"

module l1d_reservation_unit #(`L1D_PARAMS) (
    clk, rst,
    sc_check_line_addr, sc_reservation_matches,
    s2_line_addr, s2_lr_completed, s2_sc_completed, s2_write_completed, s2_amo_read_completed, s2_amo_read_was_hit, s2_amo_write_completed,
    s2_install_valid, s2_install_line_addr,
    s1_clear_valid, s1_clear_line_addr,
    maint_clear,
    reservation_valid, reservation_line_addr,
    amo_lock_valid, amo_lock_snoop_hold, amo_lock_line, amo_lock_timeout_pulse
);
    `include "l1d_encodings.vh"
    `include "l1d_fields.vh"

    // TO_W = bits of the time-out counter; TO_LAST = the counter value one cycle before the time-out
    localparam TO_W = $clog2(LOCK_TIMEOUT + 1);
    localparam [TO_W-1:0] TO_LAST = LOCK_TIMEOUT - 1;
    // TIMING OPT (R-1): predecessor comparison removes the incrementer from to_last.
    // Both sides use TO_W-bit arithmetic, including wraparound; no cycle changes.
    localparam [TO_W-1:0] TO_PRELAST = TO_LAST - 1'b1; // TO_W = 11 bits by default

    input  wire                   clk;                    // clock: all registers change on its rising edge
    input  wire                   rst;                    // synchronous reset, active high (control state goes to its idle value)
    // Stage 1: SC check
    input  wire [LINE_ADDR_W-1:0] sc_check_line_addr;     // line of the SC in Stage 1 (for the reservation check)
    output wire                   sc_reservation_matches; // a reservation is valid on sc_check_line_addr
    // Stage 2: completions of the LSU request in Stage 2 (all on s2_line)
    input  wire [LINE_ADDR_W-1:0] s2_line_addr;           // line address of the request completing in Stage 2
    input  wire                   s2_lr_completed;        // an LR completed in Stage 2
    input  wire                   s2_sc_completed;        // an SC completed in Stage 2 (success or fail)
    input  wire                   s2_write_completed;     // a store completed in Stage 2
    input  wire                   s2_amo_read_completed;  // an AMO read completed in Stage 2
    input  wire                   s2_amo_read_was_hit;    // ... and it was answered by a cache hit
    input  wire                   s2_amo_write_completed; // an AMO write completed in Stage 2
    // Stage 2: a refill / swap installed inst_line
    input  wire                   s2_install_valid;       // a refill installs a line in Stage 2
    input  wire [LINE_ADDR_W-1:0] s2_install_line_addr;   // line address of that install
    // Stage 1: snoop on a line, or eviction of a line
    input  wire                   s1_clear_valid;         // Stage 1 snoop or eviction: clear a reservation on s1_clear_line_addr
    input  wire [LINE_ADDR_W-1:0] s1_clear_line_addr;     // line of that snoop or eviction
    // flush / clean start
    input  wire                   maint_clear;            // a flush/clean starts: clear the reservation
    // state
    output reg                    reservation_valid;      // an LR reservation is held
    output reg  [LINE_ADDR_W-1:0] reservation_line_addr;  // line address of the reservation
    output reg                    amo_lock_valid;         // an AMO lock is held
    output reg                    amo_lock_snoop_hold;    // snoops to the locked line are held
    output reg  [LINE_ADDR_W-1:0] amo_lock_line;          // line address of the AMO lock
    output reg                    amo_lock_timeout_pulse; // one-cycle pulse: the lock timed out (the AMO write never came)

    // SC check: a reservation exists and it is on the line of the SC in Stage 1
    assign sc_reservation_matches = reservation_valid && (reservation_line_addr == sc_check_line_addr);

    // ---- reservation: first the next value caused by the request completing in Stage 2 (v_s2, l_s2 = "valid" and "line"),
    //      then the Stage 1 clear (snoop / eviction) is applied on top ----
    reg                   v_s2;
    reg [LINE_ADDR_W-1:0] l_s2;
    // Stage 2 events: an LR sets the reservation; an SC always clears it (success or fail); a store to the reserved line clears it
    always @* begin
        v_s2 = reservation_valid;
        l_s2 = reservation_line_addr;
        if (s2_lr_completed) begin
            v_s2 = 1'b1;
            l_s2 = s2_line_addr;
        end else if (s2_sc_completed) begin
            v_s2 = 1'b0;
        end else if (s2_write_completed && reservation_valid && (reservation_line_addr == s2_line_addr)) begin
            v_s2 = 1'b0;
        end
    end
    // a snoop or eviction in Stage 1 hits the (new) reservation line: clear it
    wire s1_hit_rsv = s1_clear_valid && v_s2 && (l_s2 == s1_clear_line_addr);

    // the reservation registers (also cleared when a flush / clean starts)
    always @(posedge clk) begin
        if (rst) begin
            reservation_valid <= 1'b0;
            reservation_line_addr  <= {LINE_ADDR_W{1'b0}};
        end else begin
            reservation_valid <= v_s2 && !s1_hit_rsv && !maint_clear;
            reservation_line_addr  <= l_s2;
        end
    end

    // ---------------- lock ----------------
    // ---- AMO lock: time-out counter, and the two ways the lock is released ----
    reg [TO_W-1:0] to_cnt;                                // counts the cycles the lock has been held
    reg            to_last;                               // to_cnt == LOCK_TIMEOUT - 1, kept as a flop (no compare in the time-out path)
    wire           rel_amow = amo_lock_valid && s2_amo_write_completed && (s2_line_addr == amo_lock_line);  // the AMO write on the locked line completes: release
    wire           rel_to   = amo_lock_valid && to_last;  // the time-out expires: release (and raise the error pulse)

    // the lock registers
    always @(posedge clk) begin
        if (rst) begin
            amo_lock_valid <= 1'b0;
            amo_lock_snoop_hold   <= 1'b0;
            amo_lock_line  <= {LINE_ADDR_W{1'b0}};
            to_cnt     <= {TO_W{1'b0}};
            to_last    <= 1'b0;
            amo_lock_timeout_pulse     <= 1'b0;
        end else begin
            amo_lock_timeout_pulse <= 1'b0;
            // an AMO read completes: take the lock on its line (the time-out counter restarts below)
            if (s2_amo_read_completed) begin
                amo_lock_valid <= 1'b1;
                amo_lock_snoop_hold   <= s2_amo_read_was_hit;
                amo_lock_line  <= s2_line_addr;
            // release; the error pulse is raised only for a time-out (not when the AMO write released it)
            end else if (rel_amow || rel_to) begin
                amo_lock_valid <= 1'b0;
                amo_lock_snoop_hold   <= 1'b0;
                amo_lock_timeout_pulse     <= rel_to && !rel_amow;
            // lock held: when the locked line gets installed (AMO read was a miss) start holding snoops
            end else if (amo_lock_valid) begin
                if (s2_install_valid && (s2_install_line_addr == amo_lock_line))
                    amo_lock_snoop_hold <= 1'b1;
            end
            // TIMING OPT (RU-1): the time-out counter restarts with a new lock and counts in EVERY locked cycle, also in the
            // release cycle (it used to hold there). to_cnt / to_last are read only while the lock is held (rel_to = amo_lock_valid && to_last)
            // and every new lock restarts them, so the outputs are the same in every cycle; the counter enable no longer waits for the
            // 58-bit compare of the release (rel_amow).
            if (s2_amo_read_completed) begin
                to_cnt  <= {TO_W{1'b0}};
                to_last <= 1'b0;
            end else if (amo_lock_valid) begin
                to_cnt  <= to_cnt + 1'b1;
                to_last <= (to_cnt == TO_PRELAST);
            end
        end
    end

// ---- simulation-only trace: reservation and lock changes ----
`ifdef L1D_DEBUG
    // Debug trace (simulation only): reservation and lock changes.
    always @(posedge clk) begin
        if (!rst) begin
            if (s2_lr_completed)
                $display("[%0t] L1D RSV  %m LR sets reservation line=%h", $time, {s2_line_addr, {OFFSET_W{1'b0}}});
            if (s2_sc_completed && reservation_valid)
                $display("[%0t] L1D RSV  %m SC clears reservation", $time);
            if (s2_write_completed && reservation_valid && reservation_line_addr == s2_line_addr)
                $display("[%0t] L1D RSV  %m write to the reserved line clears it", $time);
            if (s1_hit_rsv)
                $display("[%0t] L1D RSV  %m snoop / eviction clears reservation line=%h", $time, {s1_clear_line_addr, {OFFSET_W{1'b0}}});
            if (s2_amo_read_completed)
                $display("[%0t] L1D LOCK %m AMO read locks line=%h (snoop hold %b)", $time, {s2_line_addr, {OFFSET_W{1'b0}}}, s2_amo_read_was_hit);
            if (rel_amow)
                $display("[%0t] L1D LOCK %m AMO write releases line=%h", $time, {amo_lock_line, {OFFSET_W{1'b0}}});
            if (rel_to && !rel_amow)
                $display("[%0t] L1D LOCK %m ERROR lock on line=%h timed out after %0d cycles (AMO write never came)",
                         $time, {amo_lock_line, {OFFSET_W{1'b0}}}, LOCK_TIMEOUT);
            if (amo_lock_valid && !amo_lock_snoop_hold && s2_install_valid && s2_install_line_addr == amo_lock_line)
                $display("[%0t] L1D LOCK %m locked line installed: snoops now held", $time);
        end
    end
`endif

endmodule

`default_nettype wire
