// module: ps_gaussian_top
//
// Wraps ps_kernel_control and ps_gaussian.
//
// Contains passthrough logic for when gaussian filter is disabled.
//
module kp_gaussian_top 
    #(parameter LINE_LENGTH    = 480,
      parameter LINE_COUNT     = 480,
      parameter DATA_WIDTH     = 16,
      parameter OBUF_PTR_WIDTH = 4)
    (
    input  wire                    i_clk,    // input clock
    input  wire                    i_rstn,   // active low sync reset
    input  wire                    i_enable, // filter enable
    input  wire                    i_flush,
  
    input  wire [DATA_WIDTH-1:0]   i_data,   // input data, 8 bits of R,G, or B
    input  wire                    i_almostempty, 
    output reg                     o_rd,     // 
     
    // output buffer interface 
    input  wire                    i_obuf_rd,
    output wire [DATA_WIDTH-1:0]   o_obuf_data,
    output wire [OBUF_PTR_WIDTH:0] o_obuf_fill,
    output wire                    o_obuf_full,
    output wire                    o_obuf_almostfull,
    output wire                    o_obuf_empty,
    output wire                    o_obuf_almostempty,

    output wire                    o_error,
    output wire                    o_status
    );

//
    wire [(3*DATA_WIDTH-1):0]    r0_data, r1_data, r2_data;
    wire                         control_valid;
    wire                         req;
    
    reg                          nxt_rd;
    reg                          nxt_din_valid, din_valid;
    reg  [$clog2(LINE_LENGTH):0] nxt_rdCounter, rdCounter;
   
    reg  [DATA_WIDTH-1:0]        obuf_wdata;
    reg                          obuf_wr;

    reg         STATE, NEXT_STATE;
    localparam  STATE_IDLE   = 0,
                STATE_ACTIVE = 1;
//
    wire       red_valid, green_valid, blue_valid;
    wire [4:0] red_dout, blue_dout;
    wire [5:0] green_dout;

// FSM next state logic for FIFO reads
//
    always@* begin
        nxt_rd        = 0;
        nxt_din_valid = 0;
        NEXT_STATE    = STATE;

        case(STATE)
            
            // Input FIFO almost-empty flag is asserted
            STATE_IDLE: begin
                case(i_enable)
                    // Filter not enabled
                    0: begin
                        if(!i_almostempty) begin
                            nxt_rd        = 1;
                            nxt_din_valid = 1;
                            NEXT_STATE    = STATE_ACTIVE;
                        end
                    end

                    // Filter enabled
                    1: begin
                        if(!i_almostempty && req) begin
                            nxt_rd        = 1;
                            nxt_din_valid = 1;
                            NEXT_STATE    = STATE_ACTIVE;
                        end
                    end
                endcase 
            end

            // Input FIFO has data; almost-empty is not asserted
            STATE_ACTIVE: begin
                case(i_enable)
                    // Filter not enabled   
                    0: begin
                        nxt_rd        = (!i_almostempty);
                        nxt_din_valid = (!i_almostempty);
                        NEXT_STATE    = (i_almostempty) ? STATE_IDLE : STATE_ACTIVE;
                    end
            
                    // Filter enabled
                    1: begin
                        nxt_rd        = (!i_almostempty && req);
                        nxt_din_valid = (!i_almostempty && req);
                        NEXT_STATE    = (i_almostempty || !req) ? STATE_IDLE : STATE_ACTIVE;
                    end
                endcase
            end
        endcase
    end

// FSM registers
//
    always@(posedge i_clk) begin
        if(!i_rstn) begin
            o_rd      <= 0;
            din_valid <= 0;
            rdCounter <= 0;
            STATE     <= STATE_IDLE;
        end
        else begin
            o_rd      <= (i_flush) ? 1 : nxt_rd;
            din_valid <= nxt_din_valid;
            rdCounter <= nxt_rdCounter;
            STATE     <= NEXT_STATE;
        end
    end

// passthrough logic for if filter is not enabled
    always@* begin
        if(i_enable) begin
            obuf_wdata = {red_dout, green_dout, blue_dout};
            obuf_wr    = red_valid && green_valid && blue_valid;
        end
        else begin
            obuf_wdata = i_data;
            obuf_wr    = din_valid;
        end
    end

// error signal
    assign o_error = (i_enable && !control_valid); // true when i_enable is on
    assign o_status = (o_rd);

// Submodule instantiation
    kp_kernel_control 
    #(.LINE_LENGTH (LINE_LENGTH),
      .LINE_COUNT  (LINE_COUNT),
      .DATA_WIDTH  (16))
    gaus_ctrl_i (
    .i_clk     (i_clk              ),
    .i_rstn    (i_rstn&&(~i_flush) ),
  
    .i_data    (i_data             ),
    .i_valid   (din_valid          ),
    .o_req     (req                ),
      
    .o_r0_data (r0_data            ),
    .o_r1_data (r1_data            ),
    .o_r2_data (r2_data            ),
    .o_valid   (control_valid      )
    );

    kp_gaussian
    #(.DATA_WIDTH (5)) 
    gaus_red_i (
    .i_clk     (i_clk              ),
    .i_rstn    (i_rstn&&(~i_flush) ),

    .i_r0_data ({r0_data[47:43], r0_data[31:27], r0_data[15:11]}),
    .i_r1_data ({r1_data[47:43], r1_data[31:27], r1_data[15:11]}),
    .i_r2_data ({r2_data[47:43], r2_data[31:27], r2_data[15:11]}),
    .i_valid   (control_valid ),
    
    .o_data    (red_dout      ),
    .o_valid   (red_valid     )
    );

    kp_gaussian
    #(.DATA_WIDTH (6)) 
    gaus_green_i (
    .i_clk     (i_clk              ),
    .i_rstn    (i_rstn&&(~i_flush) ),

    .i_r0_data ({r0_data[42:37], r0_data[26:21], r0_data[10:5]}),
    .i_r1_data ({r1_data[42:37], r1_data[26:21], r1_data[10:5]}),
    .i_r2_data ({r2_data[42:37], r2_data[26:21], r2_data[10:5]}),
    .i_valid   (control_valid   ),
    
    .o_data    (green_dout      ),
    .o_valid   (green_valid     )
    );

    kp_gaussian
    #(.DATA_WIDTH (5)) 
    gaus_blue_i (
    .i_clk     (i_clk              ),
    .i_rstn    (i_rstn&&(~i_flush) ),

    .i_r0_data ({r0_data[36:32], r0_data[20:16], r0_data[4:0]}),
    .i_r1_data ({r1_data[36:32], r1_data[20:16], r1_data[4:0]}),
    .i_r2_data ({r2_data[36:32], r2_data[20:16], r2_data[4:0]}),
    .i_valid   (control_valid  ),
    
    .o_data    (blue_dout      ),
    .o_valid   (blue_valid     )
    );

    fifo_sync 
    #(.DATA_WIDTH        (DATA_WIDTH),
      .ADDR_WIDTH        (OBUF_PTR_WIDTH),
      .ALMOSTFULL_OFFSET (2),
      .ALMOSTEMPTY_OFFSET(1))
    kp_obuf_i (
    .i_clk         (i_clk),
    .i_rstn        (i_rstn&&(~i_flush) ),
            
    .i_wr          (obuf_wr),
    .i_data        (obuf_wdata),
            
    .i_rd          (i_obuf_rd),
    .o_data        (o_obuf_data),
    
    .o_fill        (o_obuf_fill),

    .o_full        (o_obuf_full),
    .o_almostfull  (o_obuf_almostfull),
    .o_empty       (o_obuf_empty),
    .o_almostempty (o_obuf_almostempty)
    );
endmodule