
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/neighbor.h"

module NeighborDiscoveryP{
    uses interface Timer<TMilli> as periodicTimer;
    uses interface Timer<TMilli> as printTimer;
    uses interface SimpleSend as Flooding;
    uses interface Receive as neighborReceive;
    uses interface List<pack> as neighborList;
    //uses interface Random as random;

    provides interface NeighborDiscovery;
}

implementation {
    pack sendPackage;
    Neighbor neighborhood[100];
    uint16_t index = 0;
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
    void updateNeighbor();
    //bool findNeighbor(pack* newMsg);
    

    command void NeighborDiscovery.start(){
        //dbg(GENERAL_CHANNEL, "Started\n");
        call periodicTimer.startOneShot(1000);
    }

    command void NeighborDiscovery.startPrint(){
        call printTimer.startOneShot(10000);
    }

    command void NeighborDiscovery.neighborReceived(uint16_t source){
        uint16_t i = 0;
        for (i = 0; i < 100; i++){
            if (neighborhood[i].address == source){
                neighborhood[i].age = 5;
                return;
            }
            else {
                neighborhood[index].address = source;
                neighborhood[index].age = 5;
                index++;
                return;
            }
        }
    }

    command void NeighborDiscovery.printNeighborhood(){
        uint16_t i = 0;
        for (i = 0; i < 100; i++){
            if (neighborhood[i].address != 0){
                dbg(NEIGHBOR_CHANNEL,"Neighbor: %u\n", neighborhood[i].address);
            }
        }
    }

    event void periodicTimer.fired(){
        uint16_t i;
        char* payload;
        payload = "packet";
        
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_PING, 0, (uint8_t*) payload, PACKET_MAX_PAYLOAD_SIZE);
        call Flooding.send(sendPackage, AM_BROADCAST_ADDR);
        //updateNeighbor();
        
        for (i = 0; i < 100; i++){
            if (neighborhood[i].age > 1){
                neighborhood[i].age -1;
            }
        }

        for (i = 0; i < 100; i++){
            if (neighborhood[i].age == 1){
                neighborhood[i].address = neighborhood[i++].address = 0;
                neighborhood[i].age = neighborhood[i++].age = 0;
                index--;
            }
        }
    }

    event message_t* neighborReceive.receive(message_t* message, void* payload, uint8_t len){
        pack* newMsg = (pack*) payload;

        if (newMsg -> dest == AM_BROADCAST_ADDR){
            newMsg -> dest == newMsg -> src;
            newMsg -> src == TOS_NODE_ID;
            newMsg -> protocol = PROTOCOL_PINGREPLY;
            call Flooding.send(*newMsg, newMsg -> dest);
        }
        
        if (newMsg -> dest == TOS_NODE_ID){
            call NeighborDiscovery.neighborReceived(newMsg -> src);
        }
        return message;
    }

    event void printTimer.fired(){
        call NeighborDiscovery.printNeighborhood();
    }

    command Neighbor* NeighborDiscovery.getNeighborhood(){
        return neighborhood;
    }

    command uint16_t NeighborDiscovery.neighborhoodSize(){
        return index;
    }

    // void updateNeighbor(){
    //     uint16_t i = 0;
    //     for (i = 0; i < 100; i++){
    //         if (neighborhood[i].age > 1){
    //             neighborhood[i].age -1;
    //         }
    //     }

    //     for (i = 0; i < 100; i++){
    //         if (neighborhood[i].age == 1){
    //             neighborhood[i].address = neighborhood[i++].address = 0;
    //             neighborhood[i].age = neighborhood[i++].age = 0;
    //             index--;
    //         }
    //     }
    // }

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }

}