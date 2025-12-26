`timescale 1ns / 1ps
module router_reg_tb ();

  // declaration of the dut input regs
  reg clock;
  reg resetn;
  reg [7:0] data_in;
  reg pkt_valid;
  reg fifo_full;
  reg rst_int_reg;
  reg detect_add;
  reg ld_state;
  reg laf_state;
  reg full_state;
  reg lfd_state;

  // declaration of the dut output wires
  wire parity_done;
  wire low_pkt_valid;
  wire err;
  wire [7:0] dout;

  // parameters
  parameter CYCLE = 100, Thold = 5, Tsetup = 5;

  // instantiation of the module
  router_reg dut (
      .clock(clock),
      .resetn(resetn),
      .data_in(data_in),
      .pkt_valid(pkt_valid),
      .fifo_full(fifo_full),
      .rst_int_reg(rst_int_reg),
      .detect_add(detect_add),
      .ld_state(ld_state),
      .lfd_state(lfd_state),
      .full_state(full_state),
      .laf_state(laf_state),
      .parity_done(parity_done),
      .low_pkt_valid(low_pkt_valid),
      .err(err),
      .dout(dout)
  );

  // memory register for data packet
  reg     [7:0] data_pkt                            [0:63];
  reg     [7:0] tb_parity;  // TB reference parity 
  reg     [7:0] sent_byte;


  // integers
  integer       i;
  integer       idx;

  // initializing the data packet
  // Initialize packet
  initial begin
    // Header
    data_pkt[0] = 8'h16;

    // Payload
    data_pkt[1] = 8'hA1;
    data_pkt[2] = 8'hB2;
    data_pkt[3] = 8'hC3;
    data_pkt[4] = 8'hD4;
    data_pkt[5] = 8'hE5;

    // Parity
    data_pkt[6] = 8'hE1;
  end


  // clock initialization
  initial begin
    clock = 1'b0;
    forever begin
      #(CYCLE / 2) clock = ~clock;
    end
  end



  // initializing the values
  initial begin
    resetn = 1'b1;
    pkt_valid = 1'b0;
    data_in = 8'h00;
    fifo_full = 1'b0;
    rst_int_reg = 1'b0;
    detect_add = 1'b0;
    ld_state = 1'b0;
    laf_state = 1'b0;
    lfd_state = 1'b0;
    full_state = 1'b0;
  end

  // task to check resetn
  task reset_check;
    begin
      @(negedge clock);
      resetn = 1'b0;
      data_in = $random;
      detect_add = 1'b0;
      rst_int_reg = 1'b0;
      fifo_full = 1'b0;
      pkt_valid = 1'b1;
      lfd_state = 1'b1;
      laf_state = 1'b0;
      ld_state = 1'b1;
      full_state = 1'b0;

      @(posedge clock);
      #(Thold);
      if (dout !== 8'h00 || err !== 1'b0 || parity_done !== 1'b0 || low_pkt_valid !== 1'b0) begin
        $display("Error : resetn is not working at time: %t", $time);
      end
      $display("Success : resetn is working PERFECT at time: %t", $time);

      @(negedge clock);
      resetn = 1'b1;
      #(CYCLE - Tsetup - Thold);
    end
  endtask

  // task for dout, error flag and parity done flag check
  task drive_packet_error_check;
    input integer payload_length;
    input integer corrupt_idx;  // -1 : no error // else byte index to be currupt 
    input [7:0] corrupt_byte;  // currupt byte value

    begin
      @(negedge clock);
      resetn = 1'b1;
      /* Lets suppose the data packet
       header byte = [{payload_length = 5 byte, address = 2'b10}]
       header byte = 0001001_10 i.e hex = 0x16
       
       payload bytes = 5 bytes
       -payload[0] = 0xA1
       -payload[1] = 0xB2
       -payload[2] = 0xC3
       -payload[3] = 0xD4
       -payload[4] = 0xE5
       
       Parity calculation
       parity_byte = 0xA1 ^ 0xB2 ^ 0xC3 ^ 0xD4 ^ 0xE5 = 0xE1
       
       The data packet 
       0x16     --------- header byte

       0xA1     
       0xB2       
       0xC3     --------- payload bytes
       0xD4
       0xE5     

       0xE1     -------- parity byte    */

      // 1) Header phase
      @(negedge clock);
      detect_add = 1'b1;
      pkt_valid  = 1'b1;
      lfd_state  = 1'b1;
      ld_state   = 1'b0;
      laf_state  = 1'b0;
      fifo_full  = 1'b0;

      // send header
      sent_byte  = data_pkt[0];
      if (corrupt_idx == 0) begin
        sent_byte = sent_byte ^ corrupt_byte;
      end
      data_in   = sent_byte;


      // reference parity
      tb_parity = 8'h00 ^ sent_byte;

      // 2) Payload phase
      @(negedge clock);
      detect_add = 1'b0;
      lfd_state  = 1'b0;
      ld_state   = 1'b1;

      for (idx = 1; idx < payload_length; idx = idx + 1) begin
        sent_byte = data_pkt[idx];
        if (corrupt_idx == idx) sent_byte = sent_byte ^ corrupt_byte;
        data_in   = sent_byte;
        tb_parity = tb_parity ^ sent_byte;
        @(posedge clock);
        #(Thold)
        if (dout !== sent_byte) begin
          $display("Error : dout is now working at time : %t", $time);
        end
        $display("Success : dout is working at time : %t", $time);
        @(negedge clock);
      end

      // 3) Parity phase
      pkt_valid = 1'b0;
      sent_byte = data_pkt[payload_length+1];
      if (corrupt_idx == (payload_length + 1)) sent_byte = sent_byte ^ corrupt_byte;
      data_in = sent_byte;

      @(negedge clock);
      // after packet read error will sample when parity_done == 1'b1;
      wait (parity_done == 1'b1);
      $display("Success : parity_done is working at time : %t", $time);
      @(negedge clock);  // to settle the error

      // parity check : tb_parity vs sent parity
      if (tb_parity !== sent_byte) begin
        // parity missmatched || error ---> 1
        if (err !== 1'b1) begin
          $display("Error: err flag is not working at time : %t", $time);
        end else begin
          $display("Success : err flag is working");
        end
      end else begin
        // parity matched || error ---> 0
        if (err !== 1'b0) begin
          $display("Error: err flag is not working at time : %t", $time);
        end else begin
          $display("Success : err flag is working");
        end
      end

      @(negedge clock);
      ld_state   = 1'b0;
      laf_state  = 1'b0;
      lfd_state  = 1'b0;
      pkt_valid  = 1'b0;
      detect_add = 1'b0;

      // clear error flag using resetn
      @(negedge clock);
      resetn = 1'b0;

      @(negedge clock);
      resetn = 1'b1;
    end
  endtask

  // task for delay
  task delay;
    #(CYCLE);
  endtask

  // task to check low pkt valid check
  task low_pkt_valid_check;
    begin
      @(negedge clock);
      resetn = 1'b1;
      ld_state = 1'b1;
      pkt_valid = 1'b0;

      @(posedge clock);
      #(Thold);
      if (low_pkt_valid !== 1'b1) begin
        $display("Error : low_pkt_valid is not working at time : %t", $time);
      end
      $display("Success : low_pkt_valid is working at time : %t", $time);
    end
  endtask


  // stimulus 
  initial begin

    // reset check
    reset_check;

    // valid packet 1 - no error
    drive_packet_error_check(5, -1, 8'h00);

    // corrupt packet 2 - single byte corrupt - 3rd byte
    drive_packet_error_check(5, 3, 8'h01);

    // corrupt parity byte
    drive_packet_error_check(5, 6, 8'hFF);

    // low_pkt_valid_check 
    low_pkt_valid_check;

    // display and finish the simmulation
    $display("Simmulation complete : %t", $time);
    $finish;
  end
endmodule
