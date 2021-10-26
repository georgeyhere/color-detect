module colorDetect_top
    (
    input  wire i_clk,
    input  wire i_rstn,

    input  wire [15:0] i_data,
    input  wire [17:0] i_addr,
    input  wire        i_valid,

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

    hsv_top hsv_i (
    .i_clk    (i_clk),
    .i_rstn   (i_rstn),
 
    .i_data   (i_data),
    .i_addr   (i_addr),
    .i_valid  (i_valid),
    
    .o_addr   (addr),
    .o_hue    (hue),
    .o_sat    (sat),
    .o_value  (value),
    .o_valid  (hsv_valid)
    );

    colorBin colorBin_i (
    .i_clk    (i_clk),
    .i_rstn   (i_rstn),
    
    //.i_addr   (addr),
    .i_hue    (hue),
    .i_sat    (sat),
    .i_value  (value),
    .i_valid  (hsv_valid),

    .o_color0 (o_color0),
    .o_color1 (o_color1),
    .o_color2 (o_color2),
    .o_color3 (o_color3),
    .o_color4 (o_color4),
    .o_color5 (o_color5),
    .o_color6 (o_color6),
    .o_color7 (o_color7),
    .o_color8 (o_color8)
    );

endmodule