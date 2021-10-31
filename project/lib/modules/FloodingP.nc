/*
    Flooding needs 3 things sending, receiving and checking for double

    *TinyOS notes*
    "message_t" data type stores packet content
    "error_t" data type that describes error codes like fail or success
    "command" is like function 
    "event" is for timed based functon like for timer
    "call" is for calling command/event on an interface

    "TOS_NODE_ID" means address of node
    "AM_BROADCAST_ADDR" mean broadcasting to all nodes

    *My notes*
    Using list to store "message", since list is like cache with pop and push
    message doesn't need to be stored after sent
*/

// to fixing flooding get orginal destination from first iteration 
//by making a function to store the value
// then make another else if that calles that function when true to output the node got it
//or then change condition in else if statement that has dbg "node got it"

#include "../../includes/protocol.h"
#include "../../includes/channels.h"
#include "../../includes/packet.h"
//#include "../../includes/lsp.h"
#include "../../includes/CommandMsg.h"


module FloodingP{
    uses interface NeighborDiscovery;

    //Using list to store "message", since list is like cache with pop and push
    //message doesn't need to be stored after sent
    uses interface List<pack> as CacheList;
    //uses interface List<lsp> as lspList;
    //uses interface Hashmap<int> as routingTable;
    uses interface Receive as Gotit;
    
    //Flooding (from above) is for sending
    //InsideSend is for sending newMsg, stop loops 
    uses interface SimpleSend as InsideSend;    

    provides interface SimpleSend as Flooding;
    provides interface Receive as floodReceive;
    //provides interface SimpleSend as lspSender;
    //provides interface SimpleSend as routingTableSender;
}

implementation{
    //re-naming pack from packet.h
    pack sendPackage;
    uint16_t seqNumber = 0;
    bool duplicate(pack* message);
    void Cache (pack *messsage);
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length);

    // lsp lspLink;
    // uint16_t age;


    //using error_t so can output "fail or success"
    command error_t Flooding.send(pack message, uint16_t dest){
        //node address
        message.src = TOS_NODE_ID;
        //message.protocol = PROTOCOL_PING;
        //seq# increments for each message not hop
        message.seq = seqNumber + 1;
        //TTL is given in packet.h
        message.TTL = MAX_TTL;
        //sending packet
        //dbg(FLOODING_CHANNEL, "Flooding Network: %s\n", message.payload);
        call InsideSend.send(message, AM_BROADCAST_ADDR);
        //dbg(FLOODING_CHANNEL, "Flooding Network: Message has been sent\n");
    }

    // command error_t lspSender.send(pack message, uint16_t dest){
    //     call InsideSend.send(message, AM_BROADCAST_ADDR);
    // }

    // command error_t routingTableSender.send(pack message, uint16_t dest){
    //     message.seq = seqNumber + 1;
    //     call InsideSend.send(message, dest);
    // }
    
    // event message_t* Gotit.receive(message_t *message, void *payload, uint8_t len){
    //     //dbg(FLOODING_CHANNEL, "Flooding Network: Received message\n"); 

    //     if (len == sizeof(pack)){
    //         pack* newMsg = (pack*) payload;
    //         //uint16_t nextHop = 0;
    //         //uint16_t temp;

    //         uint16_t i;
    //         pack secMsg;
    //         //dbg(FLOODING_CHANNEL, "checking size of payloads\n");

    //         if (newMsg -> TTL == 0){
    //             //dbg(FLOODING_CHANNEL, "TTL is zero\n");
    //             //Sending message back to sender
    //             return message;
    //         }
            
    //         //checking for duplicate
    //         for (i = 0; i < call CacheList.size(); i++){
    //             secMsg = call CacheList.get(i);
    //             if (secMsg.seq == newMsg->seq && secMsg.src == newMsg->src && secMsg.dest == newMsg->dest){
    //                 //dbg(FLOODING_CHANNEL, "dupilicate\n");              
    //             return message;
    //             }
    //         }
            
    //         Cache(newMsg);

    //         else if (TOS_NODE_ID == newMsg->dest){
                
    //             //ping is searching
    //             if (newMsg -> protocol == PROTOCOL_PING){
    //                 //dbg(FLOODING_CHANNEL, "message in cache\n");
    //                 Cache(newMsg);
    //                 //call InsideSend.send(*newMsg, newMsg -> dest);
                    
    //                 if(call routingTable.contains(newMsg -> src)){
    //                     //dbg(NEIGHBOR_CHANNEL, "to get to:%d, send through:%d\n", newMsg -> src, call routingTable.get( newMsg -> src));
    //                     makePack(&sendPackage, newMsg->dest, newMsg->src, MAX_TTL, PROTOCOL_PINGREPLY, newMsg->seq, (uint8_t *) newMsg->payload, sizeof(newMsg->payload));
    //                     call InsideSend.send(sendPackage, call routingTable.get(newMsg -> src));
    //                 }

    //                 else{
    //                     //dbg(NEIGHBOR_CHANNEL, "Couldn't find the routing table for:%d so flooding\n",TOS_NODE_ID);
    //                     makePack(&sendPackage, newMsg->dest, newMsg->src, newMsg->TTL-1, PROTOCOL_PINGREPLY, newMsg->seq, (uint8_t *) newMsg->payload, sizeof(newMsg->payload));
    //                     call InsideSend.send(sendPackage, AM_BROADCAST_ADDR);
    //                 }
    //                 return message;
    //             }

    //             else if (newMsg -> protocol == PROTOCOL_PINGREPLY){
    //                 //dbg(FLOODING_CHANNEL, "node got it\n");
    //             }
    //             //Neighbor Discovery starts here    
    //             //print neighbor list
    //             call NeighborDiscovery.print();
    //         }
            
    //         //broadcasting to every node
    //         else if (AM_BROADCAST_ADDR == newMsg -> dest){
    //             //dbg(FLOODING_CHANNEL, "Flooding Network: going to send %d to %d \n", newMsg->src, newMsg->dest);

    //             if(newMsg->protocol == PROTOCOL_LINKEDLIST){
    //                 uint16_t i,j,k;
    //                 bool checker = TRUE;
    //                 for(i = 0; i < newMsg->seq; i++){
    //                     for(j = 0; j < call lspList.size(); j++){
    //                         lsp packet = call lspList.get(j);
    //                         if(packet.src == newMsg->src && packet.neighbor == newMsg->payload[i]){
    //                             checker = FALSE;
    //                         }
    //                     }
    //                 }

    //                 //adding to lsp list with the cost of 5 for each node
    //                 if(checker){
    //                     for(k = 0; k < newMsg->seq; k++){
    //                         lspLink.neighbor = newMsg->payload[k];
    //                         lspLink.cost = 5;
    //                         lspLink.src = newMsg->src;
    //                         call lspList.pushback(lspLink);
    //                         //dbg(ROUTING_CHANNEL,"$$$Neighbor: %d\n",lspL.neighbor);
    //                     }
    //                     makePack(&sendPackage, newMsg->src, AM_BROADCAST_ADDR, newMsg->TTL-1 , PROTOCOL_LINKEDLIST, newMsg->seq, newMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
    //                     call InsideSend.send(sendPackage,AM_BROADCAST_ADDR);
    //                 }
    //                 else{
    //                     //dbg(ROUTING_CHANNEL,"LSP already exists for %d\n",TOS_NODE_ID);
    //                 }
    //             }
                
    //             //send discovery packet
    //             if (PROTOCOL_PING == newMsg -> protocol){
    //                 makePack (&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, newMsg -> TTL-1, PROTOCOL_PINGREPLY, seqNumber,newMsg -> payload, PACKET_MAX_PAYLOAD_SIZE);
    //                 call InsideSend.send(sendPackage, newMsg -> src);
    //             }
    //             //checks neighbors
    //             if (PROTOCOL_PINGREPLY == newMsg -> protocol){
    //                 //aknowledgement
    //                 call NeighborDiscovery.received(newMsg);
    //             }
    //             //for routing table
    //             //nextHop =  call routingTable.getNextHop(newMsg -> dest);
    //             // if (nextHop == 1000 || nextHop < 1){
    //             //     dbg(ROUTING_CHANNEL, "packet dropped")
    //             //     return message;
    //             // }
    //             //printing neighbor list
    //             call NeighborDiscovery.print();
    //             return message;
    //         }

    //         else{
    //             Cache(newMsg);
    //             if(call routingTable.contains(newMsg -> src)){
    //                 //dbg(NEIGHBOR_CHANNEL, "to get to:%d, send through:%d\n", newMsg -> dest, call routingTable.get(newMsg -> dest));
    //                 makePack(&sendPackage, newMsg->src, newMsg->dest, newMsg->TTL-1, newMsg->protocol, newMsg->seq, (uint8_t *) newMsg->payload, sizeof(newMsg->payload));
    //                 call InsideSend.send(sendPackage, call routingTable.get(newMsg -> dest));
    //             }
    //             else{
    //                 //dbg(NEIGHBOR_CHANNEL, "Couldn't find the routing table for:%d so flooding\n",TOS_NODE_ID);
    //                 makePack(&sendPackage, newMsg->src, newMsg->dest, newMsg->TTL-1, newMsg->protocol, newMsg->seq, (uint8_t *) newMsg->payload, sizeof(newMsg->payload));
    //                 call InsideSend.send(sendPackage, AM_BROADCAST_ADDR);
    //             }
    //             return message;
    //         }
    //     return message;
    //     }
    //     //dbg(FLOODING_CHANNEL, "unknown packet\n");
    //     //error with message/packet
    //     return message;   
    // }    

    event message_t* Gotit.receive(message_t* message, void* payload, uint8_t len){
        uint16_t newTTL;
        uint16_t newMsgSource;
        if (len == sizeof(pack)){
            pack* newMsg = (pack*) payload;
            dbg(FLOODING_CHANNEL, "inside flooding\n");
            //pack* newMsg = (pack*) payload;

            if (newMsg -> TTL == 0){
                return message;
            }
            
            //checking for duplicate
            if (duplicate(newMsg)){
                return message;
            }

            Cache(newMsg);

            if (newMsg -> dest == TOS_NODE_ID){
                if (newMsg -> protocol == PROTOCOL_PING){
                    //uint16_t newMsgSource;
                    newMsgSource = newMsg -> src;
                    newMsg -> src = newMsg -> dest;
                    newMsg -> dest = newMsgSource;
                    newMsg -> protocol = PROTOCOL_PINGREPLY;
                    call Flooding.send(*newMsg, newMsg -> dest);
                    return signal floodReceive.receive(message, payload, len);
                }
                else {
                    dbg(FLOODING_CHANNEL, "ACK received from %d\n", newMsg->src);
                }
                //call NeighborDiscovery.print();
            }

            else {
                //call NeighborDiscovery.received(newMsg);
                newTTL = newMsg-> TTL;
                newMsg -> TTL = newTTL--;

                if (newMsg -> TTL < 1){
                    return message;
                }

                //call NeighborDiscovery.print();
                call InsideSend.send(*newMsg, AM_BROADCAST_ADDR);
            }
            return message;
        }
        dbg(FLOODING_CHANNEL," Unknown Packet");
        return message;
    }

    bool duplicate(pack* message){
        uint16_t i;
        uint16_t size = call CacheList.size();
        pack secMsg;

        for (i = 0; i < size; i++){
            dbg(FLOODING_CHANNEL, "inside dup flooding\n");
            secMsg = call CacheList.get(i);
            if (secMsg.dest == message -> dest && secMsg.src == message -> src && secMsg.seq == message -> seq){
                return TRUE;
            }
        }
        return FALSE;
    }

    //adding to the list
    void Cache (pack *message){
       if (call CacheList.size() >= call CacheList.sizeMax()){
            //doing popfront() to have new "messange" to the front and old to the back
            //it could be front or back, I just choose front and it will be faster to read
            call CacheList.popback();
       }
       call CacheList.pushfront(*message);
   }

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}