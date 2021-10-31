#include "../../includes/neighbor.h"
#define AM_NEIGHBOR 15

configuration NeighborDiscoveryC{
    provides interface NeighborDiscovery;
}

implementation {
    components NeighborDiscoveryP;
    NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;
    //NeighborDiscovery.neighborList = neighborListC;
    
    //100 is a random number I picked
    components new ListC(pack, 100) as neighborList;
    NeighborDiscoveryP.neighborList -> neighborList;

    components FloodingC;
    NeighborDiscoveryP.Flooding -> FloodingC.Flooding;

    components new TimerMilliC() as periodicTimer;
    NeighborDiscoveryP.periodicTimer -> periodicTimer;

    components new TimerMilliC() as printTimer;
    NeighborDiscoveryP.printTimer -> printTimer;

    components new SimpleSendC(AM_NEIGHBOR);
    NeighborDiscoveryP.Flooding -> SimpleSendC;

    components new AMReceiverC(AM_NEIGHBOR);
    NeighborDiscoveryP.neighborReceive -> AMReceiverC;

    // components RandomC as random;
    // NeighborDiscoveryP.random -> random;

}