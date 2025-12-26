module router_reg #(
    parameter WIDTH = 8
) (
    clock,
    resetn,
    pkt_valid,
    data_in,
    fifo_full,
    rst_int_reg,
    detect_add,
    ld_state,
    laf_state,
    full_state,
    lfd_state,
    parity_done,
    low_pkt_valid,
    err,
    dout
);

  // declaration of the inputs
  input clock;
  input resetn;
  input pkt_valid;
  input [WIDTH-1:0] data_in;
  input fifo_full;
  input rst_int_reg;
  input detect_add;
  input ld_state;
  input laf_state;
  input full_state;
  input lfd_state;

  // declaration of the output
  output reg parity_done;
  output reg low_pkt_valid;
  output reg err;
  output reg [WIDTH-1:0] dout;

  // declaration of the internal regs
  reg [WIDTH-1:0] header_byte;
  reg [WIDTH-1:0] full_state_byte;
  reg [WIDTH-1:0] pkt_parity_byte;
  reg [WIDTH-1:0] int_parity_byte;

  // parity done logic body
  always @(posedge clock) begin
    if (!resetn) begin
      parity_done <= 1'b0;
    end else if ((ld_state && !fifo_full && !pkt_valid) ||(laf_state && low_pkt_valid && !parity_done)) begin
      parity_done <= 1'b1;
    end else if (detect_add) begin
      parity_done <= 1'b0;
    end
  end

  // low pkt valid logic body
  always @(posedge clock) begin
    if (!resetn) begin
      low_pkt_valid <= 1'b0;
    end else if (ld_state && !pkt_valid) begin
      low_pkt_valid <= 1'b1;
    end else if (rst_int_reg) begin
      low_pkt_valid <= 1'b0;
    end
  end

  // data out logic body
  always @(posedge clock) begin
    if (!resetn) begin
      dout <= 8'd0;
      header_byte <= 8'd0;
      full_state_byte <= 8'd0;
    end else begin
      if (detect_add && pkt_valid) begin
        header_byte <= data_in;
      end else if (lfd_state) begin
        dout <= header_byte;
      end else if (ld_state && !fifo_full) begin
        dout <= data_in;
      end else if (ld_state && fifo_full) begin
        full_state_byte <= data_in;
      end else if (laf_state) begin
        dout <= full_state_byte;
      end
    end
  end

  // internal parity checking
  always @(posedge clock) begin
    if (!resetn) begin
      int_parity_byte <= 8'd0;
    end else begin
      if (detect_add) begin
        int_parity_byte <= 8'd0;
      end else if (lfd_state) begin
        int_parity_byte <= int_parity_byte ^ header_byte;  //internal parity calculation 
      end else if (ld_state && !full_state && pkt_valid) begin
        int_parity_byte <= int_parity_byte ^ data_in;
      end
    end
  end

  // pkt parity byte (last byte of the pkt)
  always @(posedge clock) begin
    if (!resetn) begin
      pkt_parity_byte <= 8'd0;
    end else if (detect_add) begin
      pkt_parity_byte <= 8'd0;
    end else if ((ld_state && !fifo_full && !pkt_valid) ||(laf_state && low_pkt_valid && !parity_done)) begin
      pkt_parity_byte <= data_in;  // last byte (parity_byte) will be stored
    end
  end

  // error logic body
  always @(posedge clock) begin
    if (!resetn) begin
      err <= 1'b0;
    end else if (!parity_done) begin  // checks if pkt parity is loaded 
      err <= 1'b0;
    end else if (int_parity_byte !== pkt_parity_byte) begin     // check if pkt parity is matching or not with internal parity
      err <= 1'b1;
    end
  end

endmodule
