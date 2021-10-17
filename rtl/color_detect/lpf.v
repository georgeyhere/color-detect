// module: lpf.sv
//
// Instantiates three gaussian low pass filter processing units,
// one for each RGB channel.
//
// They are all identical with one minor difference; Red and Blue 
// have 5 bits each, while Green has 6 bits as per RGB565.
//
module lpf
	#(parameter LINE_LENGTH    = 480,
	  parameter LINE_COUNT     = 480,
	  parameter OBUF_PTR_WIDTH = 4)
	(
	input  wire                    i_clk,
	input  wire                    i_rstn,
                    
	input  wire                    i_enable,
	input  wire                    i_flush,
            
	input  wire [15:0]             i_data,        // RGB565
	input  wire                    i_almostempty,
	output wire                    o_rd,
            
	input  wire                    i_obuf_rd,
	output wire [15:0]             o_obuf_data,   // RGB565
	output wire [OBUF_PTR_WIDTH:0] o_obuf_fill,
	output wire                    o_obuf_full,
	output wire                    o_obuf_almostfull,
	output wire                    o_obuf_empty,
	output wire                    o_obuf_almostempty,

	output wire                    o_error
	);

	// filter module data requests
	wire        red_rd, blue_rd, green_rd;

	// filter module output buffer data out
	wire [4:0]  red_obuf_data, blue_obuf_data; // Red and Blue -> 5 bits
	wire [5:0]  green_obuf_data;               // Green -> 6 bits

	// filter module output status signals
	wire [OBUF_PTR_WIDTH:0] red_obuf_fill, green_obuf_fill, blue_obuf_fill;
	wire red_obuf_almostfull, green_obuf_almostfull, blue_obuf_almostfull;
	wire red_obuf_full, green_obuf_full, blue_obuf_full;
	wire red_obuf_empty, green_obuf_empty, blue_obuf_empty;
	wire red_obuf_almostempty, green_obuf_almostempty, blue_obuf_almostempty;

	assign o_rd = red_rd || green_rd || blue_rd;

	assign o_obuf_data = {red_obuf_data,
	                      green_obuf_data,
	                      blue_obuf_data};

	assign o_obuf_fill = red_obuf_fill &
	                     green_obuf_fill &
	                     blue_obuf_fill;

	assign o_obuf_full = red_obuf_full   ||
	                     green_obuf_full ||
	                     blue_obuf_full;

	assign o_obuf_almostfull = red_obuf_almostfull   ||
	                           green_obuf_almostfull ||
	                           blue_obuf_almostfull;

	assign o_obuf_empty = red_obuf_empty   ||
	                      green_obuf_empty ||
	                      blue_obuf_empty;

	assign o_obuf_almostempty = red_obuf_almostempty   ||
	                            green_obuf_almostempty ||
	                            blue_obuf_almostempty;

	assign o_error = (red_rd != (green_rd && blue_rd)) ||
	                 (red_obuf_fill != (green_obuf_fill && blue_obuf_fill)) ||
	                 (red_obuf_almostfull != (green_obuf_almostfull && blue_obuf_almostfull)) ||
	                 (red_obuf_empty != (green_obuf_empty && blue_obuf_empty)) ||
	                 (red_obuf_almostempty != (green_obuf_almostempty && blue_obuf_almostempty));
/*
	`ifdef XILINX_SIMULATOR
		assert(red_rd != (green_rd && blue_rd));
		assert(red_obuf_fill == (green_obuf_fill && blue_obuf_fill));
		assert(red_obuf_fill == (green_obuf_full && blue_obuf_full));
		assert(red_obuf_almostfull == (green_obuf_almostfull && blue_obuf_almostfull));
		assert(red_obuf_empty == (green_obuf_empty && blue_obuf_empty));
		assert(red_obuf_almostempty == (green_obuf_almostempty && blue_obuf_almostempty));
	`endif
*/
	kp_gaussian_top 
	#(.LINE_LENGTH(LINE_LENGTH),
	  .LINE_COUNT (LINE_COUNT),
	  .DATA_WIDTH (5))
	red_filter_i 
	(
	.i_clk              (i_clk                ),
	.i_rstn             (i_rstn               ),
	.i_enable           (i_enable             ),
	.i_flush            (i_flush              ),
  
	.i_data             (i_data[15:11]        ),
	.i_almostempty      (i_almostempty        ),
	.o_rd               (red_rd               ),
       
	.i_obuf_rd          (i_obuf_rd            ),
	.o_obuf_data        (red_obuf_data        ),
	.o_obuf_fill        (red_obuf_fill        ),
	.o_obuf_full        (red_obuf_full        ),
	.o_obuf_almostfull  (red_obuf_almostfull  ),
	.o_obuf_empty       (red_obuf_empty       ),
	.o_obuf_almostempty (red_obuf_almostempty )
	);

	kp_gaussian_top 
	#(.LINE_LENGTH (LINE_LENGTH),
	  .LINE_COUNT  (LINE_COUNT),
	  .DATA_WIDTH  (6))
	blue_filter_i 
	(
	.i_clk              (i_clk                  ),
	.i_rstn             (i_rstn                 ),
	.i_enable           (i_enable               ),
	.i_flush            (i_flush                ),
 
	.i_data             (i_data[10:5]           ),
	.i_almostempty      (i_almostempty          ),
	.o_rd               (green_rd               ),
        
	.i_obuf_rd          (i_obuf_rd              ),
	.o_obuf_data        (green_obuf_data        ),
	.o_obuf_fill        (green_obuf_fill        ),
	.o_obuf_full        (green_obuf_full        ),
	.o_obuf_almostfull  (green_obuf_almostfull  ),
	.o_obuf_empty       (green_obuf_empty       ),
	.o_obuf_almostempty (green_obuf_almostempty )
	);

	kp_gaussian_top 
	#(.LINE_LENGTH    (LINE_LENGTH),
	  .LINE_COUNT     (LINE_COUNT),
	  .DATA_WIDTH     (5),
	  .OBUF_PTR_WIDTH (OBUF_PTR_WIDTH))
	green_filter_i 
	(
	.i_clk              (i_clk                  ),
	.i_rstn             (i_rstn                 ),
	.i_enable           (i_enable               ),
	.i_flush            (i_flush                ),
               
	.i_data             (i_data[4:0]            ),
	.i_almostempty      (i_almostempty          ),
	.o_rd               (blue_rd                ),
       
	.i_obuf_rd          (i_obuf_rd              ),
	.o_obuf_data        (blue_obuf_data         ),
	.o_obuf_fill        (blue_obuf_fill         ),
	.o_obuf_full        (blue_obuf_full         ),
	.o_obuf_almostfull  (blue_obuf_almostfull   ),
	.o_obuf_empty       (blue_obuf_empty        ),
	.o_obuf_almostempty (blue_obuf_almostempty  )
	); 

endmodule