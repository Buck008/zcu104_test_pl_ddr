#include "FPGA_init.h"

void *mem_map_base;
void *data_loop_map_base;
int fd;
void FPGA_init()
{
	fd=open("/dev/mem",O_RDWR|O_SYNC);
	if(fd==-1)
		printf("Error: Can't open /dev/mem\n");
	
	data_loop_map_base=mmap(0,DATA_LOOP_SIZE,PROT_READ|PROT_WRITE,MAP_SHARED,fd,DATA_LOOP_BASEADDR);
	if(data_loop_map_base==NULL)
		printf("Error: data_loop mmap fail\n");
   
   
	mem_map_base=mmap(0,PL_DDR_SIZE,PROT_READ|PROT_WRITE,MAP_SHARED,fd,PL_DDR_BASE_ADDR);
	if(mem_map_base==NULL)
		printf("Error: mem_base mmap fail\n");

	// signal(SIGALRM, handle_timeout);
	// alarm(5);  
	// for(int i=0;i<0x40000;i++)
	// 	*(int *)(((uint64_t)mem_map_base)+i*4)=0;
	
	// for(int i=0;i<0x40000;i++)
	// {
	// 	if(*(int *)(((uint64_t)mem_map_base)+i*4)!=0)
	// 		printf("ddr4[%d]=%d\n",i,*(int *)(((uint64_t)mem_map_base)+i*4));
	// }
	// alarm(0);
	printf("FPGA Init Done\n");
}

void FPGA_finish()
{
	munmap(data_loop_map_base, DATA_LOOP_SIZE);
	munmap(mem_map_base, PL_DDR_SIZE);
}

void handle_timeout(int sig) {
    printf("Operation timed out, FPGA init failed.\n");
	exit(0);
}