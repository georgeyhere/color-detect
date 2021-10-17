// module: kp_kernel_control
//
// This module stores incoming data in 4x line buffers. 
//
// It reads three line buffers at a time and feeds that data
// to the Gaussian block.
//
// The fourth line buffer is pre-loaded while the other three are
// being read from.
//
// It also has a request flag that indicates it needs data to write
// to the next line buffer.
//
module kp_kernel_control 
	#(
    parameter LINE_LENGTH = 640,
    parameter LINE_COUNT  = 480,
    parameter DATA_WIDTH  = 8
    )
	(
	input  wire                      i_clk,   // input clock
	input  wire                      i_rstn,  // sync active low reset
 	   
 	// Data in interface   
	input  wire [DATA_WIDTH-1:0]     i_data,  // 8-bit greyscale data
	input  wire                      i_valid, //
	output reg                       o_req,   // asserted when ready for more data

	// Gaussian MAC interface
	output reg  [(3*DATA_WIDTH-1):0] o_r0_data, 
	output reg  [(3*DATA_WIDTH-1):0] o_r1_data,
	output reg  [(3*DATA_WIDTH-1):0] o_r2_data,
	output reg                       o_valid
	);

//
	reg         nxt_req;

// LINE BUFFER I/O 
	reg  [3:0]  lineBuffer_wr;     // line buffer write enables
	reg  [3:0]  lineBuffer_rd;     // line buffer read enables
	//
	wire [(3*DATA_WIDTH-1):0] lB0_rdata;
	wire [(3*DATA_WIDTH-1):0] lB1_rdata;
	wire [(3*DATA_WIDTH-1):0] lB2_rdata;
	wire [(3*DATA_WIDTH-1):0] lB3_rdata;
	//
	reg  [(3*DATA_WIDTH-1):0] lineBuffer0_rdata;
	reg  [(3*DATA_WIDTH-1):0] lineBuffer1_rdata;
	reg  [(3*DATA_WIDTH-1):0] lineBuffer2_rdata;
	reg  [(3*DATA_WIDTH-1):0] lineBuffer3_rdata;


// LINE BUFFER WRITE LOGIC
	reg  [$clog2(LINE_LENGTH)-1:0]  w_pixelCounter; // counts pixels written to single buffer
	reg  [1:0]  w_lineBuffer_sel; // keeps track of buffer to write to
	 
// LINE BUFFER READ LOGIC
    // total fill level of all buffers
	reg  [$clog2(LINE_LENGTH):0] r_fill;        

	// counts pixels read from current buffer      
	reg  [$clog2(LINE_LENGTH)-1:0] r_pixelCounter,      
	                               nxt_r_pixelCounter; 
 	
 	// counts # of lines processed
	reg  [$clog2(LINE_COUNT)-1:0] r_lineCounter,       
	                              nxt_r_lineCounter;
 	
 	// overall buffer read enable
    reg r_lineBuffer_rd_en, nxt_r_lineBuffer_rd_en;      
        
 	
 	// keeps track of 'target' read buffer
    reg  [2:0]  r_lineBuffer_sel, nxt_r_lineBuffer_sel;   
                
 	
 	// FSM
    reg         RSTATE, NEXT_RSTATE;
    localparam  RSTATE_IDLE   = 0,
                RSTATE_ACTIVE = 1;

//
// LINE BUFFER WRITE LOGIC
//
	// count every linebuffer write
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			w_pixelCounter <= 0;
		end 
		else begin
			if(i_valid) begin
				w_pixelCounter <= (w_pixelCounter == LINE_LENGTH-1) ? 0:w_pixelCounter+1;
			end
		end
	end

	// after writing a full line buffer, select the next line buffer
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			w_lineBuffer_sel <= 0;
		end
		else begin
			if( (w_pixelCounter == LINE_LENGTH-1) && (i_valid)) begin
				if(w_lineBuffer_sel == 3) begin
					w_lineBuffer_sel <= 0;
				end
				else begin
					w_lineBuffer_sel <= w_lineBuffer_sel+1;
				end
			end
		end
	end

	// line buffer i/o
	always@* begin
		lineBuffer_wr = 0;
		lineBuffer_wr[w_lineBuffer_sel] = i_valid;
	end

//
// LINE BUFFER READ ENABLE LOGIC 
//
	// keep track of total # of pixels in line buffers
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			r_fill <= 0;
		end
		else begin

			// write and not reading
			if(i_valid && !r_lineBuffer_rd_en) begin
				r_fill <= r_fill + 1;
			end

			// not writing and read
			else if(!i_valid && r_lineBuffer_rd_en) begin
				r_fill <= r_fill - 1;
			end
		end
	end



	// read from line buffers only when three lines are full
	always@* begin
		nxt_req                 = o_req;
		nxt_r_lineBuffer_rd_en  = 0;
		nxt_r_pixelCounter      = r_pixelCounter;
		nxt_r_lineCounter       = r_lineCounter;
		nxt_r_lineBuffer_sel    = r_lineBuffer_sel;
		NEXT_RSTATE             = RSTATE;

		case(RSTATE)

		// RSTATE_IDLE: 
		// If there is 3 lines worth of pixel data present, 
		// begin reading from line buffers
			RSTATE_IDLE: begin
				if(r_fill == (3*LINE_LENGTH)) begin
					nxt_req                 = 0;
					nxt_r_lineBuffer_rd_en  = 1;
					NEXT_RSTATE             = RSTATE_ACTIVE;
				end
				else begin
					nxt_req                = 1;
					nxt_r_lineBuffer_rd_en = 0;
				end
			end

		// RSTATE_ACTIVE:
		// If a line of pixels has been read:
		//    - select next line buffer to read from
		//    - request more data
			RSTATE_ACTIVE: begin
				if(r_pixelCounter >= LINE_LENGTH-1) begin
					nxt_req                 = 1;
					nxt_r_lineBuffer_rd_en  = 0;
					nxt_r_pixelCounter      = 0;
					nxt_r_lineCounter       = (r_lineCounter == LINE_COUNT-1) ? 0:r_lineCounter+1;                               
					nxt_r_lineBuffer_sel    = (r_lineBuffer_sel == 3) ? 0:r_lineBuffer_sel+1;                         
					NEXT_RSTATE             = RSTATE_IDLE;
				end
				else begin
					nxt_req                = 0;
					nxt_r_lineBuffer_rd_en = 1;
					nxt_r_pixelCounter     = r_pixelCounter + 1;
				end
			end
		endcase
	end

	// registers
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			o_req              <= 0;
		 	r_lineBuffer_rd_en <= 0;
		 	r_pixelCounter     <= 0;
		 	r_lineCounter      <= 0;
		 	r_lineBuffer_sel   <= 0;
		 	RSTATE             <= RSTATE_IDLE;
		end 
		else begin
			o_req              <= nxt_req;
			r_lineBuffer_rd_en <= nxt_r_lineBuffer_rd_en;
			r_pixelCounter     <= nxt_r_pixelCounter;
			r_lineCounter      <= nxt_r_lineCounter;
			r_lineBuffer_sel   <= nxt_r_lineBuffer_sel;
			RSTATE             <= NEXT_RSTATE;
		end
	end

//
// LINE BUFFER READ SELECT LOGIC
//
	// assign different data to outputs based on what current row is
	always@* begin
		o_valid       = r_lineBuffer_rd_en;
		lineBuffer_rd = {4{r_lineBuffer_rd_en}};
		o_r0_data     = 0;
		o_r1_data     = 0;
		o_r2_data     = 0;

		// first row of image
		if(r_lineCounter == 0) begin
			lineBuffer_rd[2] = 0;
			lineBuffer_rd[3] = 0;
			o_r0_data        = lineBuffer0_rdata;
			o_r1_data        = lineBuffer0_rdata;
			o_r2_data        = lineBuffer1_rdata;
		end

		// last row of image
		else begin
			case(r_lineBuffer_sel)

				0: begin
					lineBuffer_rd[2] = 0;
					o_r0_data        = lineBuffer3_rdata;
					o_r1_data        = lineBuffer0_rdata;
					o_r2_data        = lineBuffer1_rdata;
				end
	
				1: begin
					lineBuffer_rd[3] = 0;
					o_r0_data        = lineBuffer0_rdata;
					o_r1_data        = lineBuffer1_rdata;
					o_r2_data        = lineBuffer2_rdata;
				end
	
				2: begin
					lineBuffer_rd[0] = 0;
					o_r0_data        = lineBuffer1_rdata;
					o_r1_data        = lineBuffer2_rdata;
					o_r2_data        = lineBuffer3_rdata;
				end
	
				3: begin
					lineBuffer_rd[1] = 0;
					o_r0_data        = lineBuffer2_rdata;
					o_r1_data        = lineBuffer3_rdata;
					o_r2_data        = lineBuffer0_rdata;
				end
			endcase
		end
	end

	localparam WORD3_INDEX = 2*DATA_WIDTH;

// Output Combinatorial logic
	always@* begin
		case(r_pixelCounter)
			default: begin
				lineBuffer0_rdata = lB0_rdata;
				lineBuffer1_rdata = lB1_rdata;
				lineBuffer2_rdata = lB2_rdata;
				lineBuffer3_rdata = lB3_rdata;
			end

			// catch the beginning of each row
			0: begin
				lineBuffer0_rdata = { {2{lB0_rdata[DATA_WIDTH+:DATA_WIDTH]}}, 
				                       lB0_rdata[0+:DATA_WIDTH]};

				lineBuffer1_rdata = { {2{lB1_rdata[DATA_WIDTH+:DATA_WIDTH]}}, 
				                       lB1_rdata[0+:DATA_WIDTH]};

				lineBuffer2_rdata = { {2{lB2_rdata[DATA_WIDTH+:DATA_WIDTH]}}, 
				                       lB2_rdata[0+:DATA_WIDTH]};

				lineBuffer3_rdata = { {2{lB3_rdata[DATA_WIDTH+:DATA_WIDTH]}}, 
				                       lB3_rdata[0+:DATA_WIDTH]};
			end

			// catch end of each row
			(LINE_LENGTH-1): begin
				lineBuffer0_rdata = { lB0_rdata[(2*DATA_WIDTH)+:DATA_WIDTH], 
				                    {2{lB0_rdata[DATA_WIDTH+:DATA_WIDTH]}} };

				lineBuffer1_rdata = { lB1_rdata[(2*DATA_WIDTH)+:DATA_WIDTH], 
				                    {2{lB1_rdata[DATA_WIDTH+:DATA_WIDTH]}} };

				lineBuffer2_rdata = { lB2_rdata[(2*DATA_WIDTH)+:DATA_WIDTH], 
				                    {2{lB2_rdata[DATA_WIDTH+:DATA_WIDTH]}} };

				lineBuffer3_rdata = { lB3_rdata[(2*DATA_WIDTH)+:DATA_WIDTH], 
				                    {2{lB3_rdata[DATA_WIDTH+:DATA_WIDTH]}} };
			end
		endcase
	end

	kp_linebuffer
	#(.LINE_LENGTH(LINE_LENGTH),
	  .DATA_WIDTH (DATA_WIDTH)) 
	LINEBUF0_i (
	.i_clk   (i_clk             ), 
	.i_rstn  (i_rstn            ), // sync active low reset
  
	.i_wr    (lineBuffer_wr[0]  ), // write enable
	.i_wdata (i_data            ), // 8-bit write data

	.i_rd    (lineBuffer_rd[0]  ), // read enable
	.o_rdata (lB0_rdata )          // 3 pixels of read data
	);

	kp_linebuffer
	#(.LINE_LENGTH(LINE_LENGTH),
	  .DATA_WIDTH (DATA_WIDTH)) 
	LINEBUF1_i (
	.i_clk   (i_clk             ), 
	.i_rstn  (i_rstn            ), // sync active low reset
  
	.i_wr    (lineBuffer_wr[1]  ), // write enable
	.i_wdata (i_data            ), // 8-bit write data

	.i_rd    (lineBuffer_rd[1]  ), // read enable
	.o_rdata (lB1_rdata )          // 3 pixels of read data
	);

	kp_linebuffer
	#(.LINE_LENGTH(LINE_LENGTH),
	  .DATA_WIDTH (DATA_WIDTH)) 
	LINEBUF2_i (
	.i_clk   (i_clk             ), 
	.i_rstn  (i_rstn            ), // sync active low reset
  
	.i_wr    (lineBuffer_wr[2]  ), // write enable
	.i_wdata (i_data            ), // 8-bit write data

	.i_rd    (lineBuffer_rd[2]  ), // read enable
	.o_rdata (lB2_rdata )          // 3 pixels of read data
	);

	kp_linebuffer
	#(.LINE_LENGTH(LINE_LENGTH),
	  .DATA_WIDTH (DATA_WIDTH)) 
	LINEBUF3_i (
	.i_clk   (i_clk             ), 
	.i_rstn  (i_rstn            ), // sync active low reset
  
	.i_wr    (lineBuffer_wr[3]  ), // write enable
	.i_wdata (i_data            ), // 8-bit write data

	.i_rd    (lineBuffer_rd[3]  ), // read enable
	.o_rdata (lB3_rdata )          // 3 pixels of read data
	);

	


endmodule