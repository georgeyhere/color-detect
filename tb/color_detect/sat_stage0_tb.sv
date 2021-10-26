//
//
//
module sat_stage0_tb();


    logic        i_clk, i_rstn;
    logic [8:0]  i_delta, i_value;
    logic        i_valid;

    logic [7:0]  o_value;
    logic [15:0] o_data;
    logic        o_valid;

    always#(4) i_clk = ~i_clk;

    sat_stage0
    #(.DIVIDE_LATENCY(16))
    DUT
    (
    .i_clk      (i_clk),
    .i_rstn     (i_rstn),

    .i_delta    (i_delta),
    .i_value    (i_value),
    .i_valid    (i_valid),

    .o_value    (o_value),
    .o_data     (o_data),
    .o_valid    (o_valid)
    );

    task divide;
        input [8:0] t_dividend;
        input [8:0] t_divisor;
        begin
            @(posedge i_clk) begin
                i_delta <= t_dividend;
                i_value <= t_divisor;
                i_valid <= 1;
            end         
            @(posedge i_clk) begin
                i_delta <= 0;
                i_value <= 0;
                i_valid <= 0;
            end
        end
    endtask

    initial begin
        i_clk = 0;
        i_rstn = 0;
        i_delta = 0;
        i_value = 0;
        i_valid = 0;

        #100;
        i_rstn = 1;
        #100;
        divide(5, 2);
        divide(1,3);
        divide(0,3);
        divide(25,0);
        divide(42,0);
        divide(3,2);
        repeat(16) @(posedge i_clk);
        divide(10,3);
    end


endmodule