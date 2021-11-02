`default_nettype none
//
// o_result
//     [31:29] -> region 0 (0,0) color
//     [28:26] -> region 1 (1,0) color
//     [25:23] -> region 2 (2,0) color
//     [22:20] -> region 3 (0,1) color
//     [19:17] -> region 4 (1,1) color
//     [16:14] -> region 5 (2,1) color
//     [13:11] -> region 6 (0,2) color
//     [10:8]  -> region 7 (1,2) color
//     [7:5]   -> region 8 (2,2) color
//     [4:0] PADDED
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
module sys_top 
    //
    `include "colorDetect_definitions.vh"
    (
    input  wire        i_sysclk,    // 125 MHz board clock
    input  wire        i_rst,       // active-high board button
  
    // camera interface
    output wire        o_cam_xclk,  // 24MHz clock to camera from DCM
    output wire        o_cam_rstn,  // camera active low reset
    output wire        o_cam_pwdn,  // camera active high power down 
   
    input  wire        i_cam_pclk,  // camera generated pixel clock
    input  wire        i_cam_vsync, // camera vsync
    input  wire        i_cam_href,  // camera href
    input  wire [7:0]  i_cam_data,  // camera 8-bit data in
  
    // i2c interface
    inout  wire        SCL,         // bidirectional SCL
    inout  wire        SDA,         // bidirectional SDA
  
    // HDMI interface
    output wire [3:0]  o_TMDS_P,
    output wire [3:0]  o_TMDS_N,
  
    // filter enable switch
    input  wire        sw_gaussian,

    // control registers
    input  wire [15:0] i_red_ctrl1,
    input  wire [31:0] i_red_ctrl2,

    input  wire [15:0] i_orange_ctrl1,
    input  wire [31:0] i_orange_ctrl2,

    input  wire [15:0] i_yellow_ctrl1,
    input  wire [31:0] i_yellow_ctrl2,

    input  wire [15:0] i_green_ctrl1,
    input  wire [31:0] i_green_ctrl2,

    input  wire [15:0] i_blue_ctrl1,
    input  wire [31:0] i_blue_ctrl2,

    input  wire [15:0] i_white_ctrl1,
    input  wire [31:0] i_white_ctrl2,

    output wire [31:0] o_result
    );
  
    
// =============================================================
//              Parameters, Registers, and Wires
// =============================================================
    localparam PIXEL_WIDTH       = 16;
    localparam FRAMEBUFFER_DEPTH = 230400;
        
    
    // DCM
    wire        clk_25MHz;
    wire        clk_250MHz;
    wire        clk_PS;
    
    // Debounce
    wire        db_rstn;
    
    // System Control
    wire        cfg_start;
    wire        sys_mode;
    wire        gaussian_enable;
    wire        pipe_flush;
    
    // Camera Block
    wire        i_scl, i_sda;
    wire        o_scl, o_sda;
    wire        sof;
    wire        cam_obuf_rd;
    wire [15:0] cam_obuf_rdata;
    wire        cam_obuf_almostempty;
    wire        cam_obuf_empty;
    wire        cfg_done;

    // Gaussian
    wire        lpf_obuf_rd;
    wire [15:0] lpf_obuf_rdata;
    wire        lpf_obuf_almostempty;
    wire        lpf_obuf_empty;
    wire        lpf_error, lpf_status;

    // BRAM
    wire        mem_wr;
    wire [17:0] mem_waddr;

    // Color Detection
    wire [2:0] color0, color1, color2, color3, color4, 
               color5, color6, color7, color8;

    // Display Interface
    wire [17:0] framebuf_raddr;
    wire [15:0] framebuf_rdata;

// =============================================================
//                    Implementation:
// =============================================================
      assign o_cam_rstn = 1'b1; // sw reset instead
      assign o_cam_pwdn = 1'b0;  

      assign o_result = {color0, color1, color2, color3, color4, color5,
                         color6, color7, color8, 5'b0};
    
// **** Debounce Reset button ****
// -> debounced in camera pclk domain (24MHz)
      debounce 
      #(.DB_COUNT(476190))    // 20ms debounce period
      //#(.DB_COUNT(1))    
      db_inst (
      .i_clk   (i_cam_pclk ),
      .i_input (~i_rst     ),
      .o_db    (db_rstn    )  // 24MHz clock domain debounced reset
      );


// **** Async Reset Synchronizers ****
      // 125 MHz
      reg sync_rstn_PS, q_rstn_PS;
      always@(posedge i_sysclk or negedge db_rstn) begin
          if(!db_rstn) {sync_rstn_PS, q_rstn_PS} <= 2'b0;
          else         {sync_rstn_PS, q_rstn_PS} <= {q_rstn_PS, 1'b1};
      end
  
      // 25 MHz
      reg sync_rstn_25, q_rstn_25;
      always@(posedge clk_25MHz or negedge db_rstn) begin
          if(!db_rstn) {sync_rstn_25, q_rstn_25} <= 2'b0;
          else         {sync_rstn_25, q_rstn_25} <= {q_rstn_25, 1'b1};
      end
    

// =============================================================
//                    Submodule Instantiation:
// =============================================================
//---------------------------------------------------
//                 Clocking Wizard:
//---------------------------------------------------
      clk_wiz_0 
      dcm_i (
      .clk_in1    (i_sysclk      ), // 125MHz board clock
      .reset      (1'b0          ),
      .clk_24MHz  (o_cam_xclk    ), // camera reference clock output
      .clk_25MHz  (clk_25MHz     ), // display pixel clock
      .clk_250MHz (clk_250MHz    ), // display TMDS clock
      .clk_PS     (clk_PS        )  // processing system clock
      );

//---------------------------------------------------
//                 System Control:
//---------------------------------------------------
      sys_control 
      ctrl_i (
      .i_sysclk          (i_sysclk        ), // 125MHz clock
      .i_rstn            (sync_rstn_PS    ), // active-low sync reset
      
      .i_sof             (sof             ),
      .i_cfg_done        (cfg_done        ),
      
      .i_sw_gaussian     (sw_gaussian     ),
      
      .o_cfg_start       (cfg_start       ), // config module start
      .o_gaussian_enable (gaussian_enable ),
      .o_pipe_flush      (pipe_flush      ),
      
      .o_status_leds     ()                   
      );
    
//---------------------------------------------------
//                 Camera Block:
//---------------------------------------------------
      assign SCL = (o_scl) ? 1'bz : 1'b0;
      assign SDA = (o_sda) ? 1'bz : 1'b0;
      assign i_scl = SCL;
      assign i_sda = SDA;
      
      cam_top 
      #(.T_CFG_CLK(8))
      cam_i (
      .i_cfg_clk          (i_sysclk        ),
      .i_rstn             (sync_rstn_PS    ),
      
    // OV7670 external inputs    
      .i_cam_pclk         (i_cam_pclk      ),
      .i_cam_vsync        (i_cam_vsync     ),
      .i_cam_href         (i_cam_href      ),
      .i_cam_data         (i_cam_data      ),
  
      // i2c bidirectional pins
      .i_scl              (i_scl           ),
      .i_sda              (i_sda           ),
      .o_scl              (o_scl           ),
      .o_sda              (o_sda           ),
  
      // Controls
      .i_cfg_init         (cfg_start       ),
      .o_cfg_done         (cfg_done        ),
      .o_sof              (sof             ),
  
      // output buffer read interface
      .i_obuf_rclk        (i_sysclk        ),
      .i_obuf_rstn        (sync_rstn_PS    ),
      .i_obuf_rd          (cam_obuf_rd     ),
      .o_obuf_data        (cam_obuf_rdata  ),
      .o_obuf_empty       (cam_obuf_empty  ),  
      .o_obuf_almostempty (cam_obuf_almostempty ),  
      .o_obuf_fill        ()
      );

//---------------------------------------------------
//                Gaussian Filter:
//---------------------------------------------------
    kp_gaussian_top 
    #(.LINE_LENGTH(480),
      .LINE_COUNT (480),
      .DATA_WIDTH (16),
      .OBUF_PTR_WIDTH(4))
    lpf_i 
    (
    .i_clk              (i_sysclk),
    .i_rstn             (sync_rstn_PS),   
    .i_enable           (gaussian_enable),
    .i_flush            (pipe_flush),

    .i_data             (cam_obuf_rdata),
    .i_almostempty      (cam_obuf_almostempty),
    .o_rd               (cam_obuf_rd),

    .i_obuf_rd          (lpf_obuf_rd),
    .o_obuf_data        (lpf_obuf_rdata),
    .o_obuf_fill        (),
    .o_obuf_full        (),
    .o_obuf_almostfull  (),
    .o_obuf_empty       (lpf_obuf_empty),
    .o_obuf_almostempty (lpf_obuf_almostempty),

    .o_error            (lpf_error),
    .o_status           (lpf_status)
    );

//---------------------------------------------------
//                 Color Detection:
//---------------------------------------------------
    colorDetect_top colorDetect_i (
    .i_clk          (i_sysclk),
    .i_rstn         (sync_rstn_PS),
  
    .i_red_ctrl1    ({8'd0, 8'd10}),
    .i_red_ctrl2    ({8'd70, 8'd100, 8'd10, 8'd100}),

    .i_orange_ctrl1 ({8'd10, 8'd30}),
    .i_orange_ctrl2 ({8'd90, 8'd100, 8'd10, 8'd100}),

    .i_yellow_ctrl1 ({8'd30, 8'd60}),
    .i_yellow_ctrl2 ({8'd75, 8'd100, 8'd10, 8'd100}),

    .i_green_ctrl1  ({8'd65, 8'd160}),
    .i_green_ctrl2  ({8'd75, 8'd100, 8'd10, 8'd100}),
 
    .i_blue_ctrl1   ({8'd160, 8'd260}),
    .i_blue_ctrl2   ({8'd40, 8'd100, 8'd10, 8'd100}),
 
    .i_white_ctrl1  ({8'd0, 8'd255}),
    .i_white_ctrl2  ({8'd0, 8'd100, 8'd80, 8'd100}),

    .i_data         (lpf_obuf_rdata),
    .i_addr         (mem_waddr),
    .i_valid        (mem_wr),
       
    .o_color0       (color0),
    .o_color1       (color1),
    .o_color2       (color2),
    .o_color3       (color3),
    .o_color4       (color4),
    .o_color5       (color5),
    .o_color6       (color6),
    .o_color7       (color7),
    .o_color8       (color8)
    );

//---------------------------------------------------
//                 Memory Interface:
//---------------------------------------------------
      mem_interface 
      #(.DATA_WIDTH (PIXEL_WIDTH),
        .BRAM_DEPTH (FRAMEBUFFER_DEPTH) 
       )
      mem_i(
      .i_clk         (i_sysclk               ), // 125 MHz board clock
      .i_rstn        (sync_rstn_PS           ), // active-low sync reset
      .i_flush       (pipe_flush             ),
  
      .o_fbuf_wr     (mem_wr),
      .o_fbuf_waddr  (mem_waddr),
  
      // Input FIFO read interface
      .o_rd          (lpf_obuf_rd),
      .i_rdata       (lpf_obuf_rdata),
      .i_almostempty (lpf_obuf_almostempty),
  
  
      // frame buffer read interface
      .i_rclk        (clk_25MHz              ),
      .i_raddr       (framebuf_raddr         ),
      .o_rdata       (framebuf_rdata         )
      ); 
  
//---------------------------------------------------
//                 Display Interface:
//---------------------------------------------------
      display_interface 
      #(.FBUF_DEPTH(FRAMEBUFFER_DEPTH))
      display_i(
    .i_p_clk       (clk_25MHz       ), // 25 MHz display clock
    .i_tmds_clk    (clk_250MHz      ), // 250 MHz TMDS clock
    .i_rstn        (sync_rstn_25    ), 
    
       // frame buffer read interface
    .o_raddr       (framebuf_raddr  ),
    .i_rdata       (framebuf_rdata  ),

    // color detection interface
    .i_color0      (color0   ),
    .i_color1      (color1   ),
    .i_color2      (color2   ),
    .i_color3      (color3   ),
    .i_color4      (color4   ),
    .i_color5      (color5   ),
    .i_color6      (color6   ),
    .i_color7      (color7   ),
    .i_color8      (color8   ),

    // TMDS out   
    .o_TMDS_P      (o_TMDS_P ), // HDMI outputs
    .o_TMDS_N      (o_TMDS_N )
      );
    
endmodule