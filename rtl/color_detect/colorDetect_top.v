module colorDetect_top
    (
    input  wire i_clk,
    input  wire i_rstn,

    // control registers
    input  wire [15:0] i_red_ctrl1,    // red hue control
    input  wire [31:0] i_red_ctrl2,    // red sat,val control
    input  wire [15:0] i_orange_ctrl1, // orange hue control
    input  wire [31:0] i_orange_ctrl2, // orange sat/val control
    input  wire [15:0] i_yellow_ctrl1, // yellow hue control
    input  wire [31:0] i_yellow_ctrl2, // yellow sat/val control
    input  wire [15:0] i_green_ctrl1,  // green hue control
    input  wire [31:0] i_green_ctrl2,  // green sat/val control
    input  wire [15:0] i_blue_ctrl1,   // blue hue control
    input  wire [31:0] i_blue_ctrl2,   // blue sat/val control
    input  wire [15:0] i_white_ctrl1,  // white hue control
    input  wire [31:0] i_white_ctrl2,  // white sat/val control

    // data in
    input  wire [15:0] i_data,
    input  wire [17:0] i_addr,
    input  wire        i_valid,

    // color detect results; updated once per frame
    output wire [2:0]  o_color0,
    output wire [2:0]  o_color1,
    output wire [2:0]  o_color2,
    output wire [2:0]  o_color3,
    output wire [2:0]  o_color4,
    output wire [2:0]  o_color5,
    output wire [2:0]  o_color6,
    output wire [2:0]  o_color7,
    output wire [2:0]  o_color8
    );

    wire [15:0] hue, sat, value;
    wire        hsv_valid;
    wire [17:0] addr;

    // RGB to HSV algorithm
    hsv_top hsv_i (
        .i_clk    (i_clk),
        .i_rstn   (i_rstn),
        
        // data input 
        .i_data   (i_data),
        .i_addr   (i_addr),
        .i_valid  (i_valid),
        
        // data output
        .o_addr   (addr),
        .o_hue    (hue),
        .o_sat    (sat),
        .o_val    (value),
        .o_valid  (hsv_valid)
    );

    // Color Binning
    colorBin colorBin_i (
        .i_clk          (i_clk          ),
        .i_rstn         (i_rstn         ),
        
        // control registers
        .i_red_ctrl1    (i_red_ctrl1    ),
        .i_red_ctrl2    (i_red_ctrl2    ),
        .i_orange_ctrl1 (i_orange_ctrl1 ),
        .i_orange_ctrl2 (i_orange_ctrl2 ),
        .i_yellow_ctrl1 (i_yellow_ctrl1 ),
        .i_yellow_ctrl2 (i_yellow_ctrl2 ),
        .i_green_ctrl1  (i_green_ctrl1  ),
        .i_green_ctrl2  (i_green_ctrl2  ),
        .i_blue_ctrl1   (i_blue_ctrl1   ),
        .i_blue_ctrl2   (i_blue_ctrl2   ),
        .i_white_ctrl1  (i_white_ctrl1  ),
        .i_white_ctrl2  (i_white_ctrl2  ),
        
        // input data interface
        .i_addr         (addr           ),
        .i_hue          (hue            ),
        .i_sat          (sat            ),
        .i_val          (value          ),
        .i_valid        (hsv_valid      ),
        
        // color detection results
        .o_color0       (o_color0       ),
        .o_color1       (o_color1       ),
        .o_color2       (o_color2       ),
        .o_color3       (o_color3       ),
        .o_color4       (o_color4       ),
        .o_color5       (o_color5       ),
        .o_color6       (o_color6       ),
        .o_color7       (o_color7       ),
        .o_color8       (o_color8       )
    );

endmodule