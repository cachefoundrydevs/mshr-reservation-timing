// Formal wrapper for l1d_mshr_entry: free inputs, except loads are naturally aligned (the l1d_resp_gen rule, O-9).
// Outputs compared as in tb_mshr_entry_equiv: line_buffer_data only while line_buffer_has_data, entry_swap_vc_slot only while busy,
// response_packet only while response_request; everything else every cycle.
`default_nettype none
`include "l1d_defines.vh"
module fv_wrap #(`L1D_PARAMS) (
    input wire clk, input wire rst,
    input wire allocate_valid, input wire [57:0] allocate_line_addr, input wire allocate_is_swap, input wire [511:0] allocate_swap_line_data,
    input wire allocate_swap_dirty, input wire allocate_swap_shared, input wire [2:0] allocate_swap_vc_slot, input wire allocate_unique_read,
    input wire [2:0] allocate_seat, input wire allocate_is_write, input wire [1:0] allocate_access_size, input wire [7:0] allocate_master_id,
    input wire [7:0] allocate_rob_index, input wire [5:0] allocate_byte_offset_raw, input wire [63:0] allocate_store_data,
    input wire axi_read_addr_accepted, input wire axi_read_beat_valid, input wire [127:0] axi_read_beat_data, input wire axi_read_beat_last,
    input wire axi_read_beat_error, input wire axi_read_beat_shared, input wire response_taken, input wire refill_token_granted,
    input wire refill_token_held_by_s1, input wire install_done_by_s2,
    output wire entry_busy, output wire [57:0] entry_line_addr, output wire axi_read_addr_request, output wire axi_read_is_unique,
    output wire response_request, output wire [127:0] response_packet_v, output wire [2:0] response_seat, output wire refill_token_request,
    output wire [511:0] line_buffer_data_v, output wire [1:0] install_state, output wire line_buffer_has_data, output wire entry_is_swap,
    output wire [2:0] entry_swap_vc_slot_v, output wire entry_freed_pulse
);
    `include "l1d_encodings.vh"
    `include "l1d_fields.vh"
    wire [OFFSET_W-1:0] off = allocate_is_write ? allocate_byte_offset_raw[OFFSET_W-1:0]
                                                : (allocate_byte_offset_raw[OFFSET_W-1:0] & ~((6'd1 << allocate_access_size) - 6'd1));
    wire [RESP_W-1:0] pkt; wire [LINE_W-1:0] lbd; wire [VC_ID_W-1:0] slot;
    // protocol: reset only in the first cycle; RLAST only on the 4th beat after the read address was accepted (AXI burst of AXI_BEATS)
    reg started; always @(posedge clk) started <= 1'b1;
    wire rst_e = rst & ~started;
    reg [2:0] bcnt;
    always @(posedge clk)
        if (rst_e || (axi_read_addr_request && axi_read_addr_accepted)) bcnt <= 3'd0;
        else if (axi_read_beat_valid) bcnt <= bcnt + 3'd1;
    wire last_e = axi_read_beat_valid && (bcnt == AXI_BEATS - 1);
    l1d_mshr_entry #(`L1D_PARAMS_PASS) u (
        .clk(clk), .rst(rst_e),
        .allocate_valid(allocate_valid), .allocate_line_addr(allocate_line_addr[LINE_ADDR_W-1:0]), .allocate_is_swap(allocate_is_swap),
        .allocate_swap_line_data(allocate_swap_line_data[LINE_W-1:0]), .allocate_swap_dirty(allocate_swap_dirty), .allocate_swap_shared(allocate_swap_shared),
        .allocate_swap_vc_slot(allocate_swap_vc_slot[VC_ID_W-1:0]), .allocate_unique_read(allocate_unique_read), .allocate_seat(allocate_seat[SEAT_W-1:0]),
        .allocate_is_write(allocate_is_write), .allocate_access_size(allocate_access_size[MEM_SIZE_BITS-1:0]),
        .allocate_master_id(allocate_master_id[MASTER_ID_BITS-1:0]), .allocate_rob_index(allocate_rob_index[IDX_BITS-1:0]),
        .allocate_byte_offset(off), .allocate_store_data(allocate_store_data[WRITE_DATA_WIDTH-1:0]),
        .axi_read_addr_accepted(axi_read_addr_accepted), .axi_read_beat_valid(axi_read_beat_valid), .axi_read_beat_data(axi_read_beat_data[AXI_DATA_W-1:0]),
        .axi_read_beat_last(last_e), .axi_read_beat_error(axi_read_beat_error), .axi_read_beat_shared(axi_read_beat_shared),
        .response_taken(response_taken), .refill_token_granted(refill_token_granted), .refill_token_held_by_s1(refill_token_held_by_s1),
        .install_done_by_s2(install_done_by_s2),
        .entry_busy(entry_busy), .entry_line_addr(entry_line_addr[LINE_ADDR_W-1:0]), .axi_read_addr_request(axi_read_addr_request),
        .axi_read_is_unique(axi_read_is_unique), .response_request(response_request), .response_packet(pkt), .response_seat(response_seat[SEAT_W-1:0]),
        .refill_token_request(refill_token_request), .line_buffer_data(lbd), .install_state(install_state), .line_buffer_has_data(line_buffer_has_data),
        .entry_is_swap(entry_is_swap), .entry_swap_vc_slot(slot), .entry_freed_pulse(entry_freed_pulse));
    assign response_packet_v    = {{(128-RESP_W){1'b0}}, pkt & {RESP_W{response_request}}};
    assign line_buffer_data_v   = lbd & {LINE_W{line_buffer_has_data}};
    assign entry_swap_vc_slot_v = {{(3-VC_ID_W){1'b0}}, slot & {VC_ID_W{entry_busy}}};
endmodule
`default_nettype wire
