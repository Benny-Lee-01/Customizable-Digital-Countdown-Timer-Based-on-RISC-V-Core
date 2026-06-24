module seg7_controller (
    input clk,
    input rst_n,
    input [15:0] data_in,
    input blink_en,
    output reg [3:0] an,
    output reg [6:0] seg
);
    reg [16:0] scan_cnt;
    reg [24:0] blink_cnt;
    wire scan_tick = (scan_cnt == 100_000 - 1);
    wire blink_state = blink_cnt[24];

    always @(posedge clk) begin
        scan_cnt <= scan_tick ? 0 : scan_cnt + 1;
        blink_cnt <= blink_cnt + 1;
    end

    reg [1:0] digit_sel;
    always @(posedge clk) begin
        if (scan_tick) digit_sel <= digit_sel + 1;
    end

    reg [3:0] current_digit;
    always @(*) begin
        case (digit_sel)
            2'b00: current_digit = data_in[3:0];
            2'b01: current_digit = data_in[7:4];
            2'b10: current_digit = data_in[11:8];
            2'b11: current_digit = data_in[15:12];
        endcase
    end

    reg [6:0] seg_decode;
    always @(*) begin
        case (current_digit)
            4'h0: seg_decode = 7'b0000001;
            4'h1: seg_decode = 7'b1001111;
            4'h2: seg_decode = 7'b0010010;
            4'h3: seg_decode = 7'b0000110;
            4'h4: seg_decode = 7'b1001100;
            4'h5: seg_decode = 7'b0100100;
            4'h6: seg_decode = 7'b0100000;
            4'h7: seg_decode = 7'b0001111;
            4'h8: seg_decode = 7'b0000000;
            4'h9: seg_decode = 7'b0000100;
            default: seg_decode = 7'b1111111;
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            an <= 4'b1111;
            seg <= 7'b1111111;
        end else begin
            if (blink_en && blink_state) begin
                an <= 4'b1111;
            end else begin
                seg <= seg_decode;
                case (digit_sel)
                    2'b00: an <= 4'b1110;
                    2'b01: an <= 4'b1101;
                    2'b10: an <= 4'b1011;
                    2'b11: an <= 4'b0111;
                endcase
            end
        end
    end
endmodule