// module: hue_stage2
//
// This module adds a constant depending on the input function.
// It then multiplies by 60, returning the hue of the input RGB pixel.
//
module hue_stage2
	(
	input  wire i_clk,
	input  wire i_rstn,

	input  wire [15:0] i_data,
	input  wire [1:0]  i_function,
	input  wire        i_valid,

	output reg  [15:0] o_data,
	output reg         o_valid
	);

	localparam MULT_CONST = 15'h0F00; // fixed-point 60.0
	localparam FP_120     = 15'h1E00; // fixed-point 120.0
	localparam FP_240     = 15'h3C00; // fixed-point 240.0
	localparam FP_360     = 15'h5A00; // fixed-point 360.0

	reg  [31:0] temp;

	always@* begin
		if(i_valid) begin
			temp = (i_data[14:0] * MULT_CONST)>>6;
		end
	end

	always@(posedge i_clk) begin
		if(!i_rstn) begin
			o_valid <= 0;
			o_data  <= 0;
		end
		else begin
			o_valid <= (i_valid);
			if(i_data[15]) begin
				case(i_function)
					1: begin
						o_data <= {1'b1, temp[14:0]}+FP_360;
					end
					2: begin
						if($signed({1'b1, temp[14:0]}+FP_120)<0) begin
							o_data <= {1'b1, temp[14:0]}+FP_120+FP_360;
						end 
						else begin
							o_data <= {1'b1, temp[14:0]}+FP_120;
						end
					end
					3: begin
						if($signed({1'b1, temp[14:0]}+FP_240)<0) begin
							o_data <= {1'b1, temp[14:0]}+FP_240+FP_360;
						end 
						else begin
							o_data <= {1'b1, temp[14:0]}+FP_240;
						end
					end
					default: o_data <= 0;
				endcase 
			end
			else begin
				case(i_function)
					1: begin
						if(temp>FP_360) o_data <= temp-FP_360;
						else            o_data <= temp;
					end
					2: begin
						if(temp+FP_120 > 360) o_data <= temp-FP_240;
						else                  o_data <= temp+FP_120;
					end
					3: begin
						if(temp+FP_240 > 360) o_data <= temp-FP_120;
						else                  o_data <= temp+FP_240;
					end
					default: o_data <= 0;
				endcase 
			end
		end
	end
endmodule