#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include "../../includes/TCP.h"

module ForwarderP{
	provides interface SimpleSend as Forwarder;
	provides interface Receive as ForwarderReceiver;

	uses interface SimpleSend as InsideSender;
	uses interface Receive as InsideReceive;

	uses interface LinkState as routingTable;
	uses interface Transport;
}

implementation{

    command error_t Forwarder.send(pack message, uint16_t dest){
		uint16_t nextHop = 0;
		nextHop = call routingTable.getNextHop(dest);

		if(nextHop == 999 || nextHop < 1){
			dbg(ROUTING_CHANNEL, "No Route Found\n");
		}
        else{
			dbg(ROUTING_CHANNEL, "Forwarding Packet to %u to get to %u\n", nextHop, dest);
			call InsideSender.send(message, nextHop);
		}
	}

    event message_t* InsideReceive.receive(message_t* message, void* payload, uint8_t len){
		uint16_t holder = 0;
		uint16_t nextHop = 0;
		pack *newMsg = (pack*) payload;
		tcp* myTCP;
		myTCP = (tcp*)(newMsg->payload);
		newMsg->TTL -= 1;

		if(newMsg->dest == TOS_NODE_ID){
			if(newMsg->protocol == PROTOCOL_PINGREPLY){
				dbg(ROUTING_CHANNEL, "Got PingReply\n");
			} 
            else if (newMsg->protocol == PROTOCOL_PING){
				holder = newMsg->src;
				newMsg->src = newMsg->dest;
				newMsg->dest = holder;
				newMsg->TTL = 15;
				call Forwarder.send(*newMsg, newMsg->dest);
			} 
            else if (newMsg->protocol == PROTOCOL_TCP){
				dbg(TRANSPORT_CHANNEL, "Node %u got Packet type %c\n", TOS_NODE_ID, myTCP->flags);
				call Transport.receive(newMsg);
			}
		}
        
        else{
			if(newMsg->TTL == 0){
				dbg(ROUTING_CHANNEL, "Dropping Packet");
                return message;
			}
				
			nextHop = call routingTable.getNextHop(newMsg->dest);
			
            if(nextHop < 1 || nextHop >= 999){
				dbg(ROUTING_CHANNEL, "Dropping Packet");
				return message;
			}
			call Forwarder.send(*newMsg, nextHop);
		}
		return message;
	}

}
