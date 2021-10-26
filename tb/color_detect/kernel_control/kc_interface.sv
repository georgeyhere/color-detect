// The interface allows verification components to access DUT signals
// using a virtual interface handle.
interface dut_if(input bit clk);
    logic        rstn;
    logic [15:0] wdata;
    logic        wvalid;
    logic [47:0] rdata;
    logic        rvalid;
    logic        enable;
    logic        ready;
endinterface
