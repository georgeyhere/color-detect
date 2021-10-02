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
    output wire [15:0] o_hue,   // Hue (0-360 degrees)
    output wire [15:0] o_sat,   //
    output wire [15:0] o_value,
    output wire        o_valid  // output valid flag
	);

// INTERMEDIATE WIRES
	wire [8:0]  decode_dividend, decode_delta;
	wire [1:0]  decode_function;
	wire [7:0]  decode_value;
	wire        decode_valid;
	
	wire [15:0] hue_stg0_dout;
	wire [1:0]  hue_stg0_function;
	wire        hue_stg0_valid;

	wire        hue_valid, sat_valid;
	assign o_valid = (hue_valid && sat_valid);

// DECODER -> 1 cycle 
	hsv_decoder hsv_decode_i (
    .i_clk       (i_clk),
    .i_rstn      (i_rstn),
 	
 	// data input
    .i_data      (i_data),
    .i_valid     (i_valid),

    // to hue stage 0
    .o_dividend  (decode_dividend),
    .o_delta     (decode_delta),
    .o_valid     (decode_valid),
    .o_function  (decode_function),
 
    // HSV Value 
    .o_value     (decode_value)
	);

// HUE PIPELINE STAGE 0 -> 16 cycles
	hue_stage0 hue0_i (
	.i_clk      (i_clk),
	.i_rstn     (i_rstn),

	// from hsv decoder
	.i_dividend (decode_dividend),
	.i_divisor  (decode_delta),
	.i_function (decode_function),
	.i_valid    (decode_valid),

	// to hue stage 1
	.o_data     (hue_stg0_dout),
	.o_function (hue_stg0_function),
	.o_valid    (hue_stg0_valid)
	);

// HUE PIPELINE STAGE 1 -> 1 cycle
	hue_stage1 hue1_i (
    .i_clk      (i_clk),
    .i_rstn     (i_rstn),

    // from stage 0
    .i_data     (hue_stg0_dout),
    .i_function (hue_stg0_function),
    .i_valid    (hue_stg0_valid),

    // output: hue (degrees)
    .o_data     (o_hue),
    .o_valid    (hue_valid)
	);

// SATURATION, VALUE 
	sat_stage0 sat0_i(
    .i_clk      (i_clk),
    .i_rstn     (i_rstn),
   
    .i_delta    (decode_delta),
    .i_value    (decode_value),
    .i_valid    (decode_valid),
   
    .o_data     (o_sat),
    .o_value    (o_value),
    .o_valid    (sat_valid)
	);

endmodule