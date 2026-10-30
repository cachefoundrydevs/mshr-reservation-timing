// ============================================================================
// l1d_arb_rr.v  -  round-robin arbiter ("who gets the resource this cycle?")
// ============================================================================
// IN SIMPLE WORDS 
//   Several units want to use ONE resource (a bus, a channel, an output register) but
//   only one can use it per cycle. The arbiter picks one of them. "Round robin" means
//   fair turns: after requester k was served, the search for the next winner starts at
//   k+1, so nobody can be starved by a busier neighbour.
//
//   Example, N = 4, everybody keeps asking (request_bits = 1111) and every grant is taken:
//        cycle:         1   2   3   4   5 ...
//        grant_index:   0   1   2   3   0 ...
//   Example, request_bits = 0101 (requesters 0 and 2), last served was 0:
//        the search order is 1,2,3,0 -> requester 2 wins; then the order is 3,0,1,2 -> requester 0 wins.
//
// WHERE IT IS USED (16 copies in the original design)
//   - l1d_mshr: 3 per bank = 12 (AXI read address, MSHR response to Stage 3, refill token to Priority Select)
//   - l1d_axi_master: 2 (AXI read channel, AXI write channel, one request per bank)
//   - l1d_resp_merge: 1 (which bank's response FIFO feeds the output register)
//   - l1d_snoop_ctrl: 1 (which bank's snoop-answer FIFO feeds the output register)
//   It is NOT used for the age order (l1d_age_matrix) nor for the Stage 0 priority (l1d_prio_select).
//
// PORTS (new name, old name, meaning)
//   request_bits                         (was req)                      one bit per requester that wants the resource
//   grant_taken                          (was advance)                  1 = the current grant was used this cycle, so the turn pointer moves on
//   grant_onehot                         (was gnt)                      one-hot grant (zero when nobody asks)
//   grant_index                          (was gnt_idx)                  number of the granted requester
//   any_request                          (was any)                      1 when at least one requester asks
//
// HOW IT WORKS
//   The only memory is `last` = the requester that was served most recently.
//   grant_onehot / grant_index are computed from request_bits and `last` in the SAME cycle (combinational).
//   `last` moves only when grant_taken = 1 and somebody was granted: "a grant that is not taken keeps its turn".
//
// WHAT KIND OF STATE MACHINE IS IT? 
//   A Mealy machine with N states (the state is `last`, binary encoded): the output grant_onehot
//   depends on the state AND on the input request_bits of the same cycle.
//
// LIMITS
//   - The users index wide multiplexers with the binary grant_index (not with the one-hot grant_onehot).
//   - In l1d_mshr + l1d_axi_master two arbiters are in series with no register between them.
//
// VERILOG WORDS USED IN THIS FILE
//   % N          remainder after division: (last + k) % N wraps the number around the ring of N requesters
//   grant_onehot[j] = 1'b1;   sets bit j only
//   integer k, j   loop counters used to build the logic (the loop is unrolled)
// ============================================================================

// TIMING OPT (O-5): same grants in every cycle, built differently.
//   Old: `last` (binary) -> (last + k) % N for every k -> a rotating priority chain (buffers on `last`, adders, 400+ ps with the muxes).
//   New: a registered mask `mask_r` = the requesters ABOVE `last` (thermometer code), kept next to the grant register, so nothing is decoded
//        from a number in the grant cycle:
//          masked = request_bits & mask_r
//          winner = lowest set bit of `masked` if there is one, else lowest set bit of request_bits    (both computed in parallel)
//        This is the same order as before: last+1 ... N-1, then 0 ... last. After reset mask_r = 0, so requester 0 is served first.
//   Ports, grant_taken rule ("a grant that is not taken keeps its turn") and all outputs are unchanged.
// ============================================================================

`default_nettype none

module l1d_arb_rr #(
    parameter N     = 4,
    parameter IDX_W = (N > 1) ? $clog2(N) : 1
) (
    input  wire             clk,                          // clock: all registers change on its rising edge
    input  wire             rst,                          // synchronous reset, active high (control state goes to its idle value)
    input  wire [N-1:0]     request_bits,                 // one bit per requester that wants the resource
    input  wire             grant_taken,                  // 1 = the current grant was used this cycle, so the turn pointer moves on
    output reg  [N-1:0]     grant_onehot,                 // one-hot grant (zero when nobody asks)
    output reg  [IDX_W-1:0] grant_index,                  // number of the granted requester
    output wire             any_request                   // 1 when at least one requester asks
);

    reg  [N-1:0] mask_r;                                  // requesters above the one served last (bit j = 1 when j > last), N bits; 0 after reset
    wire [N-1:0] masked = request_bits & mask_r;          // requests that come after `last` in this round
    wire         use_masked = |masked;

    // lowest set bit of `masked` and of `request_bits`, one-hot and as a number, computed in parallel
    reg  [N-1:0]     gm, gu;                              // one-hot of the lowest set bit, N bits
    reg  [IDX_W-1:0] im, iu;                              // its number, IDX_W bits
    reg              seen_m, seen_u;
    integer          i;
    always @* begin
        gm = {N{1'b0}};  gu = {N{1'b0}};
        im = {IDX_W{1'b0}};  iu = {IDX_W{1'b0}};
        seen_m = 1'b0;   seen_u = 1'b0;
        for (i = 0; i < N; i = i + 1) begin
            if (masked[i] && !seen_m)       begin gm[i] = 1'b1; im = i[IDX_W-1:0]; end
            if (request_bits[i] && !seen_u) begin gu[i] = 1'b1; iu = i[IDX_W-1:0]; end
            seen_m = seen_m | masked[i];
            seen_u = seen_u | request_bits[i];
        end
    end

    always @* begin
        grant_onehot = use_masked ? gm : gu;
        grant_index  = use_masked ? im : iu;
    end

    // any_request = at least one requester asks (grant_onehot is then non-zero)
    assign any_request = |request_bits;

    // ---- the memory: the mask of the requesters above the one served last ----
    // TIMING OPT (P1): the mask after the grant, for both candidate winners in parallel with the grant itself; use_masked picks one.
    // mask_next[j] = 1 when a lower bit of the grant is set (j > granted requester).
    reg  [N-1:0] mm, mu;                                  // mask after the masked winner gm / after the unmasked winner gu, N bits each
    reg          bm, bu;
    integer      m;
    always @* begin
        bm = 1'b0;  bu = 1'b0;
        for (m = 0; m < N; m = m + 1) begin
            mm[m] = bm;  bm = bm | gm[m];
            mu[m] = bu;  bu = bu | gu[m];
        end
    end
    wire [N-1:0] mask_next = use_masked ? mm : mu;
    always @(posedge clk) begin
        if (rst)
            mask_r <= {N{1'b0}};
        else if (grant_taken && any_request)
            mask_r <= mask_next;
    end

endmodule

`default_nettype wire
