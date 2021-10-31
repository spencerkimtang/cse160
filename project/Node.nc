/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"
#include "includes/socket.h"
#include "includes/TCP.h"

module Node{
    uses interface Boot;
    //from project 1 pdf (timer section)
    //uses interface Timer<TMilli> as periodicTimer;

    uses interface SplitControl as AMControl;
    uses interface Receive;

    uses interface SimpleSend as Sender;

    uses interface CommandHandler;

    //for flooding
    uses interface SimpleSend as Flooding;
    uses interface Receive as floodReceive;

    //for neighbor discovery
    uses interface NeighborDiscovery;
    uses interface LinkState;

    //for forwarder
    uses interface SimpleSend as Forwarder;
    uses interface Receive as ForwarderReceiver;

    //for transport
    uses interface Transport;
    uses interface Queue<socket_t> as SocketQueue;
    uses interface List<socket_t> as SocketList;

    //for Chat
    uses interface Chat;
}

implementation{
   pack sendPackage;

    //from project pdf (timer section)
//     event void periodicTimer.fired(){
//         call NeighborDiscovery.start();
//    }

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();
      call NeighborDiscovery.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
        call LinkState.start();
        if(err == SUCCESS){
            dbg(GENERAL_CHANNEL, "Radio On\n");
        }else{
            //Retry until successful
            call AMControl.start();
        }
   }

   event void AMControl.stopDone(error_t err){}

    event message_t* floodReceive.receive(message_t* msg, void* payload, uint8_t len){
        return msg;
    }

    event message_t* ForwarderReceiver.receive(message_t* msg, void* payload, uint8_t len){
        return msg;
    }

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Flooding.send(sendPackage, destination);
   }

   event void CommandHandler.printNeighbors(){
       call NeighborDiscovery.printNeighborhood();
   }

   event void CommandHandler.printRouteTable(){
       call LinkState.printRoutingTable();
   }

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){
       dbg(GENERAL_CHANNEL,"setting test server\n");
       call Transport.setTestServer();
   }

   event void CommandHandler.setTestClient(){
       dbg(GENERAL_CHANNEL,"setting test client\n");
       call Transport.setTestClient();
   }

   event void CommandHandler.clientClose(){}


    //for project 4
   event void CommandHandler.setAppServer(){
       dbg(GENERAL_CHANNEL,"set app server\n");
       call Chat.setAppServer();
   }

   event void CommandHandler.settingAppClient(uint16_t port, uint8_t *username){
       dbg(GENERAL_CHANNEL,"set app client\n");
       call Chat.setAppClient(port, username);
   }

   event void CommandHandler.connectServer(uint16_t server_addr, uint16_t server_port, uint16_t client_port, pack *message){
        dbg(GENERAL_CHANNEL,"hello\n");
        makePack(&sendPackage, server_addr, client_port, 0, 0, 0, message, PACKET_MAX_PAYLOAD_SIZE);
       call Chat.connectServer(server_addr, server_port, client_port, &sendPackage);
   }

   event void CommandHandler.broadcast(uint16_t client_port, pack *message){
       dbg(GENERAL_CHANNEL,"broadcasting\n");
       makePack(&sendPackage, 41, client_port, 0, 0, 0, message, PACKET_MAX_PAYLOAD_SIZE);
       call Chat.broadcast(client_port, &sendPackage);
   }

   event void CommandHandler.unicast(uint16_t srcPort, uint16_t destPort, pack* message){
        dbg(GENERAL_CHANNEL,"unicasting\n");
        makePack(&sendPackage, srcPort, destPort, 0, 0, 0, message, PACKET_MAX_PAYLOAD_SIZE);
       call Chat.unicast(srcPort, destPort, &sendPackage);
    }

    event void CommandHandler.printUser(uint16_t client_port){
        dbg(GENERAL_CHANNEL,"printing all users\n");
        call Chat.printUser(client_port);
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
