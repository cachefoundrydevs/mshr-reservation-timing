// ============================================================================
// l1d_mshr_entry.v  -  ONE MSHR entry: brings one line into the cache
// ============================================================================
// IN SIMPLE WORDS
//   MSHR = Miss Status Holding Register. When a request misses, somebody has to fetch the line while the pipeline
//   keeps working on other requests. One entry does that job for one line. l1d_mshr places MSHR_ENTRIES (8) of these.
//   An entry brings one line in, either as
//     - a FETCH: the line is read from memory over AXI (one INCR burst of AXI_BEATS beats), or
//     - a SWAP:  the line comes from a victim-cache slot (no memory trip) - a hit in the victim cache is swapped
//                back into the cache THROUGH an MSHR entry.
//
// THE THREE USES OF `line`  (the port is now entry_line_addr)
//   1. the MSHR LOOKUP KEY: l1d_mshr compares every busy entry's line with a missing line ("is it already coming?")
//   2. the AXI READ ADDRESS of the fetch (the line address followed by zero offset bits)
//   3. the address of the REFILL TOKEN: Priority Select grants the token and the pipeline installs this line.
//   The way is never sent to the entry: the pipeline carries it from Stage 1 (s1_way) to Stage 2 (s2_way) and writes
//   the line itself with the entry's line_buffer_data. The entry only learns "token held" or "install done".
//
// THE STATES   (the state machine, named E_*)
//   E_IDLE     free                                                     --allocate_valid--> E_AR (fetch) or E_TOKEN (swap)
//   E_AR       fetch: send the AXI read address                         --axi_read_addr_accepted--> E_DATA
//   E_DATA     fetch: collect the AXI_BEATS read beats into the line buffer buf_r   --last beat--> E_MERGE
//   E_MERGE    fetch: one cycle to merge the PRIMARY store's bytes into the line (the line becomes dirty)  --> E_RESP
//   E_RESP     fetch: answer the primary request (load data or store ack) = "MSHR response (2)";
//              --response_taken--> E_TOKEN   (if a read error occurred: the entry is freed without installing; mem_err is raised at the top)
//   E_TOKEN    ask Priority Select for a refill slot (refill_token_request = 1)    --refill_token_granted--> E_INSTALL
//   E_INSTALL  the pipeline installs the line (S1 chooses the victim, S2 writes the line)
//              S1 may HOLD the token (no victim-cache room)  --refill_token_held_by_s1--> back to E_TOKEN
//              S2 reports the install done                    --install_done_by_s2--> E_IDLE  (entry freed, waiting requests woken)
//
//   The entry stays busy until the line is installed. A request that misses before the install therefore finds
//   the entry ("MSHR hit") and WAITS (seat state WMSHR) instead of fetching the line twice.
//   A STORE that hits an MSHR entry is NOT merged into it: its seat waits for
//   this entry's entry_freed_pulse and is retried, and then hits the installed line. Only the PRIMARY request that
//   caused the miss is merged (state E_MERGE for a store, the load data for a load).
//
// MESI (v2): the install state
//   A fetch is a UNIQUE read (ARUSER[0] = 1) when its primary request needs E / M (store, LR, SC, AMO read, AMO write).
//     fetch : M if the primary store's bytes were merged; else E for a unique read; else S if any R beat carried
//             RUSER[0] = shared, else E
//     swap  : M if the victim-cache slot was dirty, S if it was shared, else E
//   line_buffer_has_data = 1 once the line is in the buffer: a snoop on the line then waits for the install; before that
//   the snoop answers "not present" (the data has not arrived, so this cache does not own the line yet).
//
// WHAT KIND OF STATE MACHINE IS IT?
//   A Moore machine (outputs depend on the state), except ONE Mealy output: entry_freed_pulse also depends on
//   response_taken, refill_token_held_by_s1 and install_done_by_s2 of the same cycle.
//
// PORTS (new name, old name, meaning)
//   allocate_valid                       (was alloc)                    take this entry for a new miss or swap
//   allocate_line_addr                   (was a_line)                   line address of the miss
//   allocate_is_swap                     (was a_swap)                   1 = swap from the victim cache, 0 = fetch from memory
//   allocate_swap_line_data              (was a_swap_data)              line data coming from the victim-cache slot
//   allocate_swap_dirty                  (was a_swap_dirty)             the victim-cache line was dirty
//   allocate_swap_shared                 (was a_swap_shared)            the victim-cache line was shared
//   allocate_swap_vc_slot                (was a_swap_slot)              victim-cache slot the line comes from
//   allocate_unique_read                 (was a_unique)                 the fetch needs the line unique (store class)
//   allocate_seat                        (was a_seat)                   LSU seat of the primary request
//   allocate_is_write                    (was a_rd_wr)                  primary request is a store
//   allocate_access_size                 (was a_size)                   primary request size
//   allocate_master_id                   (was a_mid)                    primary request master id
//   allocate_rob_index                   (was a_idx)                    primary request ROB index
//   allocate_byte_offset                 (was a_off)                    primary request byte offset in the line
//   allocate_store_data                  (was a_wdata)                  primary request store data
//   axi_read_addr_accepted               (was ar_gnt)                   the AXI read address of this entry was accepted
//   axi_read_beat_valid                  (was r_valid)                  an AXI read beat for this entry
//   axi_read_beat_data                   (was r_data)                   data of that beat
//   axi_read_beat_last                   (was r_last)                   that beat is the last of the burst
//   axi_read_beat_error                  (was r_err)                    that beat has an error response
//   axi_read_beat_shared                 (was r_shared)                 RUSER: another cache keeps a copy
//   response_taken                       (was resp_gnt)                 Stage 3 took the entry's response
//   refill_token_granted                 (was tok_gnt)                  Priority Select granted the refill token
//   refill_token_held_by_s1              (was tok_held)                 Stage 1 held the token (no victim-cache room), retry later
//   install_done_by_s2                   (was inst_done)                Stage 2 installed the line
//   entry_busy                           (was busy)                     the entry is in use
//   entry_line_addr                      (was line)                     line address the entry works on
//   axi_read_addr_request                (was ar_req)                   the entry wants to send its AXI read address
//   axi_read_is_unique                   (was uniq_rd)                  its AXI read is a unique read (ARUSER)
//   response_request                     (was resp_req)                 the entry has a response for Stage 3
//   response_packet                      (was resp_pkt)                 that response packet
//   response_seat                        (was resp_seat)                LSU seat the response belongs to
//   refill_token_request                 (was tok_req)                  the entry asks for a refill slot
//   line_buffer_data                     (was data)                     the line buffer (written to the data array at install)
//   install_state                        (was inst_state)               MESI state the line will be installed in
//   line_buffer_has_data                 (was has_data)                 the line is in the buffer
//   entry_is_swap                        (was swap)                     the entry is a swap
//   entry_swap_vc_slot                   (was swap_slot)                victim-cache slot of the swap
//   entry_freed_pulse                    (was freed)                    one-cycle pulse: the entry became free
//
// VERILOG WORDS USED IN THIS FILE
//   case (state) ... endcase     choose what to do for the current state
//   buf_r[beat*AXI_DATA_W +: AXI_DATA_W] <= data;   write beat number `beat` into its place in the line buffer
//   integer b, m                 loop counters used to build the byte-mask logic (unrolled)
// ============================================================================

`define L1D_CHECK_M11
`default_nettype none
`include "l1d_defines.vh"

module l1d_mshr_entry #(`L1D_PARAMS) (
    clk, rst,
    allocate_valid, allocate_line_addr, allocate_is_swap, allocate_swap_line_data, allocate_swap_dirty, allocate_swap_shared, allocate_swap_vc_slot,
    allocate_unique_read, allocate_seat, allocate_is_write, allocate_access_size, allocate_master_id, allocate_rob_index, allocate_byte_offset, allocate_store_data,
    axi_read_addr_accepted, axi_read_beat_valid, axi_read_beat_data, axi_read_beat_last, axi_read_beat_error, axi_read_beat_shared,
    response_taken, refill_token_granted, refill_token_held_by_s1, install_done_by_s2,
    entry_busy, entry_line_addr, axi_read_addr_request, axi_read_is_unique, response_request, response_packet, response_seat, refill_token_request,
    axi_read_addr_request_ctrl, response_request_ctrl, refill_token_request_ctrl,
    line_buffer_data, install_state, line_buffer_has_data, entry_is_swap, entry_swap_vc_slot, entry_freed_pulse
);
    `include "l1d_encodings.vh"
    `include "l1d_fields.vh"

    input  wire                        clk;               // clock: all registers change on its rising edge
    input  wire                        rst;               // synchronous reset, active high (control state goes to its idle value)
    // allocation (from Stage 2)
    input  wire                        allocate_valid;    // take this entry for a new miss or swap
    input  wire [LINE_ADDR_W-1:0]      allocate_line_addr;  // line address of the miss
    input  wire                        allocate_is_swap;  // 1 = swap from the victim cache, 0 = fetch from memory
    input  wire [LINE_W-1:0]           allocate_swap_line_data;  // line data coming from the victim-cache slot
    input  wire                        allocate_swap_dirty;  // the victim-cache line was dirty
    input  wire                        allocate_swap_shared;  // the victim-cache line was shared
    input  wire [VC_ID_W-1:0]          allocate_swap_vc_slot;  // victim-cache slot the line comes from
    input  wire                        allocate_unique_read;  // the fetch needs the line unique (store class)
    input  wire [SEAT_W-1:0]           allocate_seat;     // LSU seat of the primary request
    input  wire                        allocate_is_write; // primary request is a store
    input  wire [MEM_SIZE_BITS-1:0]    allocate_access_size;  // primary request size
    input  wire [MASTER_ID_BITS-1:0]   allocate_master_id;  // primary request master id
    input  wire [IDX_BITS-1:0]         allocate_rob_index;  // primary request ROB index
    input  wire [OFFSET_W-1:0]         allocate_byte_offset;  // primary request byte offset in the line
    input  wire [WRITE_DATA_WIDTH-1:0] allocate_store_data;  // primary request store data
    // AXI read
    input  wire                        axi_read_addr_accepted;  // the AXI read address of this entry was accepted
    input  wire                        axi_read_beat_valid;  // an AXI read beat for this entry
    input  wire [AXI_DATA_W-1:0]       axi_read_beat_data;  // data of that beat
    input  wire                        axi_read_beat_last;  // that beat is the last of the burst
    input  wire                        axi_read_beat_error;  // that beat has an error response
    input  wire                        axi_read_beat_shared;  // RUSER: another cache keeps a copy
    // handshakes from the bank
    input  wire                        response_taken;    // Stage 3 took the entry's response
    input  wire                        refill_token_granted;  // Priority Select granted the refill token
    input  wire                        refill_token_held_by_s1;  // Stage 1 held the token (no victim-cache room), retry later
    input  wire                        install_done_by_s2;  // Stage 2 installed the line
    // status
    output wire                        entry_busy;        // the entry is in use
    output wire [LINE_ADDR_W-1:0]      entry_line_addr;   // line address the entry works on
    output wire                        axi_read_addr_request;  // the entry wants to send its AXI read address
    output wire                        axi_read_is_unique;  // its AXI read is a unique read (ARUSER)
    output wire                        response_request;  // the entry has a response for Stage 3
    output wire [RESP_W-1:0]           response_packet;   // that response packet
    output wire [SEAT_W-1:0]           response_seat;     // LSU seat the response belongs to
    output wire                        refill_token_request;  // the entry asks for a refill slot
    // TIMING OPT (N-1): the same three requests from a third flop copy, for the control arbiters of l1d_mshr
    output wire                        axi_read_addr_request_ctrl;  // = axi_read_addr_request
    output wire                        response_request_ctrl;       // = response_request
    output wire                        refill_token_request_ctrl;   // = refill_token_request
    output wire [LINE_W-1:0]           line_buffer_data;  // the line buffer (written to the data array at install)
    output wire [1:0]                  install_state;     // MESI state the line will be installed in
    output wire                        line_buffer_has_data;  // the line is in the buffer
    output wire                        entry_is_swap;     // the entry is a swap
    output wire [VC_ID_W-1:0]          entry_swap_vc_slot;  // victim-cache slot of the swap
    output wire                        entry_freed_pulse; // one-cycle pulse: the entry became free

    // state numbers of the entry (see the header)
    localparam [2:0] E_IDLE    = 3'd0;
    localparam [2:0] E_AR      = 3'd1;
    localparam [2:0] E_DATA    = 3'd2;
    localparam [2:0] E_MERGE   = 3'd3;
    localparam [2:0] E_RESP    = 3'd4;
    localparam [2:0] E_TOKEN   = 3'd5;
    localparam [2:0] E_INSTALL = 3'd6;

    // ---- the memory of the entry ----
    reg [2:0]                  state;                     // E_* state
    reg [LINE_ADDR_W-1:0]      line_r;                    // line address the entry works on
    reg [LINE_W-1:0]           buf_r;                     // line buffer: the line being collected (fetch) or copied (swap); written to the data array at install
    reg                        dirty_r;                   // the line will be installed dirty (M)
    reg                        shared_r;                  // the line will be installed shared (S): a swap of a shared slot, or an R beat with RUSER = 1
    reg                        unique_r;                  // the fetch is a unique read
    reg                        swap_r;                    // the entry is a swap from the victim cache
    reg [VC_ID_W-1:0]          slot_r;                    // victim-cache slot of the swap
    reg                        err_r;                     // an R beat had an error response
    reg [BEAT_W-1:0]           beat;                      // number of the next read beat to arrive
    // TIMING OPT (P7, P8, P9): one-hot copies of the state and of the beat counter (flops that always equal the decode they replace)
    reg                        busy_r;                    // = (state != E_IDLE)
    reg                        ar_q;                      // = (state == E_AR)      request for the AXI read address (primary copy: state logic)
    reg                        dat_q;                     // = (state == E_DATA)
    reg                        mrg_q;                     // = (state == E_MERGE)
    reg                        rs_q;                      // = (state == E_RESP)    response request (primary copy)
    reg                        tk_q;                      // = (state == E_TOKEN)   refill token request (primary copy)
    reg                        inst_q;                    // = (state == E_INSTALL)
    reg                        ar_arb_q;                  // = ar_q   second copy: drives only the arbiter (axi_read_addr_request)
    reg                        rs_arb_q;                  // = rs_q   second copy: drives only the arbiter (response_request)
    reg                        tk_arb_q;                  // = tk_q   second copy: drives only the arbiter (refill_token_request)
    reg                        ar_c_q, rs_c_q, tk_c_q;    // = ar_q / rs_q / tk_q   third copies (N-1): drive only the control arbiters
    reg [AXI_BEATS-1:0]        beat_oh;                   // one-hot of `beat`: bit j = 1 when the next beat to arrive is beat j, AXI_BEATS = 4 bits
    // the PRIMARY request (the one that caused the miss), copied at allocation: seat, direction, size, master id, ROB index,
    // byte offset in the line, and store data
    reg [SEAT_W-1:0]           p_seat;
    reg                        p_rd_wr;
    reg [MEM_SIZE_BITS-1:0]    p_size;
    reg [MASTER_ID_BITS-1:0]   p_mid;
    reg [IDX_BITS-1:0]         p_idx;
    reg [OFFSET_W-1:0]         p_off;
    reg [WRITE_DATA_WIDTH-1:0] p_wdata;

    // ---------- primary store merge: byte mask and shifted data over the line ----------
    // ---- primary store merge: byte mask (which bytes of the line the store writes) and the store data shifted to its place ----
    // TIMING OPT (O-1): the mask and the shifted data are no longer
    // computed from p_off / p_size in the merge cycle. They are built in two register stages while the line is fetched.
    // The result in E_MERGE is bit-identical to the old adder / shifter logic, with no change in cycles:
    //   t+0  E_IDLE   allocation: p_off, p_size, p_wdata are written
    //   t+1  E_AR     stage A0 reads p_off, p_size  ->  off_hi_r, off_lo_r, szk_r       (registers, valid from t+2)
    //   t+2           stage A1 reads off_hi_r, off_lo_r  ->  off_oh_r                   (register, valid from t+3)     [TIMING OPT P3]
    //   t+3           stage B reads off_oh_r, szk_r, p_wdata  ->  st_mask, st_data      (registers, valid from t+4)
    //   t+4  earliest E_MERGE (E_AR >= 1 cycle, E_DATA >= AXI_BEATS >= 2 cycles), so the registers are always ready.
    // The stages run every cycle (no enable); p_* do not change while the entry is busy.
    // synopsys translate_off
    initial if (AXI_BEATS < 2) $display("ERROR l1d_mshr_entry: the store-merge pipeline needs AXI_BEATS >= 2 (it is %0d)", AXI_BEATS);
    // synopsys translate_on
    localparam WBYTES = WRITE_DATA_WIDTH / 8;           // WBYTES = 8 bytes in the store data
    localparam BEAT_BYTES = AXI_DATA_W / 8;             // BEAT_BYTES = 16 bytes in one AXI beat
    localparam BEAT_OFF_W = $clog2(BEAT_BYTES);         // BEAT_OFF_W = 4 bits: byte inside a beat
    localparam HI_N = LINE_BYTES / BEAT_BYTES;          // HI_N = 4 beats in the line
    reg  [HI_N-1:0]       off_hi_r;                     // stage A0: one-hot of p_off[OFFSET_W-1:BEAT_OFF_W] (which beat), 4 bits
    reg  [BEAT_BYTES-1:0] off_lo_r;                     // stage A0: one-hot of p_off[BEAT_OFF_W-1:0] (which byte of the beat), 16 bits
    reg  [LINE_BYTES-1:0] off_oh_r;                     // stage A1: one-hot of p_off (bit p_off set) = off_hi_r AND off_lo_r, 64 bits
    reg  [WBYTES-1:0]     szk_r;                        // stage A0: szk_r[k] = 1 when byte k is inside the access (k < 2**p_size), 8 bits
    reg  [LINE_BYTES-1:0] st_mask;                      // stage B: which bytes of the line the store writes, 64 bits
    reg  [LINE_W-1:0]     st_data;                      // stage B: the store data shifted to its place in the line, 512 bits
    reg  [LINE_BYTES-1:0] mask_n;                       // stage B input (combinational)
    reg  [LINE_W-1:0]     data_n;                       // stage B input (combinational)
    integer a, k, b;
    always @(posedge clk) begin                         // stages A0 and A1
        for (a = 0; a < HI_N; a = a + 1)
            off_hi_r[a] <= (p_off[OFFSET_W-1:BEAT_OFF_W] == a);
        for (a = 0; a < BEAT_BYTES; a = a + 1)
            off_lo_r[a] <= (p_off[BEAT_OFF_W-1:0] == a);
        for (a = 0; a < LINE_BYTES; a = a + 1)
            off_oh_r[a] <= off_hi_r[a / BEAT_BYTES] & off_lo_r[a % BEAT_BYTES];
        for (k = 0; k < WBYTES; k = k + 1)
            szk_r[k] <= (k < (1 << p_size));
    end
    // byte b of the line is written by store byte k when the offset is b-k and k is inside the access: a small AND-OR, no adder
    always @* begin                                     // stage B input
        for (b = 0; b < LINE_BYTES; b = b + 1) begin
            mask_n[b]        = 1'b0;
            data_n[b*8 +: 8] = 8'h00;
            for (k = 0; k < WBYTES; k = k + 1)
                if (b - k >= 0) begin
                    mask_n[b]        = mask_n[b] | (off_oh_r[b-k] & szk_r[k]);
                    data_n[b*8 +: 8] = data_n[b*8 +: 8] | ({8{off_oh_r[b-k]}} & p_wdata[k*8 +: 8]);
                end
        end
    end
    always @(posedge clk) begin                         // stage B
        st_mask <= mask_n;
        st_data <= data_n;
    end

    // the answer data of the primary request, registered in E_MERGE (TIMING OPT O-2): response_packet reads a register
    reg [WRITE_DATA_WIDTH-1:0] ld_r;

    // TIMING OPT (O-9): the load data is picked out of ONE AXI BEAT, not out of the whole 64-byte line. Accesses are naturally aligned
    // (l1d_resp_gen header), so an access of 1..8 bytes never crosses a beat. The beat that holds the access (number p_off[OFFSET_W-1:BEAT_OFF_W])
    // is copied into ld_beat_r while it arrives in E_DATA; in E_MERGE a 16-byte select (4 bits of p_off) fills ld_r. The old select looked at all
    // 512 bits with 6 select bits (p_off fan-out chain of 4 buffers, -52 ps). For an unaligned access the result would differ from the old
    // (already wrong) one; the tests use aligned accesses only.
    // (BEAT_BYTES and BEAT_OFF_W are declared with the store-merge pipeline above)
    reg [AXI_DATA_W-1:0] ld_beat_r;                    // the beat that holds the primary access, AXI_DATA_W = 128 bits

    // merged = the fetched line with the store's bytes replacing the old ones (used in state E_MERGE)
    reg [LINE_W-1:0] merged;
    integer m;
    always @* begin
        for (m = 0; m < LINE_BYTES; m = m + 1)
            merged[m*8 +: 8] = st_mask[m] ? st_data[m*8 +: 8] : buf_r[m*8 +: 8];
    end

    // ---------- primary load data ----------
    // ---- primary load data: pick the requested bytes out of the fetched line (l1d_resp_gen) ----
    // TIMING OPT (P10): the same function as l1d_resp_gen on the captured beat (shift right by the byte offset, keep access_size bytes, zero the
    // rest, zero-fill beyond the beat) written as an AND-OR with the ONE-HOT byte offset off_lo_r and the one-hot-style size mask szk_r (both
    // registers since P3/O-1), so there is no binary shifter and no fan-out chain of p_off.
    //   load byte k = szk_r[k] ? ld_beat_r byte (offset + k) : 0       (0 when offset + k is beyond the beat)
    reg [WRITE_DATA_WIDTH-1:0] load_data;
    integer lk, lj;
    always @* begin
        for (lk = 0; lk < WBYTES; lk = lk + 1) begin
            load_data[lk*8 +: 8] = 8'h00;
            for (lj = 0; lj < BEAT_BYTES; lj = lj + 1)
                if (lj + lk < BEAT_BYTES)
                    load_data[lk*8 +: 8] = load_data[lk*8 +: 8] | ({8{szk_r[lk] & off_lo_r[lj]}} & ld_beat_r[(lj+lk)*8 +: 8]);
        end
    end

    // ---------- state machine ----------
    // ---- the state machine (clocked) ----
    always @(posedge clk) begin
        if (rst) begin
            state   <= E_IDLE;
            dirty_r  <= 1'b0;
            shared_r <= 1'b0;
            unique_r <= 1'b0;
            swap_r   <= 1'b0;
            err_r    <= 1'b0;
            beat     <= {BEAT_W{1'b0}};
        end else begin
            case (state)
                E_IDLE: begin
                  // TIMING OPT (O-7a): the wide registers that nobody reads while the entry is free load the allocate inputs in EVERY idle
                  // cycle, not only on allocate_valid (that enable came through the free-entry chain of l1d_mshr and fanned out to ~600 flops).
                  // The value of the allocation cycle is the last one loaded before the entry leaves E_IDLE, so p_off, p_wdata and buf_r hold
                  // what the old code held once busy. (buf_r gets the swap data also for a fetch; the beats overwrite it before it is read.)
                  p_off   <= allocate_byte_offset;
                  p_wdata <= allocate_store_data;
                  // (buf_r is loaded in every idle cycle too, in its own always block below: TIMING OPT P7)
                  slot_r  <= allocate_swap_vc_slot;          // TIMING OPT (P4): read only for an installing swap entry, so it loads in every idle cycle too
                  if (allocate_valid) begin
                    line_r  <= allocate_line_addr;
                    swap_r  <= allocate_is_swap;
                    unique_r <= allocate_unique_read && !allocate_is_swap;
                    err_r   <= 1'b0;
                    beat    <= {BEAT_W{1'b0}};
                    p_seat  <= allocate_seat;
                    p_rd_wr <= allocate_is_write;
                    p_size  <= allocate_access_size;
                    p_mid   <= allocate_master_id;
                    p_idx   <= allocate_rob_index;
                    if (allocate_is_swap) begin                         // the line comes from the victim cache: buf_r was loaded above
                        dirty_r  <= allocate_swap_dirty;
                        shared_r <= allocate_swap_shared;
                        state    <= E_TOKEN;
                    end else begin
                        dirty_r  <= 1'b0;
                        shared_r <= 1'b0;
                        state    <= E_AR;
                    end
                  end
                end
                E_AR: if (axi_read_addr_accepted) state <= E_DATA;
                E_DATA: if (axi_read_beat_valid) begin
                    // (the beat goes into buf_r and, for the beat with the primary access, into ld_beat_r in their own always blocks below: P7)
                    beat  <= beat + 1'b1;
                    err_r <= err_r | axi_read_beat_error;
                    shared_r <= shared_r | (axi_read_beat_shared && !unique_r);
                    if (axi_read_beat_last) state <= E_MERGE;
                end
                E_MERGE: begin
                    if (p_rd_wr == OP_WRITE) begin       // store miss: its bytes go into the line (buf_r <= merged in the buf_r always block)
                        dirty_r <= 1'b1;
                    end
                    ld_r  <= (p_rd_wr == OP_WRITE) ? {WRITE_DATA_WIDTH{1'b0}} : load_data;   // buf_r is final here for a load
                    state <= E_RESP;
                end
                E_RESP: if (response_taken) state <= err_r ? E_IDLE : E_TOKEN;
                E_TOKEN: if (refill_token_granted) state <= E_INSTALL;
                E_INSTALL: begin
                    if (refill_token_held_by_s1)       state <= E_TOKEN;
                    else if (install_done_by_s2) state <= E_IDLE;
                end
                default: state <= E_IDLE;
            endcase
        end
    end

    // ---- outputs, mostly read straight from the state ----
    // TIMING OPT (O-7b): entry_busy is a flop of its own (was a decode of the 3 state bits, on the path of the free-entry chain in l1d_mshr).
    // It is 1 exactly when state != E_IDLE: set by the allocation, cleared by the cycle of entry_freed_pulse.
    // (P9: written with busy_r itself instead of a decode of state: free -> allocate_valid, busy -> cleared by the free pulse)
    always @(posedge clk) begin
        if (rst) busy_r <= 1'b0;
        else     busy_r <= busy_r ? !entry_freed_pulse : allocate_valid;
    end
    assign entry_busy      = busy_r;
    assign entry_line_addr      = line_r;
    // TIMING OPT (O-8): the three request outputs come straight from flops (a one-hot copy of the state) and not from a decode of the 3 state
    // bits (INV, OR4, AND5 = about 100 ps before the arbiters in l1d_mshr). Each flop equals (state == E_x) in every cycle:
    //   ar_q = (state == E_AR)    set by a fetch allocation, cleared by axi_read_addr_accepted
    //   rs_q = (state == E_RESP)  set from E_MERGE (which always goes to E_RESP), cleared by response_taken
    //   tk_q = (state == E_TOKEN) set by a swap allocation, by the end of E_RESP without error, and by a held token in E_INSTALL; cleared by refill_token_granted
    // TIMING OPT (P9): the next value of every flag is built from the other flags, never from a decode of `state`:
    //   dat_q  = (state == E_DATA)    set when the AXI read address is accepted, cleared by the last beat
    //   mrg_q  = (state == E_MERGE)   one cycle after the last beat (E_MERGE always goes to E_RESP)
    //   inst_q = (state == E_INSTALL) set when the token is granted, cleared when the install ends (done) or the token is held (P2)
    // and !busy_r stands for (state == E_IDLE).
    wire last_beat = dat_q && axi_read_beat_valid && axi_read_beat_last;
    wire ar_n = (!busy_r && allocate_valid && !allocate_is_swap) || (ar_q && !axi_read_addr_accepted);
    wire rs_n = mrg_q || (rs_q && !response_taken);
    // TIMING OPT (M-11): the current-state flags are exclusive. Compute
    // each state's token outcome in parallel; only its state's leaf matters.
    // TOKEN holds unless granted, RESP enters only on a non-error response,
    // and IDLE/INSTALL use the same allocation/held conditions as before.
    wire m11_other = (!busy_r && allocate_valid && allocate_is_swap) ||
                     (inst_q && refill_token_held_by_s1);
    wire tk_n = tk_q ? !refill_token_granted :
                (rs_q ? (response_taken && !err_r) : m11_other);
    // (* keep *) on both blocks: the second copies (..._arb_q) have the same inputs as the primary ones, and a plain synthesis would merge
    // them again. The primary copies feed the state logic of the entry, the _arb_ copies feed only the three arbiters of l1d_mshr (P8:
    // the worst path of l1d_mshr started at tk_q with 47 ps clock-to-q because of its fan-out of 7).
    (* keep *) always @(posedge clk) begin
        if (rst) begin
            ar_q <= 1'b0;  rs_q <= 1'b0;  tk_q <= 1'b0;  dat_q <= 1'b0;  mrg_q <= 1'b0;  inst_q <= 1'b0;
        end else begin
            ar_q   <= ar_n;
            rs_q   <= rs_n;
            tk_q   <= tk_n;
            dat_q  <= (ar_q && axi_read_addr_accepted) || (dat_q && !last_beat);
            mrg_q  <= last_beat;
            inst_q <= (tk_q && refill_token_granted) || (inst_q && !refill_token_held_by_s1 && !install_done_by_s2);
        end
    end
    (* keep *) always @(posedge clk) begin
        if (rst) begin
            ar_arb_q <= 1'b0;  rs_arb_q <= 1'b0;  tk_arb_q <= 1'b0;
        end else begin
            ar_arb_q <= ar_n;
            rs_arb_q <= rs_n;
            tk_arb_q <= tk_n;
        end
    end
    // TIMING OPT (N-1): a third copy of the three request flops, for the CONTROL arbiters of l1d_mshr (their grants drive only
    // the entries' handshakes; the _arb_ copies feed the DATA arbiters, whose grants drive the output muxes). Same values as ar_q / rs_q /
    // tk_q in every cycle; (* keep *) so that synthesis does not merge the copies.
    (* keep *) always @(posedge clk) begin
        if (rst) begin
            ar_c_q <= 1'b0;  rs_c_q <= 1'b0;  tk_c_q <= 1'b0;
        end else begin
            ar_c_q <= ar_n;
            rs_c_q <= rs_n;
            tk_c_q <= tk_n;
        end
    end
    // one-hot beat counter: the same count as `beat`, as a rotating one-hot (reset and allocation: beat 0)
    always @(posedge clk) begin
        if (rst)                              beat_oh <= {{(AXI_BEATS-1){1'b0}}, 1'b1};
        else if (!busy_r && allocate_valid)   beat_oh <= {{(AXI_BEATS-1){1'b0}}, 1'b1};
        else if (dat_q && axi_read_beat_valid) beat_oh <= (beat_oh << 1) | (beat_oh >> (AXI_BEATS - 1));
    end

    // TIMING OPT (P7): the line buffer has its own always block, selected by flops instead of the state decode, the beat compare and the binary
    // index: idle cycles load the swap data (O-7a), a beat goes to the chunk marked by beat_oh, E_MERGE of a store writes the merged line.
    // The three cases are exclusive (busy_r = 0, dat_q, mrg_q), as the states were.
    integer bj;
    always @(posedge clk) begin
        if (!busy_r) begin
            buf_r <= allocate_swap_line_data;
        end else if (dat_q && axi_read_beat_valid) begin
            for (bj = 0; bj < AXI_BEATS; bj = bj + 1)
                if (beat_oh[bj]) buf_r[bj*AXI_DATA_W +: AXI_DATA_W] <= axi_read_beat_data;
        end else if (mrg_q && (p_rd_wr == OP_WRITE)) begin
            buf_r <= merged;
        end
    end
    // the beat that holds the primary access (O-9) is also copied to ld_beat_r; off_hi_r is the one-hot of p_off's beat number (valid from t+2,
    // the first beat can arrive at t+2)
    always @(posedge clk) begin
        if (dat_q && axi_read_beat_valid && (|(beat_oh & off_hi_r)))
            ld_beat_r <= axi_read_beat_data;
    end

    assign axi_read_addr_request    = ar_arb_q;
    assign axi_read_is_unique   = unique_r;
    assign response_request  = rs_arb_q;
    assign refill_token_request   = tk_arb_q;
    assign axi_read_addr_request_ctrl = ar_c_q;          // N-1
    assign response_request_ctrl      = rs_c_q;          // N-1
    assign refill_token_request_ctrl  = tk_c_q;          // N-1
    assign line_buffer_data      = buf_r;
    // install state: M if dirty, else E if unique, else S if shared, else E
    assign install_state = dirty_r  ? ST_M :
                        unique_r ? ST_E :
                        shared_r ? ST_S : ST_E;
    // the line is in the buffer from E_MERGE on (this decides how a snoop on the line is answered)
    assign line_buffer_has_data  = mrg_q || rs_q || tk_q || inst_q;       // (P9: the flops of E_MERGE, E_RESP, E_TOKEN, E_INSTALL)
    assign entry_is_swap      = swap_r;
    assign entry_swap_vc_slot = slot_r;
    assign response_seat = p_seat;
    // the entry becomes free in the cycle when (a) it answers a read-error request, or (b) the install is done and was not held
    assign entry_freed_pulse     = (rs_q && response_taken && err_r) ||                       // rs_q = (state == E_RESP)
                       (inst_q && install_done_by_s2 && !refill_token_held_by_s1);            // inst_q = (state == E_INSTALL)

    // response packet: | rd_wr | size | master_id | idx | data |
    // (data is valid while response_request = 1, that is from E_RESP on; it was ld_r = load_data of buf_r, zero for a store)
    assign response_packet = {p_rd_wr, p_size, p_mid, p_idx, ld_r};

// ---- simulation-only trace: state changes, every R beat, protocol checks, STUCK reports ----
`ifdef L1D_DEBUG
    // ======================================================================
    // Debug trace (simulation only): state changes (printed the cycle the new
    // state is visible), every R beat, protocol checks, STUCK reports.
    // ======================================================================
    function [8*7-1:0] dbg_ename;
        input [2:0] s;
        begin
            case (s)
                E_IDLE:    dbg_ename = "IDLE";
                E_AR:      dbg_ename = "AR";
                E_DATA:    dbg_ename = "DATA";
                E_MERGE:   dbg_ename = "MERGE";
                E_RESP:    dbg_ename = "RESP";
                E_TOKEN:   dbg_ename = "TOKEN";
                E_INSTALL: dbg_ename = "INSTALL";
                default:   dbg_ename = "?";
            endcase
        end
    endfunction

    reg [2:0] dbg_ps;
    integer   dbg_age;
    initial begin dbg_ps = E_IDLE; dbg_age = 0; end

    always @(posedge clk) begin
        if (rst) begin
            dbg_ps  = E_IDLE;
            dbg_age = 0;
        end else begin
            if (state != dbg_ps) begin
                $display("[%0t] L1D MSHR %m: %0s -> %0s  line=%h %s primary idx=%0d %s err=%b",
                         $time, dbg_ename(dbg_ps), dbg_ename(state), {line_r, {OFFSET_W{1'b0}}},
                         swap_r ? "swap" : "fetch", p_idx, (p_rd_wr ? "ST" : "LD"), err_r);
                dbg_ps  = state;
                dbg_age = 0;
            end else if (state != E_IDLE) begin
                dbg_age = dbg_age + 1;
                if (dbg_age % `L1D_DBG_WD == 0)
                    $display("[%0t] L1D MSHR %m STUCK in %0s for %0d cycles  line=%h beats_received=%0d of %0d  (AR: AXI master/ARREADY; DATA: R beats with this entry's id; RESP: response FIFO place; TOKEN: Stage 0 grant; INSTALL: Stage 2)",
                             $time, dbg_ename(state), dbg_age, {line_r, {OFFSET_W{1'b0}}}, beat, AXI_BEATS);
            end
            // read beats
            if (axi_read_beat_valid) begin
                if (state != E_DATA)
                    $display("[%0t] L1D MSHR %m ERROR R beat for this entry while it is in %0s (wrong RID from memory?)",
                             $time, dbg_ename(state));
                else begin
                    $display("[%0t] L1D MSHR %m R beat %0d of %0d last=%b err=%b data=%h",
                             $time, beat, AXI_BEATS, axi_read_beat_last, axi_read_beat_error, axi_read_beat_data);
                    if (axi_read_beat_last && beat != AXI_BEATS - 1)
                        $display("[%0t] L1D MSHR %m ERROR RLAST on beat %0d, expected on beat %0d (memory sent the wrong burst length)",
                                 $time, beat, AXI_BEATS - 1);
                    if (!axi_read_beat_last && beat == AXI_BEATS - 1)
                        $display("[%0t] L1D MSHR %m ERROR beat %0d has no RLAST: the entry will never leave DATA (memory sent the wrong burst length or RLAST)",
                                 $time, beat);
                end
            end
        end
    end
`endif

endmodule

`default_nettype wire
