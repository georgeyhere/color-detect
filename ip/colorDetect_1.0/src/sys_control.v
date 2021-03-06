// sys_control.v
//
// This module acts as an interface between board inputs and
// pipeline control.
//
//
`default_nettype none
//
`define MODE_PASSTHROUGH 0
//
module sys_control
    (
    input  wire       i_sysclk,
    input  wire       i_rstn,

    input  wire       i_sof,
    input  wire       i_cfg_done,

    input  wire       i_sw_gaussian,

    output reg        o_cfg_start,
    output reg        o_pipe_flush,

    output reg        o_gaussian_enable,
    output reg  [7:0] o_status_leds
    );

// =============================================================
//              Parameters, Registers, and Wires
// =============================================================
    reg        STATE;
    localparam STATE_CFG    = 0,
               STATE_ACTIVE = 1;

    wire       db_btn_mode;
    reg        btn1, btn2;
    wire       db_btn_posedge;

    reg        FLUSH_STATE;
    localparam FLUSH_IDLE   = 0, 
               FLUSH_ACTIVE = 1;

    wire       sw_gaussian_db;
    reg        sw_gaussian_q1, sw_gaussian_q2;
    wire       delta_sw_gaussian;

// =============================================================
//                        Implementation:
// =============================================================
    debounce 
      #(.DB_COUNT(2500000))    // 20ms debounce period
      //#(.DB_COUNT(1))    
      db_sw_inst (
      .i_clk   (i_sysclk       ),
      .i_input (i_sw_gaussian  ),
      .o_db    (sw_gaussian_db )  
      );


//
// Configure camera to ROM values on startup or reset
//
    always@(posedge i_sysclk) begin
        if(!i_rstn) begin
            o_cfg_start <= 0;
            STATE <= 0;
        end
        else begin
            case(STATE)
                STATE_CFG: begin
                    o_cfg_start <= 1;
                    STATE <= 1;
                end

                STATE_ACTIVE: begin
                    o_cfg_start <= 0;
                    STATE <= 1;
                end
            endcase
        end
    end
//
// Gaussian enable
//
    always@(posedge i_sysclk) begin
        o_gaussian_enable <= (sw_gaussian_db);
    end

    always@(posedge i_sysclk) begin
        if(!i_rstn) begin
            {sw_gaussian_q1, sw_gaussian_q2} <= 2'b0;
        end
        else begin
            {sw_gaussian_q1, sw_gaussian_q2} <= {sw_gaussian_db, sw_gaussian_q1};
        end
    end
    assign delta_sw_gaussian = (sw_gaussian_q1 != sw_gaussian_q2);

//
// Flush the pipeline if a filter is applied
// -> hold the flush until start of frame
//
    always@(posedge i_sysclk) begin
        if(!i_rstn) begin
            o_pipe_flush <= 0;
            FLUSH_STATE  <= FLUSH_IDLE;
        end
        else begin
            case(FLUSH_STATE)

                FLUSH_IDLE: begin
                    o_pipe_flush <= 0;
                    FLUSH_STATE  <= (delta_sw_gaussian) ? FLUSH_ACTIVE:FLUSH_IDLE;
                end
    
                FLUSH_ACTIVE: begin
                    o_pipe_flush <= 1;
                    FLUSH_STATE  <= (i_sof) ? FLUSH_IDLE:FLUSH_ACTIVE;
                end
            endcase
        end
    end

endmodule