// module: hue_stage0
//
// This module compares RGB values and selects the correct function
// depending on which is the greatest, then generates the divisor
// and dividend for the next stage.
//
module hue_stage0
	(
    input  wire        i_clk,
    input  wire        i_rstn, 

    // data input interface
    input  wire [15:0] i_data,           // input RGB565 data
    input  wire        i_valid,          // input data valid

    // output to divider generator IP
    output reg  [8:0]  o_dividend,       // dividend
    output reg  [8:0]  o_divisor,        // divisor 
    output reg         o_valid,          // valid flag
    output reg  [1:0]  o_function        // indicates greatest RGB value
	);

// 

/*
	wire [8:0] red   = {1'b0, i_data[4:0],   3'b0}; // insert sign bit, pad 
	wire [8:0] green = {1'b0, i_data[10:5],  2'b0};
	wire [8:0] blue  = {1'b0, i_data[15:11], 3'b0};
*/
	wire [8:0] red   = {1'b0, i_data[15:11],   3'b0}; // insert sign bit, pad 
	wire [8:0] green = {1'b0, i_data[10:5],  2'b0};
	wire [8:0] blue  = {1'b0, i_data[4:0], 3'b0};

	reg [8:0] nxt_dividend, nxt_divisor;
	reg       nxt_valid;
	reg [1:0] nxt_function;


// Next-State Logic
	always@* begin
		nxt_valid    = 0;
		nxt_dividend = o_dividend;
		nxt_divisor  = o_divisor;
		nxt_function = 0;

		if(i_valid) begin
			nxt_valid = 1;

		// Greatest: Red
			if((red >= green)&&(red >= blue)) begin
				nxt_function = 1;
				nxt_dividend = $signed(green)-$signed(blue);
				if(green > blue) nxt_divisor = $signed(red)-$signed(blue);
				else             nxt_divisor = $signed(red)-$signed(green);
			end

		// Greatest: Green
			else if((green >= red)&&(green >= blue)) begin
				nxt_function = 2;
				nxt_dividend = $signed(blue) - $signed(red);
				if(blue > red) nxt_divisor = $signed(green)-$signed(red);
				else           nxt_divisor = $signed(green)-$signed(blue);
			end

		// Greatest: Blue
			else begin
				nxt_function = 3;
				nxt_dividend = $signed(red) - $signed(green);
				if(red > green) nxt_divisor = $signed(blue)-$signed(green);
				else            nxt_divisor = $signed(blue)-$signed(red);
			end
		end
	end

// Registered Logic
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			o_valid    <= 0;
			o_dividend <= 0;
			o_divisor  <= 0;
			o_function <= 0;
		end
		else begin
			o_valid    <= nxt_valid;
			o_dividend <= nxt_dividend;
			o_divisor  <= nxt_divisor;
			o_function <= nxt_function;
		end
	end


endmodule