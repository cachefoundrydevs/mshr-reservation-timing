// tb_arb_rr_equiv.v  (testbench)
// Lockstep test of the round-robin arbiter: the timing-optimised l1d_arb_rr (registered mask) against the ORIGINAL l1d_arb_rr of
// rtl/ref (renamed l1d_arb_rr_ref by scripts/run_all.sh), for N = 2, 3, 4, 5, 8 requesters.
// Same random request_bits and grant_taken for both; grant_onehot, grant_index and any_request must be equal at every falling edge.
// The request density changes over time (sparse, medium, dense, all ones) and a reset pulse comes now and then.
// Options (iverilog -D / xvlog -d):   NCYC=<n> cycles (default 200000)   SEED=<n> (default 1)

`timescale 1ns/1ps

module tb_arb_rr_equiv;
`ifdef NCYC
    localparam NCYC = `NCYC;
`else
    localparam NCYC = 200000;
`endif
`ifdef SEED
    localparam SEED0 = `SEED;
`else
    localparam SEED0 = 1;
`endif
    reg clk = 1'b0;
    reg rst = 1'b1;
    always #5 clk = ~clk;
    reg [7:0] req;           // each instance uses the low N bits
    reg       taken;
    integer   seed, cyc, errors, density, r;

    // o* = optimised, r* = reference; g*/h* = grant_index (opt/ref); a*/b* = any_request (opt/ref)
    wire [1:0] o2, r2;  wire [0:0] g2, h2;  wire a2, b2;
    wire [2:0] o3, r3;  wire [1:0] g3, h3;  wire a3, b3;
    wire [3:0] o4, r4;  wire [1:0] g4, h4;  wire a4, b4;
    wire [4:0] o5, r5;  wire [2:0] g5, h5;  wire a5, b5;
    wire [7:0] o8, r8;  wire [2:0] g8, h8;  wire a8, b8;

    l1d_arb_rr     #(.N(2), .IDX_W(1)) u_o2 (.clk(clk), .rst(rst), .request_bits(req[1:0]), .grant_taken(taken), .grant_onehot(o2), .grant_index(g2), .any_request(a2));
    l1d_arb_rr_ref #(.N(2), .IDX_W(1)) u_r2 (.clk(clk), .rst(rst), .request_bits(req[1:0]), .grant_taken(taken), .grant_onehot(r2), .grant_index(h2), .any_request(b2));
    l1d_arb_rr     #(.N(3), .IDX_W(2)) u_o3 (.clk(clk), .rst(rst), .request_bits(req[2:0]), .grant_taken(taken), .grant_onehot(o3), .grant_index(g3), .any_request(a3));
    l1d_arb_rr_ref #(.N(3), .IDX_W(2)) u_r3 (.clk(clk), .rst(rst), .request_bits(req[2:0]), .grant_taken(taken), .grant_onehot(r3), .grant_index(h3), .any_request(b3));
    l1d_arb_rr     #(.N(4), .IDX_W(2)) u_o4 (.clk(clk), .rst(rst), .request_bits(req[3:0]), .grant_taken(taken), .grant_onehot(o4), .grant_index(g4), .any_request(a4));
    l1d_arb_rr_ref #(.N(4), .IDX_W(2)) u_r4 (.clk(clk), .rst(rst), .request_bits(req[3:0]), .grant_taken(taken), .grant_onehot(r4), .grant_index(h4), .any_request(b4));
    l1d_arb_rr     #(.N(5), .IDX_W(3)) u_o5 (.clk(clk), .rst(rst), .request_bits(req[4:0]), .grant_taken(taken), .grant_onehot(o5), .grant_index(g5), .any_request(a5));
    l1d_arb_rr_ref #(.N(5), .IDX_W(3)) u_r5 (.clk(clk), .rst(rst), .request_bits(req[4:0]), .grant_taken(taken), .grant_onehot(r5), .grant_index(h5), .any_request(b5));
    l1d_arb_rr     #(.N(8), .IDX_W(3)) u_o8 (.clk(clk), .rst(rst), .request_bits(req[7:0]), .grant_taken(taken), .grant_onehot(o8), .grant_index(g8), .any_request(a8));
    l1d_arb_rr_ref #(.N(8), .IDX_W(3)) u_r8 (.clk(clk), .rst(rst), .request_bits(req[7:0]), .grant_taken(taken), .grant_onehot(r8), .grant_index(h8), .any_request(b8));

    integer n_g2, n_g3, n_g4, n_g5, n_g8;
    initial begin
        seed = SEED0; errors = 0; n_g2 = 0; n_g3 = 0; n_g4 = 0; n_g5 = 0; n_g8 = 0;
        req = 0; taken = 0; rst = 1'b1;
        repeat (3) @(posedge clk);
        #1 rst = 1'b0;
        for (cyc = 0; cyc < NCYC; cyc = cyc + 1) begin
            @(negedge clk);
            if (o2 !== r2 || g2 !== h2 || a2 !== b2 || o3 !== r3 || g3 !== h3 || a3 !== b3 || o4 !== r4 || g4 !== h4 || a4 !== b4 ||
                o5 !== r5 || g5 !== h5 || a5 !== b5 || o8 !== r8 || g8 !== h8 || a8 !== b8) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("MISMATCH cycle %0d req=%b taken=%b: one-hot opt/ref  N=2 %b/%b  N=3 %b/%b  N=4 %b/%b  N=5 %b/%b  N=8 %b/%b",
                             cyc, req, taken, o2, r2, o3, r3, o4, r4, o5, r5, o8, r8);
            end
            if (|o2) n_g2 = n_g2 + 1;
            if (|o3) n_g3 = n_g3 + 1;
            if (|o4) n_g4 = n_g4 + 1;
            if (|o5) n_g5 = n_g5 + 1;
            if (|o8) n_g8 = n_g8 + 1;
            // next inputs
            density = (cyc / 5000) % 4;
            r = $random(seed);
            req = r;
            case (density)
                0: begin r = $random(seed); req = req & r; r = $random(seed); req = req & r; end   // sparse
                1: begin r = $random(seed); req = req & r; end                                      // medium
                2: begin r = $random(seed); req = req | r; end                                      // dense
                3: req = 8'hff;                                                                      // everybody asks
            endcase
            r = $random(seed);
            taken = (r & 3) != 0;
            r = $random(seed);
            rst = ((r & 32'h7fffffff) % 20000) == 0;
        end
        $display("cycles %0d; cycles with a grant: N=2 %0d  N=3 %0d  N=4 %0d  N=5 %0d  N=8 %0d", NCYC, n_g2, n_g3, n_g4, n_g5, n_g8);
        if (n_g2 < 1000 || n_g3 < 1000 || n_g4 < 1000 || n_g5 < 1000 || n_g8 < 1000) begin
            $display("COVERAGE TOO LOW");
            errors = errors + 1;
        end
        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d mismatches", errors);
        $finish;
    end
endmodule
