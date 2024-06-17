
`timescale 1 ns / 1 ps

	module data_loop_top #
	(
		// Users to add parameters here
		parameter M_AXI_ID_WIDTH        = 1,
		parameter M_AXI_ID              = 0,
		parameter M_AXI_ADDR_WIDTH      = 16,
		parameter M_AXI_DATA_WIDTH      = 128,
		parameter M_AXI_MAX_BURST_LEN   = 256,
		parameter cDMA_TRANS_WIDTH      = 16,
		parameter AXI_BURST_SIZE_WIDTH  = 16,

		parameter BRAM_ADDR_WIDTH       = 16,
		parameter BRAM_MEM_DEPTH        = 'h4000, //16384
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
		input   logic                                     clk               ,
		input   logic                                     rst_n             ,

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
		output  logic  								      M_AXI_RREADY	    , //Read channel ready    
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 2;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 8
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	      slv_reg4 <= 0;
	      slv_reg5 <= 0;
	      slv_reg6 <= 0;
	      slv_reg7 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          3'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h4:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 4
	                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h5:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 5
	                slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h6:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 6
	                slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h7:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 7
	                slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                      slv_reg4 <= slv_reg4;
	                      slv_reg5 <= slv_reg5;
	                      slv_reg6 <= slv_reg6;
	                      slv_reg7 <= slv_reg7;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  


	logic                                     cdma_wbusy        ; //cDMA is busy, AXI write
	logic                                     cdma_rbusy        ; //cDMA is busy, AXI write
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        3'h0   : reg_data_out <= slv_reg0;
	        3'h1   : reg_data_out <= slv_reg1;
	        3'h2   : reg_data_out <= slv_reg2;
	        3'h3   : reg_data_out <= cdma_wbusy;

	        3'h4   : reg_data_out <= slv_reg4;
	        3'h5   : reg_data_out <= slv_reg5;
	        3'h6   : reg_data_out <= slv_reg6;
	        3'h7   : reg_data_out <= cdma_rbusy;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here
	logic [M_AXI_ADDR_WIDTH-1:0]              cdma_waddr        ; //cDMA write start addr
	logic                                     cdma_waddr_vld    ; //vld sigal for i_cdma_waddr. It's also the signal to ask for cDMA to prepare for the transaction, shoulde be pulse
	logic [cDMA_TRANS_WIDTH-1:0]              cdma_wsize        ; //The length of one cDMA write, total size in byte = i_cdma_wsize * M_AXI_DATA_WIDTH / 8
	// logic                                     cdma_wbusy        ; //cDMA is busy, AXI write

	logic [M_AXI_ADDR_WIDTH-1:0]              cdma_raddr        ; //cDMA read start addr
	logic                                     cdma_raddr_vld    ; //vld sigal for i_cdma_raddr. It's also the signal to ask for cDMA to prepare for the transaction, shoulde be pulse
	logic [cDMA_TRANS_WIDTH-1:0]              cdma_rsize        ; //The length of one cDMA read, total size in byte = i_cdma_rsize * M_AXI_DATA_WIDTH / 8
	// logic                                     cdma_rbusy        ; //cDMA is busy, AXI read
	
	//cdma write
	logic slv_reg1_redge;
	logic [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1_r1;
	assign slv_reg1_redge = (~slv_reg1_r1[0]) && slv_reg1[0]; //slv_reg1 must be 0 after next cDMA trans, rise edge
	always_ff@(posedge clk)begin
		slv_reg1_r1 <= slv_reg1;
	end

	always_ff@(posedge clk or negedge rst_n)begin
		if(~rst_n)
			cdma_waddr     <= 0;    
		else 
			cdma_waddr     <= slv_reg0;    
	end

	always_ff@(posedge clk or negedge rst_n)begin
		if(~rst_n)
			cdma_waddr_vld     <= 0;    
		else 
			cdma_waddr_vld     <= slv_reg1_redge;    //pulse
	end

	always_ff@(posedge clk or negedge rst_n)begin
		if(~rst_n)
			cdma_wsize     <= 0;    
		else 
			cdma_wsize     <= slv_reg2;    
	end

	//cdma read
	logic slv_reg5_redge;
	logic [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5_r1;
	assign slv_reg5_redge = (~slv_reg5_r1[0]) && slv_reg5[0]; //slv_reg5 must be 0 after next cDMA trans, rise edge
	always_ff@(posedge clk)begin
		slv_reg5_r1 <= slv_reg5;
	end

	always_ff@(posedge clk or negedge rst_n)begin
		if(~rst_n)
			cdma_raddr     <= 0;    
		else 
			cdma_raddr     <= slv_reg4;    
	end

	always_ff@(posedge clk or negedge rst_n)begin
		if(~rst_n)
			cdma_raddr_vld     <= 0;    
		else 
			cdma_raddr_vld     <= slv_reg5_redge;    //pulse
	end

	always_ff@(posedge clk or negedge rst_n)begin
		if(~rst_n)
			cdma_rsize     <= 0;    
		else 
			cdma_rsize     <= slv_reg6;    
	end
	data_loop#
	(
	.M_AXI_ID_WIDTH        (M_AXI_ID_WIDTH      ),
	.M_AXI_ID              (M_AXI_ID            ),
	.M_AXI_ADDR_WIDTH      (M_AXI_ADDR_WIDTH    ),
	.M_AXI_DATA_WIDTH      (M_AXI_DATA_WIDTH    ),
	.M_AXI_MAX_BURST_LEN   (M_AXI_MAX_BURST_LEN ),
	.cDMA_TRANS_WIDTH      (cDMA_TRANS_WIDTH    ),
	.AXI_BURST_SIZE_WIDTH  (AXI_BURST_SIZE_WIDTH),

	.BRAM_ADDR_WIDTH       (BRAM_ADDR_WIDTH     ),
	.BRAM_MEM_DEPTH        (BRAM_MEM_DEPTH      )

	)inst_data_loop
	(
	.clk            	   (clk     			),
	.rst_n          	   (rst_n   			),

	.cdma_waddr     	   (cdma_waddr       	), //cDMA write start addr
	.cdma_waddr_vld 	   (cdma_waddr_vld   	), //vld sigal for i_cdma_waddr. It's also the signal to ask for cDMA to prepare for the transaction, shoulde be pulse
	.cdma_wsize     	   (cdma_wsize       	), //The length of one cDMA write, total size in byte = i_cdma_wsize * M_AXI_DATA_WIDTH / 8
	.cdma_wbusy     	   (cdma_wbusy       	), //cDMA is busy, AXI write

	.cdma_raddr     	   (cdma_raddr       	), //cDMA read start addr
	.cdma_raddr_vld 	   (cdma_raddr_vld   	), //vld sigal for i_cdma_raddr. It's also the signal to ask for cDMA to prepare for the transaction, shoulde be pulse
	.cdma_rsize     	   (cdma_rsize       	), //The length of one cDMA read, total size in byte = i_cdma_rsize * M_AXI_DATA_WIDTH / 8
	.cdma_rbusy     	   (cdma_rbusy       	), //cDMA is busy, AXI read


	//AXI BUS
	.M_AXI_ACLK	    	   (M_AXI_ACLK	    	), //AXI global clk
	.M_AXI_ARESETN		   (M_AXI_ARESETN		), //AXI global rst_n

	.M_AXI_AWID			   (M_AXI_AWID			), //AXI ID, useless here, it's for out of order transaction, which cDMA doesn't support
	.M_AXI_AWADDR		   (M_AXI_AWADDR		), //AXI write address
	.M_AXI_AWLEN		   (M_AXI_AWLEN			), //AXI write burst length
	.M_AXI_AWSIZE		   (M_AXI_AWSIZE		), //The size of each burst (This value is equal to log2(M_AXI_DATA_WIDTH/8))
	.M_AXI_AWBURST		   (M_AXI_AWBURST		), //burst type, cDMA only support 2'b01: INCR, the addr will increase AxSIZE each time
	.M_AXI_AWLOCK		   (M_AXI_AWLOCK		), //Don't care here (I don't know it, I just give it zero like an example from Xilinx)
	.M_AXI_AWCACHE		   (M_AXI_AWCACHE		), //Memory type, give a fixed value
	.M_AXI_AWPROT		   (M_AXI_AWPROT		), //Protection type, give a fixed value
	.M_AXI_AWQOS		   (M_AXI_AWQOS			), //Quality of Service, give a fixed value
	.M_AXI_AWVALID		   (M_AXI_AWVALID		), //Write addr channel valid signal
	.M_AXI_AWREADY		   (M_AXI_AWREADY		), //Write addr channel ready signal

	.M_AXI_WID			   (M_AXI_WID			), //AXI ID
	.M_AXI_WDATA		   (M_AXI_WDATA			), //AXI write data
	.M_AXI_WSTRB		   (M_AXI_WSTRB			), //Write strobes. This signal indicates which byte lanes hold valid data.
	.M_AXI_WLAST		   (M_AXI_WLAST			), //Write last
	.M_AXI_WVALID		   (M_AXI_WVALID		), //Write data channel valid signal
	.M_AXI_WREADY		   (M_AXI_WREADY		), //Write data channel ready signal

	.M_AXI_BID			   (M_AXI_BID			), //AXI ID
	.M_AXI_BRESP		   (M_AXI_BRESP			), //Write response (Most of time it's OKAY. If it is not, I don't how to deal that)
	.M_AXI_BVALID		   (M_AXI_BVALID		), //Write response channel valid
	.M_AXI_BREADY		   (M_AXI_BREADY		), //Wrire response channel ready

	.M_AXI_ARID			   (M_AXI_ARID			), //AXI ID
	.M_AXI_ARADDR		   (M_AXI_ARADDR		), //AXI read address	 	
	.M_AXI_ARLEN		   (M_AXI_ARLEN			), //AXI read burst length
	.M_AXI_ARSIZE		   (M_AXI_ARSIZE		), //The size of each burst (This value is equal to log2(M_AXI_DATA_WIDTH/8))	 
	.M_AXI_ARBURST		   (M_AXI_ARBURST		), //Burst type	 
	.M_AXI_ARLOCK		   (M_AXI_ARLOCK		), //Don't care here (I don't know it, I just give it zero like an example from Xilinx)	 
	.M_AXI_ARCACHE		   (M_AXI_ARCACHE		), //Memory type 
	.M_AXI_ARPROT		   (M_AXI_ARPROT		), //Protection type 
	.M_AXI_ARQOS		   (M_AXI_ARQOS			), //Quality of Service	 	   
	.M_AXI_ARVALID		   (M_AXI_ARVALID		), //Read address channel valid	 
	.M_AXI_ARREADY		   (M_AXI_ARREADY		), //Read address channel ready	 

	.M_AXI_RID			   (M_AXI_RID			), //AXI ID	 
	.M_AXI_RDATA		   (M_AXI_RDATA			), //AXI read data	 
	.M_AXI_RRESP		   (M_AXI_RRESP			), //Read response. This signal indicates the status of the read transfer
	.M_AXI_RLAST		   (M_AXI_RLAST			), //Read last
	.M_AXI_RVALID		   (M_AXI_RVALID		), //Read channel valid   
	.M_AXI_RREADY		   (M_AXI_RREADY		)  //Read channel ready    
	);
	// User logic ends

	endmodule
