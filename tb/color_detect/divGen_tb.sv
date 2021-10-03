module divGen_tb();

	logic [7:0]  divisor, dividend;
	logic        divisor_valid, dividend_valid;
	logic [15:0] result;
	logic        result_valid;
	logic        dbz;
	logic        clk, rstn;


	div_gen_0 DUT(
    .s_axis_divisor_tdata   (divisor),
    .s_axis_divisor_tvalid  (divisor_valid),

    .s_axis_dividend_tdata  (dividend),
    .s_axis_dividend_tvalid (dividend_valid),

    .m_axis_dout_tdata      (result),
    .m_axis_dout_tvalid     (result_valid),
    .m_axis_dout_tuser      (dbz),

    .aclk                   (clk),
    .aresetn                (rstn)
	); 

	always#(4) clk = ~clk;


	task divide;
		input [7:0] t_dividend;
		input [7:0] t_divisor;
		begin
			@(posedge clk) begin
				dividend       <= t_dividend;
				divisor        <= t_divisor;
				dividend_valid <= 1;
				divisor_valid  <= 1;
			end			
			@(posedge clk) begin
				dividend       <= 0;
				divisor        <= 0;
				dividend_valid <= 0;
				divisor_valid  <= 0;
			end
		end
	endtask


	initial begin
		clk            = 0;		
		rstn           = 0;
		divisor        = 0;
		dividend       = 0;
		divisor_valid  = 0;
		dividend_valid = 0;
		#100;
		rstn = 1;
		#100;

		divide(1,1);
		divide(1,2);
		divide(1,3);
		divide(3,0);
		divide(5,2);
		divide(0,3);
		divide(2,10);

		#100;
		@(posedge clk) begin
			dividend = $signed(5) - $signed(13);
			divisor = ~dividend + 1'b1;
		end

	end


endmodule