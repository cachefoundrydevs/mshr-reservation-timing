// ============================================================================
// l1d_mshr.v  -  the cacheable MSHR of one bank (MSHR_ENTRIES entries + shared logic)
// ============================================================================
// IN SIMPLE WORDS
//   When a request misses in the cache, one MSHR entry takes charge of bringing the line in (from memory, or back from
//   the victim cache) while the pipeline carries on with other requests. This file contains the MSHR_ENTRIES (8) copies
//   of l1d_mshr_entry (generate loop) plus everything they SHARE:
//
//     LOOKUP      "is this line already being brought in?"  A CAM (l1d_cam) compares the line with every busy
//                 entry; l1d_pri_enc gives the entry number (lookup_hit, lookup_entry_id).
//     ALLOCATION  the first free entry takes a new miss (can_allocate, allocate_entry_id).
//     THREE ROUND-ROBIN ARBITERS (l1d_arb_rr), because many entries may want ONE shared resource at the same time:
//                   u_ar_arb  entries with an AXI read address to send  -> the bank's read channel
//                   u_rs_arb  entries with a response (load data / store ack) -> Stage 3 of the pipeline
//                   u_tk_arb  entries asking for a refill slot (token)   -> Priority Select
//     R BEATS     AXI read beats are steered to the entry named by the AXI id (the sub id = entry number).
//     INSTALL DATA Stage 1 and Stage 2 read an entry's install state / slot / line by entry number
//                 (s1_install_*, s2_install_*).
//   The non-cacheable accesses are NOT here; they are in l1d_mshr_nc.
//
// v2 ADDITIONS
//   unique reads (axi_read_req_unique = ARUSER[0]), the RUSER shared bit (axi_read_beat_shared), the install state of an
//   entry (s1_install_state) and lookup_entry_has_data for snoops (the matching entry already holds the line).
//
// A MISS FROM START TO FINISH (cacheable fetch)
//   Stage 2: lookup miss -> allocate an entry (the primary request's seat becomes OWNED)
//   entry:   E_AR (arbiter sends the read address) -> E_DATA (beats arrive) -> E_MERGE -> E_RESP (answers the CPU through
//            Stage 3) -> E_TOKEN (arbiter asks Priority Select) -> E_INSTALL (S1 picks a victim way, S2 writes line + tag)
//            -> E_IDLE and entry_freed_pulses[entry] = 1, which wakes the seats that were waiting for it.
//
// PORTS (new name, old name, meaning)
//   lookup_line_addr                     (was lk_line)                  line address looked up (is it already coming?)
//   lookup_hit                           (was lk_hit)                   an entry already works on that line
//   lookup_entry_id                      (was lk_id)                    that entry's number
//   lookup_entry_has_data                (was lk_has_data)              that entry already holds the line
//   allocate_valid                       (was alloc)                    allocate an entry this cycle
//   allocate_line_addr                   (was a_line)                   line address of the miss
//   allocate_is_swap                     (was a_swap)                   1 = swap from the victim cache
//   allocate_swap_line_data              (was a_swap_data)              line data from the victim-cache slot
//   allocate_swap_dirty                  (was a_swap_dirty)             that line was dirty
//   allocate_swap_shared                 (was a_swap_shared)            that line was shared
//   allocate_swap_vc_slot                (was a_swap_slot)              victim-cache slot it comes from
//   allocate_unique_read                 (was a_unique)                 the fetch needs the line unique
//   allocate_seat                        (was a_seat)                   LSU seat of the primary request
//   allocate_is_write                    (was a_rd_wr)                  primary request is a store
//   allocate_access_size                 (was a_size)                   primary request size
//   allocate_master_id                   (was a_mid)                    primary request master id
//   allocate_rob_index                   (was a_idx)                    primary request ROB index
//   allocate_byte_offset                 (was a_off)                    primary request byte offset
//   allocate_store_data                  (was a_wdata)                  primary request store data
//   can_allocate                         (was can_alloc)                a free entry exists
//   allocate_entry_id                    (was alloc_id)                 number of the free entry that would be used
//   axi_read_req_valid                   (was rd_valid)                 an entry offers its AXI read address
//   axi_read_req_ready                   (was rd_ready)                 the bank's read channel takes it
//   axi_read_req_line_addr               (was rd_line)                  line address to read
//   axi_read_req_sub_id                  (was rd_sub)                   MSHR entry number, sent as the AXI id
//   axi_read_req_unique                  (was rd_unique)                unique read (ARUSER)
//   axi_read_beat_valid                  (was r_valid)                  an AXI read beat for one of the cacheable entries
//   axi_read_beat_sub_id                 (was r_sub)                    entry number from the AXI id
//   axi_read_beat_data                   (was r_data)                   beat data
//   axi_read_beat_last                   (was r_last)                   last beat of the burst
//   axi_read_beat_error                  (was r_err)                    error response
//   axi_read_beat_shared                 (was r_shared)                 RUSER: another cache keeps a copy
//   response_valid                       (was resp_valid)               an entry has a response for Stage 3
//   response_packet                      (was resp_pkt)                 the response packet
//   response_seat                        (was resp_seat)                LSU seat of the response
//   response_taken                       (was resp_ack)                 Stage 3 took the response
//   refill_token_valid                   (was tok_valid)                an entry offers a refill token
//   refill_token_entry_id                (was tok_id)                   entry number of the token
//   refill_token_line_addr               (was tok_line)                 line address of the token
//   refill_token_granted                 (was tok_gnt)                  Priority Select granted the token
//   s1_install_entry_id                  (was q1_id)                    entry being installed (read by Stage 1)
//   s1_install_state                     (was q1_state)                 MESI state to install
//   s1_install_is_swap                   (was q1_swap)                  the install is a swap (the victim goes to the reserved slot)
//   s1_install_vc_slot                   (was q1_slot)                  victim-cache slot of the swap
//   s2_install_entry_id                  (was q2_id)                    entry being installed (read by Stage 2)
//   s2_install_line_data                 (was q2_data)                  line data to write into the data array
//   s1_token_held_valid                  (was held_valid)               Stage 1 held the token
//   s1_token_held_entry_id               (was held_id)                  entry of that token
//   s2_install_done_valid                (was inst_valid)               Stage 2 installed a line
//   s2_install_done_entry_id             (was inst_id)                  entry that was installed
//   any_entry_busy                       (was busy_any)                 at least one entry is in use
//   entry_freed_pulses                   (was freed)                    one bit per entry: it became free
//
// VERILOG WORDS USED IN THIS FILE
//   e_line[ar_i*LINE_ADDR_W +: LINE_ADDR_W]   the line address of entry ar_i, picked out of the wide bus of all entries
//   genvar g / generate for                   builds one l1d_mshr_entry per number g (instance names g_entry[g].u_entry)
//   wire [N*RESP_W-1:0] e_pkt                 the response packets of all entries laid end to end
// ============================================================================

`define L1D_CHECK_M7
`default_nettype none
`include "l1d_defines.vh"

module l1d_mshr #(`L1D_PARAMS) (
    clk, rst,
    lookup_line_addr, lookup_hit, lookup_entry_id, lookup_entry_has_data,
    allocate_valid, allocate_line_addr, allocate_is_swap, allocate_swap_line_data, allocate_swap_dirty, allocate_swap_shared, allocate_swap_vc_slot,
    allocate_unique_read, allocate_seat, allocate_is_write, allocate_access_size, allocate_master_id, allocate_rob_index, allocate_byte_offset, allocate_store_data, can_allocate, allocate_entry_id,
    axi_read_req_valid, axi_read_req_ready, axi_read_req_line_addr, axi_read_req_sub_id, axi_read_req_unique,
    axi_read_beat_valid, axi_read_beat_sub_id, axi_read_beat_data, axi_read_beat_last, axi_read_beat_error, axi_read_beat_shared,
    response_valid, response_packet, response_seat, response_taken,
    refill_token_valid, refill_token_entry_id, refill_token_line_addr, refill_token_granted,
    s1_install_entry_id, s1_install_state, s1_install_is_swap, s1_install_vc_slot,
    s2_install_entry_id, s2_install_line_data,
    s1_token_held_valid, s1_token_held_entry_id, s2_install_done_valid, s2_install_done_entry_id,
    any_entry_busy, entry_freed_pulses
);
    `include "l1d_encodings.vh"
    `include "l1d_fields.vh"

    // N = number of entries
    localparam N = MSHR_ENTRIES;

    input  wire                        clk;               // clock: all registers change on its rising edge
    input  wire                        rst;               // synchronous reset, active high (control state goes to its idle value)
    // lookup (Stage 2)
    input  wire [LINE_ADDR_W-1:0]      lookup_line_addr;  // line address looked up (is it already coming?)
    output wire                        lookup_hit;        // an entry already works on that line
    output wire [MSHR_ID_W-1:0]        lookup_entry_id;   // that entry's number
    output wire                        lookup_entry_has_data;  // that entry already holds the line
    // allocation (Stage 2)
    input  wire                        allocate_valid;    // allocate an entry this cycle
    input  wire [LINE_ADDR_W-1:0]      allocate_line_addr;  // line address of the miss
    input  wire                        allocate_is_swap;  // 1 = swap from the victim cache
    input  wire [LINE_W-1:0]           allocate_swap_line_data;  // line data from the victim-cache slot
    input  wire                        allocate_swap_dirty;  // that line was dirty
    input  wire                        allocate_swap_shared;  // that line was shared
    input  wire [VC_ID_W-1:0]          allocate_swap_vc_slot;  // victim-cache slot it comes from
    input  wire                        allocate_unique_read;  // the fetch needs the line unique
    input  wire [SEAT_W-1:0]           allocate_seat;     // LSU seat of the primary request
    input  wire                        allocate_is_write; // primary request is a store
    input  wire [MEM_SIZE_BITS-1:0]    allocate_access_size;  // primary request size
    input  wire [MASTER_ID_BITS-1:0]   allocate_master_id;  // primary request master id
    input  wire [IDX_BITS-1:0]         allocate_rob_index;  // primary request ROB index
    input  wire [OFFSET_W-1:0]         allocate_byte_offset;  // primary request byte offset
    input  wire [WRITE_DATA_WIDTH-1:0] allocate_store_data;  // primary request store data
    output wire                        can_allocate;      // a free entry exists
    output wire [MSHR_ID_W-1:0]        allocate_entry_id; // number of the free entry that would be used
    // AXI read address (to the bank's read channel)
    output wire                        axi_read_req_valid;  // an entry offers its AXI read address
    input  wire                        axi_read_req_ready;  // the bank's read channel takes it
    output wire [LINE_ADDR_W-1:0]      axi_read_req_line_addr;  // line address to read
    output wire [MSHR_ID_W-1:0]        axi_read_req_sub_id;  // MSHR entry number, sent as the AXI id
    output wire                        axi_read_req_unique;  // unique read (ARUSER)
    // AXI read data (already known to be for this bank's cacheable entries)
    input  wire                        axi_read_beat_valid;  // an AXI read beat for one of the cacheable entries
    input  wire [MSHR_ID_W-1:0]        axi_read_beat_sub_id;  // entry number from the AXI id
    input  wire [AXI_DATA_W-1:0]       axi_read_beat_data;  // beat data
    input  wire                        axi_read_beat_last;  // last beat of the burst
    input  wire                        axi_read_beat_error;  // error response
    input  wire                        axi_read_beat_shared;  // RUSER: another cache keeps a copy
    // MSHR response (2) to Stage 3
    output wire                        response_valid;    // an entry has a response for Stage 3
    output wire [RESP_W-1:0]           response_packet;   // the response packet
    output wire [SEAT_W-1:0]           response_seat;     // LSU seat of the response
    input  wire                        response_taken;    // Stage 3 took the response
    // refill token to Priority Select
    output wire                        refill_token_valid;  // an entry offers a refill token
    output wire [MSHR_ID_W-1:0]        refill_token_entry_id;  // entry number of the token
    output wire [LINE_ADDR_W-1:0]      refill_token_line_addr;  // line address of the token
    input  wire                        refill_token_granted;  // Priority Select granted the token
    // entry data for Stage 1 (install state) and Stage 2 (line)
    input  wire [MSHR_ID_W-1:0]        s1_install_entry_id;  // entry being installed (read by Stage 1)
    output wire [1:0]                  s1_install_state;  // MESI state to install
    output wire                        s1_install_is_swap;  // the install is a swap (the victim goes to the reserved slot)
    output wire [VC_ID_W-1:0]          s1_install_vc_slot;  // victim-cache slot of the swap
    input  wire [MSHR_ID_W-1:0]        s2_install_entry_id;  // entry being installed (read by Stage 2)
    output wire [LINE_W-1:0]           s2_install_line_data;  // line data to write into the data array
    // install results
    input  wire                        s1_token_held_valid;  // Stage 1 held the token
    input  wire [MSHR_ID_W-1:0]        s1_token_held_entry_id;  // entry of that token
    input  wire                        s2_install_done_valid;  // Stage 2 installed a line
    input  wire [MSHR_ID_W-1:0]        s2_install_done_entry_id;  // entry that was installed
    // status
    output wire                        any_entry_busy;    // at least one entry is in use
    output wire [N-1:0]                entry_freed_pulses;  // one bit per entry: it became free

    // ---- signals from the entries, one slot per entry (e_busy[g] belongs to entry g; wide ones are laid end to end) ----
    //   e_busy entry in use   e_ar wants to send an AXI read address   e_resp has a response   e_tok asks for a refill slot
    //   e_swap entry is a swap   e_uniq its read is unique   e_hasd the line is in its buffer   e_ist its install state
    //   e_line its line address   e_pkt/e_seat its response packet and seat   e_data its line buffer   e_slot its swap slot
    wire [N-1:0]               e_busy, e_ar, e_resp, e_tok, e_swap, e_uniq, e_hasd;
    wire [2*N-1:0]             e_ist;
    wire [N*LINE_ADDR_W-1:0]   e_line;
    wire [N*RESP_W-1:0]        e_pkt;
    wire [N*SEAT_W-1:0]        e_seat;
    wire [N*LINE_W-1:0]        e_data;
    wire [N*VC_ID_W-1:0]       e_slot;

    // ---------------- lookup ----------------
    // ---- lookup: CAM over the lines of the busy entries, then the number of the matching entry ----
    wire [N-1:0] lk_match;
    l1d_cam #(.N(N), .KEY_W(LINE_ADDR_W)) u_cam (
        .stored_keys  (e_line),
        .stored_valid (e_busy),
        .search_key   (lookup_line_addr),
        .match_onehot (lk_match)
    );
    l1d_pri_enc #(.N(N), .IDX_W(MSHR_ID_W)) u_lk (
        .request_bits (lk_match), .lowest_set_index (lookup_entry_id), .any_set (lookup_hit)
    );

    // ---------------- allocation ----------------
    // ---- allocation: the lowest-numbered entry that is not busy (can_allocate = there is one) ----
    l1d_pri_enc #(.N(N), .IDX_W(MSHR_ID_W)) u_free (
        .request_bits (~e_busy), .lowest_set_index (allocate_entry_id), .any_set (can_allocate)
    );
    // TIMING OPT (O-4): the same choice as one-hot bits, straight from e_busy. Each entry takes allocate_valid with its own bit and
    // no longer compares allocate_entry_id with its number (encode, then decode again). allocate_entry_id / can_allocate stay as outputs.
    reg [N-1:0] free_g;                                   // lowest free entry, one-hot (zero when every entry is busy), N = 8 bits
    reg         busy_below;                               // every lower entry is busy
    integer     f;
    always @* begin
        busy_below = 1'b1;
        for (f = 0; f < N; f = f + 1) begin
            free_g[f]  = ~e_busy[f] & busy_below;
            busy_below = busy_below & e_busy[f];
        end
    end

    // ---------------- arbiters ----------------
    // ---- arbiters: *_g = one-hot grant over the entries, *_i = number of the granted entry ----
    wire [N-1:0]         ar_g, rs_g, tk_g;
    wire [MSHR_ID_W-1:0] ar_i, rs_i, tk_i;

    // AXI read address: the winner's line is sent; the turn moves on when the bank's read channel accepts it (axi_read_req_ready)
    l1d_arb_rr #(.N(N), .IDX_W(MSHR_ID_W)) u_ar_arb (
        .clk(clk), .rst(rst), .request_bits(e_ar), .grant_taken(axi_read_req_ready), .grant_onehot(ar_g), .grant_index(ar_i), .any_request(axi_read_req_valid)
    );
    // response to Stage 3: the winner's packet is taken when Stage 3 has room (response_taken)
    l1d_arb_rr #(.N(N), .IDX_W(MSHR_ID_W)) u_rs_arb (
        .clk(clk), .rst(rst), .request_bits(e_resp), .grant_taken(response_taken), .grant_onehot(rs_g), .grant_index(rs_i), .any_request(response_valid)
    );
    // refill token: the winner is offered to Priority Select; the turn moves on when it is granted (refill_token_granted)
    l1d_arb_rr #(.N(N), .IDX_W(MSHR_ID_W)) u_tk_arb (
        .clk(clk), .rst(rst), .request_bits(e_tok), .grant_taken(refill_token_granted), .grant_onehot(tk_g), .grant_index(tk_i), .any_request(refill_token_valid)
    );
    // TIMING OPT (N-1): a CONTROL copy of each arbiter. It gets the same requests (from a third flop copy in every entry,
    // *_request_ctrl) and the same grant_taken, so its mask and its grant are the same as the arbiter above in every cycle. Its grant drives
    // only the entries' handshakes (accepted / taken / granted); the grants above drive only the output muxes and outputs. The 58- to 72-bit
    // output load then leaves the path grant -> entry next state. The control arbiters' own outputs (index, any) are not used.
    wire [N-1:0] e_ar_c, e_resp_c, e_tok_c;               // the entries' requests, third flop copy, N = 8 bits each
    wire [N-1:0] ar_gc, rs_gc, tk_gc;                     // the control grants, one-hot, N = 8 bits each
    l1d_arb_rr #(.N(N), .IDX_W(MSHR_ID_W)) u_ar_arb_c (
        .clk(clk), .rst(rst), .request_bits(e_ar_c), .grant_taken(axi_read_req_ready), .grant_onehot(ar_gc), .grant_index(), .any_request()
    );
    l1d_arb_rr #(.N(N), .IDX_W(MSHR_ID_W)) u_rs_arb_c (
        .clk(clk), .rst(rst), .request_bits(e_resp_c), .grant_taken(response_taken), .grant_onehot(rs_gc), .grant_index(), .any_request()
    );
    l1d_arb_rr #(.N(N), .IDX_W(MSHR_ID_W)) u_tk_arb_c (
        .clk(clk), .rst(rst), .request_bits(e_tok_c), .grant_taken(refill_token_granted), .grant_onehot(tk_gc), .grant_index(), .any_request()
    );

    // TIMING OPT (M-7): compute both arbitration-round payload outcomes for
    // AXI, response and token in parallel, and let the round select act last.
    // Each kept mask copy has the original reset/update rule; prefix of the
    // original grant equals the original arbiter next mask in every cycle.
    (* keep *) reg [N-1:0] m7_ar_mask;                // N = 8 bits
    wire [N-1:0] m7_ar_next, m7_ar_masked, m7_ar_gm, m7_ar_gu;
    wire [N-1:0] m7_ar_sm, m7_ar_su;                   // N = 8 bits each
    wire m7_ar_use = |m7_ar_masked;
    genvar m7_ar_j;
    generate
        for (m7_ar_j = 0; m7_ar_j < N; m7_ar_j = m7_ar_j + 1) begin : g_m7_ar
            if (m7_ar_j == 0) begin : g_first
                assign m7_ar_next[m7_ar_j] = 1'b0;
                assign m7_ar_gm[m7_ar_j] = m7_ar_masked[m7_ar_j];
                assign m7_ar_gu[m7_ar_j] = e_ar[m7_ar_j];
            end else begin : g_rest
                assign m7_ar_next[m7_ar_j] = |ar_g[m7_ar_j-1:0];
                assign m7_ar_gm[m7_ar_j] = m7_ar_masked[m7_ar_j] & ~|m7_ar_masked[m7_ar_j-1:0];
                assign m7_ar_gu[m7_ar_j] = e_ar[m7_ar_j] & ~|e_ar[m7_ar_j-1:0];
            end
        end
    endgenerate
    (* keep *) always @(posedge clk) begin
        if (rst) m7_ar_mask <= {N{1'b0}};
        else if (axi_read_req_ready && axi_read_req_valid) m7_ar_mask <= m7_ar_next;
    end
    assign m7_ar_masked = e_ar & m7_ar_mask;
    assign m7_ar_sm = {m7_ar_gm[N-1:1], ~|m7_ar_gm[N-1:1]};
    assign m7_ar_su = {m7_ar_gu[N-1:1], ~|m7_ar_gu[N-1:1]};
    (* keep *) reg [N-1:0] m7_rs_mask;                // N = 8 bits
    wire [N-1:0] m7_rs_next, m7_rs_masked, m7_rs_gm, m7_rs_gu;
    wire [N-1:0] m7_rs_sm, m7_rs_su;                   // N = 8 bits each
    wire m7_rs_use = |m7_rs_masked;
    genvar m7_rs_j;
    generate
        for (m7_rs_j = 0; m7_rs_j < N; m7_rs_j = m7_rs_j + 1) begin : g_m7_rs
            if (m7_rs_j == 0) begin : g_first
                assign m7_rs_next[m7_rs_j] = 1'b0;
                assign m7_rs_gm[m7_rs_j] = m7_rs_masked[m7_rs_j];
                assign m7_rs_gu[m7_rs_j] = e_resp[m7_rs_j];
            end else begin : g_rest
                assign m7_rs_next[m7_rs_j] = |rs_g[m7_rs_j-1:0];
                assign m7_rs_gm[m7_rs_j] = m7_rs_masked[m7_rs_j] & ~|m7_rs_masked[m7_rs_j-1:0];
                assign m7_rs_gu[m7_rs_j] = e_resp[m7_rs_j] & ~|e_resp[m7_rs_j-1:0];
            end
        end
    endgenerate
    (* keep *) always @(posedge clk) begin
        if (rst) m7_rs_mask <= {N{1'b0}};
        else if (response_taken && response_valid) m7_rs_mask <= m7_rs_next;
    end
    assign m7_rs_masked = e_resp & m7_rs_mask;
    assign m7_rs_sm = {m7_rs_gm[N-1:1], ~|m7_rs_gm[N-1:1]};
    assign m7_rs_su = {m7_rs_gu[N-1:1], ~|m7_rs_gu[N-1:1]};
    (* keep *) reg [N-1:0] m7_tk_mask;                // N = 8 bits
    wire [N-1:0] m7_tk_next, m7_tk_masked, m7_tk_gm, m7_tk_gu;
    wire [N-1:0] m7_tk_sm, m7_tk_su;                   // N = 8 bits each
    wire m7_tk_use = |m7_tk_masked;
    genvar m7_tk_j;
    generate
        for (m7_tk_j = 0; m7_tk_j < N; m7_tk_j = m7_tk_j + 1) begin : g_m7_tk
            if (m7_tk_j == 0) begin : g_first
                assign m7_tk_next[m7_tk_j] = 1'b0;
                assign m7_tk_gm[m7_tk_j] = m7_tk_masked[m7_tk_j];
                assign m7_tk_gu[m7_tk_j] = e_tok[m7_tk_j];
            end else begin : g_rest
                assign m7_tk_next[m7_tk_j] = |tk_g[m7_tk_j-1:0];
                assign m7_tk_gm[m7_tk_j] = m7_tk_masked[m7_tk_j] & ~|m7_tk_masked[m7_tk_j-1:0];
                assign m7_tk_gu[m7_tk_j] = e_tok[m7_tk_j] & ~|e_tok[m7_tk_j-1:0];
            end
        end
    endgenerate
    (* keep *) always @(posedge clk) begin
        if (rst) m7_tk_mask <= {N{1'b0}};
        else if (refill_token_granted && refill_token_valid) m7_tk_mask <= m7_tk_next;
    end
    assign m7_tk_masked = e_tok & m7_tk_mask;
    assign m7_tk_sm = {m7_tk_gm[N-1:1], ~|m7_tk_gm[N-1:1]};
    assign m7_tk_su = {m7_tk_gu[N-1:1], ~|m7_tk_gu[N-1:1]};

    // TIMING OPT (O-3): the winners' data are picked out of the entry buses with the
    // arbiters' ONE-HOT grants (AND-OR) and not with the grant NUMBERS (a binary shift amount like ar_i*LINE_ADDR_W fans out to every bit).
    // The old code read entry 0 when nobody is granted (the number is 0 then), so entry 0 is also selected when no other entry is
    // granted; the output pins are therefore identical in every cycle.
    wire [N-1:0] ar_sel = {ar_g[N-1:1], ~|ar_g[N-1:1]};   // one-hot select of the AXI read address winner, N = 8 bits
    wire [N-1:0] rs_sel = {rs_g[N-1:1], ~|rs_g[N-1:1]};   // one-hot select of the response winner, N = 8 bits
    wire [N-1:0] tk_sel = {tk_g[N-1:1], ~|tk_g[N-1:1]};   // one-hot select of the refill token winner, N = 8 bits
    wire [LINE_ADDR_W-1:0] ar_line, tk_line;             // LINE_ADDR_W = 58 bits
    wire ar_unique;
    wire [RESP_W-1:0] rs_pkt;                           // RESP_W = 72 bits
    wire [SEAT_W-1:0] rs_seat;                          // SEAT_W = 3 bits
    reg [LINE_ADDR_W-1:0] m7_am, m7_au, m7_km, m7_ku;   // 58 bits each
    reg m7_um, m7_uu;
    reg [RESP_W-1:0] m7_pm, m7_pu;                      // 72 bits each
    reg [SEAT_W-1:0] m7_tm, m7_tu;                      // 3 bits each
    integer m7k;
    always @* begin
        m7_am = {LINE_ADDR_W{1'b0}}; m7_au = {LINE_ADDR_W{1'b0}};
        m7_km = {LINE_ADDR_W{1'b0}}; m7_ku = {LINE_ADDR_W{1'b0}};
        m7_pm = {RESP_W{1'b0}}; m7_pu = {RESP_W{1'b0}};
        m7_tm = {SEAT_W{1'b0}}; m7_tu = {SEAT_W{1'b0}};
        m7_um = 1'b0; m7_uu = 1'b0;
        for (m7k = 0; m7k < N; m7k = m7k + 1) begin
            m7_am = m7_am | ({LINE_ADDR_W{m7_ar_sm[m7k]}} & e_line[m7k*LINE_ADDR_W +: LINE_ADDR_W]);
            m7_au = m7_au | ({LINE_ADDR_W{m7_ar_su[m7k]}} & e_line[m7k*LINE_ADDR_W +: LINE_ADDR_W]);
            m7_km = m7_km | ({LINE_ADDR_W{m7_tk_sm[m7k]}} & e_line[m7k*LINE_ADDR_W +: LINE_ADDR_W]);
            m7_ku = m7_ku | ({LINE_ADDR_W{m7_tk_su[m7k]}} & e_line[m7k*LINE_ADDR_W +: LINE_ADDR_W]);
            m7_pm = m7_pm | ({RESP_W{m7_rs_sm[m7k]}} & e_pkt[m7k*RESP_W +: RESP_W]);
            m7_pu = m7_pu | ({RESP_W{m7_rs_su[m7k]}} & e_pkt[m7k*RESP_W +: RESP_W]);
            m7_tm = m7_tm | ({SEAT_W{m7_rs_sm[m7k]}} & e_seat[m7k*SEAT_W +: SEAT_W]);
            m7_tu = m7_tu | ({SEAT_W{m7_rs_su[m7k]}} & e_seat[m7k*SEAT_W +: SEAT_W]);
            m7_um = m7_um | (m7_ar_sm[m7k] & e_uniq[m7k]);
            m7_uu = m7_uu | (m7_ar_su[m7k] & e_uniq[m7k]);
        end
    end
    assign ar_line = m7_ar_use ? m7_am : m7_au;
    assign ar_unique = m7_ar_use ? m7_um : m7_uu;
    assign tk_line = m7_tk_use ? m7_km : m7_ku;
    assign rs_pkt = m7_rs_use ? m7_pm : m7_pu;
    assign rs_seat = m7_rs_use ? m7_tm : m7_tu;
    assign axi_read_req_line_addr   = ar_line;
    assign axi_read_req_sub_id    = ar_i;
    assign axi_read_req_unique = ar_unique;
    assign response_packet  = rs_pkt;
    assign response_seat = rs_seat;
    assign refill_token_entry_id    = tk_i;
    assign refill_token_line_addr  = tk_line;

    // TIMING OPT (O-4): has_data of the matching entry without the encoder and the index mux. lk_first = the lowest matching entry,
    // one-hot (the encoder u_lk picks the same one for lookup_entry_id). With no match the old value was e_hasd[0]; the bank reads
    // lookup_entry_has_data only when lookup_hit = 1, so that case is not observable.
    reg [N-1:0] lk_first;                                 // lowest matching entry, one-hot, N = 8 bits
    reg         lk_seen;                                  // a lower entry already matched
    integer     q;
    always @* begin
        lk_seen = 1'b0;
        for (q = 0; q < N; q = q + 1) begin
            lk_first[q] = lk_match[q] & ~lk_seen;
            lk_seen     = lk_seen | lk_match[q];
        end
    end
    assign lookup_entry_has_data = |(lk_first & e_hasd);

    // install data read by entry number: Stage 1 reads the state / swap flag / slot, Stage 2 reads the line to write
    assign s1_install_state  = e_ist[2*s1_install_entry_id +: 2];
    assign s1_install_is_swap   = e_swap[s1_install_entry_id];
    assign s1_install_vc_slot   = e_slot[s1_install_entry_id*VC_ID_W +: VC_ID_W];
    assign s2_install_line_data   = e_data[s2_install_entry_id*LINE_W +: LINE_W];

    assign any_entry_busy  = |e_busy;

    // ---- the entries. Each gets only its own share of the shared strobes: its allocate pulse, its AXI read beats (sub id == g),
    //      and the grants of the three arbiters. ----
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : g_entry
            l1d_mshr_entry #(`L1D_PARAMS_PASS) u_entry (
                .clk                     (clk),
                .rst                     (rst),
                .allocate_valid          (allocate_valid && free_g[g]),
                .allocate_line_addr      (allocate_line_addr),
                .allocate_is_swap        (allocate_is_swap),
                .allocate_swap_line_data (allocate_swap_line_data),
                .allocate_swap_dirty     (allocate_swap_dirty),
                .allocate_swap_shared    (allocate_swap_shared),
                .allocate_swap_vc_slot   (allocate_swap_vc_slot),
                .allocate_unique_read    (allocate_unique_read),
                .allocate_seat           (allocate_seat),
                .allocate_is_write       (allocate_is_write),
                .allocate_access_size    (allocate_access_size),
                .allocate_master_id      (allocate_master_id),
                .allocate_rob_index      (allocate_rob_index),
                .allocate_byte_offset    (allocate_byte_offset),
                .allocate_store_data     (allocate_store_data),
                .axi_read_addr_accepted  (axi_read_req_ready && ar_gc[g]),     // N-1: control grant
                .axi_read_beat_valid     (axi_read_beat_valid && (axi_read_beat_sub_id == g)),
                .axi_read_beat_data      (axi_read_beat_data),
                .axi_read_beat_last      (axi_read_beat_last),
                .axi_read_beat_error     (axi_read_beat_error),
                .axi_read_beat_shared    (axi_read_beat_shared),
                .response_taken          (response_taken && rs_gc[g]),         // N-1: control grant
                .refill_token_granted    (refill_token_granted && tk_gc[g]),   // N-1: control grant
                .refill_token_held_by_s1 (s1_token_held_valid && (s1_token_held_entry_id == g)),
                .install_done_by_s2      (s2_install_done_valid && (s2_install_done_entry_id == g)),
                .entry_busy              (e_busy[g]),
                .entry_line_addr         (e_line[g*LINE_ADDR_W +: LINE_ADDR_W]),
                .axi_read_addr_request   (e_ar[g]),
                .axi_read_is_unique      (e_uniq[g]),
                .response_request        (e_resp[g]),
                .response_packet         (e_pkt[g*RESP_W +: RESP_W]),
                .response_seat           (e_seat[g*SEAT_W +: SEAT_W]),
                .refill_token_request    (e_tok[g]),
                .axi_read_addr_request_ctrl (e_ar_c[g]),        // N-1
                .response_request_ctrl      (e_resp_c[g]),      // N-1
                .refill_token_request_ctrl  (e_tok_c[g]),       // N-1
                .line_buffer_data        (e_data[g*LINE_W +: LINE_W]),
                .install_state           (e_ist[2*g +: 2]),
                .line_buffer_has_data    (e_hasd[g]),
                .entry_is_swap           (e_swap[g]),
                .entry_swap_vc_slot      (e_slot[g*VC_ID_W +: VC_ID_W]),
                .entry_freed_pulse       (entry_freed_pulses[g])
            );
        end
    endgenerate

// ---- simulation-only checks (the entries print their own states): allocation while full, double fetch of a line, R beat for a free entry ----
`ifdef L1D_DEBUG
    // Debug trace (simulation only): the entries print their own states; here
    // only the shared checks.
    always @(posedge clk) begin
        if (!rst) begin
            if (allocate_valid && !can_allocate)
                $display("[%0t] L1D MSHR %m ERROR allocation while every entry is busy", $time);
            if (allocate_valid && lookup_hit && !allocate_is_swap)
                $display("[%0t] L1D MSHR %m ERROR fetch allocated for line %h, which entry %0d already has",
                         $time, {allocate_line_addr, {OFFSET_W{1'b0}}}, lookup_entry_id);
            if (axi_read_beat_valid && !e_busy[axi_read_beat_sub_id])
                $display("[%0t] L1D MSHR %m ERROR R beat for entry %0d, which is free (wrong RID from memory?)",
                         $time, axi_read_beat_sub_id);
        end
    end
`endif

endmodule

`default_nettype wire
