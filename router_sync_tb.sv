`timescale 1ns / 1ps

module router_sync_tb ();

  // declaration of the input regs
  reg detect_add;
  reg [1:0] data_in;
  reg write_enb_reg;
  reg clock;
  reg resetn;
  reg read_enb_0;
  reg read_enb_1;
  reg read_enb_2;
  reg empty_0;
  reg empty_1;
  reg empty_2;
  reg full_0;
  reg full_1;
  reg full_2;

  // declaration of the output wires
  wire vld_out_0;
  wire vld_out_1;
  wire vld_out_2;
  wire [2:0] write_enb;
  wire fifo_full;
  wire soft_reset_0;
  wire soft_reset_1;
  wire soft_reset_2;

  // parameter
  parameter Thold = 1, Tsetup = 1, CYCLE = 20;

  // integer declaration
  integer clk_cycle;

  // instantiation of the module

  router_sync dut (
      .detect_add(detect_add),
      .data_in(data_in),
      .write_enb_reg(write_enb_reg),
      .clock(clock),
      .resetn(resetn),
      .read_enb_0(read_enb_0),
      .read_enb_1(read_enb_1),
      .read_enb_2(read_enb_2),
      .empty_0(empty_0),
      .empty_1(empty_1),
      .empty_2(empty_2),
      .full_0(full_0),
      .full_1(full_1),
      .full_2(full_2),
      .vld_out_0(vld_out_0),
      .vld_out_1(vld_out_1),
      .vld_out_2(vld_out_2),
      .write_enb(write_enb),
      .fifo_full(fifo_full),
      .soft_reset_0(soft_reset_0),
      .soft_reset_1(soft_reset_1),
      .soft_reset_2(soft_reset_2)
  );


  //driving clock
  initial begin
    clock = 1'b0;
    forever #(CYCLE / 2) clock = ~clock;
  end

  // clock cycle counting
  initial clk_cycle = 0;

  always @(posedge clock or negedge resetn) begin
    if (!resetn) clk_cycle <= 0;
    else clk_cycle <= clk_cycle + 1;
  end


  // task to initialize the values
  task initialize;
    begin
      detect_add = 1'b0;
      data_in = 2'b00;
      write_enb_reg = 1'b0;
      resetn = 1'b0;
      read_enb_0 = 1'b0;
      read_enb_1 = 1'b0;
      read_enb_2 = 1'b0;
      empty_0 = 1'b0;
      empty_1 = 1'b0;
      empty_2 = 1'b0;
      full_0 = 1'b0;
      full_1 = 1'b0;
      full_2 = 1'b0;
    end
  endtask

  //task to check reset
  task reset_check;
    begin
      @(negedge clock);
      resetn = 1'b0;
      data_in = $random;
      detect_add = $random;
      {read_enb_0, read_enb_1, read_enb_2} = $random;
      {full_0, full_1, full_2} = $random;

      @(posedge clock);
      #(Thold);
      if (soft_reset_0 !== 1'b0 || soft_reset_1 !== 1'b0 || soft_reset_2 !== 1'b0) begin
        $display("The reset is now working");
        $display("Error at time : %t", $time);
      end
      $display("Reset is working PERFECT");

      @(negedge clock);
      resetn = 1'b1;
      #(CYCLE - Thold - Tsetup);
    end
  endtask


  // task to check the fifo select reg
  task fifo_sel(input [1:0] i);
    begin
      @(negedge clock);
      resetn = 1'b1;
      data_in = i;
      detect_add = 1'b1;
      {full_0, full_1, full_2} = $random;

      @(posedge clock);
      #(Thold);
      case (data_in)

        2'b00: begin
          if (fifo_full !== full_0) begin
            $display("fifo_0 full is not working");
            $display("Error at time : %t", $time);
          end
          $display("fifo_0 full is PERFECT");
        end

        2'b01: begin
          if (fifo_full !== full_1) begin
            $display("fifo_1 full is not working");
            $display("Error at time : %t", $time);
          end
          $display("Fifo_1 full is PERFECT");
        end

        2'b10: begin
          if (fifo_full !== full_2) begin
            $display("fifo_2 full is not working");
            $display("Error at time : %t", $time);
          end
          $display("Fifo_2 full is PERFECT");
        end

        default: begin
          if (fifo_full !== 1'b0) begin
            $display("default fifo full is not working");
            $display("Error at time : %t", $time);
          end
          $display("Fifo full default is PERFECT");
        end

      endcase
      @(negedge clock);
      resetn = 1'b0;
      #(CYCLE - Thold - Tsetup);
    end
  endtask

  // task to check write_enb_reg to choose the fifo
  task write_fifo(input [1:0] i);
    begin
      @(negedge clock);
      resetn = 1'b1;
      data_in = i;
      write_enb_reg = 1'b1;

      @(posedge clock);
      #(Thold);
      case (data_in)

        2'b00: begin
          if (write_enb !== 3'b001) begin
            $display("fifo_0 select is not working");
            $display("Error at time : %t", $time);
          end
          $display("Fifo_0 select is PERFECT");
        end

        2'b01: begin
          if (write_enb !== 3'b010) begin
            $display("fifo_1 select is not working");
            $display("Error at time : %t", $time);
          end
          $display("Fifo_1 select is PERFECT");
        end

        2'b10: begin
          if (write_enb !== 3'b100) begin
            $display("fifo_2 select is not working");
            $display("Error at time : %t", $time);
          end
          $display("Fifo_2 select is PERFECT");
        end

        default: begin
          if (write_enb !== 3'b000) begin
            $display("fifo select default is not working");
            $display("Error at time : %t", $time);
          end
          $display("Fifo select default is PERFECT");
        end

      endcase
      @(negedge clock);
      resetn = 1'b0;
      #(CYCLE - Thold - Tsetup);
    end
  endtask

  // task to check soft_reset
  task soft_reset_check(input integer ch);
    integer idle;
    begin
      idle = 0;
      @(negedge clock);
      resetn = 1'b1;
      read_enb_0 = 1'b0;
      read_enb_1 = 1'b0;
      read_enb_2 = 1'b0;

      case (ch)
        0: begin

          @(posedge clock);
          wait (vld_out_0 === 1'b1);
          repeat (30) begin
            @(posedge clock);
            if (vld_out_0 && !read_enb_0) idle = idle + 1;
            else idle = 0;

            if (idle == 30) begin
              if (soft_reset_0 !== 1'b1)
                $display("ERROR: soft_reset_0 not asserted at 30 idle cycles, time=%t", $time);
              else $display("PASS: soft_reset_0 asserted at 30 idle cycles, time=%t", $time);
            end
          end
        end

        1: begin
          @(posedge clock);
          wait (vld_out_1 === 1'b1);
          repeat (30) begin
            @(posedge clock);
            if (vld_out_1 && !read_enb_1) idle = idle + 1;
            else idle = 0;

            if (idle == 30) begin
              if (soft_reset_1 !== 1'b1)
                $display("ERROR: soft_reset_1 not asserted at 30 idle cycles, time=%t", $time);
              else $display("PASS: soft_reset_1 asserted at 30 idle cycles, time=%t", $time);
            end
          end
        end

        2: begin
          @(posedge clock);
          wait (vld_out_2 === 1'b1);
          repeat (30) begin
            @(posedge clock);
            if (vld_out_2 && !read_enb_2) idle = idle + 1;
            else idle = 0;

            if (idle == 30) begin
              if (soft_reset_2 !== 1'b1)
                $display("ERROR: soft_reset_2 not asserted at 30 idle cycles, time=%t", $time);
              else $display("PASS: soft_reset_2 asserted at 30 idle cycles, time=%t", $time);
            end
          end
        end
      endcase
    end
  endtask

  // task to check vld_out_x
  task vld_out_check;
    begin
      {empty_0, empty_1, empty_2} = $random;
      $display("empty_0: %b, empty_1: %b, empty_2: %b", empty_0, empty_1, empty_2);
      #(CYCLE);
      $display("vld_out_0: %b, vld_out_1: %b, vld_out_2: %b", vld_out_0, vld_out_1, vld_out_2);
    end
  endtask

  // task for delay
  task delay;
    #20;
  endtask

  // stimulus 
  initial begin
    initialize;
    delay;
    reset_check;
    delay;

    //fifo sel
    fifo_sel(2'b00);
    delay;
    fifo_sel(2'b01);
    delay;
    fifo_sel(2'b10);
    delay;
    fifo_sel(2'b11);
    delay;

    //write fifo
    write_fifo(2'b00);
    delay;
    write_fifo(2'b01);
    delay;
    write_fifo(2'b10);
    delay;
    write_fifo(2'b11);
    delay;

    //soft reset check

    // FIFO 0
    detect_add    = 1'b0;
    write_enb_reg = 1'b0;
    empty_0 = 1'b0;
    empty_1 = 1'b1;
    empty_2 = 1'b1;
    soft_reset_check(0);
    empty_0 = 1'b1;

    // FIFO 1
    empty_0 = 1'b1;
    empty_1 = 1'b0;
    empty_2 = 1'b1;
    soft_reset_check(1);
    empty_1 = 1'b1;

    // FIFO 2
    empty_0 = 1'b1;
    empty_1 = 1'b1;
    empty_2 = 1'b0;
    soft_reset_check(2);
    empty_2 = 1'b1;

    // vld out check
    vld_out_check;
    delay;

    $finish;
  end

endmodule
