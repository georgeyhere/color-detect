
module kernel_control_tb();


    logic        clk;
    logic        rstn;

    logic [15:0]  i_data;
    logic        i_valid;
    logic        o_req;

    logic [47:0] o_r0_data;
    logic [47:0] o_r1_data;
    logic [47:0] o_r2_data;
    logic        o_valid;

	kp_kernel_control
	#(.LINE_LENGTH (480),
	  .LINE_COUNT  (480),
	  .DATA_WIDTH  (16))
	DUT
	(
    .i_clk     (clk),
    .i_rstn    (rstn),
  
    .i_data    (i_data),
    .i_valid   (i_valid),
    .o_req     (o_req),

    .o_r0_data (o_r0_data),
    .o_r1_data (o_r1_data),
    .o_r2_data (o_r2_data),
    .o_valid   (o_valid)
	);

    always#(6) clk = ~clk;


//
	integer     test_counter = 0;
	integer     i,j,k;
    logic [15:0] test_queue1 [$];
    logic [15:0] test_queue2 [$];
    logic [15:0] test_queue3 [$];

    logic [47:0] test0_expected;
    logic [15:0] test0_data1, test0_data2, test0_data3;

    logic [47:0] test1_expected;
    logic [15:0] test1_data1, test1_data2, test1_data3;

    logic [47:0] test2_expected;
    logic [15:0] test2_data1, test2_data2, test2_data3;

//	
	task checkOutput_r0;
		input [15:0] queue [$];
		begin
			for(j=0; j<480; j=j+1) begin 
			    @(negedge clk) begin
		        	// special case: first pixel in row
		        	if(j==0) begin
                	       test0_data1 = queue.pop_back();
                	       test0_data2 = queue.pop_back();
                	       test0_data3 = queue.pop_back();
                	       test0_expected = {test0_data2, test0_data2, test0_data3};
                	       assert(o_r0_data == test0_expected)
                	       else begin
                	       	$error("Output data mismatch: Expected data = %h, Actual data = %h", test0_expected, o_r0_data);
                	       	@(negedge clk);
                	       	$stop;
                	       end
		        	end
		    
		        	// special case: second pixel in row
		        	else if(j==1) begin
                	       test0_expected = {test0_data1, test0_data2, test0_data3};
                	       assert(o_r0_data == test0_expected)
                	       else begin
                	       	$error("Output data mismatch: Expected data = %h, Actual data = %h", test0_expected, o_r0_data);
                	       	@(negedge clk);
                	       	$stop;
                	       end
		        	end
                	   
                	// special case: last pixel in row
		        	else if(j==479) begin
                	       test0_expected = {test0_data2, test0_data3, test0_data3};
                	       assert(o_r0_data == test0_expected)
                	       else begin
                	       	$error("Output data mismatch: Expected data = %h, Actual data = %h", test0_expected, o_r0_data);
                	       	@(negedge clk);
                	       	$stop;
                	       end
		        	end
		    
		        	// default
		        	else begin
		        		test0_data1 = test0_data2;
		        		test0_data2 = test0_data3;
		        		test0_data3 = queue.pop_back();
		        		test0_expected = {test0_data1, test0_data2, test0_data3};
		        		assert(o_r0_data == test0_expected)
                	       else begin
                	       	$error("Output data mismatch: Expected data = %h, Actual data = %h", test1_expected, o_r0_data);
                	       	@(negedge clk);
                	       	$stop;
                	       end
		        	end
		        end
    	    end
		end
	endtask

	task checkOutput_r1;
		input [15:0] queue [$];
		begin
			for(k=0; k<480; k=k+1) begin 
			    @(negedge clk) begin
		        	// special case: first pixel in row
		        	if(k==0) begin
                	       test1_data1 = queue.pop_back();
                	       test1_data2 = queue.pop_back();
                	       test1_data3 = queue.pop_back();
                	       test1_expected = {test1_data2, test1_data2, test1_data3};
                	       assert(o_r1_data == test1_expected)
                	       else begin
                	       	$error("Output1 data mismatch: Expected data = %h, Actual data = %h", test1_expected, o_r1_data);
                	       	@(negedge clk);
                	       	$stop;
                	       end
		        	end
		    
		        	// special case: second pixel in row
		        	else if(k==1) begin
                	       test1_expected = {test1_data1, test1_data2, test1_data3};
                	       assert(o_r1_data == test1_expected)
                	       else begin
                	       	$error("Output1 data mismatch: Expected data = %h, Actual data = %h", test1_expected, o_r1_data);
                	       	@(negedge clk);
                	       	$stop;
                	       end
		        	end
                	   
                	// special case: last pixel in row
		        	else if(k==479) begin
                	       test1_expected = {test1_data2, test1_data3, test1_data3};
                	       assert(o_r1_data == test1_expected)
                	       else begin
                	       	$error("Output1 data mismatch: Expected data = %h, Actual data = %h", test1_expected, o_r1_data);
                	       	@(negedge clk);
                	       	$stop;
                	       end
		        	end
		    
		        	// default
		        	else begin
		        		test1_data1 = test1_data2;
		        		test1_data2 = test1_data3;
		        		test1_data3 = queue.pop_back();
		        		test1_expected = {test1_data1, test1_data2, test1_data3};
		        		assert(o_r1_data == test1_expected)
                	       else begin
                	       	$error("Output1 data mismatch: Expected data = %h, Actual data = %h", test1_expected, o_r1_data);
                	       	@(negedge clk);
                	       	$stop;
                	       end
		        	end
		        end
    	    end
		end
	endtask

	task checkOutput_r2;
		input [15:0] queue [$];
		begin
			for(i=0; i<480; i=i+1) begin 
			    @(negedge clk) begin
		        	// special case: first pixel in row
		        	if(i==0) begin
                	       test2_data1 = queue.pop_back();
                	       test2_data2 = queue.pop_back();
                	       test2_data3 = queue.pop_back();
                	       test2_expected = {test2_data2, test2_data2, test2_data3};
                	       assert(o_r2_data == test2_expected)
                	       else begin
                	       	$error("Output2 data mismatch: Expected data = %h, Actual data = %h", test2_expected, o_r2_data);
                	       	@(negedge clk);
                	       	$stop;
                	       end
		        	end
		    
		        	// special case: second pixel in row
		        	else if(i==1) begin
                	       test2_expected = {test2_data1, test2_data2, test2_data3};
                	       assert(o_r2_data == test2_expected)
                	       else begin
                	       	$error("Output2 data mismatch: Expected data = %h, Actual data = %h", test2_expected, o_r2_data);
                	       	@(negedge clk);
                	       	$stop;
                	       end
		        	end
                	   
                	// special case: last pixel in row
		        	else if(i==479) begin
                	       test2_expected = {test2_data2, test2_data3, test2_data3};
                	       assert(o_r2_data == test2_expected)
                	       else begin
                	       	$error("Output2 data mismatch: Expected data = %h, Actual data = %h", test2_expected, o_r2_data);
                	       	@(negedge clk);
                	       	$stop;
                	       end
		        	end
		    
		        	// default
		        	else begin
		        		test2_data1 = test2_data2;
		        		test2_data2 = test2_data3;
		        		test2_data3 = queue.pop_back();
		        		test2_expected = {test2_data1, test2_data2, test2_data3};
		        		assert(o_r2_data == test2_expected)
                	       else begin
                	       	$error("Output2 data mismatch: Expected data = %h, Actual data = %h", test2_expected, o_r2_data);
                	       	@(negedge clk);
                	       	$stop;
                	       end
		        	end
		        end
    	    end
		end
	endtask


//    

    // provide data on request 
    always@(posedge clk) begin
    	if(o_req) begin
    		i_valid <= 1;
    		i_data  = $urandom;

            if(test_counter < 1440) test_counter = test_counter+1;
            else test_counter = 0;

            if(test_counter <= 480) begin
            	test_queue1.push_front(i_data);
            end
            else if(test_counter <= 960) begin
            	test_queue2.push_front(i_data);
            end
            else if(test_counter <= 1440) begin
                test_queue3.push_front(i_data);
            end
    	end
    	else begin
    		i_valid <= 0;
    		i_data  <= 0;
    	end
    end

    always@(posedge o_valid) begin

  		fork
  			// thread 1
			checkOutput_r0(test_queue1);

			// thread 2
			//checkOutput_r1(test_queue2);

			// thread 3
			checkOutput_r2(test_queue3);
		join
    end

    initial begin
    	clk      = 0;
    	rstn     = 0;
    	i_data   = 0;
    	i_valid  = 0;
    	#100;
    	rstn = 1;
    end

//
	property fillMax_chk;
		@(posedge clk) disable iff(!rstn)
			DUT.r_fill < 1440;
	endproperty
	A_fillMax_chk: assert property(fillMax_chk);

endmodule 