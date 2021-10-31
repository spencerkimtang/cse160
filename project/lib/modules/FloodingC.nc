#include "../../includes/am_types.h"

configuration FloodingC {
    provides interface SimpleSend as Flooding;
    // provides interface SimpleSend as lspSender;
    // provides interface SimpleSend as routingTableSender;
    provides interface Receive as floodReceive;
}

implementation {

    components FloodingP;
    Flooding = FloodingP.Flooding;
    floodReceive = FloodingP.floodReceive;
    // lspSender = FloodingP.lspSender;
    // routingTableSender = FloodingP.routingTableSender;

    components new SimpleSendC(AM_FLOODING);
    FloodingP.InsideSend -> SimpleSendC;

    components new AMReceiverC(AM_FLOODING) as GeneralReceive;
    FloodingP.Gotit -> GeneralReceive;

    //100 is a random number I picked
    components new ListC(pack, 100) as CacheList;
    FloodingP.CacheList -> CacheList;
    
    components NeighborDiscoveryC;
    FloodingP.NeighborDiscovery -> NeighborDiscoveryC;

    // components new ListC(lsp, 100) as lspListC;
    // FloodingP.lspList -> lspListC;

    // components new HashmapC(int, 100) as routingTableC;
    // FloodingP.routingTable -> routingTableC;

}