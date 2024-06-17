//Pseudo-Dual-Port BRAM

module PDP_bram #(
parameter  ADDR_WIDTH  =  16,
parameter  DATA_WIDTH  =  128,
parameter  MEM_DEPTH   =  'h4000 //16384
)
(
input  logic                  clk,     
               
input  logic                  wren,                   
input  logic [ADDR_WIDTH-1:0] wraddr,                 
input  logic [DATA_WIDTH-1:0] wrdata,                 

input  logic                  lock, //lock the read data
input  logic                  rden,                   
input  logic [ADDR_WIDTH-1:0] rdaddr,                 
output logic [DATA_WIDTH-1:0] rddata                               
);
 

 
(*ram_style = "block"*)  logic  [DATA_WIDTH-1:0] mem [MEM_DEPTH-1:0];            

always_ff@(posedge clk) begin
    if(wren)
        mem[wraddr] <= wrdata;
end

always_ff@(posedge clk) begin
    if(lock)
        rddata<=rddata;
    else if(rden)
        rddata <= mem[rdaddr];
end
endmodule

