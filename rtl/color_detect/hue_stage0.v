// module: hue_stage0
//
// This module divides the dividend by the divisor generated 
// by hue_stage0 and propagates the sign bit down the pipeline.
//
module hue_stage0 
	#(parameter DIVIDE_LATENCY = 16)
	(
	input  wire        i_clk,
	input  wire        i_rstn,

	// pipeline in
	input  wire [8:0]  i_dividend, 
	input  wire [8:0]  i_divisor,  
    input  wire [1:0]  i_function, // chooses constants in stage 2
    input  wire        i_valid,    // input valid flag

	// pipeline out
	output reg  [15:0] o_data,     // quotient + fractional remainder
    output reg  [1:0]  o_function, // i_function with 16 cycle delay
	output wire        o_valid     // output valid flag
	);

//
	reg  [7:0]  dividend, divisor;
	wire [15:0] result;
	wire        dbz;

	integer i;
	reg [0:DIVIDE_LATENCY-1] SR_SIGNBIT;
	reg [1:0] SR_FUNCTION [0:DIVIDE_LATENCY-1];

// Sign Bit Shift Register
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			SR_SIGNBIT <= {DIVIDE_LATENCY{1'b0}};
		end
		else begin
			SR_SIGNBIT <= {i_dividend[8], SR_SIGNBIT[0:DIVIDE_LATENCY-2]};
		end
	end

// Function Input Shift Register
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			for(i=0; i<DIVIDE_LATENCY; i=i+1) begin
				SR_FUNCTION[i] <= 2'b0;
			end
		end
		else begin
			SR_FUNCTION[0] <= i_function;
			for(i=1; i<DIVIDE_LATENCY; i=i+1) begin
				SR_FUNCTION[i] <= SR_FUNCTION[i-1];
			end
		end
	end

	always@* begin
		if(o_valid) o_function = SR_FUNCTION[DIVIDE_LATENCY-1];
		else        o_function = 0;
	end

// Input Logic: Remove sign bit
	always@* begin
		dividend = 0;
		divisor  = 0;
		if(i_valid) begin
			dividend = (i_dividend[8]) ? ~i_dividend+1'b1 : i_dividend[7:0]; 
			divisor  = i_divisor[7:0];
		end
	end

// Output Logic: Reapply sign bit if needed
	always@* begin
		if(o_valid && !dbz) begin
			if(SR_SIGNBIT[DIVIDE_LATENCY-1]) begin
				o_data = {SR_SIGNBIT[DIVIDE_LATENCY-1], (~result[14:0]+1'b1)};
			end
			else begin
				o_data = result;
			end
		end
		else begin
			o_data = 0;
		end
	end


// 
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