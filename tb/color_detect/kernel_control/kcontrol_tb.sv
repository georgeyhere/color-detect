/* Top level testbench contains the interface, DUT, and test handles
*  that can be used to start test components once the DUT comes out of reset.
*/
//
module kcontrol_tb();
    import kcontrol_pkg::*;
    //
    localparam LINE_LENGTH = 48;
    localparam LINE_COUNT  = 48;
    //
    logic clk;
    always #2 clk = ~clk;
    logic [47:0] r1, r2;
    //
    dut_if _if(clk);

	kp_kernel_control
	#(.LINE_LENGTH (LINE_LENGTH),
	  .LINE_COUNT  (LINE_COUNT),
	  .DATA_WIDTH  (16))
	DUT
	(
    .i_clk     (clk),
    .i_rstn    (_if.rstn),
  
    .i_data    (_if.wdata),
    .i_valid   (_if.wvalid),
    .o_req     (_if.ready),

    .o_r0_data (_if.rdata),
    .o_r1_data (r1),         // not checked
    .o_r2_data (r2),         // not checked
    .o_valid   (_if.rvalid)
	);

    //
    initial begin
        test t0;

        clk <= 0;
        _if.rstn   <= 0;
        _if.enable <= 0;
        #100 _if.rstn <= 1;

        t0 = new;
        t0.e0.vif = _if;
        t0.run();
    end

    always@(posedge _if.rvalid) begin
        $stop;
    end

endmodule