
`timescale 1ns / 1ps 
module cdma_axi_slave_test(
  input sysclk
);

wire [31:0]   cdma_raddr;
reg           cdma_rareq;
wire          cdma_rbusy;
wire [31:0]   cdma_rdata;
wire [15:0]   cdma_rsize;
wire          cdma_rvalid;
wire [31:0]   cdma_waddr;
reg           cdma_wareq;
wire          cdma_wbusy;
wire [31:0]   cdma_wdata;
wire [15:0]   cdma_wsize;
reg           cdma_wvalid;
wire          cdma_wready;
wire          ui_clk;

reg [10:0]    cdma_wvalid_delay_cnt;

parameter TEST_MEM_SIZE   = 32'd20000; //in byte
parameter cdma_BURST_LEN  = 16'd1000; // TEST_MEM_SIZE / (cdma_BURST_LEN*4) = 5 is integer
// parameter ADDR_MEM_OFFSET = 0; 
parameter ADDR_MEM_OFFSET = 32'h0000_0000; 
parameter ADDR_INC = cdma_BURST_LEN*4;
 
parameter WRITE1 = 0;
parameter WRITE2 = 1;
parameter WAIT   = 2;
parameter READ1  = 3;
parameter READ2  = 4;

reg [31: 0] t_data;
reg [31: 0] cdma_waddr_r;
reg [2  :0] T_S = 0;

assign cdma_waddr = cdma_waddr_r + ADDR_MEM_OFFSET;
assign cdma_raddr = cdma_waddr;

assign cdma_wsize = cdma_BURST_LEN;
assign cdma_rsize = cdma_BURST_LEN;
assign cdma_wdata =t_data; 
  
  
//delay reset
reg [8:0] rst_cnt = 0;
always @(posedge ui_clk)
    if(rst_cnt[8] == 1'b0)
         rst_cnt <= rst_cnt + 1'b1;
     else 
         rst_cnt <= rst_cnt;

always @(posedge ui_clk)begin
    if(rst_cnt[8] == 1'b0)begin
        T_S <=0;   
        cdma_wareq  <= 1'b0; 
        cdma_rareq  <= 1'b0; 
        t_data<=0;
        cdma_waddr_r <= 0;
        cdma_wvalid <= 0;
        cdma_wvalid_delay_cnt <= 0;       
    end 
    else begin
        case(T_S)      
        WRITE1:begin
            cdma_wvalid_delay_cnt <=0;

            if(cdma_waddr_r==TEST_MEM_SIZE) cdma_waddr_r<=0; 
            
            if(!cdma_wbusy)begin
                cdma_wareq  <= 1'b1; 
                t_data  <= 0;
            end

            if(cdma_wareq&&cdma_wbusy)begin
                cdma_wareq  <= 1'b0; 
                T_S         <= WRITE2;
            end
        end
        WRITE2:begin
            if(!cdma_wbusy) begin
                 T_S <= WAIT;
                 t_data  <= 32'd0;
            end 
            else if(!cdma_wvalid)begin
                cdma_wvalid_delay_cnt <= cdma_wvalid_delay_cnt+1;
                if(cdma_wvalid_delay_cnt == 1)
                    cdma_wvalid <= 1;
            end
            else if(cdma_wvalid&&cdma_wready) begin
                t_data <= t_data + 1'b1;
            end
        end
        WAIT:begin//not needed
            T_S <= READ1;
            cdma_wvalid <= 0;
        end
        READ1:begin
            if(!cdma_rbusy)begin
                cdma_rareq  <= 1'b1; 
                t_data   <= 0;
            end
            if(cdma_rareq&&cdma_rbusy)begin
                 cdma_rareq  <= 1'b0; 
                 T_S         <= READ2;
            end 
        end
        READ2:begin
            if(!cdma_rbusy) begin
                 T_S <= WRITE1;
                 t_data  <= 32'd0;
                 cdma_waddr_r  <= cdma_waddr_r + ADDR_INC;//128/8=16
            end 
            else if(cdma_rvalid) begin
                t_data <= t_data + 1'b1;
            end
        end   
        default:
            T_S <= WRITE1;     
        endcase
    end
  end
  
wire test_error = (cdma_rvalid && (t_data[15:0] != cdma_rdata[15:0]));

  system system_i
       (.cDMA_S_i_cdma_raddr(cdma_raddr),
        .cDMA_S_i_cdma_raddr_vld(cdma_rareq),
        .cDMA_S_o_cdma_rbusy(cdma_rbusy),
        .cDMA_S_o_cdma_rdata(cdma_rdata),
        .cDMA_S_i_cdma_rready(1'b1),
        .cDMA_S_i_cdma_rsize(cdma_rsize),
        .cDMA_S_o_cdma_rvalid(cdma_rvalid),
        .cDMA_S_i_cdma_waddr(cdma_waddr),
        .cDMA_S_i_cdma_waddr_vld(cdma_wareq),
        .cDMA_S_o_cdma_wbusy(cdma_wbusy),
        .cDMA_S_i_cdma_wdata(cdma_wdata),
        .cDMA_S_o_cdma_wready(cdma_wready),
        .cDMA_S_i_cdma_wsize(cdma_wsize),
        .cDMA_S_i_cdma_wvalid(cdma_wvalid),
        .sysclk(sysclk),
        .ui_clk(ui_clk)
        );        

endmodule
