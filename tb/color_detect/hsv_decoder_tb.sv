//
//
module hsv_decoder_tb();

    logic clk, rstn;

    logic [15:0] i_data;
    logic        i_valid;

    logic [8:0] o_hsv_value;
    logic [8:0] o_dividend, o_divisor;
    logic       o_valid;
    logic [1:0] o_function;

    hsv_decoder DUT(
    .i_clk            (clk),
    .i_rstn           (rstn),
         
    .i_data           (i_data),
    .i_valid          (i_valid),

    .o_hsv_value      (o_hsv_value),

    .o_dividend       (o_dividend),
    .o_delta          (o_divisor),
    .o_function       (o_function),
    .o_valid          (o_valid)
    );

    always#(4) clk = ~clk;

    logic [15:0] test_data;
    logic [7:0] test_red_queue [$];
    logic [7:0] test_grn_queue [$];
    logic [7:0] test_blu_queue [$];
    logic [7:0] t_red, t_grn, t_blu;
    integer i;

    task genData;
        begin
            @(posedge clk) begin
                test_data  = $urandom;
                i_data     <= test_data;
                i_valid    <= 1;
                test_red_queue.push_front({test_data[4:0],  3'b0});
                test_grn_queue.push_front({test_data[10:5], 2'b0});
                test_blu_queue.push_front({test_data[15:11],3'b0});
            end
            @(posedge clk) begin
                i_data  <= 0;
                i_valid <= 0;
            end
        end
    endtask

    always@(negedge clk) begin
        if(o_valid) begin
            t_red = test_red_queue.pop_back();
            t_grn = test_grn_queue.pop_back();
            t_blu = test_blu_queue.pop_back();
            $display("Inputs: |Red: %d |Green: %d |Blue: %d", t_red, t_grn, t_blu);
            $display("Outputs: |Dividend: %d |Divisor: %d", $signed(o_dividend), $signed(o_divisor));
            $display("Function: %d", o_function);
            if(o_function == 1) begin
                assert((t_red>=t_grn)&&(t_red>=t_blu))
                else $stop;
            end
            if(o_function == 2) begin
                assert((t_grn>=t_red)&&(t_grn>=t_blu))
                else $stop;
            end
            if(o_function == 3) begin
                assert((t_blu>=t_red)&&(t_blu>=t_grn))
                else $stop;
            end
            #1;
            case(o_function)
                0: begin
                    assert(-1);
                    $stop;
                end

                1: begin
                    assert(o_dividend == t_grn-t_blu)
                    else $stop;
                    if(t_grn > t_blu) begin
                        assert(o_divisor == t_red-t_blu)
                        else $stop;
                    end
                    else begin
                        assert(o_divisor == t_red-t_grn)
                        else $stop;
                    end
                end

                2: begin
                    assert(o_dividend == t_blu-t_red)
                    else $stop;
                    if(t_blu > t_red) begin
                        assert(o_divisor == t_grn-t_red)
                        else $stop;
                    end
                    else begin
                        assert(o_divisor == t_grn-t_blu)
                        else $stop;
                    end
                end

                3: begin
                    assert(o_dividend == t_red-t_grn)
                    else $stop;
                    if(t_grn > t_red) begin
                        assert(o_divisor == t_blu-t_red)
                        else $stop;
                    end
                    else begin
                        assert(o_divisor == t_blu-t_grn)
                        else $stop;
                    end
                end
            endcase
        end
    end

    initial begin
        clk     = 0;
        rstn    = 0;
        i_valid = 0;
        i_data  = 0;        
        #100;

        rstn = 1;

        for(i=0; i<20; i++) begin
            genData();
        end

        repeat(3) @(posedge clk);
        $display("Test Passed!");
        $stop;
    end


endmodule