/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */

#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"
//#include "includes/lsp.h"

configuration NodeC{
    
}
implementation {
    components MainC;
    components Node;
    // components new AMReceiverC(AM_PACK) as GeneralReceive;
    // components new ListC(pack, 100) as neighborListC;
    // components new ListC(lsp, 100) as lspListC;
    // components new HashmapC(int, 200) as routingTableC;

    Node -> MainC.Boot;

    components new AMReceiverC(AM_PACK) as GeneralReceive;
    Node.Receive -> GeneralReceive;

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;

    components FloodingC;
    Node.Flooding -> FloodingC.Flooding;
    Node.floodReceive -> FloodingC.floodReceive;
    //Node.routingTableSender -> FloodingC.routingTableSender;
    // FloodingC.lspListC -> lspListC;
    // FloodingC.routingTableC -> routingTableC;

    components NeighborDiscoveryC;
    Node.NeighborDiscovery -> NeighborDiscoveryC;
    // NeighborDiscoveryC.neighborListC -> neighborListC;
    // LinkStateC.lspListC -> lspListC;

    components LinkStateC;
    Node.LinkState -> LinkStateC;
    //Node.routingTable -> routingTableC;
    // LinkStateC.neighborListC -> neighborListC;
    // LinkStateC.routingTable -> routingTableC;

    components ForwarderC;
	Node.Forwarder -> ForwarderC.Forwarder;
	Node.ForwarderReceiver -> ForwarderC.ForwarderReceiver;

    // components new TimerMilliC() as periodicTimer;
    // Node.periodicTimer -> periodicTimer;

    components TransportC;
    Node.Transport -> TransportC;

    components ChatC;
    Node.Chat -> ChatC;

    components new QueueC(socket_t, 100) as SocketQueue;
    Node.SocketQueue -> SocketQueue;

}
