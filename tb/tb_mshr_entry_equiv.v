// tb_mshr_entry_equiv.v  (testbench)
// Lockstep test of ONE MSHR entry: the timing-optimised l1d_mshr_entry against the ORIGINAL entry of
// rtl/ref (renamed l1d_mshr_entry_ref by scripts/run_all.sh).
//
// Both get the same random inputs every cycle. At every falling clock edge after reset all outputs must be equal
// (entry_swap_vc_slot only while busy (P4); line_buffer_data only while line_buffer_has_data = 1, because O-7a loads the buffer in idle cycles and a partly filled buffer holds other bytes; RLAST only on the last beat; install_state, the flags, the request pins ...). response_packet is compared while
// response_request = 1 (that is the only time its data is used; the optimised entry registers it in E_MERGE).
// The stimulus is random, with no protocol: it does not matter if the AXI beats arrive at odd times, because both
// entries see the same thing. All sizes (8..64 bit), all byte offsets (also stores that run over the end of the line),
// fetches and swaps, loads and stores, read errors and shared beats happen.
// Coverage is counted and must reach a minimum: store merges, load answers, swaps, read errors.
//
// Options (iverilog -D / xvlog -d):   NCYC=<n> number of cycles (default 400000)   SEED=<n> random seed (default 1)

`timescale 1ns/1ps
`include "l1d_defines.vh"

module tb_mshr_entry_equiv #(`L1D_PARAMS) ();
    `include "l1d_encodings.vh"
    `include "l1d_fields.vh"

`ifdef NCYC
    localparam NCYC = `NCYC;
`else
    localparam NCYC = 400000;
`endif
`ifdef SEED
    localparam SEED0 = `SEED;
`else
    localparam SEED0 = 1;
`endif

    reg clk = 1'b0;
    reg rst = 1'b1;
    always #5 clk = ~clk;

    reg                        allocate_valid;
    reg  [LINE_ADDR_W-1:0]     allocate_line_addr;
    reg                        allocate_is_swap;
    reg  [LINE_W-1:0]          allocate_swap_line_data;
    reg                        allocate_swap_dirty, allocate_swap_shared;
    reg  [VC_ID_W-1:0]         allocate_swap_vc_slot;
    reg                        allocate_unique_read;
    reg  [SEAT_W-1:0]          allocate_seat;
    reg                        allocate_is_write;
    reg  [MEM_SIZE_BITS-1:0]   allocate_access_size;
    reg  [MASTER_ID_BITS-1:0]  allocate_master_id;
    reg  [IDX_BITS-1:0]        allocate_rob_index;
    reg  [OFFSET_W-1:0]        allocate_byte_offset;
    reg  [WRITE_DATA_WIDTH-1:0] allocate_store_data;
    reg                        axi_read_addr_accepted, axi_read_beat_valid, axi_read_beat_last, axi_read_beat_error, axi_read_beat_shared;
    reg  [AXI_DATA_W-1:0]      axi_read_beat_data;
    reg                        response_taken, refill_token_granted, refill_token_held_by_s1, install_done_by_s2;

    // outputs: o_* = optimised, r_* = reference
    wire                        o_busy, o_arq, o_uniq, o_rq, o_tkq, o_hasd, o_swap, o_freed;
    wire [LINE_ADDR_W-1:0]      o_line;
    wire [RESP_W-1:0]           o_pkt;
    wire [SEAT_W-1:0]           o_seat;
    wire [LINE_W-1:0]           o_data;
    wire [1:0]                  o_ist;
    wire [VC_ID_W-1:0]          o_slot;
    wire                        r_busy, r_arq, r_uniq, r_rq, r_tkq, r_hasd, r_swap, r_freed;
    wire [LINE_ADDR_W-1:0]      r_line;
    wire [RESP_W-1:0]           r_pkt;
    wire [SEAT_W-1:0]           r_seat;
    wire [LINE_W-1:0]           r_data;
    wire [1:0]                  r_ist;
    wire [VC_ID_W-1:0]          r_slot;

`define ENTRY_IN \
        .clk(clk), .rst(rst), \
        .allocate_valid(allocate_valid), .allocate_line_addr(allocate_line_addr), .allocate_is_swap(allocate_is_swap), \
        .allocate_swap_line_data(allocate_swap_line_data), .allocate_swap_dirty(allocate_swap_dirty), \
        .allocate_swap_shared(allocate_swap_shared), .allocate_swap_vc_slot(allocate_swap_vc_slot), \
        .allocate_unique_read(allocate_unique_read), .allocate_seat(allocate_seat), .allocate_is_write(allocate_is_write), \
        .allocate_access_size(allocate_access_size), .allocate_master_id(allocate_master_id), \
        .allocate_rob_index(allocate_rob_index), .allocate_byte_offset(allocate_byte_offset), \
        .allocate_store_data(allocate_store_data), \
        .axi_read_addr_accepted(axi_read_addr_accepted), .axi_read_beat_valid(axi_read_beat_valid), \
        .axi_read_beat_data(axi_read_beat_data), .axi_read_beat_last(axi_read_beat_last), \
        .axi_read_beat_error(axi_read_beat_error), .axi_read_beat_shared(axi_read_beat_shared), \
        .response_taken(response_taken), .refill_token_granted(refill_token_granted), \
        .refill_token_held_by_s1(refill_token_held_by_s1), .install_done_by_s2(install_done_by_s2),

    l1d_mshr_entry dut_opt (`ENTRY_IN
        .entry_busy(o_busy), .entry_line_addr(o_line), .axi_read_addr_request(o_arq), .axi_read_is_unique(o_uniq),
        .response_request(o_rq), .response_packet(o_pkt), .response_seat(o_seat), .refill_token_request(o_tkq),
        .line_buffer_data(o_data), .install_state(o_ist), .line_buffer_has_data(o_hasd), .entry_is_swap(o_swap),
        .entry_swap_vc_slot(o_slot), .entry_freed_pulse(o_freed));
    l1d_mshr_entry_ref dut_ref (`ENTRY_IN
        .entry_busy(r_busy), .entry_line_addr(r_line), .axi_read_addr_request(r_arq), .axi_read_is_unique(r_uniq),
        .response_request(r_rq), .response_packet(r_pkt), .response_seat(r_seat), .refill_token_request(r_tkq),
        .line_buffer_data(r_data), .install_state(r_ist), .line_buffer_has_data(r_hasd), .entry_is_swap(r_swap),
        .entry_swap_vc_slot(r_slot), .entry_freed_pulse(r_freed));

    localparam [2:0] E_MERGE = 3'd3, E_TOKEN = 3'd5;     // state numbers of the entry (see l1d_mshr_entry.v)

    integer seed;
    integer cyc;
    integer errors;
    integer n_merge_st, n_merge_ld, n_swap, n_err, n_resp, n_install, n_sizes_off;
    integer ii;

    function [31:0] rnd;       // random number 0..2**31-1 (advances seed)
        input dummy;
        begin
            rnd = $random(seed);
            rnd = rnd & 32'h7fffffff;
        end
    endfunction

    task drive;
        begin
            allocate_valid          = (rnd(0) % 3) == 0;
            allocate_line_addr      = rnd(0);
            allocate_is_swap        = (rnd(0) % 4) == 0;
            for (ii = 0; ii < LINE_W / 32; ii = ii + 1) allocate_swap_line_data[ii*32 +: 32] = rnd(0) ^ (rnd(0) << 1);
            allocate_swap_dirty     = rnd(0) % 2;
            allocate_swap_shared    = rnd(0) % 2;
            allocate_swap_vc_slot   = rnd(0);
            allocate_unique_read    = rnd(0) % 2;
            allocate_seat           = rnd(0);
            allocate_is_write       = rnd(0) % 2;
            allocate_access_size    = rnd(0);                       // 0..3: 8, 16, 32, 64 bit
            allocate_master_id      = rnd(0);
            allocate_rob_index      = rnd(0);
            // offsets: mostly random, sometimes the edge cases (0, last byte, last word)
            case (rnd(0) % 8)
                0:       allocate_byte_offset = 0;
                1:       allocate_byte_offset = LINE_BYTES - 1;
                2:       allocate_byte_offset = LINE_BYTES - 8;
                default: allocate_byte_offset = rnd(0);
            endcase
            // loads are naturally aligned (l1d_resp_gen header; the O-9 beat select relies on it); stores may start anywhere
            if (!allocate_is_write) allocate_byte_offset = allocate_byte_offset & ~((1 << allocate_access_size) - 1);
            allocate_store_data[31:0]  = rnd(0) ^ (rnd(0) << 1);
            allocate_store_data[63:32] = rnd(0) ^ (rnd(0) << 1);
            axi_read_addr_accepted  = rnd(0) % 2;
            axi_read_beat_valid     = rnd(0) % 2;
            for (ii = 0; ii < AXI_DATA_W / 32; ii = ii + 1) axi_read_beat_data[ii*32 +: 32] = rnd(0) ^ (rnd(0) << 1);
            axi_read_beat_last      = ((rnd(0) % 4) == 0) && (dut_ref.beat == AXI_BEATS - 1);   // legal burst: RLAST only on the last beat (all chunks of the buffer get written)
            axi_read_beat_error     = (rnd(0) % 32) == 0;
            axi_read_beat_shared    = rnd(0) % 2;
            response_taken          = rnd(0) % 2;
            refill_token_granted    = rnd(0) % 2;
            refill_token_held_by_s1 = (rnd(0) % 4) == 0;
            install_done_by_s2      = rnd(0) % 2;
        end
    endtask

    task check;
        begin
            if (o_busy !== r_busy || o_line !== r_line || o_arq !== r_arq || o_uniq !== r_uniq || o_rq !== r_rq ||
                o_seat !== r_seat || o_tkq !== r_tkq || (r_hasd === 1'b1 && o_data !== r_data) || o_ist !== r_ist || o_hasd !== r_hasd ||
                o_swap !== r_swap || (r_busy === 1'b1 && o_slot !== r_slot) || o_freed !== r_freed ||
                (r_rq === 1'b1 && o_pkt !== r_pkt)) begin
                errors = errors + 1;
                if (errors <= 10) begin
                    $display("MISMATCH cycle %0d: state_opt=%0d state_ref=%0d  busy %b/%b req %b/%b freed %b/%b ist %b/%b hasd %b/%b",
                             cyc, dut_opt.state, dut_ref.state, o_busy, r_busy, o_rq, r_rq, o_freed, r_freed, o_ist, r_ist, o_hasd, r_hasd);
                    if (r_hasd === 1'b1 && o_data !== r_data) $display("   line_buffer_data differs: opt=%h\n                             ref=%h", o_data, r_data);
                    if (r_rq === 1'b1 && o_pkt !== r_pkt) $display("   response_packet differs: opt=%h ref=%h", o_pkt, r_pkt);
                    $display("   primary: wr=%b size=%0d off=%0d", dut_ref.p_rd_wr, dut_ref.p_size, dut_ref.p_off);
                end
            end
`ifdef L1D_CHECK_M3
            if ((response_taken ? dut_opt.m3_busy_taken : dut_opt.m3_busy_wait) !==
                    (dut_opt.busy_r ? !dut_opt.entry_freed_pulse : allocate_valid) ||
                dut_opt.rs_n !== (dut_opt.mrg_q || (dut_opt.rs_q && !response_taken)) ||
                dut_opt.tk_n !== ((!dut_opt.busy_r && allocate_valid && allocate_is_swap) ||
                    (dut_opt.rs_q && response_taken && !dut_opt.err_r) ||
                    (dut_opt.inst_q && refill_token_held_by_s1) || (dut_opt.tk_q && !refill_token_granted))) begin
                errors = errors + 1;
                if (errors <= 10) $display("TEST FAILED: M-3 NEXT FUNCTION cycle %0d", cyc);
            end
`endif
`ifdef L1D_CHECK_M16
            if (dut_opt.m16_busy_n !== (dut_opt.busy_r ? !dut_opt.entry_freed_pulse : allocate_valid)) begin
                errors=errors+1;
                $display("TEST FAILED: M-16 BUSY NEXT cycle %0d",cyc);
            end
`endif
`ifdef L1D_CHECK_M17
            if (dut_opt.m17_response_error !== (dut_opt.rs_q && dut_opt.err_r)) begin
                errors=errors+1;
                $display("TEST FAILED: M-17 RESPONSE ERROR cycle %0d",cyc);
            end
`endif
`ifdef L1D_CHECK_M11
            if (dut_opt.state > dut_opt.E_INSTALL ||
                dut_opt.tk_q !== (dut_opt.state == dut_opt.E_TOKEN) ||
                dut_opt.rs_q !== (dut_opt.state == dut_opt.E_RESP) ||
                dut_opt.inst_q !== (dut_opt.state == dut_opt.E_INSTALL) ||
                dut_opt.busy_r !== (dut_opt.state != dut_opt.E_IDLE) ||
                dut_opt.tk_n !== ((!dut_opt.busy_r && allocate_valid && allocate_is_swap) ||
                    (dut_opt.rs_q && response_taken && !dut_opt.err_r) ||
                    (dut_opt.inst_q && refill_token_held_by_s1) || (dut_opt.tk_q && !refill_token_granted))) begin
                errors = errors + 1;
                if (errors <= 10) $display("TEST FAILED: M-11 STATE/NEXT INVARIANT cycle %0d", cyc);
            end
`endif
        end
    endtask

    initial begin
        seed = SEED0; errors = 0; cyc = 0;
        n_merge_st = 0; n_merge_ld = 0; n_swap = 0; n_err = 0; n_resp = 0; n_install = 0; n_sizes_off = 0;
        drive;
        rst = 1'b1;
        repeat (3) @(posedge clk);
        #1 rst = 1'b0;
        for (cyc = 0; cyc < NCYC; cyc = cyc + 1) begin
            @(negedge clk);
            check;
            // coverage, from the reference entry
            if (dut_ref.state == E_MERGE && dut_ref.p_rd_wr == OP_WRITE) begin
                n_merge_st = n_merge_st + 1;
                if (dut_ref.p_off + (1 << dut_ref.p_size) > LINE_BYTES) n_sizes_off = n_sizes_off + 1;
            end
            if (dut_ref.state == E_MERGE && dut_ref.p_rd_wr != OP_WRITE) n_merge_ld = n_merge_ld + 1;
            if (r_rq === 1'b1) n_resp = n_resp + 1;
            if (r_freed === 1'b1 && dut_ref.err_r) n_err = n_err + 1;
            if (r_freed === 1'b1 && !dut_ref.err_r) n_install = n_install + 1;
            if (dut_ref.state == E_TOKEN && dut_ref.swap_r) n_swap = n_swap + 1;
            drive;                       // new inputs after the check, stable for the next rising edge
        end
        $display("cycles %0d  store merges %0d (running over the line end: %0d)  load answers %0d  responses %0d  swaps in TOKEN %0d  installs %0d  read-error frees %0d",
                 NCYC, n_merge_st, n_sizes_off, n_merge_ld, n_resp, n_swap, n_install, n_err);
        if (n_merge_st < 1000 || n_merge_ld < 1000 || n_swap < 1000 || n_err < 20 || n_install < 1000) begin
            $display("COVERAGE TOO LOW");
            errors = errors + 1;
        end
        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d mismatches", errors);
        $finish;
    end
endmodule
