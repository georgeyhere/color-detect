module hue_stage1_tb();

    logic        i_clk, i_rstn;
    logic [15:0] i_data;
    logic [1:0]  i_function;
    logic        i_valid;

    logic [15:0] o_data;
    logic        o_valid;

    hue_stage1 DUT (
    .i_clk      (i_clk),
    .i_rstn     (i_rstn),

    .i_data     (i_data),
    .i_function (i_function),
    .i_valid    (i_valid),
   
    .o_data     (o_data),
    .o_valid    (o_valid)
    );

    always#(4) i_clk = ~i_clk;
    logic[15:0] test_data;
    task transaction;
        input negative;
        begin
            @(posedge i_clk) begin
                test_data = $random;

                if(negative) begin
                    test_data[15]   = 1;
                    test_data[14:6] = 9'b111111111;
                    test_data[5:0]  = $random;
                end
                else begin
                    test_data[15]   = 0;
                    test_data[14:6] = 0;
                    test_data[5:0]  = $random;
                end

                i_data <= test_data;

                i_valid <= 1;
                i_function <= $urandom_range(1,3);
            end
            @(posedge i_clk) begin
                i_data <= 0;
                i_valid <= 0;
                i_function <= 0;
            end
        end
    endtask

    initial begin
        i_clk = 0;
        i_rstn = 0;
        i_data = 0;
        i_function = 0;
        i_valid = 0;
        #100;
        i_rstn = 1;
        #100;

        for(int i=0; i<20; i++) begin
            transaction(1);
            transaction(0);
        end
    end


endmodule