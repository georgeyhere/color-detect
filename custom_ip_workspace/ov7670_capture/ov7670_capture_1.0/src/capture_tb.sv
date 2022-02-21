// capture_tb.sv
//
// Testbench for capture.sv
//
module capture_tb();

// TEST PARAMETERS
    parameter T_PCLK = 42;
    parameter X_RES  = 64;
    parameter Y_RES  = 48;
    //
    parameter FRAMES = 2; // number of frames to simulate

// CAMERA SIMULATION PARAMETERS (ns)
    localparam T_P              = 2*T_PCLK;   // pixel time
    localparam T_LINE           = 785*T_P;   // line time
    //
    localparam T_VSYNC_HI       = 3* T_LINE; // vsync high time
    localparam T_VSYNC_HREF_SOF = 17*T_LINE; // vsync low to href time @sof
    localparam T_HREF_VSYNC_EOF = 10*T_LINE; // href low to vsync high @eof
    //
    localparam T_HREF_HI        = X_RES*T_P; // href high time
    localparam T_HREF_LO        = 144*T_P;   // href low time

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
    integer i, j, k;
    logic [15:0] t_testdata;     // random pixel data
    logic [15:0] t_testqueue[$]; // queue to store expected output pixel data
    logic [15:0] t_testexpected; // expected output pixel data

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
/*verilator lint_off*/

// CLOCK GEN
    initial i_pclk = 0;
    always#(T_PCLK/2) i_pclk = !i_pclk;

// CAMERA TIMING SIGNAL SIMULATION +
// MAIN SIMULATION TASK
//
    initial begin
        $display("\n\nStarting Test! \n");
        i_rstn  = 0;
        i_vsync = 0;
        i_href  = 0;
        #100;
        i_rstn  = 1;
        repeat(2) @(posedge i_pclk);
        //
        /* CAMERA TIMING GEN */ 
        for(i=0; i<FRAMES; i++) begin

            /* SoF: vsync pulse */
            $display("Start of Frame %d\n", k);
            @(negedge i_pclk) i_vsync = 1;
            #(T_VSYNC_HI);
            @(negedge i_pclk) i_vsync = 0;

            /* Delay to first href pulse */
            #(T_VSYNC_HREF_SOF);

            /* href pulses */
            for(j=0; j<Y_RES-1; j++) begin
                /* href goes high */
                @(negedge i_pclk) i_href = 1;
                #(T_HREF_HI);

                /* href goes low */
                @(negedge i_pclk) i_href = 0;
                #(T_HREF_LO);
            end

            /* Delay to next vsync pulse */
            $display("End of Frame %d\n", k);
            if(k==FRAMES-1) break;
            else #(T_HREF_VSYNC_EOF);
            
        end

        $display("\n\n Test Completed! \n");
    end

// CAMERA DATA GENERATION
// -> generate a random 16-bit test pixel value
//     - stored in queue t_testqueue
// -> send the test value one half at a time to the DUT
//  
    initial i_data = 0;
    always@(negedge i_pclk) begin
        if(i_href) begin
            for(k=0; k<2; k++) begin
                /* Byte 1 */
                if(k==0) begin
                    t_testdata = $urandom;
                    t_testqueue.push_front(t_testdata);
                    i_data <= t_testdata[15:8];
                    @(negedge i_pclk);
                end
                /* Byte 2 */
                else begin
                    i_data <= t_testdata[7:0];
                end
            end
        end 
    end

// DATA OUT CHECKING
// -> when DUT has valid data output:
//    - pop back pixel test value from t_testqueue
//    - display expected and actual values
//
    initial t_testexpected = 0;
    always@(negedge i_pclk) begin
        if(o_tvalid) begin
            t_testexpected = t_testqueue.pop_back();
            $display("CHECK PASS: Expected Data: %h || Actual Data: %h", t_testexpected, o_tdata);
            assert(o_tdata == t_testexpected)
            else begin
                $display("\nCHECK FAIL: Expected Data: %h || Actual Data: %h", t_testexpected, o_tdata);
                @(posedge i_pclk);
                $stop;
            end
        end
    end

endmodule