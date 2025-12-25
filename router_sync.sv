module router_sync(

    // declaration of the input
    input detect_add,
    input [1:0] data_in,
    input write_enb_reg,
    input clock,
    input resetn,
    input read_enb_0,
    input read_enb_1,
    input read_enb_2,
    input empty_0,
    input empty_1,
    input empty_2,
    input full_0,
    input full_1,
    input full_2,

    // declaration of the outputs
    output vld_out_0,
    output vld_out_1,
    output vld_out_2,
    output reg [2:0] write_enb,
    output reg fifo_full,
    output reg soft_reset_0,
    output reg soft_reset_1,
    output reg soft_reset_2

);

// declaration of the internal regs
reg [1:0] select_fifo;
reg [5:0] count_0, count_1, count_2;

// fifo selection with detect_add
always @(posedge clock)
begin
    if (!resetn) begin
        select_fifo <= 2'b00;
    end
    else if (detect_add) begin
        select_fifo <= data_in;
    end
end

// fifo full logic
always @(*) begin
    case (select_fifo)
        2'b00: fifo_full = full_0;
        2'b01: fifo_full = full_1;
        2'b10: fifo_full = full_2;
        default: fifo_full = 1'b0;
    endcase
end

// Valid_out_signals
assign vld_out_0 = ~empty_0;
assign vld_out_1 = ~empty_1;
assign vld_out_2 = ~empty_2;

// write enable signal generation
always @(*) begin
    if (write_enb_reg) begin
        case (data_in)
            2'b00: write_enb = 3'b001;
            2'b01: write_enb = 3'b010;
            2'b10: write_enb = 3'b100;
            default: write_enb = 3'b000;
        endcase
    end else begin
        write_enb = 3'b000;
    end
end


// logic for soft reset signals
always @(posedge clock) begin
    if(!resetn) begin
        count_0 <= 6'b000000;
        count_1 <= 6'b000000;
        count_2 <= 6'b000000;
        soft_reset_0 <= 1'b0;
        soft_reset_1 <= 1'b0;
        soft_reset_2 <= 1'b0;
    end
    else begin
        // fifo 0 timeout logic
        if(vld_out_0 && !read_enb_0) begin 
            if (count_0 < 6'd29) begin
                count_0 <= count_0 + 1'b1;
                soft_reset_0 <= 1'b0;           // checks till 30 cycle
            end else begin
                soft_reset_0 <= 1'b1;           // when count_0 is more than 30
            end
        end else begin
            count_0 <= 6'd0;
            soft_reset_0 <= 1'b0;
        end
        
        // fifo 1 timeout logic
        if (vld_out_1 && !read_enb_1) begin
            if (count_1 < 6'd29) begin
                count_1 <= count_1 + 1'b1;
                soft_reset_1 <= 1'b0;
            end else begin
                soft_reset_1 <= 1'b1;
            end
        end else begin
            count_1 <= 6'd0;
            soft_reset_1 <= 1'b0;
        end

        // fifo 2 timeout logic
        if (vld_out_2 && !read_enb_2) begin
            if (count_2 < 6'd29) begin
                count_2 <= count_2 + 1'b1;
                soft_reset_2 <= 1'b0;
            end else begin
                soft_reset_2 <= 1'b1;
            end
        end else begin
            count_2 <= 6'd0;
            soft_reset_2 <= 1'b0;
        end

    end
end

endmodule