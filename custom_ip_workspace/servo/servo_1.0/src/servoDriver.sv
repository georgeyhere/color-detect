// servoDriver.sv
//
// This module is a servo motor driver designed for a MG996 servo.
// The MG996 uses standard servo Variable Pulse Width control so
// this module will work for any generic servo as well.
//
// MG996 Details: 
// -> Datasheet:
// https://www.electronicoscaldas.com/datasheet/MG996R_Tower-Pro.pdf

// -> Control Angle:
//    - 0-360 degrees
//
// -> Duty Cycle:
//    - The servo expects a 2ms pulse every 20ms.
//         - Minimum Width: 1ms
//         - Maximum Width: 2ms
// 
//    - The Dead Band width of the servo is the smallest amount the
//      PWM is allowed to change without affecting movement.
//         - Dead Band Width: 5us = 0.005ms
//         - Smallest Possible Movement:
//             -> 2ms / 0.005ms = 400
//             -> 60/400 = 0.15 degrees/pulse 
//                       = 0.15 deg / 2 ms
//             Min Speed: = 75 deg / s
//
//         - Largest Possible Movement:
//             -> 60 deg / 0.17s
//             Max Speed = 353 deg / s
//
//    - The width of the pulse determines the movement of the servo.
//         - 1 ms:  move 60 deg counter-clockwise 
//         - 1.5ms: neutral; maintain position
//         - 2ms:   move 60 deg clockwise
//
module servoDriver
    #(parameter T_CLK = 10)
    (
    // SYSTEM
    input  logic        i_clk,
    input  logic        i_rstn,

    // CONTROL AND STATUS
    input  logic        i_start,
    input  logic [31:0] i_pulseWidth,
    output logic        o_done,
    // SERVO INTERFACE
    output logic        o_pulse
    );

// CONSTANTS
    localparam C_NEUTRAL  = 1500000 / T_CLK; // clock periods for 1.5ms
    localparam C_MAXWIDTH = 2000000 / T_CLK; // clock periods for 2 ms
    //
    localparam STATE_IDLE   = 0,
               STATE_ACTIVE = 1;

// LOCAL LOGIC
    logic [31:0] pulseCounter;
    logic [31:0] pulseTarget;
    logic        pulseCounter_rst;
    logic        pulseDone;
    //
    logic STATE;

// PULSE GEN
    always_ff@(posedge i_clk) begin
        if(!i_rstn || pulseCounter_rst) begin
            pulseCounter <= 0;
        end
        else begin
            pulseCounter <= (pulseCounter == C_MAXWIDTH-1) ? 0 : pulseCounter+1;
        end
    end
    assign pulseDone = (pulseCounter == C_MAXWIDTH-1) ? 1:0;
    assign o_pulse   = (pulseCounter < pulseTarget)   ? 1:0;

// FSM
    always_ff@(posedge i_clk) begin
        if(!i_rstn) begin
            o_done           <= 1;
            pulseCounter_rst <= 0;
            pulseTarget      <= 0;
            STATE            <= STATE_IDLE;
        end
        else begin
            case(STATE)
                /* Idle State; hold neutral position */
                STATE_IDLE: begin
                    if(!i_start) begin
                        o_done           <= 1;
                        pulseCounter_rst <= 0;
                        pulseTarget      <= C_NEUTRAL;
                        STATE            <= STATE_IDLE;
                    end
                    else begin
                        o_done           <= 0;
                        pulseCounter_rst <= 1;
                        pulseTarget      <= i_pulseWidth;
                        STATE            <= STATE_ACTIVE;
                    end
                end

                /* Active State; make servo goto inputted position */
                STATE_ACTIVE: begin
                    pulseCounter_rst <= 0;
                    if(pulseDone) begin
                        o_done       <= 1;
                        pulseTarget  <= C_NEUTRAL;
                        STATE        <= STATE_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
