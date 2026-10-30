// tb_mshr_equiv.v  (testbench)
// Lockstep test of the whole MSHR (8 entries, CAM, free-entry pick, 3 arbiters, output muxes): the timing-optimised l1d_mshr
// (with the optimised l1d_mshr_entry) against the ORIGINAL l1d_mshr with the ORIGINAL entry of rtl/ref
// (renamed l1d_mshr_ref / l1d_mshr_entry_ref by scripts/run_all.sh).
//
// Both get the same random inputs every cycle. At every falling clock edge all outputs must be equal. Two outputs are compared
// only where they mean something: response_packet while response_valid = 1 (the optimised entry registers its data in E_MERGE)
// and lookup_entry_has_data while lookup_hit = 1 (the bank reads it only on a hit), s2_install_line_data while the selected entry holds the line (O-7a), s1_install_vc_slot while the selected entry is busy (P4).
// The stimulus is random with no protocol (both see the same). The line addresses come from a pool of 4, so lookups match
// several busy entries at once (tests the "lowest matching entry" rule); allocation is also tried while every entry is busy;
// a reset pulse comes now and then.
//
// Options (iverilog -D / xvlog -d):   NCYC=<n> number of cycles (default 300000)   SEED=<n> random seed (default 1)

`timescale 1ns/1ps
`include "l1d_defines.vh"

module tb_mshr_equiv #(`L1D_PARAMS) ();
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
    localparam N = MSHR_ENTRIES;

    reg clk = 1'b0;
    reg rst = 1'b1;
    always #5 clk = ~clk;

    reg  [LINE_ADDR_W-1:0]      lookup_line_addr;
    reg                         allocate_valid;
    reg  [LINE_ADDR_W-1:0]      allocate_line_addr;
    reg                         allocate_is_swap;
    reg  [LINE_W-1:0]           allocate_swap_line_data;
    reg                         allocate_swap_dirty, allocate_swap_shared;
    reg  [VC_ID_W-1:0]          allocate_swap_vc_slot;
    reg                         allocate_unique_read;
    reg  [SEAT_W-1:0]           allocate_seat;
    reg                         allocate_is_write;
    reg  [MEM_SIZE_BITS-1:0]    allocate_access_size;
    reg  [MASTER_ID_BITS-1:0]   allocate_master_id;
    reg  [IDX_BITS-1:0]         allocate_rob_index;
    reg  [OFFSET_W-1:0]         allocate_byte_offset;
    reg  [WRITE_DATA_WIDTH-1:0] allocate_store_data;
    reg                         axi_read_req_ready;
    reg                         axi_read_beat_valid;
    reg  [MSHR_ID_W-1:0]        axi_read_beat_sub_id;
    reg  [AXI_DATA_W-1:0]       axi_read_beat_data;
    reg                         axi_read_beat_last, axi_read_beat_error, axi_read_beat_shared;
    reg                         response_taken;
    reg                         refill_token_granted;
    reg  [MSHR_ID_W-1:0]        s1_install_entry_id, s2_install_entry_id;
    reg                         s1_token_held_valid;
    reg  [MSHR_ID_W-1:0]        s1_token_held_entry_id;
    reg                         s2_install_done_valid;
    reg  [MSHR_ID_W-1:0]        s2_install_done_entry_id;

    // outputs: o_* = optimised, r_* = reference
    wire                        o_hit, o_hasd, o_can, o_arv, o_aru, o_rv, o_tv, o_s1sw, o_any;
    wire [MSHR_ID_W-1:0]        o_hid, o_aid, o_asub, o_tid;
    wire [LINE_ADDR_W-1:0]      o_aline, o_tline;
    wire [RESP_W-1:0]           o_pkt;
    wire [SEAT_W-1:0]           o_seat;
    wire [1:0]                  o_s1st;
    wire [VC_ID_W-1:0]          o_s1sl;
    wire [LINE_W-1:0]           o_s2d;
    wire [N-1:0]                o_freed;
    wire                        r_hit, r_hasd, r_can, r_arv, r_aru, r_rv, r_tv, r_s1sw, r_any;
    wire [MSHR_ID_W-1:0]        r_hid, r_aid, r_asub, r_tid;
    wire [LINE_ADDR_W-1:0]      r_aline, r_tline;
    wire [RESP_W-1:0]           r_pkt;
    wire [SEAT_W-1:0]           r_seat;
    wire [1:0]                  r_s1st;
    wire [VC_ID_W-1:0]          r_s1sl;
    wire [LINE_W-1:0]           r_s2d;
    wire [N-1:0]                r_freed;

`define MSHR_IN \
        .clk(clk), .rst(rst), .lookup_line_addr(lookup_line_addr), \
        .allocate_valid(allocate_valid), .allocate_line_addr(allocate_line_addr), .allocate_is_swap(allocate_is_swap), \
        .allocate_swap_line_data(allocate_swap_line_data), .allocate_swap_dirty(allocate_swap_dirty), \
        .allocate_swap_shared(allocate_swap_shared), .allocate_swap_vc_slot(allocate_swap_vc_slot), \
        .allocate_unique_read(allocate_unique_read), .allocate_seat(allocate_seat), .allocate_is_write(allocate_is_write), \
        .allocate_access_size(allocate_access_size), .allocate_master_id(allocate_master_id), \
        .allocate_rob_index(allocate_rob_index), .allocate_byte_offset(allocate_byte_offset), \
        .allocate_store_data(allocate_store_data), .axi_read_req_ready(axi_read_req_ready), \
        .axi_read_beat_valid(axi_read_beat_valid), .axi_read_beat_sub_id(axi_read_beat_sub_id), \
        .axi_read_beat_data(axi_read_beat_data), .axi_read_beat_last(axi_read_beat_last), \
        .axi_read_beat_error(axi_read_beat_error), .axi_read_beat_shared(axi_read_beat_shared), \
        .response_taken(response_taken), .refill_token_granted(refill_token_granted), \
        .s1_install_entry_id(s1_install_entry_id), .s2_install_entry_id(s2_install_entry_id), \
        .s1_token_held_valid(s1_token_held_valid), .s1_token_held_entry_id(s1_token_held_entry_id), \
        .s2_install_done_valid(s2_install_done_valid), .s2_install_done_entry_id(s2_install_done_entry_id),

    l1d_mshr dut_opt (`MSHR_IN
        .lookup_hit(o_hit), .lookup_entry_id(o_hid), .lookup_entry_has_data(o_hasd),
        .can_allocate(o_can), .allocate_entry_id(o_aid),
        .axi_read_req_valid(o_arv), .axi_read_req_line_addr(o_aline), .axi_read_req_sub_id(o_asub), .axi_read_req_unique(o_aru),
        .response_valid(o_rv), .response_packet(o_pkt), .response_seat(o_seat),
        .refill_token_valid(o_tv), .refill_token_entry_id(o_tid), .refill_token_line_addr(o_tline),
        .s1_install_state(o_s1st), .s1_install_is_swap(o_s1sw), .s1_install_vc_slot(o_s1sl),
        .s2_install_line_data(o_s2d), .any_entry_busy(o_any), .entry_freed_pulses(o_freed));
    l1d_mshr_ref dut_ref (`MSHR_IN
        .lookup_hit(r_hit), .lookup_entry_id(r_hid), .lookup_entry_has_data(r_hasd),
        .can_allocate(r_can), .allocate_entry_id(r_aid),
        .axi_read_req_valid(r_arv), .axi_read_req_line_addr(r_aline), .axi_read_req_sub_id(r_asub), .axi_read_req_unique(r_aru),
        .response_valid(r_rv), .response_packet(r_pkt), .response_seat(r_seat),
        .refill_token_valid(r_tv), .refill_token_entry_id(r_tid), .refill_token_line_addr(r_tline),
        .s1_install_state(r_s1st), .s1_install_is_swap(r_s1sw), .s1_install_vc_slot(r_s1sl),
        .s2_install_line_data(r_s2d), .any_entry_busy(r_any), .entry_freed_pulses(r_freed));

    integer seed, cyc, errors, ii, pi, n1_err;
    // beat counter of every reference entry: a legal burst sends RLAST only on its last beat (so every chunk of the line buffer is written)
    wire [N-1:0] beat_is_last;
    genvar gg;
    generate
        for (gg = 0; gg < N; gg = gg + 1) begin : g_bl
            assign beat_is_last[gg] = (dut_ref.g_entry[gg].u_entry.beat == AXI_BEATS - 1);
        end
    endgenerate
    integer n_alloc, n_resp, n_hit_data, n_multi, n_freed, n_full_alloc, n_tok, n_ar;
    reg [LINE_ADDR_W-1:0] pool [0:3];

    function [31:0] rnd;       // random number 0..2**31-1 (advances seed)
        input dummy;
        begin
            rnd = $random(seed);
            rnd = rnd & 32'h7fffffff;
        end
    endfunction

    function integer popcount;
        input [N-1:0] v;
        integer k;
        begin
            popcount = 0;
            for (k = 0; k < N; k = k + 1) popcount = popcount + v[k];
        end
    endfunction

    task drive;
        begin
            lookup_line_addr        = pool[rnd(0) % 4];
            allocate_valid          = (rnd(0) % 3) == 0;
            allocate_line_addr      = pool[rnd(0) % 4];
            allocate_is_swap        = (rnd(0) % 4) == 0;
            for (ii = 0; ii < LINE_W / 32; ii = ii + 1) allocate_swap_line_data[ii*32 +: 32] = rnd(0) ^ (rnd(0) << 1);
            allocate_swap_dirty     = rnd(0) % 2;
            allocate_swap_shared    = rnd(0) % 2;
            allocate_swap_vc_slot   = rnd(0);
            allocate_unique_read    = rnd(0) % 2;
            allocate_seat           = rnd(0);
            allocate_is_write       = rnd(0) % 2;
            allocate_access_size    = rnd(0);
            allocate_master_id      = rnd(0);
            allocate_rob_index      = rnd(0);
            allocate_byte_offset    = rnd(0);
            // loads are naturally aligned (l1d_resp_gen header; the O-9 beat select relies on it); stores may start anywhere
            if (!allocate_is_write) allocate_byte_offset = allocate_byte_offset & ~((1 << allocate_access_size) - 1);
            allocate_store_data[31:0]  = rnd(0) ^ (rnd(0) << 1);
            allocate_store_data[63:32] = rnd(0) ^ (rnd(0) << 1);
            axi_read_req_ready      = rnd(0) % 2;
            axi_read_beat_valid     = (rnd(0) % 4) != 0;
            axi_read_beat_sub_id    = rnd(0);
            for (ii = 0; ii < AXI_DATA_W / 32; ii = ii + 1) axi_read_beat_data[ii*32 +: 32] = rnd(0) ^ (rnd(0) << 1);
            axi_read_beat_last      = ((rnd(0) % 4) == 0) && beat_is_last[axi_read_beat_sub_id];   // legal burst: RLAST only on the last beat of the addressed entry
            axi_read_beat_error     = (rnd(0) % 32) == 0;
            axi_read_beat_shared    = rnd(0) % 2;
            response_taken          = rnd(0) % 2;
            refill_token_granted    = rnd(0) % 2;
            s1_install_entry_id     = rnd(0);
            s2_install_entry_id     = rnd(0);
            s1_token_held_valid     = (rnd(0) % 4) == 0;
            s1_token_held_entry_id  = rnd(0);
            s2_install_done_valid   = rnd(0) % 2;
            s2_install_done_entry_id = rnd(0);
        end
    endtask

    task check;
        begin
            if (o_hit !== r_hit || o_hid !== r_hid || (r_hit === 1'b1 && o_hasd !== r_hasd) ||
                o_can !== r_can || o_aid !== r_aid ||
                o_arv !== r_arv || o_aline !== r_aline || o_asub !== r_asub || o_aru !== r_aru ||
                o_rv !== r_rv || (r_rv === 1'b1 && o_pkt !== r_pkt) || o_seat !== r_seat ||
                o_tv !== r_tv || o_tid !== r_tid || o_tline !== r_tline ||
                o_s1st !== r_s1st || o_s1sw !== r_s1sw || (dut_ref.e_busy[s1_install_entry_id] === 1'b1 && o_s1sl !== r_s1sl) || (dut_ref.e_hasd[s2_install_entry_id] === 1'b1 && o_s2d !== r_s2d) ||
                o_any !== r_any || o_freed !== r_freed) begin
                errors = errors + 1;
                if (errors <= 10) begin
                    $display("MISMATCH cycle %0d:", cyc);
                    if (o_hit !== r_hit || o_hid !== r_hid) $display("   lookup: hit %b/%b id %0d/%0d", o_hit, r_hit, o_hid, r_hid);
                    if (r_hit === 1'b1 && o_hasd !== r_hasd) $display("   lookup_entry_has_data %b/%b", o_hasd, r_hasd);
                    if (o_can !== r_can || o_aid !== r_aid) $display("   allocate: can %b/%b id %0d/%0d", o_can, r_can, o_aid, r_aid);
                    if (o_arv !== r_arv || o_aline !== r_aline || o_asub !== r_asub || o_aru !== r_aru)
                        $display("   AXI read: valid %b/%b sub %0d/%0d unique %b/%b line %h/%h", o_arv, r_arv, o_asub, r_asub, o_aru, r_aru, o_aline, r_aline);
                    if (o_rv !== r_rv || (r_rv === 1'b1 && o_pkt !== r_pkt) || o_seat !== r_seat)
                        $display("   response: valid %b/%b seat %0d/%0d packet %h/%h", o_rv, r_rv, o_seat, r_seat, o_pkt, r_pkt);
                    if (o_tv !== r_tv || o_tid !== r_tid || o_tline !== r_tline)
                        $display("   token: valid %b/%b id %0d/%0d line %h/%h", o_tv, r_tv, o_tid, r_tid, o_tline, r_tline);
                    if (o_s1st !== r_s1st || o_s1sw !== r_s1sw || (dut_ref.e_busy[s1_install_entry_id] === 1'b1 && o_s1sl !== r_s1sl) || (dut_ref.e_hasd[s2_install_entry_id] === 1'b1 && o_s2d !== r_s2d))
                        $display("   install data differ (state %b/%b swap %b/%b slot %0d/%0d)", o_s1st, r_s1st, o_s1sw, r_s1sw, o_s1sl, r_s1sl);
                    if (o_any !== r_any || o_freed !== r_freed) $display("   busy %b/%b freed %b/%b", o_any, r_any, o_freed, r_freed);
                end
            end
            // N-1 inside the optimised MSHR: the control arbiters give the same grants as the data arbiters in every cycle
            if (dut_opt.ar_gc !== dut_opt.ar_g || dut_opt.rs_gc !== dut_opt.rs_g || dut_opt.tk_gc !== dut_opt.tk_g) begin
                n1_err = n1_err + 1;
                if (n1_err <= 5) $display("N-1 GRANT ERROR cycle %0d: ar %b/%b rs %b/%b tk %b/%b", cyc, dut_opt.ar_gc, dut_opt.ar_g,
                                          dut_opt.rs_gc, dut_opt.rs_g, dut_opt.tk_gc, dut_opt.tk_g);
            end
        end
    endtask

    initial begin
        seed = SEED0; errors = 0; cyc = 0; n1_err = 0;
        n_alloc = 0; n_resp = 0; n_hit_data = 0; n_multi = 0; n_freed = 0; n_full_alloc = 0; n_tok = 0; n_ar = 0;
        for (pi = 0; pi < 4; pi = pi + 1) begin
            pool[pi][31:0]  = rnd(0) ^ (rnd(0) << 1);
            pool[pi][LINE_ADDR_W-1:32] = rnd(0);
        end
        drive;
        rst = 1'b1;
        repeat (3) @(posedge clk);
        #1 rst = 1'b0;
        for (cyc = 0; cyc < NCYC; cyc = cyc + 1) begin
            @(negedge clk);
            check;
            // coverage, from the reference MSHR
            if (allocate_valid && r_can)  n_alloc = n_alloc + 1;
            if (allocate_valid && !r_can) n_full_alloc = n_full_alloc + 1;
            if (r_rv === 1'b1)            n_resp = n_resp + 1;
            if (r_tv === 1'b1)            n_tok = n_tok + 1;
            if (r_arv === 1'b1)           n_ar = n_ar + 1;
            if (r_hit === 1'b1 && r_hasd === 1'b1) n_hit_data = n_hit_data + 1;
            if (popcount(dut_ref.lk_match) > 1)     n_multi = n_multi + 1;
            if (|r_freed)                 n_freed = n_freed + 1;
            drive;
            rst = (rnd(0) % 20000) == 0;   // a rare reset pulse, the same for both
        end
        $display("cycles %0d  allocations %0d  allocation while full %0d  responses %0d  AXI read offers %0d  tokens %0d  hit with data %0d  multi-match lookups %0d  entries freed %0d",
                 NCYC, n_alloc, n_full_alloc, n_resp, n_ar, n_tok, n_hit_data, n_multi, n_freed);
        if (n_alloc < 1000 || n_full_alloc < 1000 || n_resp < 500 || n_ar < 1000 || n_tok < 500 || n_hit_data < 100 || n_multi < 100 || n_freed < 500) begin
            $display("COVERAGE TOO LOW");
            errors = errors + 1;
        end
        $display("N-1 control / data grant errors %0d", n1_err);
        errors = errors + n1_err;
        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d mismatches", errors);
        $finish;
    end
endmodule
