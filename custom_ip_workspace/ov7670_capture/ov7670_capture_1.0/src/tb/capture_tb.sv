// capture_tb.sv
//
// Testbench for capture.sv
//
module capture_tb();

// TEST PARAMETERS
    parameter T_PCLK = 42;
    parameter X_RES  = 640;
    parameter Y_RES  = 480;
    //
    parameter FRAMES = 2; // number of frames to simulate

// CAMERA SIMULATION PARAMETERS (ns)
    localparam T_P              = 2*T_CLK;   // pixel time
    localparam T_LINE           = 785*T_P;   // line time
    //
    localparam T_VSYNC_HI       = 3* T_LINE; // vsync high time
    localparam T_VSYNC_HREF_SOF = 17*T_LINE; // vsync low to href time @sof
    localparam T_HREF_VSYNC_EOF = 10*T_LINE; // href low to vsync high @eof
    //
    localparam T_HREF_HI        = X_RES*T_P; // href high time
    localparam T_HERF_LO        = 144*T_P;   // href low time

// TEST VARS
    // -> inputs
    logic        i_rstn;  // sync active low reset
    logic        i_pclk;  // pixel clock
    logic        i_vsync; 
    logic        i_href;
    logic [7:0]  i_data;

    // -> outputs
    logic [15:0] o_tdata;  // output video data
    logic        o_tvalid; // data valid
    logic        o_tlast;  // end of line
    logic        o_tuser;  // start of frame

    // -> test environment
    integer i, j;
    logic   t_pixel_half;

// DUT INSTANTIATION
    capture  
    #(.X_RES(X_RES),
      .Y_RES(Y_RES))
    DUT
    (
    .i_rstn   (i_rstn),
    // 
    .i_pclk   (i_pclk),
    .i_vsync  (i_vsync),
    .i_href   (i_href),
    .i_data   (i_data),
    //
    .o_tdata  (o_tdata),
    .o_tvalid (o_tvalid),
    .o_tlast  (o_tlast),
    .o_tuser  (o_tuser)
    );

// CLOCK GEN
    initial i_pclk = 0;
    always#(T_PCLK/2) i_pclk = !i_pclk;

// CAMERA TIMING SIGNAL SIMULATION
/*verilator lint_off*/
    initial begin
        i_vsync = 0;
        i_href  = 0;
        #100;
        
        //
        for(i=0; i<FRAMES; i++) begin

            /* SoF: vsync pulse */
            @(posedge i_pclk) i_vsync = 1;
            #(T_VSYNC_HI);
            @(posedge i_pclk) i_vsync = 0;

            /* Delay to first href pulse */
            #(T_VSYNC_HREF_SOF);

            /* href pulses */
            for(i=0; i<Y_RES-1; i++) begin
                /* href goes high */
                @(posedge i_pclk) i_href = 1;
                #(T_HREF_HI);

                /* href goes low */
                @(posedge i_pclk) i_href = 0;
                #(T_HREF_LO);
            end

            /* Delay to next vsync pulse */
            #(T_HREF_VSYNC_EOF);
        end
    end

// CAMERA DATA GENERATION
    always@(posedge i_pclk) begin
        if(i_href) begin
            if(t_pixel_half) begin
                
            end
            else begin
                
            end
        end
    end