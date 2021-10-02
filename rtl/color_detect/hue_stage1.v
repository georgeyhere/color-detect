// module: hue_stage1
//
// This module divides the dividend by the divisor generated 
// by hue_stage0 and propagates the sign bit down the pipeline.
//
module hue_stage1 
	#(parameter DIVIDE_LATENCY = 16)
	(
	input  wire        i_clk,
	input  wire        i_rstn,

	// dividend and divisor
	input  wire [8:0]  i_dividend,
	input  wire [8:0]  i_divisor,
	input  wire        i_valid,

	// output 
	output reg  [15:0] o_data,
	output wire        o_valid
	);

	reg  [7:0]  dividend, divisor;
	wire [15:0] result;
	wire        dbz;

	

	integer i;
	reg [0:DIVIDE_LATENCY-1] SHIFTREG;
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			SHIFTREG <= {DIVIDE_LATENCY{1'b0}};
		end
		else begin
			if(i_valid) begin
				SHIFTREG <= {i_dividend[8], SHIFTREG[0:DIVIDE_LATENCY-2]};
			end
			else begin
				SHIFTREG <= {1'b0, SHIFTREG[0:DIVIDE_LATENCY-2]};
			end
		end
	end

	always@* begin
		dividend = 0;
		divisor  = 0;
		if(i_valid) begin
			dividend = (i_dividend[8]) ? ~i_dividend+1'b1 : i_dividend[7:0]; 
			divisor  = i_divisor[7:0];
		end
	end

	always@* begin
		if(o_valid && !dbz) begin
			o_data = {SHIFTREG[DIVIDE_LATENCY-1], (~result[14:0]+1'b1)};
		end
		else begin
			o_data = 0;
		end
	end

	div_gen_0 DUT(
	.s_axis_dividend_tdata  (dividend),
    .s_axis_dividend_tvalid (i_valid),

    .s_axis_divisor_tdata   (divisor),
    .s_axis_divisor_tvalid  (i_valid),

    .m_axis_dout_tdata      (result),
    .m_axis_dout_tvalid     (o_valid),
    .m_axis_dout_tuser      (dbz),

    .aclk                   (i_clk),
    .aresetn                (i_rstn)
	); 

endmodule