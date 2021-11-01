// cam_top.sv
//
// Encapsulates all camera-related modules into a single block.
//
module cam_top 
    #(parameter T_CFG_CLK = 8)
    (
    input  logic        i_cfg_clk,
    input  logic        i_rstn,
    input  logic        i_flush,

    // OV7670 I/O
    input  logic        i_cam_pclk,
    input  logic        i_cam_vsync,    // active-high, indicates start of frame
    input  logic        i_cam_href,     // active-high, indicates row data transmission
    input  logic [7:0]  i_cam_data,     // pixel data from camera

    // i2c bidirectional pins
    input  logic        i_scl,
    input  logic        i_sda,
    output logic        o_scl,
    output logic        o_sda,

    // Output Buffer FIFO
    input  logic        i_obuf_rclk,
    input  logic        i_obuf_rstn,
    input  logic        i_obuf_rd,
    output logic [15:0] o_obuf_data,
    output logic        o_obuf_empty,
    output logic        o_obuf_almostempty,
    output logic [10:0] o_obuf_fill,

    // Configuration Control
    input  logic        i_cfg_init, // initialize cam registers to ROM
    output logic        o_cfg_done, // config done flag

    // Status Outputs
    output logic        o_sof       // start of frame flag
    );

// =============================================================
//              Parameters, Registers, and Wires
// =============================================================
    logic        obuf_wr;
    logic [15:0] obuf_wdata;
         

//==============================================================
//---------------------------------------------------
//            Camera Configuration Module:
//---------------------------------------------------
    cfg_interface 
    #(.T_CLK(8) )
    cfg_i (
    .i_clk   (i_cfg_clk     ), 
    .i_rstn  (i_rstn        ), // active-low sync reset 

    // controls
    .o_done  (o_cfg_done    ), // done flag
    .i_start (i_cfg_init    ), // initialize cam registers

    // i2c pins
    .i_scl   (i_scl         ), 
    .i_sda   (i_sda         ),
    .o_scl   (o_scl         ),
    .o_sda   (o_sda         )
    );


//---------------------------------------------------
//            Pixel Data Capture Module:
//---------------------------------------------------
    capture capture_i (
    .i_pclk     (i_cam_pclk       ), // camera pclk
    .i_rstn     (i_rstn           ), // active-low sync reset
    .i_cfg_done (o_cfg_done       ), // config module done flag
 
    // Camera Interface 
    .i_vsync    (i_cam_vsync      ), // vsync from camera
    .i_href     (i_cam_href       ), // href from camera
    .i_data     (i_cam_data       ), // 8-bit data
    
    // 24MHz to 125MHz FIFO Write interface
    .o_wr       (obuf_wr          ), // FIFO write enable
    .o_wdata    (obuf_wdata       ), // 16-bit RGB data

    .o_sof      (o_sof            )
    ); 

//---------------------------------------------------
//                  Output FIFO:
//---------------------------------------------------
    fifo_async
    #(.DATA_WIDTH         (16),
      .PTR_WIDTH          (11),
      .ALMOSTFULL_OFFSET  (2),
      .ALMOSTEMPTY_OFFSET (2) 
     )
    frontFIFO_i (
    // write interface
    .i_wclk         (i_cam_pclk       ), // 24 MHz camera pclk
    .i_wrstn        (i_rstn&&(~i_flush)), // active-low async reset (24MHz)
    .i_wr           (obuf_wr          ), // write enable
    .i_wdata        (obuf_wdata       ), // write data
    .o_wfull        (), 
    .o_walmostfull  (), 
    .o_wfill        (), 
    
    // read interface
    .i_rclk         (i_obuf_rclk        ), // read clock
    .i_rrstn        (i_obuf_rstn        ), // active-low async reset 
    .i_rd           (i_obuf_rd          ), // read enable
    .o_rdata        (o_obuf_data        ), // read data
    .o_rempty       (o_obuf_empty       ), // empty flag
    .o_ralmostempty (o_obuf_almostempty ), // almost empty flag
    .o_rfill        (o_obuf_fill        )  // read-side fill level 
    );

endmodule

