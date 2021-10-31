#include "../../includes/neighbor.h"

interface NeighborDiscovery{
	command void start();
	command void neighborReceived(uint16_t source);
	command void printNeighborhood();
	command void startPrint();
	command Neighbor* getNeighborhood();
	command uint16_t neighborhoodSize();
}