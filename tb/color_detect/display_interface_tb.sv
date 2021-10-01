module display_interface_tb();

	logic i_p_clk, i_tmds_clk;
	logic i_rstn;
	logic i_mode;

	logic [17:0] o_raddr;
	logic [15:0] i_rdata;

	logic [3:0] o_TMDS_P, o_TMDS_N;

	localparam  STATE_INITIAL = 0,
	            STATE_DELAY   = 1,
	            STATE_IDLE    = 2,
	            STATE_ACTIVE  = 3;

	display_interface DUT
	(
    .i_p_clk    (i_p_clk),
    .i_tmds_clk (i_tmds_clk),
    .i_rstn     (i_rstn),
    .i_mode     (1'b0),
   
    .o_raddr    (o_raddr),
    .i_rdata    (i_rdata),

    .i_color0   (),
   	.i_color1   (),
   	.i_color2   (),
   	.i_color3   (),
   	.i_color4   (),
   	.i_color5   (),
   	.i_color6   (),
   	.i_color7   (),
   	.i_color8   (),

    .o_TMDS_P   (o_TMDS_P),
    .o_TMDS_N   (o_TMDS_N)
	);

	always#(20) i_p_clk = ~i_p_clk;

	initial begin
		i_p_clk = 0;
		i_tmds_clk = 0;
		i_rstn = 0;
		i_mode = 0;
		i_rdata = 0;
		#100;
		i_rstn = 1;
	end

	always@(posedge i_p_clk) begin
		i_rdata <= o_raddr;
	end

	logic [2:0] runCounter = 0;	
	always@(posedge i_p_clk) begin
		if(($rose(DUT.vsync)) && (DUT.STATE == STATE_IDLE)) begin
			runCounter <= runCounter + 1;
		end

		if(runCounter == 5) begin
			$display("Test passed!");
			$finish;
		end
	end

// check that read latency is accounted for
	property bram_rdLatency_chk;
		@(posedge i_p_clk) disable iff(!i_rstn) 
			($rose(DUT.active) && DUT.STATE==STATE_ACTIVE) |-> o_raddr == $past(o_raddr)+1;
	endproperty
	A_bram_rdLatency_chk: assert property(bram_rdLatency_chk)
		else $stop;

// check that FSM is in idle state one clock prior to end of line
	property bram_rdStopAddr_chk;
		@(posedge i_p_clk) disable iff(!i_rstn)
			($fell(DUT.active)) |-> (DUT.STATE==STATE_IDLE);
	endproperty
	A_bram_rdStopAddr_chk: assert property(bram_rdStopAddr_chk);

// check that reads are always aligned
	property bram_rdAlign_chk;
		@(posedge i_p_clk) disable iff(!i_rstn)
			($fell(DUT.active)) |-> (o_raddr % 480 == 0);
	endproperty
	A_bram_rdAlign_chk: assert property(bram_rdAlign_chk)
		else $stop;

// check that reads always start from zero for each frame
	property bram_rdStartAddr_chk;
		@(posedge i_p_clk) disable iff(!i_rstn)
			(DUT.counterX==0 && DUT.counterY==0) |-> (i_rdata == 0); 
	endproperty
	A_bram_rdStartAddr_chk: assert property(bram_rdStartAddr_chk)
		else $stop;

endmodule