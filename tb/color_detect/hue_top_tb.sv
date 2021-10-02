module hue_top_tb ();

	logic        i_clk, i_rstn;
	logic [15:0] i_data;
	logic        i_valid;
	logic [15:0] o_data;
	logic        o_valid;

	hue_top DUT
	(
    .i_clk   (i_clk),
    .i_rstn  (i_rstn),
    .i_data  (i_data),
    .i_valid (i_valid),
    .o_data  (o_data),
    .o_valid (o_valid)
	);

	always#(4) i_clk = ~i_clk;

	logic [15:0] test_iqueue [$];
	logic [15:0] test_expected [$];
	logic [15:0] t_i,t_e;

	integer i,j,k;
	logic [15:0] t_inputs [0:7];
	logic [15:0] t_expected [0:7];
	initial begin
		$readmemh("hue_testInputs.txt", t_inputs);
		$readmemh("hue_testExpected.txt", t_expected);
	end

	task startOp;
		begin
			@(posedge i_clk) begin
				i_data  <= t_inputs[i];
				i_valid <= 1;
				test_iqueue.push_front(t_inputs[i]);
				test_expected.push_front(t_expected[i]);
				i++;
			end
		end
	endtask

	task endOp; 
		@(posedge i_clk) begin
			i_data  <= 0;
			i_valid <= 0;
		end
	endtask 

	always@(negedge i_clk) begin
		if(o_valid) begin
			t_e = test_expected.pop_back();
			t_i = test_iqueue.pop_back();
		end
	end

	initial begin
		i=0;
		i_clk = 0;
		i_rstn = 0;
		i_data = 0;
		i_valid = 0;
		#100;
		i_rstn = 1;
		#100;

		for(k=0; k<8; k++) begin
			startOp(); 
		end
		endOp();
	end

endmodule