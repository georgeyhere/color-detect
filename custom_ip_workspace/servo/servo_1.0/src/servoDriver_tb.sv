`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/21/2022 08:26:06 PM
// Design Name: 
// Module Name: servoDriver_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module servoDriver_tb();

// SIMULATION PARAMETERS
    parameter T_CLK = 10;

// TEST VARS
    // -> inputs
    logic        i_clk;
    logic        i_rstn;
    logic        i_start;
    logic [31:0] i_pulseWidth;

    // -> outputs
    logic        o_done;
    logic        o_pulse;

    // -> test environment
    realtime     t_startTime;
    realtime     t_elapsedTime;

// DUT INSTANTIATION
    servoDriver 
    #(.T_CLK(T_CLK))
    DUT (
    .i_clk        (i_clk),
    .i_rstn       (i_rstn),
    //
    .i_start      (i_start),
    .i_pulseWidth (i_pulseWidth),
    .o_done       (o_done),
    //
    .o_pulse      (o_pulse)    
    );

// CLOCK GEN
    initial i_clk = 0;
    always#(T_CLK/2) i_clk = !i_clk;

// TESTBENCH START
    initial begin
        i_rstn = 0;
        i_start = 0;
        i_pulseWidth = 0;
        #100;
        i_rstn = 1;
        @(posedge i_clk);
        $display("\n\nTestbench Start!");
        //
        setServo(32'hF);
        #20ms;
        setServo(32'hFF);
        #20ms;
        setServo(32'hFFF);
        #20ms;
        setServo(32'hFFFF);
        #20ms;
    end

// SIMULATION TASK
    task setServo;
        input logic [31:0] pos;
        begin

            /* Apply Input */
            @(posedge i_clk) begin
                $display("Running Test; Desired Counter Value = %d", pos);
                i_pulseWidth <= pos;
                i_start      <= 1;
            end

            /* Check Status */
            @(posedge i_clk) begin
                @(posedge i_clk);
                i_start <= 0;
                if(o_done) begin
                    repeat(2) @(posedge i_clk);
                    $display("\nDUT Status Error!");
                    $stop;
                end
            end

            /* Look for rising edge of pulse */
            for(int i=0; i<5; i++) begin
                @(posedge i_clk) begin
                    if(i==0) t_startTime = $realtime;
                    if(o_pulse) begin
                        $display("Pulse High! Continuing with test...");
                        break;
                    end
                    else begin
                        $display("\nNo Pulse! Timed out...");
                        $stop;
                    end
                end
            end

            /* Hang until pulse falls */
            for(int i=0; i<32'hFFFFFFF; i++) begin
                @(posedge i_clk) begin
                    if(!o_pulse) begin
                        break;
                    end
                end
            end

            repeat(3) @(posedge i_clk);
        end
    endtask

// PULSE CHECKER
    always@(posedge i_clk) begin
        //
        if($rose(o_pulse)) begin
            t_startTime = $realtime;
        end
        //
        if($fell(o_pulse)) begin
            t_elapsedTime = $realtime-t_startTime;
            $display("\nPulse Fell! Time Elapsed: %t", t_startTime);
        end
    end
    
endmodule
