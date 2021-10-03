module arithmeticTest ();

	
	reg [15:0] a,b;
	reg [15:0] c;

	initial begin
		a=0;
		b=0;
		a[15:6] = 0;
		b[15:6] = 1;

		#100;
		c = a-b;

		#100;
		c=16'bx;

		#100;
		c = $signed(a) - $signed(b);

	//
		#100; 
		a[15:6] = $signed(-100);
		b[15:6] = $signed(10);
		c = 16'bx;

		#100;
		c = ($signed(a)/$signed(b)) << 6;

	//
		#100;
		a[15:6] = $signed(-100);
		b[15:6] = $signed(33);
		c = 16'bx;

		#100;
		c = (($signed(a)<<6)/$signed(b));

	//
		#100;
		a[15:6] = $signed(-10);
		b[15:6] = $signed(22);
		c = 16'bx;

		#100;
		c = (($signed(a)<<6)/$signed(b)) << 6;

	end

endmodule