module top(
    input clk,
    input [15:0] sw,
    input btnC,
    input btnD,
    output [15:0] led,
    output [6:0] seg,
    output [3:0] an
);
    reg [7:0] por_cnt = 0;
    wire rst_n = (por_cnt == 8'hFF) & (~btnD);

    always @(posedge clk) begin
        if (por_cnt != 8'hFF) begin
            por_cnt <= por_cnt + 1;
        end
    end

    wire [31:0] mem_addr, mem_wdata;
    wire [3:0] mem_wstrb;
    wire mem_valid;
    reg [31:0] mem_rdata;
    reg mem_ready;

    reg [31:0] memory [0:2047];
    
    reg [7:0] temp_mem [0:8191];
    integer i;
    initial begin
        $readmemh("firmware.mem", temp_mem);
        for (i = 0; i < 2048; i = i + 1) begin
            memory[i] = {temp_mem[i*4+3], temp_mem[i*4+2], temp_mem[i*4+1], temp_mem[i*4]};
        end
    end

    reg [15:0] reg_led;
    reg [15:0] reg_seg_data;
    reg reg_blink_en;
    reg timer_flag;

    reg [24:0] blink_cnt;
    always @(posedge clk) begin
        blink_cnt <= blink_cnt + 1;
    end
    
    assign led = (reg_blink_en && blink_cnt[24]) ? 16'b0 : reg_led;
    
    wire tick_1hz;

    timer_1hz timer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tick_1hz(tick_1hz)
    );

    seg7_controller seg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(reg_seg_data),
        .blink_en(reg_blink_en),
        .seg(seg),
        .an(an)
    );

    picorv32 cpu (
        .clk(clk),
        .resetn(rst_n),
        .mem_valid(mem_valid),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata)
    );

    always @(posedge clk) begin
        mem_ready <= 0;
        if (tick_1hz) timer_flag <= 1;

        if (mem_valid && !mem_ready) begin
            mem_ready <= 1;
            
            if (mem_addr < 32'h0000_2000) begin
                if (mem_wstrb != 0) begin
                    if (mem_wstrb[0]) memory[mem_addr >> 2][7:0]   <= mem_wdata[7:0];
                    if (mem_wstrb[1]) memory[mem_addr >> 2][15:8]  <= mem_wdata[15:8];
                    if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
                end else begin
                    mem_rdata <= memory[mem_addr >> 2];
                end
            end
            
            else if (mem_addr == 32'h4000_0000 && mem_wstrb == 0) mem_rdata <= {16'b0, sw};
            else if (mem_addr == 32'h4000_0004 && mem_wstrb == 0) mem_rdata <= {31'b0, btnC};
            else if (mem_addr == 32'h4000_0008 && mem_wstrb == 0) begin
                mem_rdata <= {31'b0, timer_flag};
                timer_flag <= 0;
            end
            else if (mem_addr == 32'h4000_000C && mem_wstrb != 0) reg_seg_data <= mem_wdata[15:0];
            else if (mem_addr == 32'h4000_0010 && mem_wstrb != 0) reg_led <= mem_wdata[15:0];
            else if (mem_addr == 32'h4000_0014 && mem_wstrb != 0) reg_blink_en <= mem_wdata[0];
        end
    end
endmodule