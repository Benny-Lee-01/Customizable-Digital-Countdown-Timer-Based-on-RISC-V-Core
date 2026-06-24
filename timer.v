module timer_1hz (
    input clk,
    input rst_n,
    output reg tick_1hz
);
    reg [26:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            tick_1hz <= 0;
        end else begin
            if (counter == 100_000_000 - 1) begin
                counter <= 0;
                tick_1hz <= 1;
            end else begin
                counter <= counter + 1;
                tick_1hz <= 0;
            end
        end
    end
endmodule