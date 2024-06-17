// Signal description
// 1) i_ input
// 2) o_ output
// 3) IO_ input output
// 4) _n activ low
// 5) _dg debug signal 
// 6) _r delay or register
// 7) _s state mechine

//cDMA build an bridge between AXI4 Master interface and user's self defined channel

module cDMA#(
parameter integer                                 M_AXI_ID_WIDTH          = 1   ,
parameter integer                                 M_AXI_ID                = 0   ,
parameter integer                                 M_AXI_ADDR_WIDTH        = 32  , //memory addr width
parameter integer                                 M_AXI_DATA_WIDTH        = 32  , //bus data width
parameter integer                                 M_AXI_MAX_BURST_LEN     = 64  , //AXI largest burst length
parameter integer                                 cDMA_TRANS_WIDTH        = 16  , //cDMA largest trans length width
parameter integer                                 AXI_BURST_SIZE_WIDTH    = 16  //The width of burst size of AXI in byte(consider 4K boundary??)
)
(
input   logic [M_AXI_ADDR_WIDTH-1:0]              i_cdma_waddr     , //cDMA write start addr
input   logic                                     i_cdma_waddr_vld , //vld sigal for i_cdma_waddr. It's also the signal to ask for cDMA to prepare for the transaction, should be pulse
input   logic [cDMA_TRANS_WIDTH-1:0]              i_cdma_wsize     , //The length of one cDMA write, total size in byte = i_cdma_wsize * M_AXI_DATA_WIDTH / 8
output  logic                                     o_cdma_wbusy     , //cDMA is busy, AXI write
 
input   logic [M_AXI_DATA_WIDTH-1 :0]             i_cdma_wdata	   , //cDMA write data
output  logic                                     o_cdma_wready    , //cDMA write ready, this signal will only be high after you send the addr
input   logic                                     i_cdma_wvalid	   , //cDMA write valid
 
input   logic [M_AXI_ADDR_WIDTH-1:0]              i_cdma_raddr     , //cDMA read start addr
input   logic                                     i_cdma_raddr_vld , //vld sigal for i_cdma_raddr. It's also the signal to ask for cDMA to prepare for the transaction, should be pulse
input   logic [cDMA_TRANS_WIDTH-1:0]              i_cdma_rsize     , //The length of one cDMA read, total size in byte = i_cdma_rsize * M_AXI_DATA_WIDTH / 8
output  logic                                     o_cdma_rbusy     , //cDMA is busy, AXI read
 
output  logic [M_AXI_DATA_WIDTH-1 :0]             o_cdma_rdata	   , //cDMA read data
input   logic                                     i_cdma_rready    , //cDMA read ready
output  logic                                     o_cdma_rvalid	   , //cDMA read valid

//AXI BUS
input 	logic  								      M_AXI_ACLK	    , //AXI global clk
input 	logic  								      M_AXI_ARESETN		, //AXI global rst_n

output 	logic [M_AXI_ID_WIDTH-1 : 0]		      M_AXI_AWID		, //AXI ID, useless here, it's for out of order transaction, which cDMA doesn't support
output 	logic [M_AXI_ADDR_WIDTH-1 : 0] 	          M_AXI_AWADDR		, //AXI write address
output 	logic [7 : 0]						      M_AXI_AWLEN		, //AXI write burst length
output 	logic [2 : 0] 						      M_AXI_AWSIZE		, //The size of each burst (This value is equal to log2(M_AXI_DATA_WIDTH/8))
output 	logic [1 : 0] 						      M_AXI_AWBURST		, //burst type, cDMA only support 2'b01: INCR, the addr will increase AxSIZE each time
output 	logic  								      M_AXI_AWLOCK		, //Don't care here (I don't know it, I just give it zero like an example from Xilinx)
output 	logic [3 : 0] 						      M_AXI_AWCACHE		, //Memory type, give a fixed value
output 	logic [2 : 0] 						      M_AXI_AWPROT		, //Protection type, give a fixed value
output 	logic [3 : 0] 						      M_AXI_AWQOS		, //Quality of Service, give a fixed value
output 	logic  								      M_AXI_AWVALID		, //Write addr channel valid signal
input	logic  								      M_AXI_AWREADY		, //Write addr channel ready signal

output  logic [M_AXI_ID_WIDTH-1 : 0] 		      M_AXI_WID			, //AXI ID
output  logic [M_AXI_DATA_WIDTH-1 : 0] 	          M_AXI_WDATA		, //AXI write data
output  logic [M_AXI_DATA_WIDTH/8-1 : 0] 	      M_AXI_WSTRB		, //Write strobes. This signal indicates which byte lanes hold valid data.
output  logic  								      M_AXI_WLAST		, //Write last
output  logic  								      M_AXI_WVALID		, //Write data channel valid signal
input   logic  								      M_AXI_WREADY		, //Write data channel ready signal

input   logic [M_AXI_ID_WIDTH-1 : 0] 		      M_AXI_BID			, //AXI ID
input   logic [1 : 0] 						      M_AXI_BRESP		, //Write response (Most of time it's OKAY. If it is not, I don't how to deal that)
input   logic  								      M_AXI_BVALID		, //Write response channel valid
output  logic  								      M_AXI_BREADY		, //Wrire response channel ready

output  logic [M_AXI_ID_WIDTH-1 : 0] 		      M_AXI_ARID		, //AXI ID
output  logic [M_AXI_ADDR_WIDTH-1 : 0] 	          M_AXI_ARADDR		, //AXI read address	 	
output  logic [7 : 0] 						      M_AXI_ARLEN		, //AXI read burst length
output  logic [2 : 0] 						      M_AXI_ARSIZE		, //The size of each burst (This value is equal to log2(M_AXI_DATA_WIDTH/8))	 
output  logic [1 : 0] 						      M_AXI_ARBURST		, //Burst type	 
output  logic  								      M_AXI_ARLOCK		, //Don't care here (I don't know it, I just give it zero like an example from Xilinx)	 
output  logic [3 : 0] 						      M_AXI_ARCACHE		, //Memory type 
output  logic [2 : 0] 						      M_AXI_ARPROT		, //Protection type 
output  logic [3 : 0] 						      M_AXI_ARQOS		, //Quality of Service	 	   
output  logic  								      M_AXI_ARVALID		, //Read address channel valid	 
input   logic  								      M_AXI_ARREADY		, //Read address channel ready	 

input   logic [M_AXI_ID_WIDTH-1 : 0] 		      M_AXI_RID			, //AXI ID	 
input   logic [M_AXI_DATA_WIDTH-1 : 0] 	          M_AXI_RDATA		, //AXI read data	 
input   logic [1 : 0] 						      M_AXI_RRESP		, //Read response. This signal indicates the status of the read transfer
input   logic  								      M_AXI_RLAST		, //Read last
input   logic  								      M_AXI_RVALID		, //Read channel valid   
output  logic  								      M_AXI_RREADY	      //Read channel ready
);

localparam AXI_BYTES =  M_AXI_DATA_WIDTH/8; //AXI data bytes in one burst
// localparam [3:0] MAX_BURST_LEN_SIZE = $clog2(M_AXI_MAX_BURST_LEN);    

//----------------------cDMA write----------------------
logic   [M_AXI_ADDR_WIDTH-1:0]        axi_awaddr           ; //AXI write addr
logic                                 axi_awvalid          ; //AXI write addr valid
logic   [M_AXI_DATA_WIDTH-1:0]        axi_wdata            ; //AXI4 write data
logic                                 axi_wlast            ; //AXI4 write last
logic                                 axi_wvalid           ; //AXI4 write data valid
logic                                 w_next               ; //write next 
logic   [8:0]                         wburst_len           ; //write axi burst len (max: M_AXI_MAX_BURST_LEN )
logic   [8:0]                         wburst_cnt           ; //The cnt of each AXI bust (max: M_AXI_MAX_BURST_LEN)
logic   [cDMA_TRANS_WIDTH-1:0]        wcdma_cnt            ; //The cnt of cdma for write
logic                                 wburst_len_req       ; //Require to calculate wburst_len
logic   [cDMA_TRANS_WIDTH-1:0]        cdma_wleft_cnt       ; //The left to write in one cDMA trans
logic                                 axi_wstart_locked    ; //The locked signal of axi_wstart (for each axi trans)
logic                                 axi_wstart_locked_r1 ;
logic                                 axi_wstart_locked_r2 ;
logic   [AXI_BURST_SIZE_WIDTH-1:0]    axi_wburst_size      ; //AXI addr calculation (in byte)
logic                                 cdma_wstart_locked   ; //The locked signal of cdma_wstart
logic                                 cdma_wend            ; //cDMA write end
logic                                 cdma_wstart          ; //cDMA write start


//AXI write interfaces
assign M_AXI_AWID       = M_AXI_ID; 
assign M_AXI_AWADDR     = axi_awaddr;
assign M_AXI_AWLEN      = wburst_len - 1;
assign M_AXI_AWSIZE     = $clog2(AXI_BYTES);
assign M_AXI_AWBURST    = 2'b01;
assign M_AXI_AWLOCK     = 1'b0;
assign M_AXI_AWCACHE    = 4'b0010;//non cache,non buffer
assign M_AXI_AWPROT     = 3'h0;
assign M_AXI_AWQOS      = 4'h0;
assign M_AXI_AWVALID    = axi_awvalid;
assign M_AXI_WDATA      = axi_wdata;
assign M_AXI_WSTRB      = {(AXI_BYTES){1'b1}};//IMPORTANT! This means all the data in M_AXI_WDATA will be valid
assign M_AXI_WLAST      = axi_wlast;
assign M_AXI_WVALID     = axi_wvalid & i_cdma_wvalid;//when both two valid signals are high, after axi_wvalid is high
assign M_AXI_BREADY     = 1'b1;

//Self defined signals
assign o_cdma_wbusy     = cdma_wstart_locked;
assign w_next           = (M_AXI_WVALID & M_AXI_WREADY); //a valid shake hand
assign axi_wburst_size  = wburst_len * AXI_BYTES; // to calculate the addr
assign o_cdma_wready    = M_AXI_WREADY & axi_wvalid; //only after axi_wvalid is high then we can use cDMA to write data, here diff
assign cdma_wstart      = (cdma_wstart_locked == 1'b0 && i_cdma_waddr_vld == 1'b1); //Keep high during one AXI_CLK cycle, rised by i_cdma_waddr_vld

//During the whole cDMA write process, cdma_wstart_locked will be high
always_ff @(posedge M_AXI_ACLK) begin
    if(M_AXI_ARESETN == 1'b0)
        cdma_wstart_locked <= 1'b0;
    else if(cdma_wend)
        cdma_wstart_locked <= 1'b0;
    else if(cdma_wstart)
        cdma_wstart_locked <= 1'b1;
end

//axi_wstart_locked
//axi_wstart_locked indicates that an axi write burst operation is in progress
//This is used to generate the rising edge for awvalid and wvalid
always_ff @(posedge M_AXI_ACLK) begin
    if(M_AXI_ARESETN == 1'b0)
        axi_wstart_locked <= 1'b0;    
    else if( cdma_wstart_locked == 1'b1 &&  axi_wstart_locked == 1'b0)
        axi_wstart_locked <= 1'b1; 
    else if(axi_wlast == 1'b1) //here diff!!!
        axi_wstart_locked <= 1'b0;
end

always_ff @(posedge M_AXI_ACLK)begin
    axi_wstart_locked_r1 <= axi_wstart_locked;
    axi_wstart_locked_r2 <= axi_wstart_locked_r1;
end

//----------------------AXI write-addr / write channel----------------------

//axi_awaddr
//At start, axi_awaddr = i_cdma_waddr
//After each AXI trans, axi_awaddr += axi_wburst_size
always_ff @(posedge M_AXI_ACLK) begin
    if(M_AXI_ARESETN == 1'b0)
        axi_awaddr <= 'd0;
    else if(cdma_wstart)
        axi_awaddr <= i_cdma_waddr;
    else if(axi_wlast)
        axi_awaddr <= axi_awaddr + axi_wburst_size;
end

always_ff @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)
        axi_awvalid <= 1'b0;
    else if(axi_wstart_locked_r1 == 1'b1 &&  axi_wstart_locked_r2 == 1'b0)
        axi_awvalid <= 1'b1;
    else if((M_AXI_AWVALID == 1'b1 && M_AXI_AWREADY == 1'b1)|| axi_wstart_locked == 1'b0)//here diff!!!
        axi_awvalid <= 1'b0;   
end

always_ff @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)
        axi_wvalid <= 1'b0;
    if((axi_wstart_locked_r1 == 1'b1) &&  axi_wstart_locked_r2 == 1'b0) //same with awvalid
        axi_wvalid <= 1'b1;
    else if(axi_wlast == 1'b1 || axi_wstart_locked == 1'b0)
        axi_wvalid <= 1'b0;
end

assign axi_wdata = i_cdma_wdata;
assign axi_wlast = (w_next == 1'b1) && (wburst_cnt == M_AXI_AWLEN);

//The counter for each AXI trans
always_ff @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)
        wburst_cnt <= 'd0;
    else if(axi_wstart_locked == 1'b0)
        wburst_cnt <= 'd0;
    else if(w_next)
        wburst_cnt <= wburst_cnt + 1;    
end

// wburst_len_req is to calculate the burst length of each AXI4 trans
always_ff @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)
        wburst_len_req <= 1'b0;
    else
        wburst_len_req <= cdma_wstart|axi_wlast;
end

// cdma_wleft_cnt
always @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)begin
        wcdma_cnt <= 'd0;
        cdma_wleft_cnt <= 'd0;
    end
    else if( cdma_wstart )begin
        wcdma_cnt <= 'd0;
        cdma_wleft_cnt <= i_cdma_wsize;
    end
    else if(w_next)begin
        wcdma_cnt <= wcdma_cnt + 1'b1;  
        cdma_wleft_cnt <= (i_cdma_wsize - 1'b1) - wcdma_cnt;
    end
end

//Calculate AXI write burst size
//Max: M_AXI_MAX_BURST_LEN
always @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)begin
        wburst_len <= 1;
    end
    else if(wburst_len_req)begin
        if(cdma_wleft_cnt > M_AXI_MAX_BURST_LEN)  
            wburst_len <= M_AXI_MAX_BURST_LEN;
        else 
            wburst_len <= cdma_wleft_cnt;
    end
    else 
        wburst_len <= wburst_len;
end

//cDMA write end
assign  cdma_wend = w_next && (cdma_wleft_cnt == 1);





//----------------------cDMA read----------------------
logic   [M_AXI_ADDR_WIDTH-1 : 0]      axi_araddr           ; //AXI read addr
logic                                 axi_arvalid          ; //AXI read addr valid
logic                                 axi_rlast            ; //AXI read last
logic                                 axi_rready           ; //AXI4 
logic                                 r_next               ; //A valid read shake hand
logic   [8 :0]                        rburst_len           ; //read axi burst len (max: M_AXI_MAX_BURST_LEN )
logic   [8 :0]                        rburst_cnt           ; //The cnt of each AXI read
logic   [cDMA_TRANS_WIDTH-1:0]        rcdma_cnt            ; //cDMA read cnt
logic                                 axi_rstart_locked    ; //Will be high when AXI read
logic                                 axi_rstart_locked_r1 ;
logic                                 axi_rstart_locked_r2 ;
logic   [AXI_BURST_SIZE_WIDTH-1:0]    axi_rburst_size      ; //To calculate the AXI read addr  
logic                                 cdma_rstart_locked   ; //Will be high during the whole cDMA read
logic                                 cdma_rend            ; //cDMA read end
logic                                 cdma_rstart          ; //cDMA read start
logic                                 rburst_len_req       ; //Require to update read burst len
logic   [cDMA_TRANS_WIDTH-1:0]        cdma_rleft_cnt       ; //Cnt of cDMA for read

//AXI read interfaces
assign M_AXI_ARID       = M_AXI_ID; //AXI ID
assign M_AXI_ARADDR     = axi_araddr;
assign M_AXI_ARLEN      = rburst_len - 1; //The length of AXI burst trans
assign M_AXI_ARSIZE     = $clog2(AXI_BYTES);
assign M_AXI_ARBURST    = 2'b01; //INCR
assign M_AXI_ARLOCK     = 1'b0; 
assign M_AXI_ARCACHE    = 4'b0010;//non cache,non buffer
assign M_AXI_ARPROT     = 3'h0;
assign M_AXI_ARQOS      = 4'h0;
assign M_AXI_ARVALID    = axi_arvalid;
assign M_AXI_RREADY     = axi_rready&&i_cdma_rready; //ready to accept the read data


//Self defined signals
assign r_next           = (M_AXI_RVALID && M_AXI_RREADY); //a valid read shake hand
assign axi_rburst_size  = rburst_len * AXI_BYTES;
assign cdma_rstart      = (cdma_rstart_locked == 1'b0 && i_cdma_raddr_vld == 1'b1); 
assign o_cdma_rbusy     = cdma_rstart_locked;


//cdma_rstart_locked will high during the whole cDMA read process
always_ff @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)
        cdma_rstart_locked <= 1'b0;
    else if(cdma_rend == 1'b1)
        cdma_rstart_locked <= 1'b0;
    else if(cdma_rstart)
        cdma_rstart_locked <= 1'b1;   
end

always_ff @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)
        axi_rstart_locked <= 1'b0;
    else if(cdma_rstart_locked == 1'b1 &&  axi_rstart_locked == 1'b0)
        axi_rstart_locked <= 1'b1; 
    else if(axi_rlast == 1'b1) //here diff!!!
        axi_rstart_locked <= 1'b0;
end

always_ff @(posedge M_AXI_ACLK)begin
    axi_rstart_locked_r1 <= axi_rstart_locked;
    axi_rstart_locked_r2 <= axi_rstart_locked_r1;
end

//----------------------AXI read-addr / read channel----------------------

//axi_araddr
//At start, axi_araddr = i_cdma_raddr
//After each AXI trans, axi_araddr += axi_rburst_size
always_ff @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)
        axi_araddr <= 'd0;
    else if(cdma_rstart == 1'b1)    
        axi_araddr <= i_cdma_raddr;
    else if(axi_rlast == 1'b1)
        axi_araddr <= axi_araddr + axi_rburst_size;     
end 

always_ff @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)
        axi_arvalid <= 1'b0;
    else if(axi_rstart_locked_r1 == 1'b1 &&  axi_rstart_locked_r2 == 1'b0)
        axi_arvalid <= 1'b1;
    else if((M_AXI_ARVALID == 1'b1 && M_AXI_ARREADY == 1'b1)|| axi_rstart_locked == 1'b0)//here diff!!!
        axi_arvalid <= 1'b0;  
end

//AXI4 read data  
always_ff @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)
        axi_rready <= 1'b0;
    else if(axi_rstart_locked_r1 == 1'b1 &&  axi_rstart_locked_r2 == 1'b0)
        axi_rready <= 1'b1;
    else if(axi_rlast == 1'b1 || axi_rstart_locked == 1'b0)
        axi_rready <= 1'b0;   
end

assign o_cdma_rdata     = M_AXI_RDATA;    
assign o_cdma_rvalid    = M_AXI_RVALID; //here diff!!!
assign axi_rlast = (r_next == 1'b1) && (rburst_cnt == M_AXI_ARLEN);

//AXI4 read data burst len counter
always_ff @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)
        rburst_cnt <= 'd0;
    else if(axi_rstart_locked == 1'b0)
        rburst_cnt <= 'd0;
    else if(r_next)
        rburst_cnt <= rburst_cnt + 1'b1;       
end

always_ff @(posedge M_AXI_ACLK) begin
    if(M_AXI_ARESETN == 1'b0)
        rburst_len_req <= 1'b0;
    else 
        rburst_len_req <= cdma_rstart | axi_rlast;  
end

// cdma_rleft_cnt          
always_ff @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)begin
        rcdma_cnt <= 'd0;
        cdma_rleft_cnt <= 'd0;
    end
    else if(cdma_rstart )begin
        rcdma_cnt <= 'd0;
        cdma_rleft_cnt <= i_cdma_rsize;
    end
    else if(r_next)begin
        rcdma_cnt <= rcdma_cnt + 1'b1;  
        cdma_rleft_cnt <= (i_cdma_rsize - 1'b1) - rcdma_cnt;
    end
end

assign  cdma_rend = r_next && (cdma_rleft_cnt == 1 );

always_ff @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)begin
        rburst_len <= 'd1;
    end
    else if(rburst_len_req)begin
        if(cdma_rleft_cnt > M_AXI_MAX_BURST_LEN)  
            rburst_len <= M_AXI_MAX_BURST_LEN;
        else 
            rburst_len <= cdma_rleft_cnt;
    end
    else 
        rburst_len <= rburst_len;
end
endmodule