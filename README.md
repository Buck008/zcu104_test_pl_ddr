# zcu104_test_pl_ddr
test PL DDR; run in C++; self defined memory controller for PL DDR; vivado 2022.1.  The whole system runs on Linux system.

cDMA: custom DMA, changed from FDMA. simple shake hand channel <=> cDMA <=> AXI Master channel.  

data_loop: read the data from DDR, and write the same data to the DDR. Something like DUT.

FPGA_DDR.cpp: A simple self defined function to control the PL side's DDR. (Something like malloc and free.)

FPGA_init.cpp: Physical memory address mapping to Virtual memory address.

FPGA_basic.cpp: FPGA_write/read32: Use the AXI Lite interface to write and read the control registers' value.

Use the system.tcl to rebuild the block design.
![image](https://github.com/Buck008/zcu104_test_pl_ddr/assets/75256444/65cc6a04-704c-4c7c-89df-2b9198410b20)
![image](https://github.com/Buck008/zcu104_test_pl_ddr/assets/75256444/327e59ff-55a2-4187-b12f-838d5881d756)
![image](https://github.com/Buck008/zcu104_test_pl_ddr/assets/75256444/f2e49ba3-851d-449c-982d-ba8c983816f7)
