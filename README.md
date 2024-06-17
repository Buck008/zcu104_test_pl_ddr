# zcu104_test_pl_ddr
test PL DDR; run in C++; self defined memory controller for PL DDR; vivado 2022.1.  

cDMA: custom DMA, changed from FDMA. simple shake hand channel <=> cDMA <=> AXI Master channel.  

data_loop: read the data from DDR, and write the same data to the DDR. Something like DUT.
