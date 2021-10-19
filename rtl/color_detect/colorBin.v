// module: colorBin
//
//
module colorBin
	`include "colorDetect_definitions.vh"
	(
    input  wire        i_clk,
    input  wire        i_rstn,

    input  wire [17:0] i_addr,
    input  wire [15:0] i_hue,
    input  wire [15:0] i_sat,
    input  wire [15:0] i_value,
    input  wire        i_valid,

    output reg  [2:0]  o_color0,
    output reg  [2:0]  o_color1,
    output reg  [2:0]  o_color2,
    output reg  [2:0]  o_color3,
    output reg  [2:0]  o_color4,
    output reg  [2:0]  o_color5,
    output reg  [2:0]  o_color6,
    output reg  [2:0]  o_color7,
    output reg  [2:0]  o_color8
	);
//
	localparam RES_X = 480;
	localparam RES_Y = 480;
	reg [9:0] counterX, counterY;
	integer i;
//
// [0] -> red
// [1] -> orange
// [2] -> yellow
// [3] -> green
// [4] -> blue
// [5] -> white
// [6] -> other
	reg [14:0] color0 [0:6];
	reg [14:0] color1 [0:6];
	reg [14:0] color2 [0:6];
	reg [14:0] color3 [0:6];
	reg [14:0] color4 [0:6];
	reg [14:0] color5 [0:6];
	reg [14:0] color6 [0:6];
	reg [14:0] color7 [0:6];
	reg [14:0] color8 [0:6];

	reg red, orange, yellow, green, blue, white, other;

// Coordinate Counters
	always@(posedge i_clk) begin
		if((!i_rstn)||(i_addr == 230399)) begin
			counterX <= 0;
			counterY <= 0;
		end
		else begin
			if(i_valid) begin
				counterX <= (counterX==479) ? 0:counterX+1;
				if(counterX==479) begin
					counterY <= (counterY==479) ? 0:counterY+1;
				end
			end
		end
	end

//
	always@* begin
		red    = 0;
		orange = 0;
		yellow = 0;
		green  = 0;
		blue   = 0;
		white  = 0;
		other  = 0;

		if((i_value[15:6]>10)&&
		       ((i_hue[15:6]>140)||(i_hue[15:6]<280))&&
		       ( i_sat[15:6]>50)) begin
			blue = 1;
		end

		else if((i_value[15:6]>10)&&
		       ((i_hue[15:6]>75)||(i_hue[15:6]<140))&&
		       ( i_sat[15:6]>50)) begin
			green = 1;
		end

		else if(i_sat[15:6]<10) begin
			white = 1;
		end

		else if((i_value[15:6]>10)&&
		       ((i_hue[15:6]>15)||(i_hue[15:6]<75))&&
		       ( i_sat[15:6]>50)) begin
			yellow = 1;
		end

		if((i_value[15:6]>10)&&
		   ((i_hue[15:6]>325)||(i_hue[15:6]<10))&&
		    (i_sat[15:6]>50)) begin
			red = 1;
		end
		else if((i_value[15:6]>10)&&
		       ((i_hue[15:6]>10)||(i_hue[15:6]<15))&&
		       ( i_sat[15:6]>90)) begin
			orange = 1;
		end

		else begin
			other = 1;
		end
	end

//
	always@(posedge i_clk) begin
		if((!i_rstn)||((counterX==479)&&(counterY==479))) begin
			for(i=0; i<7; i=i+1) begin
				color0[i] <= 0;
				color1[i] <= 0;
				color2[i] <= 0;
				color3[i] <= 0;
				color4[i] <= 0;
				color5[i] <= 0;
				color6[i] <= 0;
				color7[i] <= 0;
				color8[i] <= 0;
			end
		end
		else if(i_valid) begin
			//
			if((counterX>=0)&&(counterX<156)&&(counterY>=0)&&(counterY<156)) begin
				if(red)         color0[0] <= color0[0]+1;
				else if(orange) color0[1] <= color0[1]+1;
				else if(yellow) color0[2] <= color0[2]+1;
				else if(green)  color0[3] <= color0[3]+1;
				else if(blue)   color0[4] <= color0[4]+1;
				else if(white)  color0[5] <= color0[5]+1;
				else            color0[6] <= color0[6]+1;
			end

			//
			else if((counterX>=164)&&(counterX<316)&&(counterY>=0)&&(counterY<156)) begin
				if(red)         color1[0] <= color1[0]+1;
				else if(orange) color1[1] <= color1[1]+1;
				else if(yellow) color1[2] <= color1[2]+1;
				else if(green)  color1[3] <= color1[3]+1;
				else if(blue)   color1[4] <= color1[4]+1;
				else if(white)  color1[5] <= color1[5]+1;
				else            color1[6] <= color1[6]+1;
			end

			//
			else if((counterX>=324)&&(counterX<476)&&(counterY>=0)&&(counterY<156)) begin
				if(red)         color2[0] <= color2[0]+1;
				else if(orange) color2[1] <= color2[1]+1;
				else if(yellow) color2[2] <= color2[2]+1;
				else if(green)  color2[3] <= color2[3]+1;
				else if(blue)   color2[4] <= color2[4]+1;
				else if(white)  color2[5] <= color2[5]+1;
				else            color2[6] <= color2[6]+1;
			end

			//
			if((counterX>=0)&&(counterX<156)&&(counterY>=164)&&(counterY<316)) begin
				if(red)         color3[0] <= color3[0]+1;
				else if(orange) color3[1] <= color3[1]+1;
				else if(yellow) color3[2] <= color3[2]+1;
				else if(green)  color3[3] <= color3[3]+1;
				else if(blue)   color3[4] <= color3[4]+1;
				else if(white)  color3[5] <= color3[5]+1;
				else            color3[6] <= color3[6]+1;
			end

			//
			else if((counterX>=164)&&(counterX<316)&&(counterY>=164)&&(counterY<316)) begin
				if(red)         color4[0] <= color4[0]+1;
				else if(orange) color4[1] <= color4[1]+1;
				else if(yellow) color4[2] <= color4[2]+1;
				else if(green)  color4[3] <= color4[3]+1;
				else if(blue)   color4[4] <= color4[4]+1;
				else if(white)  color4[5] <= color4[5]+1;
				else            color4[6] <= color4[6]+1;
			end

			//
			else if((counterX>=324)&&(counterX<476)&&(counterY>=164)&&(counterY<316)) begin
				if(red)         color5[0] <= color5[0]+1;
				else if(orange) color5[1] <= color5[1]+1;
				else if(yellow) color5[2] <= color5[2]+1;
				else if(green)  color5[3] <= color5[3]+1;
				else if(blue)   color5[4] <= color5[4]+1;
				else if(white)  color5[5] <= color5[5]+1;
				else            color5[6] <= color5[6]+1;
			end

			//
			if((counterX>=0)&&(counterX<156)&&(counterY>=324)&&(counterY<476)) begin
				if(red)         color6[0] <= color6[0]+1;
				else if(orange) color6[1] <= color6[1]+1;
				else if(yellow) color6[2] <= color6[2]+1;
				else if(green)  color6[3] <= color6[3]+1;
				else if(blue)   color6[4] <= color6[4]+1;
				else if(white)  color6[5] <= color6[5]+1;
				else            color6[6] <= color6[6]+1;
			end

			//
			else if((counterX>=164)&&(counterX<316)&&(counterY>=324)&&(counterY<476)) begin
				if(red)         color7[0] <= color7[0]+1;
				else if(orange) color7[1] <= color7[1]+1;
				else if(yellow) color7[2] <= color7[2]+1;
				else if(green)  color7[3] <= color7[3]+1;
				else if(blue)   color7[4] <= color7[4]+1;
				else if(white)  color7[5] <= color7[5]+1;
				else            color7[6] <= color7[6]+1;
			end

			//
			else if((counterX>=324)&&(counterX<476)&&(counterY>=324)&&(counterY<476)) begin
				if(red)         color8[0] <= color8[0]+1;
				else if(orange) color8[1] <= color8[1]+1;
				else if(yellow) color8[2] <= color8[2]+1;
				else if(green)  color8[3] <= color8[3]+1;
				else if(blue)   color8[4] <= color8[4]+1;
				else if(white)  color8[5] <= color8[5]+1;
				else            color8[6] <= color8[6]+1;
			end
		end
	end

	//
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			o_color0 <= 0;
		end
		else if((counterX==478)&&(counterY==479)) begin
			if( (color0[0]>=color0[1]) && (color0[0]>=color0[2]) &&
			    (color0[0]>=color0[3]) && (color0[0]>=color0[4]) &&
			    (color0[0]>=color0[5]) && (color0[0]>=color0[6])) begin
				o_color0 <= `DT_RED;
			end

			else if( (color0[1]>=color0[0]) && (color0[1]>=color0[2]) &&
			         (color0[1]>=color0[3]) && (color0[1]>=color0[4]) &&
			         (color0[1]>=color0[5]) && (color0[1]>=color0[6])) begin
				o_color0 <= `DT_ORNGE;
			end

			else if( (color0[2]>=color0[0]) && (color0[2]>=color0[1]) &&
			         (color0[2]>=color0[3]) && (color0[2]>=color0[4]) &&
			         (color0[2]>=color0[5]) && (color0[2]>=color0[6])) begin
				o_color0 <= `DT_YLLW;
			end

			else if( (color0[3]>=color0[0]) && (color0[3]>=color0[1]) &&
			         (color0[3]>=color0[2]) && (color0[3]>=color0[4]) &&
			         (color0[3]>=color0[5]) && (color0[3]>=color0[6])) begin
				o_color0 <= `DT_GRN;
			end

			else if( (color0[4]>=color0[0]) && (color0[4]>=color0[1]) &&
			         (color0[4]>=color0[2]) && (color0[4]>=color0[3]) &&
			         (color0[4]>=color0[5]) && (color0[4]>=color0[6])) begin
				o_color0 <= `DT_GRN;
			end

			else if( (color0[5]>=color0[0]) && (color0[5]>=color0[1]) &&
			         (color0[5]>=color0[2]) && (color0[5]>=color0[3]) &&
			         (color0[5]>=color0[4]) && (color0[5]>=color0[6])) begin
				o_color0 <= `DT_BLU;
			end

			else if( (color0[6]>=color0[0]) && (color0[6]>=color0[1]) &&
			         (color0[6]>=color0[2]) && (color0[6]>=color0[3]) &&
			         (color0[6]>=color0[4]) && (color0[6]>=color0[5])) begin
				o_color0 <= `DT_WHT;
			end

			else begin
				o_color0 <= 0;
			end
		end
	end

//
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			o_color1 <= 0;
		end
		else if((counterX==478)&&(counterY==479)) begin
			if( (color1[0]>=color1[1]) && (color1[0]>=color1[2]) &&
			    (color1[0]>=color1[3]) && (color1[0]>=color1[4]) &&
			    (color1[0]>=color1[5]) && (color1[0]>=color1[6])) begin
				o_color1 <= `DT_RED;
			end

			else if( (color1[1]>=color1[0]) && (color1[1]>=color1[2]) &&
			         (color1[1]>=color1[3]) && (color1[1]>=color1[4]) &&
			         (color1[1]>=color1[5]) && (color1[1]>=color1[6])) begin
				o_color1 <= `DT_ORNGE;
			end

			else if( (color1[2]>=color1[0]) && (color1[2]>=color1[1]) &&
			         (color1[2]>=color1[3]) && (color1[2]>=color1[4]) &&
			         (color1[2]>=color1[5]) && (color1[2]>=color1[6])) begin
				o_color1 <= `DT_YLLW;
			end

			else if( (color1[3]>=color1[0]) && (color1[3]>=color1[1]) &&
			         (color1[3]>=color1[2]) && (color1[3]>=color1[4]) &&
			         (color1[3]>=color1[5]) && (color1[3]>=color1[6])) begin
				o_color1 <= `DT_GRN;
			end

			else if( (color1[4]>=color1[0]) && (color1[4]>=color1[1]) &&
			         (color1[4]>=color1[2]) && (color1[4]>=color1[3]) &&
			         (color1[4]>=color1[5]) && (color1[4]>=color1[6])) begin
				o_color1 <= `DT_GRN;
			end

			else if( (color1[5]>=color1[0]) && (color1[5]>=color1[1]) &&
			         (color1[5]>=color1[2]) && (color1[5]>=color1[3]) &&
			         (color1[5]>=color1[4]) && (color1[5]>=color1[6])) begin
				o_color1 <= `DT_BLU;
			end

			else if( (color1[6]>=color1[0]) && (color1[6]>=color1[1]) &&
			         (color1[6]>=color1[2]) && (color1[6]>=color1[3]) &&
			         (color1[6]>=color1[4]) && (color1[6]>=color1[5])) begin
				o_color1 <= `DT_WHT;
			end

			else begin
				o_color1 <= 0;
			end
		end
	end

//
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			o_color2 <= 0;
		end
		else if((counterX==478)&&(counterY==479)) begin
			if( (color2[0]>=color2[1]) && (color2[0]>=color2[2]) &&
			    (color2[0]>=color2[3]) && (color2[0]>=color2[4]) &&
			    (color2[0]>=color2[5]) && (color2[0]>=color2[6])) begin
				o_color2 <= `DT_RED;
			end

			else if( (color2[1]>=color2[0]) && (color2[1]>=color2[2]) &&
			         (color2[1]>=color2[3]) && (color2[1]>=color2[4]) &&
			         (color2[1]>=color2[5]) && (color2[1]>=color2[6])) begin
				o_color2 <= `DT_ORNGE;
			end

			else if( (color2[2]>=color2[0]) && (color2[2]>=color2[1]) &&
			         (color2[2]>=color2[3]) && (color2[2]>=color2[4]) &&
			         (color2[2]>=color2[5]) && (color2[2]>=color2[6])) begin
				o_color2 <= `DT_YLLW;
			end

			else if( (color2[3]>=color2[0]) && (color2[3]>=color2[1]) &&
			         (color2[3]>=color2[2]) && (color2[3]>=color2[4]) &&
			         (color2[3]>=color2[5]) && (color2[3]>=color2[6])) begin
				o_color2 <= `DT_GRN;
			end

			else if( (color2[4]>=color2[0]) && (color2[4]>=color2[1]) &&
			         (color2[4]>=color2[2]) && (color2[4]>=color2[3]) &&
			         (color2[4]>=color2[5]) && (color2[4]>=color2[6])) begin
				o_color2 <= `DT_GRN;
			end

			else if( (color2[5]>=color2[0]) && (color2[5]>=color2[1]) &&
			         (color2[5]>=color2[2]) && (color2[5]>=color2[3]) &&
			         (color2[5]>=color2[4]) && (color2[5]>=color2[6])) begin
				o_color2 <= `DT_BLU;
			end

			else if( (color2[6]>=color2[0]) && (color2[6]>=color2[1]) &&
			         (color2[6]>=color2[2]) && (color2[6]>=color2[3]) &&
			         (color2[6]>=color2[4]) && (color2[6]>=color2[5])) begin
				o_color2 <= `DT_WHT;
			end

			else begin
				o_color2 <= 0;
			end
		end
	end

//
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			o_color3 <= 0;
		end
		else if((counterX==478)&&(counterY==479)) begin
			if( (color3[0]>=color3[1]) && (color3[0]>=color3[2]) &&
			    (color3[0]>=color3[3]) && (color3[0]>=color3[4]) &&
			    (color3[0]>=color3[5]) && (color3[0]>=color3[6])) begin
				o_color3 <= `DT_RED;
			end

			else if( (color3[1]>=color3[0]) && (color3[1]>=color3[2]) &&
			         (color3[1]>=color3[3]) && (color3[1]>=color3[4]) &&
			         (color3[1]>=color3[5]) && (color3[1]>=color3[6])) begin
				o_color3 <= `DT_ORNGE;
			end

			else if( (color3[2]>=color3[0]) && (color3[2]>=color3[1]) &&
			         (color3[2]>=color3[3]) && (color3[2]>=color3[4]) &&
			         (color3[2]>=color3[5]) && (color3[2]>=color3[6])) begin
				o_color3 <= `DT_YLLW;
			end

			else if( (color3[3]>=color3[0]) && (color3[3]>=color3[1]) &&
			         (color3[3]>=color3[2]) && (color3[3]>=color3[4]) &&
			         (color3[3]>=color3[5]) && (color3[3]>=color3[6])) begin
				o_color3 <= `DT_GRN;
			end

			else if( (color3[4]>=color3[0]) && (color3[4]>=color3[1]) &&
			         (color3[4]>=color3[2]) && (color3[4]>=color3[3]) &&
			         (color3[4]>=color3[5]) && (color3[4]>=color3[6])) begin
				o_color3 <= `DT_GRN;
			end

			else if( (color3[5]>=color3[0]) && (color3[5]>=color3[1]) &&
			         (color3[5]>=color3[2]) && (color3[5]>=color3[3]) &&
			         (color3[5]>=color3[4]) && (color3[5]>=color3[6])) begin
				o_color3 <= `DT_BLU;
			end

			else if( (color3[6]>=color3[0]) && (color3[6]>=color3[1]) &&
			         (color3[6]>=color3[2]) && (color3[6]>=color3[3]) &&
			         (color3[6]>=color3[4]) && (color3[6]>=color3[5])) begin
				o_color3 <= `DT_WHT;
			end

			else begin
				o_color3 <= 0;
			end
		end
	end

//
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			o_color4 <= 0;
		end
		else if((counterX==478)&&(counterY==479)) begin
			if( (color4[0]>=color4[1]) && (color4[0]>=color4[2]) &&
			    (color4[0]>=color4[3]) && (color4[0]>=color4[4]) &&
			    (color4[0]>=color4[5]) && (color4[0]>=color4[6])) begin
				o_color4 <= `DT_RED;
			end

			else if( (color4[1]>=color4[0]) && (color4[1]>=color4[2]) &&
			         (color4[1]>=color4[3]) && (color4[1]>=color4[4]) &&
			         (color4[1]>=color4[5]) && (color4[1]>=color4[6])) begin
				o_color4 <= `DT_ORNGE;
			end

			else if( (color4[2]>=color4[0]) && (color4[2]>=color4[1]) &&
			         (color4[2]>=color4[3]) && (color4[2]>=color4[4]) &&
			         (color4[2]>=color4[5]) && (color4[2]>=color4[6])) begin
				o_color4 <= `DT_YLLW;
			end

			else if( (color4[3]>=color4[0]) && (color4[3]>=color4[1]) &&
			         (color4[3]>=color4[2]) && (color4[3]>=color4[4]) &&
			         (color4[3]>=color4[5]) && (color4[3]>=color4[6])) begin
				o_color4 <= `DT_GRN;
			end

			else if( (color4[4]>=color4[0]) && (color4[4]>=color4[1]) &&
			         (color4[4]>=color4[2]) && (color4[4]>=color4[3]) &&
			         (color4[4]>=color4[5]) && (color4[4]>=color4[6])) begin
				o_color4 <= `DT_GRN;
			end

			else if( (color4[5]>=color4[0]) && (color4[5]>=color4[1]) &&
			         (color4[5]>=color4[2]) && (color4[5]>=color4[3]) &&
			         (color4[5]>=color4[4]) && (color4[5]>=color4[6])) begin
				o_color4 <= `DT_BLU;
			end

			else if( (color4[6]>=color4[0]) && (color4[6]>=color4[1]) &&
			         (color4[6]>=color4[2]) && (color4[6]>=color4[3]) &&
			         (color4[6]>=color4[4]) && (color4[6]>=color4[5])) begin
				o_color4 <= `DT_WHT;
			end

			else begin
				o_color4 <= 0;
			end
		end
	end

//
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			o_color5 <= 0;
		end
		else if((counterX==478)&&(counterY==479)) begin
			if( (color5[0]>=color5[1]) && (color5[0]>=color5[2]) &&
			    (color5[0]>=color5[3]) && (color5[0]>=color5[4]) &&
			    (color5[0]>=color5[5]) && (color5[0]>=color5[6])) begin
				o_color5 <= `DT_RED;
			end

			else if( (color5[1]>=color5[0]) && (color5[1]>=color5[2]) &&
			         (color5[1]>=color5[3]) && (color5[1]>=color5[4]) &&
			         (color5[1]>=color5[5]) && (color5[1]>=color5[6])) begin
				o_color5 <= `DT_ORNGE;
			end

			else if( (color5[2]>=color5[0]) && (color5[2]>=color5[1]) &&
			         (color5[2]>=color5[3]) && (color5[2]>=color5[4]) &&
			         (color5[2]>=color5[5]) && (color5[2]>=color5[6])) begin
				o_color5 <= `DT_YLLW;
			end

			else if( (color5[3]>=color5[0]) && (color5[3]>=color5[1]) &&
			         (color5[3]>=color5[2]) && (color5[3]>=color5[4]) &&
			         (color5[3]>=color5[5]) && (color5[3]>=color5[6])) begin
				o_color5 <= `DT_GRN;
			end

			else if( (color5[4]>=color5[0]) && (color5[4]>=color5[1]) &&
			         (color5[4]>=color5[2]) && (color5[4]>=color5[3]) &&
			         (color5[4]>=color5[5]) && (color5[4]>=color5[6])) begin
				o_color5 <= `DT_GRN;
			end

			else if( (color5[5]>=color5[0]) && (color5[5]>=color5[1]) &&
			         (color5[5]>=color5[2]) && (color5[5]>=color5[3]) &&
			         (color5[5]>=color5[4]) && (color5[5]>=color5[6])) begin
				o_color5 <= `DT_BLU;
			end

			else if( (color5[6]>=color5[0]) && (color5[6]>=color5[1]) &&
			         (color5[6]>=color5[2]) && (color5[6]>=color5[3]) &&
			         (color5[6]>=color5[4]) && (color5[6]>=color5[5])) begin
				o_color5 <= `DT_WHT;
			end

			else begin
				o_color5 <= 0;
			end
		end
	end

//
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			o_color6 <= 0;
		end
		else if((counterX==478)&&(counterY==479)) begin
			if( (color6[0]>=color6[1]) && (color6[0]>=color6[2]) &&
			    (color6[0]>=color6[3]) && (color6[0]>=color6[4]) &&
			    (color6[0]>=color6[5]) && (color6[0]>=color6[6])) begin
				o_color6 <= `DT_RED;
			end

			else if( (color6[1]>=color6[0]) && (color6[1]>=color6[2]) &&
			         (color6[1]>=color6[3]) && (color6[1]>=color6[4]) &&
			         (color6[1]>=color6[5]) && (color6[1]>=color6[6])) begin
				o_color6 <= `DT_ORNGE;
			end

			else if( (color6[2]>=color6[0]) && (color6[2]>=color6[1]) &&
			         (color6[2]>=color6[3]) && (color6[2]>=color6[4]) &&
			         (color6[2]>=color6[5]) && (color6[2]>=color6[6])) begin
				o_color6 <= `DT_YLLW;
			end

			else if( (color6[3]>=color6[0]) && (color6[3]>=color6[1]) &&
			         (color6[3]>=color6[2]) && (color6[3]>=color6[4]) &&
			         (color6[3]>=color6[5]) && (color6[3]>=color6[6])) begin
				o_color6 <= `DT_GRN;
			end

			else if( (color6[4]>=color6[0]) && (color6[4]>=color6[1]) &&
			         (color6[4]>=color6[2]) && (color6[4]>=color6[3]) &&
			         (color6[4]>=color6[5]) && (color6[4]>=color6[6])) begin
				o_color6 <= `DT_GRN;
			end

			else if( (color6[5]>=color6[0]) && (color6[5]>=color6[1]) &&
			         (color6[5]>=color6[2]) && (color6[5]>=color6[3]) &&
			         (color6[5]>=color6[4]) && (color6[5]>=color6[6])) begin
				o_color6 <= `DT_BLU;
			end

			else if( (color6[6]>=color6[0]) && (color6[6]>=color6[1]) &&
			         (color6[6]>=color6[2]) && (color6[6]>=color6[3]) &&
			         (color6[6]>=color6[4]) && (color6[6]>=color6[5])) begin
				o_color6 <= `DT_WHT;
			end

			else begin
				o_color6 <= 0;
			end
		end
	end

//
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			o_color7 <= 0;
		end
		else if((counterX==478)&&(counterY==479)) begin
			if( (color7[0]>=color7[1]) && (color7[0]>=color7[2]) &&
			    (color7[0]>=color7[3]) && (color7[0]>=color7[4]) &&
			    (color7[0]>=color7[5]) && (color7[0]>=color7[6])) begin
				o_color7 <= `DT_RED;
			end

			else if( (color7[1]>=color7[0]) && (color7[1]>=color7[2]) &&
			         (color7[1]>=color7[3]) && (color7[1]>=color7[4]) &&
			         (color7[1]>=color7[5]) && (color7[1]>=color7[6])) begin
				o_color7 <= `DT_ORNGE;
			end

			else if( (color7[2]>=color7[0]) && (color7[2]>=color7[1]) &&
			         (color7[2]>=color7[3]) && (color7[2]>=color7[4]) &&
			         (color7[2]>=color7[5]) && (color7[2]>=color7[6])) begin
				o_color7 <= `DT_YLLW;
			end

			else if( (color7[3]>=color7[0]) && (color7[3]>=color7[1]) &&
			         (color7[3]>=color7[2]) && (color7[3]>=color7[4]) &&
			         (color7[3]>=color7[5]) && (color7[3]>=color7[6])) begin
				o_color7 <= `DT_GRN;
			end

			else if( (color7[4]>=color7[0]) && (color7[4]>=color7[1]) &&
			         (color7[4]>=color7[2]) && (color7[4]>=color7[3]) &&
			         (color7[4]>=color7[5]) && (color7[4]>=color7[6])) begin
				o_color7 <= `DT_GRN;
			end

			else if( (color7[5]>=color7[0]) && (color7[5]>=color7[1]) &&
			         (color7[5]>=color7[2]) && (color7[5]>=color7[3]) &&
			         (color7[5]>=color7[4]) && (color7[5]>=color7[6])) begin
				o_color7 <= `DT_BLU;
			end

			else if( (color7[6]>=color7[0]) && (color7[6]>=color7[1]) &&
			         (color7[6]>=color7[2]) && (color7[6]>=color7[3]) &&
			         (color7[6]>=color7[4]) && (color7[6]>=color7[5])) begin
				o_color7 <= `DT_WHT;
			end

			else begin
				o_color7 <= 0;
			end
		end
	end

//
	always@(posedge i_clk) begin
		if(!i_rstn) begin
			o_color8 <= 0;
		end
		else if((counterX==478)&&(counterY==479)) begin
			if( (color8[0]>=color8[1]) && (color8[0]>=color8[2]) &&
			    (color8[0]>=color8[3]) && (color8[0]>=color8[4]) &&
			    (color8[0]>=color8[5]) && (color8[0]>=color8[6])) begin
				o_color8 <= `DT_RED;
			end

			else if( (color8[1]>=color8[0]) && (color8[1]>=color8[2]) &&
			         (color8[1]>=color8[3]) && (color8[1]>=color8[4]) &&
			         (color8[1]>=color8[5]) && (color8[1]>=color8[6])) begin
				o_color8 <= `DT_ORNGE;
			end

			else if( (color8[2]>=color8[0]) && (color8[2]>=color8[1]) &&
			         (color8[2]>=color8[3]) && (color8[2]>=color8[4]) &&
			         (color8[2]>=color8[5]) && (color8[2]>=color8[6])) begin
				o_color8 <= `DT_YLLW;
			end

			else if( (color8[3]>=color8[0]) && (color8[3]>=color8[1]) &&
			         (color8[3]>=color8[2]) && (color8[3]>=color8[4]) &&
			         (color8[3]>=color8[5]) && (color8[3]>=color8[6])) begin
				o_color8 <= `DT_GRN;
			end

			else if( (color8[4]>=color8[0]) && (color8[4]>=color8[1]) &&
			         (color8[4]>=color8[2]) && (color8[4]>=color8[3]) &&
			         (color8[4]>=color8[5]) && (color8[4]>=color8[6])) begin
				o_color8 <= `DT_GRN;
			end

			else if( (color8[5]>=color8[0]) && (color8[5]>=color8[1]) &&
			         (color8[5]>=color8[2]) && (color8[5]>=color8[3]) &&
			         (color8[5]>=color8[4]) && (color8[5]>=color8[6])) begin
				o_color8 <= `DT_BLU;
			end

			else if( (color8[6]>=color8[0]) && (color8[6]>=color8[1]) &&
			         (color8[6]>=color8[2]) && (color8[6]>=color8[3]) &&
			         (color8[6]>=color8[4]) && (color8[6]>=color8[5])) begin
				o_color8 <= `DT_WHT;
			end

			else begin
				o_color8 <= 0;
			end
		end
	end


endmodule