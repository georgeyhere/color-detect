//
//
//
module hue_stage0_tb();


	logic        i_clk, i_rstn;
	logic [8:0]  i_dividend, i_divisor;
	logic [1:0]  i_function;
	logic        i_valid;

	logic [15:0] o_data;
	logic        o_valid;

	always#(4) i_clk = ~i_clk;

	hue_stage0
	#(.DIVIDE_LATENCY(16))
	DUT
	(
    .i_clk      (i_clk),
    .i_rstn     (i_rstn),

    .i_dividend (i_dividend),
    .i_divisor  (i_divisor),
    .i_function (i_function),
    .i_valid    (i_valid),

    .o_data     (o_data),
    .o_valid    (o_valid)
	);

	task divide;
		input [8:0] t_dividend;
		input [8:0] t_divisor;
		begin
			@(posedge i_clk) begin
				i_dividend <= t_dividend;
				i_divisor  <= t_divisor;
				i_function <= $urandom_range(1,3);
				i_valid    <= 1;
			end			
			@(posedge i_clk) begin
				i_dividend <= 0;
				i_divisor  <= 0;
				i_function <= 0;
				i_valid    <= 0;
			end
		end
	endtask

	initial begin
		i_clk = 0;
		i_rstn = 0;
		i_dividend = 0;
		i_divisor = 0;
		i_valid = 0;

		#100;
		i_rstn = 1;
		#100;
		divide(-5, 2);
		divide(1,3);
		divide(0,3);
		divide(25,0);
		divide(-42,0);
		divide(3,2);
		repeat(16) @(posedge i_clk);
		divide(-10,3);
	end


endmodule