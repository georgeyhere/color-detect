package kcontrol_pkg;
	
	// Pixel Transaction Class:
	// This is the base transaction object that will be used in the 
	// environment to initiate and capture transactions at DUT interface.
	class pixel_item;
    	rand bit [15:0] wdata;
    	rand bit        wvalid;
    	     bit [47:0] rdata;  
    	     bit        rvalid;
	
    	function void print(string tag="");
    		$timeformat(-9, 1, "ns");
    	    $display("T=%t [%s] wvalid=%0d wdata=0x%0h rvalid=%0d rdata=0x%0h", 
    	                $time, tag, wvalid, wdata, rvalid, rdata);
   		endfunction 
	endclass 

	// Driver Class:
	// This class is responsible for driving transactions to the DUT.
	// It fetches transactions from the mailbox if available and drives
	// it to the DUT interface.
	class driver;
		virtual dut_if vif;
		event          drv_done;
		mailbox        drv_mbx;
	
		task run();
			$timeformat(-9, 1, "ns");
			$display("T=%t [Driver] starting ...", $time);
			@(posedge vif.clk) 
	
			/* Get a new transaction and assign contents to interface
			*  if the DUT is ready. */
			forever begin
				pixel_item item = new;
				// $display("T=%t [Driver] waiting for item ...", $time);
				drv_mbx.get(item);
				//item.print("Driver     ");
				vif.enable <= 1;
				vif.wvalid <= item.wvalid;
				vif.wdata  <= item.wdata;
				//
				@(posedge vif.clk) begin
					while(!vif.ready) begin
						// $display("T=%t [Driver] wait until req is high", $time);
						vif.wvalid <= 0;
						@(posedge vif.clk);
					end
				end
			end
	
			// when transfer is done, raise the done event
			vif.enable <= 0; ->drv_done;
		endtask
	endclass


	// Monitor Class:
	// The monitor has a virtual interface handle that allows it to
	// it to monitor events happening on the interface. It sees new
	// transactions, captures information into a packet, and sends
	// it to the scoreboard using another mailbox.
	class monitor;
		virtual dut_if vif;
		mailbox        scb_mbx; // mailbox connected to scoreboard
		pixel_item     item;
	
		task run();
			$timeformat(-9, 1, "ns");
			$display("T=%t [Monitor] starting ...", $time);
			item = new;
	
			/* Check every posedge clk if there is a valid transaction;
			*  If yes, capture info into an object and send it to the
			*  scoreboard when the transaction is over. 
			*/
			forever begin
				@(posedge vif.clk);
				if(vif.enable) begin
					item = new;
					item.wvalid = vif.wvalid;
					item.wdata  = vif.wdata;
					item.rvalid = vif.rvalid;
					item.rdata  = vif.rdata;
				end
				//item.print("Monitor    ");
				scb_mbx.put(item);
			end
		endtask
	endclass

	// Scoreboard Class:
	// The scoreboard is responsible for checking data integrity.
	class scoreboard;
		mailbox    scb_mbx;
		pixel_item refq[100000];
		int w=0;
		int r=0;
		int c=0;
		bit [47:0] expected;
	
		task run();
			$timeformat(-9, 1, "ns");
			forever begin
				pixel_item item = new;
				scb_mbx.get(item);
				//item.print("Scoreboard ");
	
				// Store valid writes in consecutive addresses 
				if(item.wvalid) begin
					refq[w] = item;
					$display("T=%t [Scoreboard ] Store i=%0d wvalid=%0d data=0x%0h",
					      $time, w, item.wvalid, item.wdata); 
					w++;
				end
				
				// Checking procedure
				if(item.rvalid) begin
					if(r<2) begin
							if(c==0) begin
							expected = {refq[c].wdata, 
						                refq[c].wdata, 
						                refq[c+1].wdata};
						end
						else if(c==47) begin
							expected = {refq[c-1].wdata, 
						                refq[c].wdata, 
						                refq[c].wdata};
						end
						else begin
							expected = {refq[c-1].wdata, 
						                refq[c].wdata, 
						                refq[c+1].wdata};
						end
					end
					else begin
						if(c==0) begin
							expected = {refq[c+((r-1)*48)].wdata, 
						                refq[c+((r-1)*48)].wdata, 
						                refq[c+((r-1)*48)+1].wdata};
						end
						else if(c==47) begin
							expected = {refq[c+((r-1)*48)-1].wdata, 
						                refq[c+((r-1)*48)].wdata, 
						                refq[c+((r-1)*48)].wdata};
						end
						else begin
							expected = {refq[c+((r-1)*48)-1].wdata, 
						                refq[c+((r-1)*48)].wdata, 
						                refq[c+((r-1)*48)+1].wdata};
						end
					end

					if(item.rdata != expected)
						$display("T=%t [Scoreboard] ERROR! r=%0d c=%0d exp=0x%0h act=0x%0h",
							        $time, r, c, expected, item.rdata);
					else 
						$display("T=%t [Scoreboard] PASS! r=%0d c=%0d exp=0x%0h act=0x%0h",
							        $time, r, c, expected, item.rdata);
					if(c<47) c++;
					else begin
						c=0;
						r++;
					end    
				end
			end
		endtask
	endclass

	// Environment Class:
	// The environment is a container object that holds all 
	// verification components.
	class env;
		driver            d0;      // Driver to dut
		monitor           m0;      // Monitor from dut
		scoreboard        s0;      // Scoreboard connected to Monitor
		mailbox           scb_mbx; // Top level mailbox; Scoreboard <-> Monitor
		virtual dut_if    vif;     // virtual interface handle
	
		// Constructor
		function new();
			d0      = new;
			m0      = new;
			s0      = new;
			scb_mbx = new;
		endfunction
	
		// Assign handles and start all components
		virtual task run();
			d0.vif = vif;
			m0.vif = vif;
			m0.scb_mbx = scb_mbx;
			s0.scb_mbx = scb_mbx;
	
			fork 
				s0.run();
				d0.run();
				m0.run();
			join_any
		endtask
	endclass

	// Generator Class:
	// A class that creates an environment object; write stimulus here.
	class test;
		env e0;
		mailbox drv_mbx;
	
		// constructor
		function new();
			drv_mbx = new();
			e0      = new();
		endfunction
	
		//
		virtual task run();
			e0.d0.drv_mbx = drv_mbx;
			fork
				e0.run();
			join_none
	
			apply_stim();
		endtask
	
		// Stimulus Generator
		virtual task apply_stim();
			integer i=0;
			pixel_item item;
			$timeformat(-9, 1, "ns");
			$display("T=%t [Test] Starting stimulus ...", $time);
			while(i<1000) begin
				item = new;
				item.randomize();
				drv_mbx.put(item);
				i=(item.wvalid) ? (i+1):i;
			end
		endtask
	endclass


endpackage // kcontrol_pkg