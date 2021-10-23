// module: kp_gaussian
//
// Applies a 3x3 Gaussian low pass filter kernel.
//
module kp_gaussian 
	#(
    parameter DATA_WIDTH = 8
	)
	(
	input  wire                      i_clk,     // input clock
	input  wire                      i_rstn,    // sync active-low reset
 	
 	// kernel control interface; 3 pixels from each row
	input  wire [(3*DATA_WIDTH-1):0] i_r0_data, 
	input  wire [(3*DATA_WIDTH-1):0] i_r1_data, 
	input  wire [(3*DATA_WIDTH-1):0] i_r2_data,
	input  wire                      i_valid,

	// output interface
	output reg  [DATA_WIDTH-1:0]     o_data,    // 8-bit result 
	output reg                       o_valid    // valid flag
	);

	integer i;

//  3x3 kernel
	reg  [DATA_WIDTH-1:0]     kernel [8:0];

// stage 1: multiply (2 cycles)
    wire [(9*DATA_WIDTH-1):0] rowdata;
	reg  [DATA_WIDTH+2:0]     stage1_data [8:0];
	reg                       stage1_valid;
	//
	reg                       stage1_reg_valid;
	reg  [DATA_WIDTH+2:0]     stage1_data_reg [8:0];
	

// stage 2: accumulate (1 cycle)
	reg  [DATA_WIDTH+3:0] stage2_accumulator;
	reg  [DATA_WIDTH+3:0] stage2_data;
	reg                   stage2_valid;

// stage 3: divide by 16 (1 cycle)
	reg  [DATA_WIDTH+3:0] stage3_data;
	reg                   stage3_valid;


// KERNEL DEFINITION: 3X3 GAUSSIAN BLUR
	initial begin
		kernel[0] = 1;
		kernel[1] = 2;
		kernel[2] = 1;
		kernel[3] = 2;
		kernel[4] = 4;
		kernel[5] = 2;
		kernel[6] = 1;
		kernel[7] = 2;
		kernel[8] = 1;
	end

// PIPELINE STAGE 1 (2 cycles)
// 
	assign rowdata = {i_r0_data, i_r1_data, i_r2_data};

	// multiply pixel data by kernel
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			stage1_valid <= 0;
			for(i=0; i<9; i=i+1) begin
				stage1_data[i] <= 0;
			end
		end
		else begin
			stage1_valid <= i_valid;
			for(i=0; i<9; i=i+1) begin
				stage1_data[i] <= $signed(kernel[i]) * 
				                  $signed({1'b0, rowdata[i*DATA_WIDTH+:DATA_WIDTH]});
			end
		end
	end

	// another register here for performance
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			stage1_reg_valid <= 0;
			for(i=0; i<9; i=i+1) begin
				stage1_data_reg[i] <= 0;
			end
		end
		else begin
			stage1_reg_valid <= stage1_valid;
			for(i=0; i<9; i=i+1) begin
				stage1_data_reg[i] <= stage1_data[i];
			end
		end
	end

// PIPELINE STAGE 2 (1 cycle)
//
	// sum all the stage 1 data
	always@* begin
		stage2_accumulator = 0;
		for(i=0;  i<9; i=i+1) begin
			stage2_accumulator = $signed(stage2_accumulator) +
			                     $signed(stage1_data_reg[i]);
		end
	end

	// and register it
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			stage2_valid <= 0;
			stage2_data  <= 0;
		end
		else begin
			stage2_valid <= stage1_reg_valid;
			stage2_data  <= stage2_accumulator;
		end
	end

// PIPELINE STAGE 3 (1 cycle)
//
	// divide by 16 and output
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			o_valid <= 0;
			o_data  <= 0;
		end
		else begin
			o_valid <= stage2_valid;
			o_data  <= stage2_data >> 4; // do da divide
		end
	end


endmodule