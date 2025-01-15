#include <iostream>
#include <vector>
#include <cstring>
#include <chrono>

#include "FPGA_init.h"
#include "FPGA_DDR.h"
#include "FPGA_basic.h"

#define BRAM_DEPTH 0x4000
#define BRAM_WIDTH 16 //16byte
//0x4000 * 16B = 256KB
#define FPGA_DDR_DATA_LOOP_BIAS_ADDR 0x00000000
#define CDMA_WADDR_OFFSET 0
#define CDMA_WADDR_VLD_OFFSET 4
#define CDMA_WSIZE_OFFSET 8
#define CDMA_WBUSY_OFFSET 12

#define CDMA_RADDR_OFFSET 16
#define CDMA_RADDR_VLD_OFFSET 20
#define CDMA_RSIZE_OFFSET 24
#define CDMA_RBUSY_OFFSET 28

extern void *mem_map_base;
extern void *data_loop_map_base;

int main() {
    auto start = std::chrono::steady_clock::now();
    
    // Initialize
    FPGA_init();
    // return 0;
    std::cout << "Initial memory state:" << std::endl;

    Debug_mcb();

    // Allocate memory blocks
    int prt1_size = 100;
    void *ptr1 = FPGA_DDR_malloc(prt1_size);

    printf("After allocating %d bytes:\n",prt1_size);
    Debug_mcb();

    unsigned char test_val = 0XAA;

    // Write to and read from memory
    if (ptr1 != FPGA_NULL) {
        for (unsigned int i = 0; i < prt1_size; ++i) {
            *((unsigned char*)ptr1 + i) = test_val;      
        }
        bool success = true;
        for (unsigned int i = 0; i < prt1_size; ++i) {
            if (*((unsigned char*)ptr1 + i) != test_val) {
                success = false;
                break;
            }
        }
        std::cout << "Memory write and read test for ptr1: " << (success ? "Success" : "Failure") << std::endl;
    }
  
    int prt2_size = 200;
    void *ptr2 = FPGA_DDR_malloc(prt2_size);
    printf("After allocating %d bytes:\n",prt2_size);
    Debug_mcb();

    if (ptr2 != FPGA_NULL) {
        for (unsigned int i = 0; i < prt2_size; ++i) {
            *((unsigned char*)ptr2 + i) = test_val;      
        }
        bool success = true;
        for (unsigned int i = 0; i < prt2_size; ++i) {
            if (*((unsigned char*)ptr2 + i) != test_val) {
                success = false;
                break;
            }
        }
        std::cout << "Memory write and read test for ptr2: " << (success ? "Success" : "Failure") << std::endl;
    }
    int prt3_size = 50000;
    void *ptr3 = FPGA_DDR_malloc(prt3_size);
    printf("After allocating %d bytes:\n",prt3_size);
    Debug_mcb();

    if (ptr3 != FPGA_NULL) {
        for (unsigned int i = 0; i < prt3_size; ++i) {
            *((unsigned char*)ptr3 + i) = test_val;      
        }
        bool success = true;
        for (unsigned int i = 0; i < prt3_size; ++i) {
            if (*((unsigned char*)ptr3 + i) != test_val) {
                success = false;
                break;
            }
        }
        std::cout << "Memory write and read test for ptr3: " << (success ? "Success" : "Failure") << std::endl;
    }

    // Free a memory block
    FPGA_DDR_free(ptr2);
    printf("After freeing %d bytes:\n",prt2_size);
    Debug_mcb();

    int prt4_size = 2560;
    void *ptr4 = FPGA_DDR_malloc(prt4_size);
    printf("After allocating %d bytes:\n",prt4_size);
    Debug_mcb();

    if (ptr4 != FPGA_NULL) {
        for (unsigned int i = 0; i < prt4_size; ++i) {
            *((unsigned char*)ptr4 + i) = test_val;      
        }
        bool success = true;
        for (unsigned int i = 0; i < prt4_size; ++i) {
            if (*((unsigned char*)ptr4 + i) != test_val) {
                success = false;
                break;
            }
        }
        std::cout << "Memory write and read test for ptr4: " << (success ? "Success" : "Failure") << std::endl;
    }

    int prt5_size = 12;
    void *ptr5 = FPGA_DDR_malloc(prt5_size);
    printf("ptr5: %lx\n",(uint64_t)ptr5);
    printf("After allocating %d bytes:\n",prt5_size);
    Debug_mcb();

    if (ptr5 != FPGA_NULL) {
        for (unsigned int i = 0; i < prt5_size; ++i) {
            *((unsigned char*)ptr5 + i) = test_val;      
            // printf("i: %d\n",i);
        }
        bool success = true;
        for (unsigned int i = 0; i < prt5_size; ++i) {
            if (*((unsigned char*)ptr5 + i) != test_val) {
                success = false;
                break;
            }
        }
        std::cout << "Memory write and read test for ptr5: " << (success ? "Success" : "Failure") << std::endl;
    }

    // Free all memory blocks
    FPGA_DDR_free(ptr1);
    FPGA_DDR_free(ptr3);
    FPGA_DDR_free(ptr4);
    FPGA_DDR_free(ptr5);
    std::cout << "After freeing all memory blocks:" << std::endl;
    Debug_mcb();
    auto end = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    std::cout << "Runing time: " << duration.count() << " us\n";

    // return 0;
    printf("Start test data loop\n");

    void *TX_BUFFER_BASE = FPGA_DDR_malloc(BRAM_DEPTH*BRAM_WIDTH);
    void *RX_BUFFER_BASE = FPGA_DDR_malloc(BRAM_DEPTH*BRAM_WIDTH);
    uint32_t PS_DDR_array[BRAM_DEPTH*BRAM_WIDTH/4];
    uint32_t * DDR_buf0 = (uint32_t *)TX_BUFFER_BASE ;
    uint32_t * DDR_buf1 = (uint32_t *)RX_BUFFER_BASE ;

    for(int i=0; i <BRAM_DEPTH*BRAM_WIDTH/4;i++ ){
        PS_DDR_array[i] = random();
	}

    // auto start_PS2PL = std::chrono::steady_clock::now();
    // memcpy(DDR_buf0, PS_DDR_array, BRAM_DEPTH*BRAM_WIDTH);
    // //sometime memcpy may have bus error, so don't use this in real project.
    // auto end_PS2PL = std::chrono::steady_clock::now();
    // duration = std::chrono::duration_cast<std::chrono::microseconds>(end_PS2PL - start_PS2PL);
    // std::cout << "PS2PL time: " << duration.count() << " us\n";
    // time difference of memcpy and for loop is very little
    
    auto start_PS2PL = std::chrono::steady_clock::now();
    for(int i=0; i <BRAM_DEPTH*BRAM_WIDTH/4;i++ ){
		DDR_buf0[i] = PS_DDR_array[i];
	}
    auto end_PS2PL = std::chrono::steady_clock::now();
    duration = std::chrono::duration_cast<std::chrono::microseconds>(end_PS2PL - start_PS2PL);
    std::cout << "PS2PL time: " << duration.count() << " us\n";
    
    auto start_TX = std::chrono::steady_clock::now();
	FPGA_write32((void *)((uint64_t)data_loop_map_base+CDMA_RADDR_OFFSET), (uint32_t)((uint64_t)DDR_buf0 -(uint64_t)mem_map_base + FPGA_DDR_DATA_LOOP_BIAS_ADDR));
	FPGA_write32((void *)((uint64_t)data_loop_map_base+CDMA_RSIZE_OFFSET), BRAM_DEPTH);
	FPGA_write32((void *)((uint64_t)data_loop_map_base+CDMA_RADDR_VLD_OFFSET), 1);
	while( FPGA_read32((void *)((uint64_t)data_loop_map_base+CDMA_RBUSY_OFFSET))
    )
    {
		printf("*\n");
	}
    auto end_TX = std::chrono::steady_clock::now();
    FPGA_write32(((void *)((uint64_t)data_loop_map_base+CDMA_RADDR_VLD_OFFSET)), 0);
    
    duration = std::chrono::duration_cast<std::chrono::microseconds>(end_TX - start_TX);
    std::cout << "TX time: " << duration.count() << " us\n";

    printf("Start RX\n");
    auto start_RX = std::chrono::steady_clock::now();
	FPGA_write32((void *)((uint64_t)data_loop_map_base+CDMA_WADDR_OFFSET), (uint32_t)((uint64_t)DDR_buf1 -(uint64_t)mem_map_base + FPGA_DDR_DATA_LOOP_BIAS_ADDR));
	FPGA_write32((void *)((uint64_t)data_loop_map_base+CDMA_WSIZE_OFFSET), BRAM_DEPTH);
	FPGA_write32((void *)((uint64_t)data_loop_map_base+CDMA_WADDR_VLD_OFFSET), 1);
	while(
        FPGA_read32( (void *)((uint64_t)data_loop_map_base+CDMA_WBUSY_OFFSET) )
        )
    {
		printf("*\n");
	}
    auto end_RX = std::chrono::steady_clock::now();
    FPGA_write32((void *)((uint64_t)data_loop_map_base+CDMA_WADDR_VLD_OFFSET), 0);

    duration = std::chrono::duration_cast<std::chrono::microseconds>(end_RX - start_RX);
    std::cout << "RX time: " << duration.count() << " us\n";

    int result = memcmp(PS_DDR_array, DDR_buf1, BRAM_DEPTH*BRAM_WIDTH);
    if(result==0){
		printf("Right!\n");
	}else{
		printf("Wrong!\n");
	}
    int error_cnt = 0;
	for(int i=0; i <BRAM_DEPTH*BRAM_WIDTH/4;i++ ){
//		if(i<100){
//			printf("DDR_buf0[%d] = %d, DDR_buf1[%d] = %d\n",i,DDR_buf0[i],i,DDR_buf1[i]);
//		}
		if(PS_DDR_array[i] != DDR_buf1[i]){
			error_cnt++;
			if(error_cnt<100){
				printf("PS_DDR_array[%d] = %d, DDR_buf1[%d] = %d, DDR_buf0[%d] = %d\n",i,PS_DDR_array[i],i,DDR_buf1[i],i,DDR_buf0[i]);
			}
		}
	}
    FPGA_DDR_free(TX_BUFFER_BASE);
    FPGA_DDR_free(RX_BUFFER_BASE);
    FPGA_finish();
    return 0;
}


// int main(int argc, char const *argv[])
// {
//     printf("Hello\n");
//     return 0;
// }
