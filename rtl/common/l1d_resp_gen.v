// ============================================================================
// l1d_resp_gen.v  -  load data alignment: pick the requested bytes out of a line
// ============================================================================
// IN SIMPLE WORDS 
//   A load asks for 1, 2, 4 or 8 bytes somewhere inside a 64-byte line. The CPU wants those bytes at the BOTTOM of
//   the 64-bit response word (bit 0 upwards), with the upper bits ZERO. This block does exactly that:
//        shift the line right by (byte_offset x 8) bits, keep access_size bytes, zero the rest.
//   NO sign extension: the LSU does it itself (design decision). Accesses are naturally aligned, so they never
//   cross the block; an unaligned access would silently give wrong data (not checked).
//
//   access_size: 0 = 1 byte (8 bits), 1 = 2 bytes (16), 2 = 4 bytes (32), 3 = 8 bytes (64)    bytes = 2**access_size
//
//   Worked example: source_block = a 64-byte line, byte_offset = 0x2A (42), access_size = 1 (halfword):
//        load_data[15:0] = { line byte 43, line byte 42 },  load_data[63:16] = 0.
//
// WHERE IT IS USED (44 copies)
//   2 per bank in l1d_bank (data from the cache line, data from a victim-cache line), 1 per MSHR entry (8 x 4 = 32),
//   1 per non-cacheable queue (4); for a non-cacheable load source_block is ONE AXI BEAT instead of a line.
//
// WHAT KIND OF LOGIC IS IT?  Combinational (no clock, no state): a barrel shifter and a byte mask.
//
// PORTS (new name, old name, meaning)
//   source_block                         (was block)                    bytes to pick from (a cache line, or one AXI beat)
//   byte_offset                          (was offset)                   first byte of the access inside the block
//   access_size                          (was size)                     0 = 8, 1 = 16, 2 = 32, 3 = 64 bits
//   load_data                            (was data)                     the requested bytes from bit 0, upper bits zero (no sign extension)
//
// VERILOG WORDS USED IN THIS FILE
//   block >> {offset, 3'b000}   shift right by offset x 8 bits ({offset, 3'b000} is offset multiplied by 8)
//   1 << access_size            1, 2, 4 or 8 = the number of bytes
//   (i < nbytes) ? ... : 8'h00  keep byte i only if it is inside the access, otherwise 0
// ============================================================================

`default_nettype none

module l1d_resp_gen #(
    parameter IN_BYTES         = 64,                 // bytes in the input block
    parameter WRITE_DATA_WIDTH = 64,                 // output width
    parameter MEM_SIZE_BITS    = 2,
    parameter OFF_W            = $clog2(IN_BYTES)
) (
    input  wire [IN_BYTES*8-1:0]       source_block,      // bytes to pick from (a cache line, or one AXI beat)
    input  wire [OFF_W-1:0]            byte_offset,       // first byte of the access inside the block
    input  wire [MEM_SIZE_BITS-1:0]    access_size,       // 0 = 8, 1 = 16, 2 = 32, 3 = 64 bits
    output reg  [WRITE_DATA_WIDTH-1:0] load_data          // the requested bytes from bit 0, upper bits zero (no sign extension)
);

    // OUT_BYTES = bytes of the response word (8)
    localparam OUT_BYTES = WRITE_DATA_WIDTH / 8;

    // bring the first requested byte to bit 0 (shift right by byte_offset x 8)
    wire [IN_BYTES*8-1:0] shifted = source_block >> {byte_offset, 3'b000};   // first byte to bit 0
    integer i;
    integer nbytes;

    // keep the first nbytes bytes of the shifted block, force all the others to zero (no sign extension)
    always @* begin
        nbytes = 1 << access_size;
        for (i = 0; i < OUT_BYTES; i = i + 1)
            load_data[i*8 +: 8] = (i < nbytes) ? shifted[i*8 +: 8] : 8'h00;
    end

endmodule

`default_nettype wire
