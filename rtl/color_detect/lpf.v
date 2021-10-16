module lpf
	(
	input  wire        i_clk,
	input  wire        i_rstn,
        
	input  wire        i_enable,
	input  wire        i_flush,

	input  wire [15:0] i_data,        // RGB565
	input  wire        i_almostempty,
	output wire        o_rd,

	input  wire        i_obuf_rd,
	output wire [15:0] o_obuf_data,   // RGB565
	output wire [10:0] o_obuf_fill,
	output wire        o_obuf_full,
	output wire        o_obuf_almostfull,
	output wire        o_obuf_empty,
	output wire        o_obuf_almostempty
	);

	wire        red_rd, blue_rd, green_rd;
	wire [7:0]  red_obuf_data, green_obuf_data, blue_obuf_data;
	wire [10:0] red_obuf_fill, green_obuf_fill, blue_obuf_fill;
	wire        red_obuf_almostfull, green_obuf_almostfull, blue_obuf_almostfull;
	wire        red_obuf_full, green_obuf_full, blue_obuf_full;
	wire        red_obuf_empty, green_obuf_empty, blue_obuf_empty;
	wire        red_obuf_almostempty, green_obuf_almostempty, blue_obuf_almostempty;

	assign o_rd = red_rd || green_rd || blue_rd;

	assign o_obuf_data = {red_obuf_data  [7:3],
	                      green_obuf_data[7:2],
	                      blue_obuf_data [7:3]};

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

	kp_gaussian_top red_filter_i 
	(
	.i_clk              (i_clk                ),
	.i_rstn             (i_rstn               ),
	.i_enable           (i_enable             ),
	.i_flush            (i_flush              ),
  
	.i_data             ({i_data[15:11], 3'b0}),
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

	kp_gaussian_top blue_filter_i 
	(
	.i_clk              (i_clk                  ),
	.i_rstn             (i_rstn                 ),
	.i_enable           (i_enable               ),
	.i_flush            (i_flush                ),
 
	.i_data             ({i_data[10:5], 2'b0}   ),
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

	kp_gaussian_top green_filter_i 
	(
	.i_clk              (i_clk                  ),
	.i_rstn             (i_rstn                 ),
	.i_enable           (i_enable               ),
	.i_flush            (i_flush                ),
               
	.i_data             ({i_data[4:0], 3'b0}    ),
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