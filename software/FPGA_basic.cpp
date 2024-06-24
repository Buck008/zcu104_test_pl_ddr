#include "FPGA_basic.h"

__attribute__((optimize("-O0"))) uint32_t FPGA_read32(void* Addr)
{
	return *(volatile uint32_t *) Addr;
}

__attribute__((optimize("-O0"))) void FPGA_write32(void* Addr, uint32_t Value)
{
	volatile uint32_t *LocalAddr = (volatile uint32_t *)Addr;
	*LocalAddr = Value;
}