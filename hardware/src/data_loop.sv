module data_loop#
(
parameter M_AXI_ID_WIDTH        = 1,
parameter M_AXI_ID              = 0,
parameter M_AXI_ADDR_WIDTH      = 16,
parameter M_AXI_DATA_WIDTH      = 128,
parameter M_AXI_MAX_BURST_LEN   = 256,
parameter cDMA_TRANS_WIDTH      = 16,
parameter AXI_BURST_SIZE_WIDTH  = 16,

parameter BRAM_ADDR_WIDTH       = 16,
localparam BRAM_DATA_WIDTH       = M_AXI_DATA_WIDTH,
parameter BRAM_MEM_DEPTH        = 'h4000 //16384
)
(
input   logic                                     clk               ,
input   logic                                     rst_n             ,

input   logic [M_AXI_ADDR_WIDTH-1:0]              cdma_waddr        , //cDMA write start addr
input   logic                                     cdma_waddr_vld    , //vld sigal for i_cdma_waddr. It's also the signal to ask for cDMA to prepare for the transaction, shoulde be pulse
input   logic [cDMA_TRANS_WIDTH-1:0]              cdma_wsize        , //The length of one cDMA write, total size in byte = i_cdma_wsize * M_AXI_DATA_WIDTH / 8
output  logic                                     cdma_wbusy        , //cDMA is busy, AXI write

input   logic [M_AXI_ADDR_WIDTH-1:0]              cdma_raddr        , //cDMA read start addr
input   logic                                     cdma_raddr_vld    , //vld sigal for i_cdma_raddr. It's also the signal to ask for cDMA to prepare for the transaction, shoulde be pulse
input   logic [cDMA_TRANS_WIDTH-1:0]              cdma_rsize        , //The length of one cDMA read, total size in byte = i_cdma_rsize * M_AXI_DATA_WIDTH / 8
output  logic                                     cdma_rbusy        , //cDMA is busy, AXI read


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



logic [M_AXI_DATA_WIDTH-1 :0]               cdma_wdata	   ; //cDMA write data
logic                                       cdma_wready    ; //cDMA write ready
logic                                       cdma_wvalid	   ; //cDMA write valid

logic [M_AXI_DATA_WIDTH-1 :0]               cdma_rdata	   ; //cDMA read data
logic                                       cdma_rready    ; //cDMA read ready
logic                                       cdma_rvalid	   ; //cDMA read valid


               
logic                                       bram_wren;                   
logic [BRAM_ADDR_WIDTH-1:0]                 bram_wraddr;                 
logic [BRAM_DATA_WIDTH-1:0]                 bram_wrdata; 

logic                                       bram_rden;
logic                                       bram_rden_r1;
logic                                       bram_lock;                         
logic [BRAM_ADDR_WIDTH-1:0]                 bram_rdaddr;                 
logic [BRAM_DATA_WIDTH-1:0]                 bram_rddata;


//cDMA write and BRAM read
assign cdma_wdata = bram_rddata;
assign cdma_wvalid = bram_rden_r1;
assign bram_lock = ~cdma_wready;

always_ff@(posedge clk or  negedge rst_n)begin
    if(~rst_n)
        bram_rdaddr <= 0;
    else if(cdma_waddr_vld)//before each cDMA tans, we should let bram_rdaddr set to 0
        bram_rdaddr <= 0;
    else if(bram_rden & cdma_wready)
        bram_rdaddr = bram_rdaddr + 1;
end

always_ff@(posedge clk or  negedge rst_n)begin
    if(~rst_n)
        bram_rden <= 0;
    else if(cdma_waddr_vld)
        bram_rden <= 0;  //before each cDMA tans, we should let bram_rden set to 0
    else if(cdma_wready) //cDMA is ready， then BRAM can send the data out
        bram_rden <= 1;
end
always_ff@(posedge clk)begin
    bram_rden_r1 <= bram_rden;
end

//cDMA read and BRAM write
assign bram_wrdata = cdma_rdata;
assign bram_wren = cdma_rvalid;
assign cdma_rready = 1'b1;

always_ff@(posedge clk or  negedge rst_n)begin
    if(~rst_n)
        bram_wraddr <= 0;
    else if(cdma_raddr_vld)
        bram_wraddr <= 0;
    else if(bram_wren & cdma_rready)
        bram_wraddr = bram_wraddr + 1;
end

// ila_0 inst_ila_0 (
// 	.clk(clk), // input wire clk


// 	.probe0({
//         bram_wrdata[15:0],
//         bram_wren,
//         bram_wraddr,
//         cdma_rvalid,

//         bram_rddata[15:0],
//         bram_rden,
//         bram_rdaddr,
//         cdma_wvalid
//     }) 
// );


// ila_0 inst_ila_1 (
// 	.clk(clk), // input wire clk


// 	.probe0({
//         cdma_waddr,
//         cdma_waddr_vld,
//         cdma_wsize,
//         cdma_wbusy,

//         cdma_raddr,
//         cdma_raddr_vld,
//         cdma_rsize,
//         cdma_rbusy
//     }) 
// );
cDMA #(
.M_AXI_ID_WIDTH       (M_AXI_ID_WIDTH),
.M_AXI_ID             (M_AXI_ID),
.M_AXI_ADDR_WIDTH     (M_AXI_ADDR_WIDTH), //memory addr width
.M_AXI_DATA_WIDTH     (M_AXI_DATA_WIDTH), //bus data width
.M_AXI_MAX_BURST_LEN  (M_AXI_MAX_BURST_LEN), //AXI largest burst length
.cDMA_TRANS_WIDTH     (cDMA_TRANS_WIDTH), //cDMA largest trans length width
.AXI_BURST_SIZE_WIDTH (AXI_BURST_SIZE_WIDTH)//The width of burst size of AXI in byte(consider 4K boundary??)
)inst_cDMA
(
.i_cdma_waddr       (cdma_waddr    ), //cDMA write start addr
.i_cdma_waddr_vld   (cdma_waddr_vld), //vld sigal for i_cdma_waddr. It's also the signal to ask for cDMA to prepare for the transaction
.i_cdma_wsize       (cdma_wsize    ), //The length of one cDMA write, total size in byte = i_cdma_wsize * M_AXI_DATA_WIDTH / 8
.o_cdma_wbusy       (cdma_wbusy    ), //cDMA is busy, AXI write

.i_cdma_wdata	    (cdma_wdata	   ), //cDMA write data
.o_cdma_wready      (cdma_wready   ), //cDMA write ready
.i_cdma_wvalid	    (cdma_wvalid   ), //cDMA write valid

.i_cdma_raddr       (cdma_raddr    ), //cDMA write start addr
.i_cdma_raddr_vld   (cdma_raddr_vld), //vld sigal for i_cdma_raddr. It's also the signal to ask for cDMA to prepare for the transaction
.i_cdma_rsize       (cdma_rsize    ), //The length of one cDMA read, total size in byte = i_cdma_rsize * M_AXI_DATA_WIDTH / 8
.o_cdma_rbusy       (cdma_rbusy    ), //cDMA is busy, AXI read

.o_cdma_rdata	    (cdma_rdata	   ), //cDMA read data
.i_cdma_rready      (cdma_rready   ), //cDMA read ready
.o_cdma_rvalid	    (cdma_rvalid   ), //cDMA read valid

//AXI BUS
.M_AXI_ACLK	        (M_AXI_ACLK     ), //AXI global clk
.M_AXI_ARESETN		(M_AXI_ARESETN  ), //AXI global rst_n

.M_AXI_AWID		    (M_AXI_AWID		), //AXI ID, useless here, it's for out of order transaction, which cDMA doesn't support
.M_AXI_AWADDR		(M_AXI_AWADDR	), //AXI write address
.M_AXI_AWLEN		(M_AXI_AWLEN	), //AXI write burst length
.M_AXI_AWSIZE		(M_AXI_AWSIZE	), //The size of each burst (This value is equal to log2(M_AXI_DATA_WIDTH/8))
.M_AXI_AWBURST		(M_AXI_AWBURST	), //burst type, cDMA only support 2'b01: INCR, the addr will increase AxSIZE each time
.M_AXI_AWLOCK		(M_AXI_AWLOCK	), //Don't care here (I don't know it, I just give it zero like an example from Xilinx)
.M_AXI_AWCACHE		(M_AXI_AWCACHE	), //Memory type, give a fixed value
.M_AXI_AWPROT		(M_AXI_AWPROT	), //Protection type, give a fixed value
.M_AXI_AWQOS		(M_AXI_AWQOS	), //Quality of Service, give a fixed value
.M_AXI_AWVALID		(M_AXI_AWVALID	), //Write addr channel valid signal
.M_AXI_AWREADY		(M_AXI_AWREADY	), //Write addr channel ready signal

.M_AXI_WID			(M_AXI_WID		), //AXI ID
.M_AXI_WDATA		(M_AXI_WDATA	), //AXI write data
.M_AXI_WSTRB		(M_AXI_WSTRB	), //Write strobes. This signal indicates which byte lanes hold valid data.
.M_AXI_WLAST		(M_AXI_WLAST	), //Write last
.M_AXI_WVALID		(M_AXI_WVALID	), //Write data channel valid signal
.M_AXI_WREADY		(M_AXI_WREADY	), //Write data channel ready signal

.M_AXI_BID			(M_AXI_BID		), //AXI ID
.M_AXI_BRESP		(M_AXI_BRESP	), //Write response (Most of time it's OKAY. If it is not, I don't how to deal that)
.M_AXI_BVALID		(M_AXI_BVALID	), //Write response channel valid
.M_AXI_BREADY		(M_AXI_BREADY	), //Wrire response channel ready

.M_AXI_ARID		    (M_AXI_ARID		), //AXI ID
.M_AXI_ARADDR		(M_AXI_ARADDR	), //AXI read address	 	
.M_AXI_ARLEN		(M_AXI_ARLEN	), //AXI read burst length
.M_AXI_ARSIZE		(M_AXI_ARSIZE	), //The size of each burst (This value is equal to log2(M_AXI_DATA_WIDTH/8))	 
.M_AXI_ARBURST		(M_AXI_ARBURST	), //Burst type	 
.M_AXI_ARLOCK		(M_AXI_ARLOCK	), //Don't care here (I don't know it, I just give it zero like an example from Xilinx)	 
.M_AXI_ARCACHE		(M_AXI_ARCACHE	), //Memory type 
.M_AXI_ARPROT		(M_AXI_ARPROT	), //Protection type 
.M_AXI_ARQOS		(M_AXI_ARQOS	), //Quality of Service	 	   
.M_AXI_ARVALID		(M_AXI_ARVALID	), //Read address channel valid	 
.M_AXI_ARREADY		(M_AXI_ARREADY	), //Read address channel ready	 

.M_AXI_RID			(M_AXI_RID		), //AXI ID	 
.M_AXI_RDATA		(M_AXI_RDATA	), //AXI read data	 
.M_AXI_RRESP		(M_AXI_RRESP	), //Read response. This signal indicates the status of the read transfer
.M_AXI_RLAST		(M_AXI_RLAST	), //Read last
.M_AXI_RVALID		(M_AXI_RVALID	), //Read channel valid   
.M_AXI_RREADY	    (M_AXI_RREADY	)  //Read channel ready
);

PDP_bram #(
.ADDR_WIDTH(BRAM_ADDR_WIDTH),
.DATA_WIDTH(BRAM_DATA_WIDTH),
.MEM_DEPTH (BRAM_MEM_DEPTH )
)inst_PDP_bram
(
.clk   (clk),     

.wren  (bram_wren),                   
.wraddr(bram_wraddr),                 
.wrdata(bram_wrdata),                 

.lock  (bram_lock),
.rden  (bram_rden),                   
.rdaddr(bram_rdaddr),                 
.rddata(bram_rddata)                              
);
    
endmodule