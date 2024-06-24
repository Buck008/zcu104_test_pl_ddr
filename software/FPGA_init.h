#ifndef _FPGA_INIT_
#define _FPGA_INIT_
#include <iostream>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>

#define PL_DDR_BASE_ADDR    0x0400000000
#define PL_DDR_SIZE         0x0100000000

#define DATA_LOOP_BASEADDR  0x00A0000000
#define DATA_LOOP_SIZE      0x0000001000
void FPGA_init();
void FPGA_finish();
void handle_timeout(int sig);
#endif 
