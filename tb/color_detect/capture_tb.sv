//
//
module capture_tb();


// DUT I/O
//
	logic        clk = 0;
	logic        rstn;
	logic        vsync;
	logic        href;
	logic [7:0]  data;

	logic        o_wr;
	logic [15:0] o_wdata;

	

// DUT Instantiation
//
	capture DUT(
    .i_pclk  (clk),
    .i_rstn  (rstn),

    .i_vsync (vsync),
    .i_href  (href),
    .i_data  (data),

    .o_wr    (o_wr),
    .o_wdata (o_wdata),

    .o_sof   ()
	);


// Testbench Setup
//
	localparam TESTRUNS  = 3;
	localparam ROWCOUNT  = 480;
	localparam ROWLENGTH = 640;

	integer k;
	logic [15:0] test_data;
	logic [15:0] test_queue[$];
	logic [15:0] test_expected;

	always#(21) clk = ~clk;

	task startFrame;
		begin
			vsync = 0;
        	@(posedge clk);
        	vsync = 1;
        	repeat(3) @(posedge clk);  // mimic vsync pulse
        	vsync = 0;
        	repeat(17) @(posedge clk); // mimic vsync back porch
		end
	endtask

// Testbench 
//
	initial begin
		rstn  = 0;
		vsync = 0;
		href  = 0;
        data  = 0;
        #100;
        
        rstn  = 1;

        repeat(17) @(posedge clk);

        // repeat for # of frames
        for(int i=0; i<TESTRUNS; i++) begin 
        	startFrame();

        	// repeat for # of rows per frame
        	for(int j=0; j<ROWCOUNT; j++) begin
        		$display("Frame: %0h, Row: %0h", i,j);

        		// send a row of data
        	    for(k=0; k<(ROWLENGTH*2-1); k++) begin
        	    	@(negedge clk) begin
        	    		//
        	    		if(k==0) begin
        	    			href = 1;
        	    			test_data = $urandom;
        	    			data      = test_data[15:8];
        	    		end
        	    		else if(k%2 == 0) begin
        	    			data = test_data[7:0];
        	    			if(k>=319) begin
        	    				test_queue.push_front(test_data);
        	    			end
        	    		end
        	    		else begin
        	    			test_data = $urandom;
        	    			data      = test_data[15:8];
        	    		end
        	    	end
        	    end
        	    @(negedge clk) href = 0;  // drop href to signal end of row
        	    repeat(5) @(posedge clk); 
        	end
        end
        #1us
        $display("Test passed for given parameters!");
        $finish;
	end

// check that data matches data in
	always@(posedge clk) begin
		if(o_wr) begin
			test_expected = test_queue.pop_back();
			assert(o_wdata == test_expected)
			else begin
				$error("Checking failed: Expected data = %h, Actual data = %h", test_expected, o_wdata);
				$stop;
			end 
		end
	end

// check that the correct number of pixels is being written to obuf
	integer t_rowCount = 0;
	logic   t_valid = 0;
	always@(posedge clk) begin
		if($rose(href)) begin
			t_valid <= 1;
		end
	end

	always@(posedge clk) begin
		if($rose(href)&&t_valid) begin
			assert(t_rowCount == 480) 
			else begin
				$error("Incorrect number of pixels written!");
				@(negedge clk);
				$stop;
			end
			t_rowCount = 0;
		end
		else if(o_wr) begin
			t_rowCount = t_rowCount+1;
		end

		assert(t_rowCount <= 480)
		else begin
			$error("Excess pixels written!");
			@(negedge clk);
			$stop;
		end
	end
	

endmodule