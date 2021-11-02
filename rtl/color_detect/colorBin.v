// module: colorBin
//
// The display is divided into a 3x3 grid with 9 total regions; one region
// for each Rubik's cube sticker on a face.
//
// This module uses the HSV value of each pixel to determine the color
// of each region.
//
// Each region can be configured as follows:
// - Hue lower threshold -> 0-256, 8 bit integer
// - Hue upper threshold -> 0-256, 8 bit integer
//    
// - Saturation lower threshold -> 0-100, 8 bit integer
// - Saturation upper threshold -> 0-100, 8 bit integer
//
// - Value lower threshold -> 0-100, 8 bit integer
// - Value upper threshold -> 0-100, 8 bit integer
//
// i_<color>_ctrl1 
//     [15:8]  -> hue lower threshold
//     [7:0]   -> hue upper threshold
//
// i_<color>_ctrl2
//     [31:24] -> saturation upper threshold
//     [23:16] -> saturation lower threshold
//     [15:8]  -> value upper threshold
//     [7:0]   -> value lower threshold
//
module colorBin
    `include "colorDetect_definitions.vh"
    (
    input  wire        i_clk,
    input  wire        i_rstn,
    
    // control registers
    input  wire [15:0] i_red_ctrl1,    // red hue control
    input  wire [31:0] i_red_ctrl2,    // red sat,val control
    //
    input  wire [15:0] i_orange_ctrl1, // orange hue control
    input  wire [31:0] i_orange_ctrl2, // orange sat/val control
    //
    input  wire [15:0] i_yellow_ctrl1, // yellow hue control
    input  wire [31:0] i_yellow_ctrl2, // yellow sat/val control
    //
    input  wire [15:0] i_green_ctrl1,  // green hue control
    input  wire [31:0] i_green_ctrl2,  // green sat/val control
    //
    input  wire [15:0] i_blue_ctrl1,   // blue hue control
    input  wire [31:0] i_blue_ctrl2,   // blue sat/val control
    //
    input  wire [15:0] i_white_ctrl1,  // white hue control
    input  wire [31:0] i_white_ctrl2,  // white sat/val control

    // data in interface
    input  wire [17:0] i_addr,
    input  wire [15:0] i_hue,
    input  wire [15:0] i_sat,
    input  wire [15:0] i_val,
    input  wire        i_valid,

    // color detect results
    output reg  [2:0]  o_color0,
    output reg  [2:0]  o_color1,
    output reg  [2:0]  o_color2,
    output reg  [2:0]  o_color3,
    output reg  [2:0]  o_color4,
    output reg  [2:0]  o_color5,
    output reg  [2:0]  o_color6,
    output reg  [2:0]  o_color7,
    output reg  [2:0]  o_color8
    );

// Control Register fields
    /*
    *  color [0] -> red
    *  color [1] -> orange
    *  color [2] -> yellow
    *  color [3] -> green
    *  color [4] -> blue
    *  color [5] -> white
    */
    reg [7:0] color_h_l [0:5]; // hue lower thresholds
    reg [7:0] color_h_h [0:5]; // hue upper thresholds
    //
    reg [7:0] color_s_l [0:5]; // saturation lower thresholds
    reg [7:0] color_s_h [0:5]; // saturation upper thresholds
    //
    reg [7:0] color_v_l [0:5]; // value lower thresholds
    reg [7:0] color_v_h [0:5]; // value upper thresholds 

// Screen Color Detection Regions
    localparam RES_X = 480;
    localparam RES_Y = 480;
    reg [9:0] counterX, counterY;
    integer i;

    localparam MAX_VAL = 99;
    localparam MAX_SAT = 99;

    // region 0 bounds
    localparam [9:0] R0_X0 = 20;
    localparam [9:0] R0_X1 = 136;
    localparam [9:0] R0_Y0 = 20;
    localparam [9:0] R0_Y1 = 136;

    // region 1 bounds
    localparam [9:0] R1_X0 = 184;
    localparam [9:0] R1_X1 = 296;
    localparam [9:0] R1_Y0 = 20;
    localparam [9:0] R1_Y1 = 136;

    // region 2 bounds
    localparam [9:0] R2_X0 = 344;
    localparam [9:0] R2_X1 = 456;
    localparam [9:0] R2_Y0 = 20;
    localparam [9:0] R2_Y1 = 136;

    // region 3 bounds
    localparam [9:0] R3_X0 = 20;
    localparam [9:0] R3_X1 = 136;
    localparam [9:0] R3_Y0 = 184;
    localparam [9:0] R3_Y1 = 296;

    // region 4 bounds
    localparam [9:0] R4_X0 = 184;
    localparam [9:0] R4_X1 = 296;
    localparam [9:0] R4_Y0 = 184;
    localparam [9:0] R4_Y1 = 296;

    // region 5 bounds
    localparam [9:0] R5_X0 = 344;
    localparam [9:0] R5_X1 = 456;
    localparam [9:0] R5_Y0 = 184;
    localparam [9:0] R5_Y1 = 296;

    // region 6 bounds
    localparam [9:0] R6_X0 = 20;
    localparam [9:0] R6_X1 = 136;
    localparam [9:0] R6_Y0 = 344;
    localparam [9:0] R6_Y1 = 456;

    // region 7 bounds
    localparam [9:0] R7_X0 = 184;
    localparam [9:0] R7_X1 = 296;
    localparam [9:0] R7_Y0 = 344;
    localparam [9:0] R7_Y1 = 456;

    // region 8 bounds
    localparam [9:0] R8_X0 = 344;
    localparam [9:0] R8_X1 = 456;
    localparam [9:0] R8_Y0 = 344;
    localparam [9:0] R8_Y1 = 456;

// Color Bins
// - One bin for each rubik's cube sticker; 9 regions of the screen
// - Each bin comprised of 6 7-bit registers
// - One register for each color

    reg [14:0] color0 [0:5]; // region 0 
    reg [14:0] color1 [0:5]; // region 1 
    reg [14:0] color2 [0:5]; // region 2
    reg [14:0] color3 [0:5]; // region 3
    reg [14:0] color4 [0:5]; // region 4
    reg [14:0] color5 [0:5]; // region 5
    reg [14:0] color6 [0:5]; // region 6
    reg [14:0] color7 [0:5]; // region 7
    reg [14:0] color8 [0:5]; // region 8

    reg red, orange, yellow, green, blue, white;

// Control Register combinatorial logic
    always@* begin
        // hue lower thresholds
        color_h_l[0] = i_red_ctrl1    [15:8];
        color_h_l[1] = i_orange_ctrl1 [15:8];
        color_h_l[2] = i_yellow_ctrl1 [15:8];
        color_h_l[3] = i_green_ctrl1  [15:8];
        color_h_l[4] = i_blue_ctrl1   [15:8];
        color_h_l[5] = i_white_ctrl1  [15:8];

        // hue upper thresholds
        color_h_h[0] = i_red_ctrl1    [7:0];
        color_h_h[1] = i_orange_ctrl1 [7:0];
        color_h_h[2] = i_yellow_ctrl1 [7:0];
        color_h_h[3] = i_green_ctrl1  [7:0];
        color_h_h[4] = i_blue_ctrl1   [7:0];
        color_h_h[5] = i_white_ctrl1  [7:0];

        // saturation lower thresholds
        color_s_l[0] = i_red_ctrl2    [31:24];
        color_s_l[1] = i_orange_ctrl2 [31:24];
        color_s_l[2] = i_yellow_ctrl2 [31:24];
        color_s_l[3] = i_green_ctrl2  [31:24];
        color_s_l[4] = i_blue_ctrl2   [31:24];
        color_s_l[5] = i_white_ctrl2  [31:24];

        // saturation upper thresholds
        color_s_h[0] = i_red_ctrl2    [23:16];
        color_s_h[1] = i_orange_ctrl2 [23:16];
        color_s_h[2] = i_yellow_ctrl2 [23:16];
        color_s_h[3] = i_green_ctrl2  [23:16];
        color_s_h[4] = i_blue_ctrl2   [23:16];
        color_s_h[5] = i_white_ctrl2  [23:16];

        // value lower thresholds
        color_v_l[0] = i_red_ctrl2    [15:8];
        color_v_l[1] = i_orange_ctrl2 [15:8];
        color_v_l[2] = i_yellow_ctrl2 [15:8];
        color_v_l[3] = i_green_ctrl2  [15:8];
        color_v_l[4] = i_blue_ctrl2   [15:8];
        color_v_l[5] = i_white_ctrl2  [15:8];

        // value upper thresholds
        color_v_h[0] = i_red_ctrl2    [7:0];
        color_v_h[1] = i_orange_ctrl2 [7:0];
        color_v_h[2] = i_yellow_ctrl2 [7:0];
        color_v_h[3] = i_green_ctrl2  [7:0];
        color_v_h[4] = i_blue_ctrl2   [7:0];
        color_v_h[5] = i_white_ctrl2  [7:0];
    end

// Coordinate Counters
    always@(posedge i_clk) begin
        if((!i_rstn)||(i_addr == 230399)) begin
            counterX <= 0;
            counterY <= 0;
        end
        else begin
            if(i_valid) begin
                counterX <= (counterX==479) ? 0:counterX+1;
                if(counterX==479) begin
                    counterY <= (counterY==479) ? 0:counterY+1;
                end
            end
        end
    end

// Pixel Color Detection
// - Combinatorial logic that raises a flag if an input HSV value
//   falls within thresholds for a color.
// - A pixel can raise more than one flag if control registers are
//   are incorrectly configured!
//
    always@* begin
        red    = 0;
        orange = 0;
        yellow = 0;
        green  = 0;
        blue   = 0;
        white  = 0;

        // check if pixel is red
        if( (i_hue[15:6] > color_h_l[0]) && // hue lower threshold 
            (i_hue[15:6] < color_h_h[0]) && // hue upper threshold 
            (i_sat[15:6] > color_s_l[0]) && // sat lower threshold
            (i_sat[15:6] < color_s_h[0]) && // sat upper threshold
            (i_val[15:6] > color_v_l[0]) && // val lower threshold
            (i_val[15:6] < color_v_h[0])    // val upper threshold
          ) begin
            red = 1;
        end

        // check if pixel is orange
        if( (i_hue[15:6] > color_h_l[1]) &&  
            (i_hue[15:6] < color_h_h[1]) &&  
            (i_sat[15:6] > color_s_l[1]) && 
            (i_sat[15:6] < color_s_h[1]) && 
            (i_val[15:6] > color_v_l[1]) && 
            (i_val[15:6] < color_v_h[1])    
          ) begin
            orange = 1;
        end

        // check if pixel is yellow
        if( (i_hue[15:6] > color_h_l[2]) &&  
            (i_hue[15:6] < color_h_h[2]) &&  
            (i_sat[15:6] > color_s_l[2]) && 
            (i_sat[15:6] < color_s_h[2]) && 
            (i_val[15:6] > color_v_l[2]) && 
            (i_val[15:6] < color_v_h[2])    
          ) begin
            yellow = 1;
        end

        // check if pixel is green
        if( (i_hue[15:6] > color_h_l[3]) &&  
            (i_hue[15:6] < color_h_h[3]) &&  
            (i_sat[15:6] > color_s_l[3]) && 
            (i_sat[15:6] < color_s_h[3]) && 
            (i_val[15:6] > color_v_l[3]) && 
            (i_val[15:6] < color_v_h[3])    
          ) begin
            green = 1;
        end

        // check if pixel is blue
        if( (i_hue[15:6] > color_h_l[4]) &&  
            (i_hue[15:6] < color_h_h[4]) &&  
            (i_sat[15:6] > color_s_l[4]) && 
            (i_sat[15:6] < color_s_h[4]) && 
            (i_val[15:6] > color_v_l[4]) && 
            (i_val[15:6] < color_v_h[4])    
          ) begin
            blue = 1;
        end

        // check if pixel is white
        if( (i_hue[15:6] > color_h_l[5]) &&  
            (i_hue[15:6] < color_h_h[5]) &&  
            (i_sat[15:6] > color_s_l[5]) && 
            (i_sat[15:6] < color_s_h[5]) && 
            (i_val[15:6] > color_v_l[5]) && 
            (i_val[15:6] < color_v_h[5])    
          ) begin
            white = 1;
        end
    end

// Pixel Color Binning
// - Synchronous process that adds to color bins for each region
//   based on pixel color
// - Resets at the end of each frame
//
    always@(posedge i_clk) begin
        if((!i_rstn)||
           ((counterX==(RES_X-1)) && (counterY==(RES_Y-1))) ) begin
            for(i=0; i<6; i=i+1) begin
                color0[i] <= 0;
                color1[i] <= 0;
                color2[i] <= 0;
                color3[i] <= 0;
                color4[i] <= 0;
                color5[i] <= 0;
                color6[i] <= 0;
                color7[i] <= 0;
                color8[i] <= 0;
            end
        end
        else if(i_valid) begin

            // REGION 0 (0,0)
            if((counterX>R0_X0)&&(counterX<R0_X1)&&
               (counterY>R0_Y0)&&(counterY<R0_Y1)) begin
                if(red)    color0[0] <= color0[0]+1;
                if(orange) color0[1] <= color0[1]+1;
                if(yellow) color0[2] <= color0[2]+1;
                if(green)  color0[3] <= color0[3]+1;
                if(blue)   color0[4] <= color0[4]+1;
                if(white)  color0[5] <= color0[5]+1;
            end

            // REGION 1 (1,0)
            if((counterX>R1_X0)&&(counterX<R1_X1)&&
               (counterY>R1_Y0)&&(counterY<R1_Y1)) begin
                if(red)    color1[0] <= color1[0]+1;
                if(orange) color1[1] <= color1[1]+1;
                if(yellow) color1[2] <= color1[2]+1;
                if(green)  color1[3] <= color1[3]+1;
                if(blue)   color1[4] <= color1[4]+1;
                if(white)  color1[5] <= color1[5]+1;
            end

            // REGION 2 (2,0)
            if((counterX>R2_X0)&&(counterX<R2_X1)&&
               (counterY>R2_Y0)&&(counterY<R2_Y1)) begin
                if(red)    color2[0] <= color2[0]+1;
                if(orange) color2[1] <= color2[1]+1;
                if(yellow) color2[2] <= color2[2]+1;
                if(green)  color2[3] <= color2[3]+1;
                if(blue)   color2[4] <= color2[4]+1;
                if(white)  color2[5] <= color2[5]+1;
            end

            // REGION 3 (0,1)
            if((counterX>R3_X0)&&(counterX<R3_X1)&&
               (counterY>R3_Y0)&&(counterY<R3_Y1)) begin
                if(red)    color3[0] <= color3[0]+1;
                if(orange) color3[1] <= color3[1]+1;
                if(yellow) color3[2] <= color3[2]+1;
                if(green)  color3[3] <= color3[3]+1;
                if(blue)   color3[4] <= color3[4]+1;
                if(white)  color3[5] <= color3[5]+1;
            end
 
            // REGION 4 (1,1)
            if((counterX>R4_X0)&&(counterX<R4_X1)&&
               (counterY>R4_Y0)&&(counterY<R4_Y1)) begin
                if(red)    color4[0] <= color4[0]+1;
                if(orange) color4[1] <= color4[1]+1;
                if(yellow) color4[2] <= color4[2]+1;
                if(green)  color4[3] <= color4[3]+1;
                if(blue)   color4[4] <= color4[4]+1;
                if(white)  color4[5] <= color4[5]+1;
            end

            // REGION 5 (2,1)
            if((counterX>R5_X0)&&(counterX<R5_X1)&&
               (counterY>R5_Y0)&&(counterY<R5_Y1)) begin
                if(red)    color5[0] <= color5[0]+1;
                if(orange) color5[1] <= color5[1]+1;
                if(yellow) color5[2] <= color5[2]+1;
                if(green)  color5[3] <= color5[3]+1;
                if(blue)   color5[4] <= color5[4]+1;
                if(white)  color5[5] <= color5[5]+1;
            end

            // REGION 6 (0,2)
            if((counterX>R6_X0)&&(counterX<R6_X1)&&
               (counterY>R6_Y0)&&(counterY<R6_Y1)) begin
                if(red)    color6[0] <= color6[0]+1;
                if(orange) color6[1] <= color6[1]+1;
                if(yellow) color6[2] <= color6[2]+1;
                if(green)  color6[3] <= color6[3]+1;
                if(blue)   color6[4] <= color6[4]+1;
                if(white)  color6[5] <= color6[5]+1;
            end

            // REGION 7 (1,2)
            if((counterX>R7_X0)&&(counterX<R7_X1)&&
               (counterY>R7_Y0)&&(counterY<R7_Y1)) begin
                if(red)    color7[0] <= color7[0]+1;
                if(orange) color7[1] <= color7[1]+1;
                if(yellow) color7[2] <= color7[2]+1;
                if(green)  color7[3] <= color7[3]+1;
                if(blue)   color7[4] <= color7[4]+1;
                if(white)  color7[5] <= color7[5]+1;
            end

            // REGION 8 (2,2)
            if((counterX>R8_X0)&&(counterX<R8_X1)&&
                (counterY>R8_Y0)&&(counterY<R8_Y1)) begin
                if(red)    color8[0] <= color8[0]+1;
                if(orange) color8[1] <= color8[1]+1;
                if(yellow) color8[2] <= color8[2]+1;
                if(green)  color8[3] <= color8[3]+1;
                if(blue)   color8[4] <= color8[4]+1;
                if(white)  color8[5] <= color8[5]+1;
            end
        end
    end

//
// The following synchronous processes check which color bin has
// the greatest value at the end of the frame for each region and
// sets the color detection result accordingly.
//
    // REGION 0: color0
    always@(posedge i_clk) begin
        if(!i_rstn) begin
            o_color0 <= 0;
        end
        else if((counterX==478)&&(counterY==479)) begin
            if( (color0[0]>=color0[1]) && (color0[0]>=color0[2]) &&
                (color0[0]>=color0[3]) && (color0[0]>=color0[4]) &&
                (color0[0]>=color0[5])) begin
                o_color0 <= `DT_RED;
            end

            else if( (color0[1]>=color0[0]) && (color0[1]>=color0[2]) &&
                     (color0[1]>=color0[3]) && (color0[1]>=color0[4]) &&
                     (color0[1]>=color0[5])) begin
                o_color0 <= `DT_ORNGE;
            end

            else if( (color0[2]>=color0[0]) && (color0[2]>=color0[1]) &&
                     (color0[2]>=color0[3]) && (color0[2]>=color0[4]) &&
                     (color0[2]>=color0[5])) begin
                o_color0 <= `DT_YLLW;
            end

            else if( (color0[3]>=color0[0]) && (color0[3]>=color0[1]) &&
                     (color0[3]>=color0[2]) && (color0[3]>=color0[4]) &&
                     (color0[3]>=color0[5])) begin
                o_color0 <= `DT_GRN;
            end

            else if( (color0[4]>=color0[0]) && (color0[4]>=color0[1]) &&
                     (color0[4]>=color0[2]) && (color0[4]>=color0[3]) &&
                     (color0[4]>=color0[5])) begin
                o_color0 <= `DT_BLU;
            end

            else if( (color0[5]>=color0[0]) && (color0[5]>=color0[1]) &&
                     (color0[5]>=color0[2]) && (color0[5]>=color0[3]) &&
                     (color0[5]>=color0[4])) begin
                o_color0 <= `DT_WHT;
            end

            else begin
                o_color0 <= 0;
            end
        end
    end

    // REGION 1: color1
    always@(posedge i_clk) begin
        if(!i_rstn) begin
            o_color1 <= 0;
        end
        else if((counterX==478)&&(counterY==479)) begin
            if( (color1[0]>=color1[1]) && (color1[0]>=color1[2]) &&
                (color1[0]>=color1[3]) && (color1[0]>=color1[4]) &&
                (color1[0]>=color1[5])) begin
                o_color1 <= `DT_RED;
            end

            else if( (color1[1]>=color1[0]) && (color1[1]>=color1[2]) &&
                     (color1[1]>=color1[3]) && (color1[1]>=color1[4]) &&
                     (color1[1]>=color1[5])) begin
                o_color1 <= `DT_ORNGE;
            end

            else if( (color1[2]>=color1[0]) && (color1[2]>=color1[1]) &&
                     (color1[2]>=color1[3]) && (color1[2]>=color1[4]) &&
                     (color1[2]>=color1[5])) begin
                o_color1 <= `DT_YLLW;
            end

            else if( (color1[3]>=color1[0]) && (color1[3]>=color1[1]) &&
                     (color1[3]>=color1[2]) && (color1[3]>=color1[4]) &&
                     (color1[3]>=color1[5])) begin
                o_color1 <= `DT_GRN;
            end

            else if( (color1[4]>=color1[0]) && (color1[4]>=color1[1]) &&
                     (color1[4]>=color1[2]) && (color1[4]>=color1[3]) &&
                     (color1[4]>=color1[5])) begin
                o_color1 <= `DT_BLU;
            end

            else if( (color1[5]>=color1[0]) && (color1[5]>=color1[1]) &&
                     (color1[5]>=color1[2]) && (color1[5]>=color1[3]) &&
                     (color1[5]>=color1[4])) begin
                o_color1 <= `DT_WHT;
            end

            else begin
                o_color1 <= 0;
            end
        end
    end

    // REGION 2: color2
    always@(posedge i_clk) begin
        if(!i_rstn) begin
            o_color2 <= 0;
        end
        else if((counterX==478)&&(counterY==479)) begin
            if( (color2[0]>=color2[1]) && (color2[0]>=color2[2]) &&
                (color2[0]>=color2[3]) && (color2[0]>=color2[4]) &&
                (color2[0]>=color2[5])) begin
                o_color2 <= `DT_RED;
            end

            else if( (color2[1]>=color2[0]) && (color2[1]>=color2[2]) &&
                     (color2[1]>=color2[3]) && (color2[1]>=color2[4]) &&
                     (color2[1]>=color2[5])) begin
                o_color2 <= `DT_ORNGE;
            end

            else if( (color2[2]>=color2[0]) && (color2[2]>=color2[1]) &&
                     (color2[2]>=color2[3]) && (color2[2]>=color2[4]) &&
                     (color2[2]>=color2[5])) begin
                o_color2 <= `DT_YLLW;
            end

            else if( (color2[3]>=color2[0]) && (color2[3]>=color2[1]) &&
                     (color2[3]>=color2[2]) && (color2[3]>=color2[4]) &&
                     (color2[3]>=color2[5])) begin
                o_color2 <= `DT_GRN;
            end

            else if( (color2[4]>=color2[0]) && (color2[4]>=color2[1]) &&
                     (color2[4]>=color2[2]) && (color2[4]>=color2[3]) &&
                     (color2[4]>=color2[5])) begin
                o_color2 <= `DT_BLU;
            end

            else if( (color2[5]>=color2[0]) && (color2[5]>=color2[1]) &&
                     (color2[5]>=color2[2]) && (color2[5]>=color2[3]) &&
                     (color2[5]>=color2[4])) begin
                o_color2 <= `DT_WHT;
            end

            else begin
                o_color2 <= 0;
            end
        end
    end

    // REGION 3: color3
    always@(posedge i_clk) begin
        if(!i_rstn) begin
            o_color3 <= 0;
        end
        else if((counterX==478)&&(counterY==479)) begin
            if( (color3[0]>=color3[1]) && (color3[0]>=color3[2]) &&
                (color3[0]>=color3[3]) && (color3[0]>=color3[4]) &&
                (color3[0]>=color3[5])) begin
                o_color3 <= `DT_RED;
            end

            else if( (color3[1]>=color3[0]) && (color3[1]>=color3[2]) &&
                     (color3[1]>=color3[3]) && (color3[1]>=color3[4]) &&
                     (color3[1]>=color3[5])) begin
                o_color3 <= `DT_ORNGE;
            end

            else if( (color3[2]>=color3[0]) && (color3[2]>=color3[1]) &&
                     (color3[2]>=color3[3]) && (color3[2]>=color3[4]) &&
                     (color3[2]>=color3[5])) begin
                o_color3 <= `DT_YLLW;
            end

            else if( (color3[3]>=color3[0]) && (color3[3]>=color3[1]) &&
                     (color3[3]>=color3[2]) && (color3[3]>=color3[4]) &&
                     (color3[3]>=color3[5])) begin
                o_color3 <= `DT_GRN;
            end

            else if( (color3[4]>=color3[0]) && (color3[4]>=color3[1]) &&
                     (color3[4]>=color3[2]) && (color3[4]>=color3[3]) &&
                     (color3[4]>=color3[5])) begin
                o_color3 <= `DT_BLU;
            end

            else if( (color3[5]>=color3[0]) && (color3[5]>=color3[1]) &&
                     (color3[5]>=color3[2]) && (color3[5]>=color3[3]) &&
                     (color3[5]>=color3[4])) begin
                o_color3 <= `DT_WHT;
            end

            else begin
                o_color3 <= 0;
            end
        end
    end

    // REGION 4: color4
    always@(posedge i_clk) begin
        if(!i_rstn) begin
            o_color4 <= 0;
        end
        else if((counterX==478)&&(counterY==479)) begin
            if( (color4[0]>=color4[1]) && (color4[0]>=color4[2]) &&
                (color4[0]>=color4[3]) && (color4[0]>=color4[4]) &&
                (color4[0]>=color4[5])) begin
                o_color4 <= `DT_RED;
            end

            else if( (color4[1]>=color4[0]) && (color4[1]>=color4[2]) &&
                     (color4[1]>=color4[3]) && (color4[1]>=color4[4]) &&
                     (color4[1]>=color4[5])) begin
                o_color4 <= `DT_ORNGE;
            end

            else if( (color4[2]>=color4[0]) && (color4[2]>=color4[1]) &&
                     (color4[2]>=color4[3]) && (color4[2]>=color4[4]) &&
                     (color4[2]>=color4[5])) begin
                o_color4 <= `DT_YLLW;
            end

            else if( (color4[3]>=color4[0]) && (color4[3]>=color4[1]) &&
                     (color4[3]>=color4[2]) && (color4[3]>=color4[4]) &&
                     (color4[3]>=color4[5])) begin
                o_color4 <= `DT_GRN;
            end

            else if( (color4[4]>=color4[0]) && (color4[4]>=color4[1]) &&
                     (color4[4]>=color4[2]) && (color4[4]>=color4[3]) &&
                     (color4[4]>=color4[5])) begin
                o_color4 <= `DT_BLU;
            end

            else if( (color4[5]>=color4[0]) && (color4[5]>=color4[1]) &&
                     (color4[5]>=color4[2]) && (color4[5]>=color4[3]) &&
                     (color4[5]>=color4[4])) begin
                o_color4 <= `DT_WHT;
            end

            else begin
                o_color4 <= 0;
            end
        end
    end

    // REGION 5: color5
    always@(posedge i_clk) begin
        if(!i_rstn) begin
            o_color5 <= 0;
        end
        else if((counterX==478)&&(counterY==479)) begin
            if( (color5[0]>=color5[1]) && (color5[0]>=color5[2]) &&
                (color5[0]>=color5[3]) && (color5[0]>=color5[4]) &&
                (color5[0]>=color5[5])) begin
                o_color5 <= `DT_RED;
            end

            else if( (color5[1]>=color5[0]) && (color5[1]>=color5[2]) &&
                     (color5[1]>=color5[3]) && (color5[1]>=color5[4]) &&
                     (color5[1]>=color5[5])) begin
                o_color5 <= `DT_ORNGE;
            end

            else if( (color5[2]>=color5[0]) && (color5[2]>=color5[1]) &&
                     (color5[2]>=color5[3]) && (color5[2]>=color5[4]) &&
                     (color5[2]>=color5[5])) begin
                o_color5 <= `DT_YLLW;
            end

            else if( (color5[3]>=color5[0]) && (color5[3]>=color5[1]) &&
                     (color5[3]>=color5[2]) && (color5[3]>=color5[4]) &&
                     (color5[3]>=color5[5])) begin
                o_color5 <= `DT_GRN;
            end

            else if( (color5[4]>=color5[0]) && (color5[4]>=color5[1]) &&
                     (color5[4]>=color5[2]) && (color5[4]>=color5[3]) &&
                     (color5[4]>=color5[5])) begin
                o_color5 <= `DT_BLU;
            end

            else if( (color5[5]>=color5[0]) && (color5[5]>=color5[1]) &&
                     (color5[5]>=color5[2]) && (color5[5]>=color5[3]) &&
                     (color5[5]>=color5[4])) begin
                o_color5 <= `DT_WHT;
            end

            else begin
                o_color5 <= 0;
            end
        end
    end

    // REGION 6: color6
    always@(posedge i_clk) begin
        if(!i_rstn) begin
            o_color6 <= 0;
        end
        else if((counterX==478)&&(counterY==479)) begin
            if( (color6[0]>=color6[1]) && (color6[0]>=color6[2]) &&
                (color6[0]>=color6[3]) && (color6[0]>=color6[4]) &&
                (color6[0]>=color6[5])) begin
                o_color6 <= `DT_RED;
            end

            else if( (color6[1]>=color6[0]) && (color6[1]>=color6[2]) &&
                     (color6[1]>=color6[3]) && (color6[1]>=color6[4]) &&
                     (color6[1]>=color6[5])) begin
                o_color6 <= `DT_ORNGE;
            end

            else if( (color6[2]>=color6[0]) && (color6[2]>=color6[1]) &&
                     (color6[2]>=color6[3]) && (color6[2]>=color6[4]) &&
                     (color6[2]>=color6[5])) begin
                o_color6 <= `DT_YLLW;
            end

            else if( (color6[3]>=color6[0]) && (color6[3]>=color6[1]) &&
                     (color6[3]>=color6[2]) && (color6[3]>=color6[4]) &&
                     (color6[3]>=color6[5])) begin
                o_color6 <= `DT_GRN;
            end

            else if( (color6[4]>=color6[0]) && (color6[4]>=color6[1]) &&
                     (color6[4]>=color6[2]) && (color6[4]>=color6[3]) &&
                     (color6[4]>=color6[5])) begin
                o_color6 <= `DT_BLU;
            end

            else if( (color6[5]>=color6[0]) && (color6[5]>=color6[1]) &&
                     (color6[5]>=color6[2]) && (color6[5]>=color6[3]) &&
                     (color6[5]>=color6[4])) begin
                o_color6 <= `DT_WHT;
            end

            else begin
                o_color6 <= 0;
            end
        end
    end

    // REGION 7: color7
    always@(posedge i_clk) begin
        if(!i_rstn) begin
            o_color7 <= 0;
        end
        else if((counterX==478)&&(counterY==479)) begin
            if( (color7[0]>=color7[1]) && (color7[0]>=color7[2]) &&
                (color7[0]>=color7[3]) && (color7[0]>=color7[4]) &&
                (color7[0]>=color7[5])) begin
                o_color7 <= `DT_RED;
            end

            else if( (color7[1]>=color7[0]) && (color7[1]>=color7[2]) &&
                     (color7[1]>=color7[3]) && (color7[1]>=color7[4]) &&
                     (color7[1]>=color7[5])) begin
                o_color7 <= `DT_ORNGE;
            end

            else if( (color7[2]>=color7[0]) && (color7[2]>=color7[1]) &&
                     (color7[2]>=color7[3]) && (color7[2]>=color7[4]) &&
                     (color7[2]>=color7[5])) begin
                o_color7 <= `DT_YLLW;
            end

            else if( (color7[3]>=color7[0]) && (color7[3]>=color7[1]) &&
                     (color7[3]>=color7[2]) && (color7[3]>=color7[4]) &&
                     (color7[3]>=color7[5])) begin
                o_color7 <= `DT_GRN;
            end

            else if( (color7[4]>=color7[0]) && (color7[4]>=color7[1]) &&
                     (color7[4]>=color7[2]) && (color7[4]>=color7[3]) &&
                     (color7[4]>=color7[5])) begin
                o_color7 <= `DT_BLU;
            end

            else if( (color7[5]>=color7[0]) && (color7[5]>=color7[1]) &&
                     (color7[5]>=color7[2]) && (color7[5]>=color7[3]) &&
                     (color7[5]>=color7[4])) begin
                o_color7 <= `DT_WHT;
            end

            else begin
                o_color7 <= 0;
            end
        end
    end

    // REGION 8: color8
    always@(posedge i_clk) begin
        if(!i_rstn) begin
            o_color8 <= 0;
        end
        else if((counterX==478)&&(counterY==479)) begin
            if( (color8[0]>=color8[1]) && (color8[0]>=color8[2]) &&
                (color8[0]>=color8[3]) && (color8[0]>=color8[4]) &&
                (color8[0]>=color8[5])) begin
                o_color8 <= `DT_RED;
            end

            else if( (color8[1]>=color8[0]) && (color8[1]>=color8[2]) &&
                     (color8[1]>=color8[3]) && (color8[1]>=color8[4]) &&
                     (color8[1]>=color8[5])) begin
                o_color8 <= `DT_ORNGE;
            end

            else if( (color8[2]>=color8[0]) && (color8[2]>=color8[1]) &&
                     (color8[2]>=color8[3]) && (color8[2]>=color8[4]) &&
                     (color8[2]>=color8[5])) begin
                o_color8 <= `DT_YLLW;
            end

            else if( (color8[3]>=color8[0]) && (color8[3]>=color8[1]) &&
                     (color8[3]>=color8[2]) && (color8[3]>=color8[4]) &&
                     (color8[3]>=color8[5])) begin
                o_color8 <= `DT_GRN;
            end

            else if( (color8[4]>=color8[0]) && (color8[4]>=color8[1]) &&
                     (color8[4]>=color8[2]) && (color8[4]>=color8[3]) &&
                     (color8[4]>=color8[5])) begin
                o_color8 <= `DT_BLU;
            end

            else if( (color8[5]>=color8[0]) && (color8[5]>=color8[1]) &&
                     (color8[5]>=color8[2]) && (color8[5]>=color8[3]) &&
                     (color8[5]>=color8[4])) begin
                o_color8 <= `DT_WHT;
            end

            else begin
                o_color8 <= 0;
            end
        end
    end

endmodule