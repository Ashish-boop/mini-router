`timescale 1ps / 1ps

module router_fifo #(
    parameter WIDTH = 9,
    parameter DEPTH = 16,
    parameter ADDR  = 4
) (

    // declaration of the inputs
    input wire             clock,
    input wire             resetn,      // synchronous active-low
    input wire             soft_reset,  // synchronous active-high
    input wire             write_enb,
    input wire             read_enb,
    input wire [WIDTH-1:0] data_in,     // payload byte (MSB for header)
    input wire             ifd_state,   // header detect (1 for header byte)

    // declaration of the outputs
    output reg empty,
    output reg full,
    output [7:0] data_out
);

  // declaration of the fifo memory and internal regs
  reg [WIDTH -1:0] fifo_mem[0:DEPTH-1];
  reg [ADDR-1:0] rd_ptr, wr_ptr;
  reg [ADDR:0] count;


  reg [   7:0] dout;
  reg [   7:0] pkt_count;  //payload lenght + 1 parity bit
  reg          pkt_active;  //pkt it in the fifo (still reading)
  reg          pkt_complete;  //one shot pulse after pke read complete

  reg          hi_z_active;  //tri-state mux for data_out

  // hi_z_active logic
  assign data_out = (hi_z_active) ? 8'bz : dout;

  //read & write wires
  wire read_byte = read_enb && !empty;
  wire write_byte = write_enb && !full;

  // synchronous logic for read and write logic
  always @(negedge clock) begin
    if (!resetn) begin
      wr_ptr <= 4'h0;
      rd_ptr <= 4'h0;
      count <= 5'h0;
      empty <= 1'b1;
      full <= 1'b0;
      dout <= 8'h0;
      pkt_count <= 8'h0;
      pkt_active <= 1'b0;
      pkt_complete <= 1'b0;
      hi_z_active <= 1'b0;
    end else begin
      // pulse clear
      pkt_complete <= 1'b0;
      if (soft_reset) begin
        wr_ptr <= 4'h0;
        rd_ptr <= 4'h0;
        count <= 5'h0;
        empty <= 1'b1;
        full <= 1'b0;
        dout <= 8'h0;
        pkt_count <= 8'h0;
        pkt_active <= 1'b0;
        pkt_complete <= 1'b0;
        hi_z_active <= 1'b1;
      end else begin
        // write operation
        if (write_byte && count < DEPTH) begin
          fifo_mem[wr_ptr] <= {ifd_state, data_in};  // first bit (9) for header detection
          wr_ptr <= wr_ptr + 1'b1;
          count <= count + 1'b1;
        end

        // read operation
        if (read_byte && count > 0) begin
          dout <= fifo_mem[rd_ptr][7:0];
          //pkt_tracking
          if (fifo_mem[rd_ptr][8]) begin
            pkt_count   <= fifo_mem[rd_ptr][7:2] + 8'd1;  // payload lenght + parity bit
            pkt_active  <= 1'b1;
            hi_z_active <= 1'b0;  // starts new packet
          end else if (pkt_active) begin
            // decrement the count signal
            if (count !== 8'd0) begin
              pkt_count <= pkt_count - 8'd1;
              // when parity gets read
              if (pkt_count == 8'd1) begin
                pkt_active   <= 1'b0;
                pkt_complete <= 1'b1;
                hi_z_active  <= 1'b1;  // complete the read operation

              end
            end
          end
          // decrementing count after read operation
          rd_ptr <= rd_ptr + 1'b1;
          count  <= count - 1'b1;
        end

        // null statement for the specific condition when fifo is empty and not actively in the packet
        if (empty && !pkt_active && !soft_reset) begin
          // no action needed
        end

        // status flags (empty and full)
        empty <= (count == 0);
        full  <= (count == DEPTH - 1 && write_byte) ? 1'b1 : (count == DEPTH);
      end
    end
  end

endmodule
