// module: sat_stage1
//
// This module calculates the HSV saturation component by dividing
// delta by the HSV Value component. 
//
// It contains shift registers to delay its outputs
// by a total of 17 cycles so that it syncs up with the 
// output of the Hue pipeline.
//
// It uses 16-bit fixed point (unsinged) with 
// 6 bits of fractional remainder.
//
module sat_stage0
    #(parameter DIVIDE_LATENCY = 16)
    (
    input  wire        i_clk,
    input  wire        i_rstn,

    // pipeline in
    input  wire [8:0]  i_delta, 
    input  wire [7:0]  i_value, // Value Component from hsv_decoder 
    input  wire        i_valid, // input valid flag

    // pipeline out
    output reg  [15:0] o_data,  // HSV Saturation Component
    output wire [15:0] o_value, // HSV Value Component
    output reg         o_valid  // output valid flag
    );

//
    wire [15:0] sat_div_result;
    wire        sat_div_valid, sat_div_dbz;

    wire [15:0] val_div_result;
    wire        val_div_valid, val_div_dbz;
    
    integer i;
    reg [15:0] SR_VALUE [0:8];

    localparam [15:0] MULT_CONST = 16'h1900; // fixed-point 100.0

// Saturation Divider -> Saturation = (value/delta)
// - 16 cycles of latency
    div_gen_0 sat_divider(
    .s_axis_dividend_tdata  (i_delta[7:0]), 
    .s_axis_dividend_tvalid (i_valid),

    .s_axis_divisor_tdata   (i_value),
    .s_axis_divisor_tvalid  (i_valid),

    .m_axis_dout_tdata      (sat_div_result),
    .m_axis_dout_tvalid     (sat_div_valid),
    .m_axis_dout_tuser      (sat_div_dbz),

    .aclk                   (i_clk),
    .aresetn                (i_rstn)
    ); 

// Value Divider -> Value = (value/255)
// - 8 cycles of latency
    div_gen_1 val_divider(
    .s_axis_dividend_tdata  (i_value),
    .s_axis_dividend_tvalid (i_valid),

    .s_axis_divisor_tdata   (8'hFF),
    .s_axis_divisor_tvalid  (i_valid),

    .m_axis_dout_tdata      (val_div_result),
    .m_axis_dout_tvalid     (val_div_valid),
    .m_axis_dout_tuser      (val_div_dbz),

    .aclk                   (i_clk),
    .aresetn                (i_rstn)
    );

// shift register for the hsv value
// multiply output by 100 to get percentage
    always@(posedge i_clk) begin
        if(!i_rstn) begin
            for(i=0; i<9; i=i+1) begin
                SR_VALUE[i] <= 0;
            end
        end
        else begin
            SR_VALUE[0] <= (val_div_dbz) ? 0:((val_div_result>>2)*MULT_CONST)>>6;
            for(i=1; i<9; i=i+1) begin
                SR_VALUE[i] <= SR_VALUE[i-1];
            end
        end
    end
    assign o_value = SR_VALUE[8];

// saturation output
// multiply output by 100 to get percentage
    always@(posedge i_clk) begin
        if(!i_rstn) begin
            o_valid <= 0;
            o_data  <= 0;
        end
        else begin
            o_valid <= (sat_div_valid);
            o_data  <= (sat_div_dbz) ? 0:(sat_div_result*MULT_CONST)>>6; // check for divide by zero
        end
    end



endmodule