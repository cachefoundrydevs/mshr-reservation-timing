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

    // After reset `last` = N-1, so the search starts at requester 0: requester 0 is served first.
    localparam [IDX_W-1:0] LAST_INIT = N - 1;   // so requester 0 is served first
    reg [IDX_W-1:0] last;       // last requester that was served
    // k = how far after `last` we look (1 = the next requester, N = `last` itself); j = the requester number there.
    integer k;
    integer j;

    // ---- combinational part: choose the winner ----
    // Look at last+1, last+2, ..., last+N (wrapping around). The loop runs from k = N down to 1 and a later hit
    // overwrites an earlier one, so the hit with the SMALLEST k - the first requester after `last` - remains.
    always @* begin
        grant_onehot     = {N{1'b0}};
        grant_index = {IDX_W{1'b0}};
        // look at last+1, last+2, ..., last+N (wrapping); keep the first hit
        for (k = N; k >= 1; k = k - 1) begin
            j = (last + k) % N;
            if (request_bits[j]) begin
                grant_onehot     = {N{1'b0}};
                grant_onehot[j]  = 1'b1;
                grant_index = j[IDX_W-1:0];
            end
        end
    end

    // any_request = at least one requester asks (grant_onehot is then non-zero)
    assign any_request = |request_bits;

    // ---- the memory: remember who was served last ----
    always @(posedge clk) begin
        if (rst)
            last <= LAST_INIT;
        else if (grant_taken && any_request)
            last <= grant_index;
    end

endmodule

`default_nettype wire
