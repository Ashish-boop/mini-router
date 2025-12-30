module router_top (
    clock,
    resetn,
    read_enb_0,
    read_enb_1,
    read_enb_2,
    data_in,
    pkt_valid,
    data_out_0,
    data_out_1,
    data_out_2,
    valid_out_0,
    valid_out_1,
    valid_out_2,
    error,
    busy
);

  // declaration of the inputs
  input clock;
  input resetn;
  input read_enb_0;
  input read_enb_1;
  input read_enb_2;
  input [7:0] data_in;
  input pkt_valid;

  // declaration of the outputs
  output [7:0] data_out_0;
  output [7:0] data_out_1;
  output [7:0] data_out_2;
  output valid_out_0;
  output valid_out_1;
  output valid_out_2;
  output error;
  output busy;

  // declaration of the wires
  wire parity_done_wire, fifo_full_wire, low_pkt_valid_wire;
  wire soft_reset_0_wire, soft_reset_1_wire, soft_reset_2_wire;
  wire fifo_empty_0_wire, fifo_empty_1_wire, fifo_empty_2_wire;
  wire detect_add_wire;
  wire ld_state_wire, laf_state_wire, lfd_state_wire;
  wire full_state_wire, write_enb_reg_wire, rst_int_reg_wire;
  wire full_0_wire, full_1_wire, full_2_wire;
  wire [2:0] write_enb_wire;
  wire [7:0] dout_wire;

  // instantiation of the fsm module
  router_fsm FSM (
      .clock(clock),
      .resetn(resetn),
      .pkt_valid(pkt_valid),
      .busy(busy),
      .parity_done(parity_done_wire),
      .data_in(data_in[1:0]),
      .soft_reset_0(soft_reset_0_wire),
      .soft_reset_1(soft_reset_1_wire),
      .soft_reset_2(soft_reset_2_wire),
      .fifo_full(fifo_full_wire),
      .low_pkt_valid(low_pkt_valid_wire),
      .fifo_empty_0(fifo_empty_0_wire),
      .fifo_empty_1(fifo_empty_1_wire),
      .fifo_empty_2(fifo_empty_2_wire),
      .detect_add(detect_add_wire),
      .ld_state(ld_state_wire),
      .laf_state(laf_state_wire),
      .full_state(full_state_wire),
      .write_enb_reg(write_enb_reg_wire),
      .rst_int_reg(rst_int_reg_wire),
      .lfd_state(lfd_state_wire)
  );

  // instantiation of the sync module
  router_sync SYNCHRONIZER (
      .detect_add(detect_add_wire),
      .data_in(data_in[1:0]),
      .clock(clock),
      .resetn(resetn),
      .write_enb_reg(write_enb_reg_wire),
      .read_enb_0(read_enb_0),
      .read_enb_1(read_enb_1),
      .read_enb_2(read_enb_2),
      .empty_0(fifo_empty_0_wire),
      .empty_1(fifo_empty_1_wire),
      .empty_2(fifo_empty_2_wire),
      .full_0(full_0_wire),
      .full_1(full_1_wire),
      .full_2(full_2_wire),
      .vld_out_0(valid_out_0),
      .vld_out_1(valid_out_1),
      .vld_out_2(valid_out_2),
      .write_enb(write_enb_wire),
      .fifo_full(fifo_full_wire),
      .soft_reset_0(soft_reset_0_wire),
      .soft_reset_1(soft_reset_1_wire),
      .soft_reset_2(soft_reset_2_wire)
  );

  // instantiation of the reg module
  router_reg REGISTER (
      .clock(clock),
      .resetn(resetn),
      .pkt_valid(pkt_valid),
      .data_in(data_in),
      .fifo_full(fifo_full_wire),
      .rst_int_reg(rst_int_reg_wire),
      .detect_add(detect_add_wire),
      .ld_state(ld_state_wire),
      .laf_state(laf_state_wire),
      .full_state(full_state_wire),
      .lfd_state(lfd_state_wire),
      .parity_done(parity_done_wire),
      .low_pkt_valid(low_pkt_valid_wire),
      .err(error),
      .dout(dout_wire)
  );

  // initiantiation of the fifo modules
  router_fifo FIFO_0 (
      .clock(clock),
      .resetn(resetn),
      .soft_reset(soft_reset_0_wire),
      .write_enb(write_enb_wire[0]),
      .read_enb(read_enb_0),
      .data_in(dout_wire),
      .lfd_state(lfd_state_wire),
      .full(full_0_wire),
      .empty(fifo_empty_0_wire),
      .data_out(data_out_0)
  );

  router_fifo FIFO_1 (
      .clock(clock),
      .resetn(resetn),
      .soft_reset(soft_reset_1_wire),
      .write_enb(write_enb_wire[1]),
      .read_enb(read_enb_1),
      .data_in(dout_wire),
      .lfd_state(lfd_state_wire),
      .full(full_1_wire),
      .empty(fifo_empty_1_wire),
      .data_out(data_out_1)
  );

  router_fifo FIFO_2 (
      .clock(clock),
      .resetn(resetn),
      .soft_reset(soft_reset_2_wire),
      .write_enb(write_enb_wire[2]),
      .read_enb(read_enb_2),
      .data_in(dout_wire),
      .lfd_state(lfd_state_wire),
      .full(full_2_wire),
      .empty(fifo_empty_2_wire),
      .data_out(data_out_2)
  );


endmodule
