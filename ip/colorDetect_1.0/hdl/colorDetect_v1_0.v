
`timescale 1 ns / 1 ps

	module colorDetect_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 6
	)
	(
		// Users to add ports here
		input  wire        i_clk_25MHz,
		input  wire        i_clk_250MHz,

    	output wire        o_cam_rstn,   // camera active low reset
    	output wire        o_cam_pwdn,   // camera active high power down 
    	
    	input  wire        i_cam_pclk,   // camera generated pixel clock
    	input  wire        i_cam_vsync,  // camera vsync
    	input  wire        i_cam_href,   // camera href
    	input  wire [7:0]  i_cam_data,   // camera 8-bit data in
   	
    	// i2c interface 
    	inout  wire        SCL,          // bidirectional SCL
    	inout  wire        SDA,          // bidirectional SDA
   	
    	// HDMI interface
    	output wire [3:0]  o_TMDS_P,
    	output wire [3:0]  o_TMDS_N,
  	
    	// filter enable switch
    	input  wire        sw_gaussian,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
// Instantiation of Axi Bus Interface S00_AXI
	colorDetect_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) colorDetect_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
		//
		.i_clk_25MHz  (i_clk_25MHz),
		.i_clk_250MHz (i_clk_250MHz),
		//
		.o_cam_rstn   (o_cam_rstn),
		.o_cam_pwdn   (o_cam_pwdn),
		//
		.i_cam_pclk   (i_cam_pclk),
		.i_cam_vsync  (i_cam_vsync),
		.i_cam_href   (i_cam_href),
		.i_cam_data   (i_cam_data),
		//
		.SCL          (SCL),
		.SDA          (SDA),
		//
		.o_TMDS_P     (o_TMDS_P),
		.o_TMDS_N     (o_TMDS_N),
		//
		.sw_gaussian  (sw_gaussian)
	);

	// Add user logic here

	// User logic ends

	endmodule
