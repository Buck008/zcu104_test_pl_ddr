#include "FPGA_DDR.h"
#include "FPGA_init.h"

using namespace std;
extern void *mem_map_base;
vector<mem_control_block> mcb(1);
unsigned int has_initialized=0;

void *FPGA_DDR_malloc(unsigned int numbytes)
{
	//make sure the address is aligned to MIN_BLOCK_SIZE
	numbytes=((numbytes+MIN_BLOCK_SIZE-1)/MIN_BLOCK_SIZE)*MIN_BLOCK_SIZE;
	 
	if(!has_initialized)
	{
		mcb[0].available=1;
		mcb[0].blocksize=FPGA_DDR_SIZE;
		mcb[0].pl_DDR_address=FPGA_DDR_BASE_ADDRESS;
		has_initialized=1;
	}
	//Debug_mcb();

	unsigned int current_mcb_num=0;
	void * memory_location = FPGA_NULL;
	while(current_mcb_num<mcb.size())
	{
		if(mcb[current_mcb_num].available)
		{
			if(mcb[current_mcb_num].blocksize>=numbytes)//Find the appropriate memory block
			{
				//printf("Malloc Success:%d\n",NULL);
				memory_location=(void *)mcb[current_mcb_num].pl_DDR_address;
				mcb[current_mcb_num].available=0;
				if(mcb[current_mcb_num].blocksize>numbytes) //Split the memory block
				{
					mem_control_block new_mcb;
					new_mcb.available=1;
					new_mcb.blocksize=mcb[current_mcb_num].blocksize-numbytes;
					new_mcb.pl_DDR_address=mcb[current_mcb_num].pl_DDR_address+numbytes;
					mcb.insert(mcb.begin()+current_mcb_num+1,new_mcb);
				}
				mcb[current_mcb_num].blocksize=numbytes;
				break;
			}
		}
		current_mcb_num++;
	}

	return (void*)((uint64_t)memory_location+(uint64_t)mem_map_base);
}

void FPGA_DDR_free(void *mcb_base_addr) 
{
//    printf("free here:%lx\n",(uint64_t)mcb_base_addr-(uint64_t)mem_map_base);
	unsigned int current_mcb_num=0;
	for(int i=0;i<mcb.size();i++)
	{
		if(mcb[i].pl_DDR_address==(uint64_t)mcb_base_addr-(uint64_t)mem_map_base)
		{
			current_mcb_num=i;
			break;
		}
	}
	mcb[current_mcb_num].available=1;
	//If the latter block is also free, merge the latter block
	if(current_mcb_num!=mcb.size()-1)
	{
		if(mcb[current_mcb_num+1].available)
		{
			mcb[current_mcb_num].blocksize+=mcb[current_mcb_num+1].blocksize;
			mcb.erase(mcb.begin()+current_mcb_num+1,mcb.begin()+current_mcb_num+2);
		}
	}
	//If the previous block is also free, merge the previous block
	if(current_mcb_num!=0)
	{
		if(mcb[current_mcb_num-1].available)
		{
			mcb[current_mcb_num-1].blocksize+=mcb[current_mcb_num].blocksize;
			mcb.erase(mcb.begin()+current_mcb_num,mcb.begin()+current_mcb_num+1);
		}
	}
}

void Debug_mcb()
{
	printf("===========================\n");
	for(int i=0;i<mcb.size();i++)
	{
		printf("mcb[%d]: avaiable:%d,[%lx,%lx]\n",i,mcb[i].available,mcb[i].pl_DDR_address,mcb[i].pl_DDR_address+mcb[i].blocksize-1);
	}
	printf("===========================\n");
}
