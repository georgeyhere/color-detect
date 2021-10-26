//
//
module display_interface 
    `include "display_definitions.vh"
    `include "colorDetect_definitions.vh"
    #(parameter FBUF_DEPTH = 307200)
    (
    input  wire        i_p_clk,
    input  wire        i_tmds_clk,
    input  wire        i_rstn,

    // Frame Buffer interface
    output reg  [17:0] o_raddr,
    input  wire [15:0] i_rdata,

    // Color Detection interface
    input  wire [2:0]  i_color0,
    input  wire [2:0]  i_color1,
    input  wire [2:0]  i_color2,
    input  wire [2:0]  i_color3,
    input  wire [2:0]  i_color4,
    input  wire [2:0]  i_color5,
    input  wire [2:0]  i_color6,
    input  wire [2:0]  i_color7,
    input  wire [2:0]  i_color8,

    // TMDS out
    output wire [3:0]  o_TMDS_P,
    output wire [3:0]  o_TMDS_N
    );


// =============================================================
//              Parameters, Registers, and Wires
// =============================================================
    reg  [18:0] nxt_raddr;

    wire        vsync, hsync, active;
    wire [9:0]  counterX, counterY;
    reg  [7:0]  red, green, blue;
 
    reg  [1:0]  STATE, NEXT_STATE;
    localparam  STATE_INITIAL = 0,
                STATE_DELAY   = 1,
                STATE_IDLE    = 2,
                STATE_ACTIVE  = 3;


// =============================================================
//                    Implementation:
// =============================================================

    initial begin
        STATE = STATE_INITIAL;
    end

    // next state combo logic
    always@* begin
        nxt_raddr  = o_raddr;
        NEXT_STATE = STATE;
        case(STATE)

        // wait 2 frames for camera configuration on reset/startup
            STATE_INITIAL: begin
                NEXT_STATE = ((counterX == 640) && (counterY == 480)) ? STATE_DELAY:STATE_INITIAL;
            end

            STATE_DELAY: begin
                NEXT_STATE = ((counterX == 640) && (counterY == 480)) ? STATE_ACTIVE:STATE_DELAY;
            end

        // Idle state
            STATE_IDLE: begin
                if((counterX == 159)&&(counterY<480)) begin
                    nxt_raddr  = o_raddr + 1;
                    NEXT_STATE = STATE_ACTIVE;
                end
                else if(counterY > 479) begin
                    nxt_raddr = 0;
                end
            end

        // Read frame buffer state
            STATE_ACTIVE: begin
                if(active && (counterX < 639)) begin
                    nxt_raddr = (o_raddr == FBUF_DEPTH-1) ? 0:o_raddr+1;
                end
                else begin
                    NEXT_STATE = STATE_IDLE;
                end
            end
        endcase
    end

    // registered logic
    always@(posedge i_p_clk) begin
        if(!i_rstn) begin
            o_raddr <= 0;
            STATE   <= STATE_INITIAL;
        end
        else begin
            o_raddr <= nxt_raddr;
            STATE   <= NEXT_STATE;
        end
    end


// 
//
    always@* begin
        {red, green, blue} = `RGB_BLK;

    // Video Overlay Outline
        if( ((counterX>158)&&(counterX<640)&&(counterY==0))   ||
                 ((counterX>158)&&(counterX<640)&&(counterY==479)) ||
                 ((counterX==159)&&(counterY<480)) ||
                 ((counterX==639)&&(counterY<480)) ) begin
            {red, green, blue} = `RGB_WHT;
        end
    // Video Overlay Reticle
        else if( ((counterX>158)&&(counterX<640)&&(counterY>157)&&(counterY<163)) ||
                 ((counterX>158)&&(counterX<640)&&(counterY>317)&&(counterY<323)) ||
                 ((counterX>315)&&(counterX<323)) ||
                 ((counterX>475)&&(counterX<483)) ) begin
            {red, green, blue} = `RGB_WHT;
        end
        
    // Frame Buffer Video
        else if((counterX>158)&&(counterX<640)&&(counterY<480)) begin
            red   = {i_rdata[15:11], 3'b111 }; // 5 bits of blue
            green = {i_rdata[10:5],  2'b11 };  // 6 bits of green
            blue  = {i_rdata[4:0],   3'b111 }; // 5 bits of red
        end

    // Color Detection Result Grid
        else if( ((counterX==60)&&(counterY>155)&&(counterY<280))  ||
                 ((counterX==100)&&(counterY>155)&&(counterY<280)) ||
                 ((counterY==197)&&(counterX>19)&&(counterX<141))  ||
                 ((counterY==238)&&(counterX>19)&&(counterX<141)) ) begin
            {red, green, blue} = `RGB_WHT;
        end

    // Color Detection Result Grid Outline
        else if( ((counterX>19)&&(counterX<139)&&(counterY==156)) ||
                 ((counterX>19)&&(counterX<139)&&(counterY==279)) ||
                 ((counterX==20)&&(counterY>153)&&(counterY<282)) ||
                 ((counterX==140)&&(counterY>153)&&(counterY<282)) ) begin
            {red, green, blue} = `RGB_WHT;
        end
    
    // Color Indicator Square 0
        else if((counterX>21)&&(counterX<59)&&(counterY>157)&&(counterY<196)) begin
            case(i_color0)
                `DT_RED:   {red, green, blue} = `RGB_RED;
                `DT_ORNGE: {red, green, blue} = `RGB_ORNGE;
                `DT_YLLW:  {red, green, blue} = `RGB_YLLW;
                `DT_GRN:   {red, green, blue} = `RGB_GRN;
                `DT_BLU:   {red, green, blue} = `RGB_BLU;
                `DT_WHT:   {red, green, blue} = `RGB_WHT;
                default:   {red, green, blue} = `RGB_BLK;
            endcase
        end

    // Color Indicator Square 1
        else if((counterX>61)&&(counterX<99)&&(counterY>157)&&(counterY<196)) begin
            case(i_color1)
                `DT_RED:   {red, green, blue} = `RGB_RED;
                `DT_ORNGE: {red, green, blue} = `RGB_ORNGE;
                `DT_YLLW:  {red, green, blue} = `RGB_YLLW;
                `DT_GRN:   {red, green, blue} = `RGB_GRN;
                `DT_BLU:   {red, green, blue} = `RGB_BLU;
                `DT_WHT:   {red, green, blue} = `RGB_WHT;
                default:   {red, green, blue} = `RGB_BLK;
            endcase
        end

    // Color Indicator Square 2
        else if((counterX>101)&&(counterX<139)&&(counterY>157)&&(counterY<196)) begin
            case(i_color2)
                `DT_RED:   {red, green, blue} = `RGB_RED;
                `DT_ORNGE: {red, green, blue} = `RGB_ORNGE;
                `DT_YLLW:  {red, green, blue} = `RGB_YLLW;
                `DT_GRN:   {red, green, blue} = `RGB_GRN;
                `DT_BLU:   {red, green, blue} = `RGB_BLU;
                `DT_WHT:   {red, green, blue} = `RGB_WHT;
                default:   {red, green, blue} = `RGB_BLK;
            endcase
        end
//
    // Color Indicator Square 3
        else if((counterX>21)&&(counterX<59)&&(counterY>198)&&(counterY<237)) begin
            case(i_color3)
                `DT_RED:   {red, green, blue} = `RGB_RED;
                `DT_ORNGE: {red, green, blue} = `RGB_ORNGE;
                `DT_YLLW:  {red, green, blue} = `RGB_YLLW;
                `DT_GRN:   {red, green, blue} = `RGB_GRN;
                `DT_BLU:   {red, green, blue} = `RGB_BLU;
                `DT_WHT:   {red, green, blue} = `RGB_WHT;
                default:   {red, green, blue} = `RGB_BLK;
            endcase
        end

    // Color Indicator Square 4
        else if((counterX>61)&&(counterX<99)&&(counterY>198)&&(counterY<237)) begin
            case(i_color4)
                `DT_RED:   {red, green, blue} = `RGB_RED;
                `DT_ORNGE: {red, green, blue} = `RGB_ORNGE;
                `DT_YLLW:  {red, green, blue} = `RGB_YLLW;
                `DT_GRN:   {red, green, blue} = `RGB_GRN;
                `DT_BLU:   {red, green, blue} = `RGB_BLU;
                `DT_WHT:   {red, green, blue} = `RGB_WHT;
                default:   {red, green, blue} = `RGB_BLK;
            endcase
        end
    
    // Color Indicator Square 5
        else if((counterX>101)&&(counterX<139)&&(counterY>198)&&(counterY<237)) begin
            case(i_color5)
                `DT_RED:   {red, green, blue} = `RGB_RED;
                `DT_ORNGE: {red, green, blue} = `RGB_ORNGE;
                `DT_YLLW:  {red, green, blue} = `RGB_YLLW;
                `DT_GRN:   {red, green, blue} = `RGB_GRN;
                `DT_BLU:   {red, green, blue} = `RGB_BLU;
                `DT_WHT:   {red, green, blue} = `RGB_WHT;
                default:   {red, green, blue} = `RGB_BLK;
            endcase
        end
//
    // Color Indicator Square 6
        else if((counterX>21)&&(counterX<59)&&(counterY>239)&&(counterY<278)) begin
            case(i_color6)
                `DT_RED:   {red, green, blue} = `RGB_RED;
                `DT_ORNGE: {red, green, blue} = `RGB_ORNGE;
                `DT_YLLW:  {red, green, blue} = `RGB_YLLW;
                `DT_GRN:   {red, green, blue} = `RGB_GRN;
                `DT_BLU:   {red, green, blue} = `RGB_BLU;
                `DT_WHT:   {red, green, blue} = `RGB_WHT;
                default:   {red, green, blue} = `RGB_BLK;
            endcase
        end

    // Color Indicator Square 7
        else if((counterX>61)&&(counterX<99)&&(counterY>239)&&(counterY<278)) begin
            case(i_color7)
                `DT_RED:   {red, green, blue} = `RGB_RED;
                `DT_ORNGE: {red, green, blue} = `RGB_ORNGE;
                `DT_YLLW:  {red, green, blue} = `RGB_YLLW;
                `DT_GRN:   {red, green, blue} = `RGB_GRN;
                `DT_BLU:   {red, green, blue} = `RGB_BLU;
                `DT_WHT:   {red, green, blue} = `RGB_WHT;
                default:   {red, green, blue} = `RGB_BLK;
            endcase
        end

    // Color Indicator Square 8
        else if((counterX>101)&&(counterX<139)&&(counterY>239)&&(counterY<278)) begin
            case(i_color8)
                `DT_RED:   {red, green, blue} = `RGB_RED;
                `DT_ORNGE: {red, green, blue} = `RGB_ORNGE;
                `DT_YLLW:  {red, green, blue} = `RGB_YLLW;
                `DT_GRN:   {red, green, blue} = `RGB_GRN;
                `DT_BLU:   {red, green, blue} = `RGB_BLU;
                `DT_WHT:   {red, green, blue} = `RGB_WHT;
                default:   {red, green, blue} = `RGB_BLK;
            endcase
        end
    end


//
//
    vtc #(
    .COUNTER_WIDTH(10)
    )
    vtc_i (
    .i_clk         (i_p_clk  ), // pixel clock
    .i_rstn        (i_rstn   ), 

    // timing signals
    .o_vsync       (vsync    ),
    .o_hsync       (hsync    ),
    .o_active      (active   ),

    // counter passthrough
    .o_counterX    (counterX ),
    .o_counterY    (counterY )
    );

    HDMI_top HDMI_i (
    .i_p_clk       (i_p_clk    ), // pixel clock
    .i_tmds_clk    (i_tmds_clk ), // 10x pixel clock
    .i_resetn      (i_rstn     ),

    .i_red         (blue       ),
    .i_green       (green      ),
    .i_blue        (red        ),

    // Timing Signals in; from VTC
    .i_vsync       (vsync      ),
    .i_hsync       (hsync      ),
    .i_active_area (active     ),

    // HDMI TMDS out
    .o_TMDS_P      (o_TMDS_P   ),
    .o_TMDS_N      (o_TMDS_N   )
    );

endmodule