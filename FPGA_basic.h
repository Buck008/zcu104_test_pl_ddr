#ifndef __FPGA_BASIC__
#define __FPGA_BASIC__

#include <stdio.h>
#include <vector>
#include <stdint.h>

uint32_t FPGA_read32(void* Addr);
void FPGA_write32(void* Addr, uint32_t Value);

#endif