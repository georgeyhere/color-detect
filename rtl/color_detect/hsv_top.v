//
//
//
//
module hsv_top
	(
    input  wire        i_clk,   // 
    input  wire        i_rstn,  // sync active-low reset

   	// RGB Input Interface
    input  wire [15:0] i_data,  // RGB 565
    input  wire        i_valid, // input valid flag

    // Hue Output
    output wire [15:0] o_data,  // Hue (0-360 degrees)
    output wire        o_valid  // output valid flag
	);

// INTERMEDIATE WIRES
	wire [8:0]  stg0_dividend, stg0_divisor;
	wire [1:0]  stg0_function;
	wire        stg0_valid;
	
	wire [15:0] stg1_dout;
	wire [1:0]  stg1_function;
	wire        stg1_valid;

// DECODER
	hsv_decoder hsv_decode_i (
    .i_clk      (i_clk),
    .i_rstn     (i_rstn),
 	
 	// data input
    .i_data     (i_data),
    .i_valid    (i_valid),

    // to stage 1
    .o_dividend (stg0_dividend),
    .o_divisor  (stg0_divisor),
    .o_valid    (stg0_valid),
    .o_function (stg0_function)
	);

// PIPELINE STAGE 0
	hue_stage1 hue1_i (
	.i_clk      (i_clk),
	.i_rstn     (i_rstn),

	// from stage 1
	.i_dividend (stg0_dividend),
	.i_divisor  (stg0_divisor),
	.i_function (stg0_function),
	.i_valid    (stg0_valid),

	// to stage 2
	.o_data     (stg1_dout),
	.o_function (stg1_function),
	.o_valid    (stg1_valid)
	);

// PIPELINE STAGE 1
	hue_stage2 hue2_i (
    .i_clk      (i_clk),
    .i_rstn     (i_rstn),

    // from stage 2
    .i_data     (stg1_dout),
    .i_function (stg1_function),
    .i_valid    (stg1_valid),

    // output: hue (degrees)
    .o_data     (o_data),
    .o_valid    (o_valid)
	);

endmodule