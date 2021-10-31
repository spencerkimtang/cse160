#include "../../includes/am_types.h"

configuration LinkStateC{
    provides interface LinkState;
}

implementation{
    components LinkStateP;
    LinkState = LinkStateP.LinkState;

    components ForwarderC;
    LinkStateP.lspSender -> ForwarderC.Forwarder;

    components new TimerMilliC() as lsTimer;
    LinkStateP.lsTimer -> lsTimer;

    components new TimerMilliC() as spTimer;
    LinkStateP.spTimer -> spTimer;

    components RandomC as random;
    LinkStateP.random -> random;

    components new ListC(pack, 100) as neighborListC;
    LinkStateP.neighborList -> neighborListC;
    
    components new ListC(lsp, 100) as lspListC;
    LinkStateP.lspList -> lspListC;
    
    components new  HashmapC(int, 100) as routingTableC;
    LinkStateP.routingTable -> routingTableC;
}