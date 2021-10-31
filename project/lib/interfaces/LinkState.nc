#include "../interfaces/tableInfo.h"

interface LinkState{
	command void start();
	command void print();
	command void printRoutingTable();
	command uint16_t getNextHop(uint16_t dest);
}