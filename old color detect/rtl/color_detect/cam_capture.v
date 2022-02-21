// capture.v
//
// This module captures incoming pixel data and is synchronous to the
// 24 MHz clock generated by the XCLK pin of the OV7670 camera.
//
// Caputures in the following regions:
//    -> x-coordinate 159-639
//    -> y-coordinate 0-479
//
// The OV7670 outputs 30FPS in VGA.
//
module capture 
    (
    input  wire        i_pclk,     // 24 MHz; sourced from OV7670 camera
    input  wire        i_rstn,     // synchronous active low reset
    input  wire        i_cfg_done, // cam config done flag
    output wire        o_status,   // asserted when capturing

    // OV7670 camera interface
    input  wire        i_vsync,    // active-high, indicates start of frame
    input  wire        i_href,     // active-high, indicates row data transmission
    input  wire [7:0]  i_data,     // pixel data from camera
    
    // FIFO write interface   
    output reg         o_wr,       // fifo write enable
    output reg  [15:0] o_wdata,    // fifo write data; {red, green, blue}

    output wire        o_sof       // start of frame flag
    );

    reg        nxt_wr;
    reg [15:0] nxt_wdata;
    reg [7:0]  byte1_data, nxt_byte1_data;

    reg        pixel_half, nxt_pixel_half;

    reg [1:0]  STATE, NEXT_STATE;
    localparam STATE_IDLE    = 0,
               STATE_ACTIVE  = 1,
               STATE_INITIAL = 2;

    initial begin
        o_wr  = 0;
        STATE = STATE_INITIAL;
    end
    assign o_status = (STATE == STATE_ACTIVE);

    reg vsync1, vsync2;
    wire vsync_posedge;

    reg [9:0] nxt_counterX, counterX;
    reg [9:0] nxt_counterY, counterY;

// **** vsync negedge detector ****
//
    always@(posedge i_pclk) begin
        if(!i_rstn) begin
            {vsync1, vsync2} <= 2'b0;
        end
        else begin
            {vsync1, vsync2} <= {i_vsync, vsync1};
        end
    end
    assign o_sof         = ((vsync1 == 0) && (vsync2 == 1)); // vsync negedge
    assign vsync_posedge = ((vsync1 == 1) && (vsync2 == 0));

// **** Next State Logic ****
//
    always@* begin
        nxt_wr           = 0;
        nxt_wdata        = o_wdata;
        nxt_byte1_data   = byte1_data;
        nxt_pixel_half   = pixel_half;
        nxt_counterX     = counterX;
        nxt_counterY     = counterY;
        NEXT_STATE       = STATE;

        case(STATE)

            STATE_INITIAL: begin
                NEXT_STATE = (i_cfg_done && o_sof) ? STATE_IDLE : STATE_INITIAL;
            end

            // camera not outputting 
            STATE_IDLE: begin
                nxt_wr         = 0;
                nxt_pixel_half = 0;
                nxt_byte1_data = 0;
                nxt_wdata      = 0;
                nxt_counterX   = 0;
                nxt_counterY   = 0;
                NEXT_STATE = (o_sof) ? STATE_ACTIVE : STATE_IDLE;
            end

            // camera outputting display data
            STATE_ACTIVE: begin
                if(i_href) begin
                    nxt_pixel_half = ~pixel_half;

                    if(pixel_half) begin 
                        // pixel coordinate counter
                        nxt_counterX = (counterX == 639) ? 0:counterX+1;   
                        
                        // pixel capture: byte 2
                        nxt_wr    = (counterX >= 160);
                        nxt_wdata = {byte1_data, i_data};
                    end
                    else begin           
                        // pixel capture: byte 1
                        nxt_wr              = 0;
                        nxt_byte1_data      = i_data;
                    end       
                end
                NEXT_STATE = (vsync_posedge) ? STATE_IDLE : STATE_ACTIVE;
            end

        endcase
    end

    always@(posedge i_pclk) begin
        if(!i_rstn) begin
            o_wr         <= 0;
            o_wdata      <= 0;
            byte1_data   <= 0;
            pixel_half   <= 0;
            counterX     <= 0;
            STATE        <= STATE_INITIAL;
        end
        else begin
            o_wr         <= nxt_wr;
            o_wdata      <= nxt_wdata;
            byte1_data   <= nxt_byte1_data;
            pixel_half   <= nxt_pixel_half;
            counterX     <= nxt_counterX;
            STATE        <= NEXT_STATE;
        end
    end

endmodule