`timescale 1ps / 1ps

module router_fifo_tb ();

  // DUT inputs
  reg clock;
  reg resetn;
  reg write_enb;
  reg read_enb;
  reg [8:0] data_in;
  reg ifd_state;
  reg soft_reset;

  // DUT outputs
  wire empty;
  wire full;
  wire [7:0] data_out;

  // Parameters
  parameter Thold = 5;
  parameter Tsetup = 5;
  parameter CYCLE = 100;

  // Local storage for expected values
  reg [8:0] exp_mem[0:15];
  integer wr_idx, rd_idx;

  // Instantiate DUT
  router_fifo dut (
      .clock(clock),
      .resetn(resetn),
      .write_enb(write_enb),
      .read_enb(read_enb),
      .data_in(data_in),
      .ifd_state(ifd_state),
      .soft_reset(soft_reset),
      .empty(empty),
      .full(full),
      .data_out(data_out)
  );

  // Clock generation
  initial begin
    clock = 0;
    forever #(CYCLE / 2) clock = ~clock;
  end

  // Initialize signals
  initial begin
    resetn     = 0;
    soft_reset = 0;
    write_enb  = 0;
    read_enb   = 0;
    data_in    = 0;
    ifd_state  = 0;
    wr_idx     = 0;
    rd_idx     = 0;
  end

  // TASKS 

  // Reset check
  task reset_check;
    begin
      @(posedge clock);
      resetn = 0;
      @(negedge clock);
      #(Thold);
      if (empty !== 1'b1 || full !== 1'b0) begin
        $display("ERROR: Reset failed at %t", $time);
      end else begin
        $display("SUCCESS: Reset OK at %t", $time);
      end
      resetn = 1;
    end
  endtask

  // Write N values
  task write_values(input integer N);
    integer i;
    begin
      write_enb = 1;
      read_enb  = 0;
      for (i = 0; i < N; i = i + 1) begin
        @(posedge clock);
        data_in = $urandom_range(1, 255);
        exp_mem[wr_idx] = {ifd_state, data_in};
        wr_idx = (wr_idx + 1) % 16;
      end
      @(negedge clock);
      #(Thold);
      $display("INFO: Wrote %0d values, full=%b, empty=%b at %t", N, full, empty, $time);
    end
  endtask

  // Read N values and check
  task read_values(input integer N);
    integer i;
    begin
      write_enb = 0;
      read_enb  = 1;
      for (i = 0; i < N; i = i + 1) begin
        @(negedge clock);
        #(Thold);
        if (data_out !== exp_mem[rd_idx][7:0]) begin
          $display("ERROR: Read mismatch at %t. Expected %h, got %h", $time, exp_mem[rd_idx][7:0],
                   data_out);
        end else begin
          $display("SUCCESS: Read match at %t. Value=%h", $time, data_out);
        end
        rd_idx = (rd_idx + 1) % 16;
      end
    end
  endtask

  // Full flag check
  task full_flag_check;
    begin
      resetn = 1;
      soft_reset = 0;
      write_values(16);
      if (full !== 1'b1) $display("ERROR: Full flag not asserted at %t", $time);
      else $display("SUCCESS: Full flag asserted at %t", $time);
      // Try one more write
      @(posedge clock);
      data_in = $urandom_range(1, 255);
      @(negedge clock);
      #(Thold);
      if (full && wr_idx == rd_idx) $display("INFO: Write blocked when full at %t", $time);
    end
  endtask

  // Empty flag check
  task empty_flag_check;
    begin
      soft_reset = 1;
      @(negedge clock);
      #(Thold);
      if (empty !== 1'b1) $display("ERROR: Empty flag not asserted at %t", $time);
      else $display("SUCCESS: Empty flag asserted at %t", $time);
      soft_reset = 0;
    end
  endtask

  // === STIMULUS ===
  initial begin
    reset_check;
    write_values(8);
    read_values(8);
    full_flag_check;
    empty_flag_check;

    $display("=== TEST COMPLETE at %t ===", $time);
    $finish;
  end

endmodule
