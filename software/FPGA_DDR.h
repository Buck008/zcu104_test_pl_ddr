#ifndef __FPGA_DDR__
#define __FPGA_DDR__

#include <stdio.h>
#include <vector>
#include <stdint.h>



#define FPGA_DDR_BASE_ADDRESS    0x00000000
#define FPGA_DDR_SIZE            0x100000000 //4GB
#define MIN_BLOCK_SIZE           0x100 //256B
extern void *mem_map_base;

struct mem_control_block{
unsigned char available;         // whether block is avaiable 
uint64_t blocksize;          // block size 
uint64_t pl_DDR_address;  // the address of DDR on FPGA board 
mem_control_block() : available(0), blocksize(FPGA_DDR_SIZE), pl_DDR_address(0) {}
};


#define FPGA_NULL (void *)(0xFFFFFFFF+(uint64_t)mem_map_base)
                    
void Debug_mcb();
void *FPGA_DDR_malloc(unsigned int numbytes);
void FPGA_DDR_free(void *firstbyte);

#endif
