#include "../../includes/socket.h"
#include "../../includes/TCP.h"
#include "../../includes/packet.h"
#include "../../includes/channels.h"


module ChatP{
    provides interface Chat;

    uses interface SimpleSend as Sender;
    uses interface Transport;
}

implementation{
    socket_t getSocket(uint16_t port);
	socket_t getServerSocket(uint16_t port);
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length);

    command void Chat.setAppServer(){
        socket_t socket;

        socket.src.port = 41;
        socket.src.addr = TOS_NODE_ID;
        socket.state = LISTEN;
        dbg(CHAT_CHANNEL,"Node: %d\n", socket.src.addr);
    }

    command void Chat.setAppClient(uint16_t port, char* username){
        socket_t socket;

        socket.src.port = port;
        socket.src.addr = TOS_NODE_ID;
        socket.state = LISTEN;
        socket.username = username;
        dbg(CHAT_CHANNEL,"Node: %d, Port: %d, username: %d\n", socket.src.addr, socket.src.port, socket.username);
    }

    command void Chat.connectServer(uint16_t server_addr, uint16_t server_port, uint16_t client_port, pack* message){
        socket_t socket;
        socket_t serverSocket;
        //pack message;
        tcp* tcpPack;

        socket = getSocket(client_port);
        socket.dest.port = server_port;
        socket.dest.addr = server_addr;

        call Transport.connected(socket);
        serverSocket = getServerSocket(server_port);
        if (serverSocket.state == ESTABLISHED){
            uint16_t i;
            //for printing out users
            for (i = 0; i < 10; i++){
                if (serverSocket.userList[i] == NULL){
                    serverSocket.userList[i] == socket.username;
                }
            }

            tcpPack = (tcp*)message->payload;
            tcpPack -> flags = 7;

            makePack(&message, TOS_NODE_ID, serverSocket.src.addr, 20, 4, 0, tcpPack, TCP_MAX_PAYLOAD_SIZE);
            //call Sender.send(message, serverSocket.src.addr); 
            
            //dbg(CHAT_CHANNEL,"hello %d %d!\r\n", username, client_port);
            dbg(CHAT_CHANNEL,"hello stang32\r\n");
        }
        serverSocket.state = LISTEN; 
    }

    command void Chat.broadcast(uint16_t client_port, pack* message){
        socket_t socket;
        tcp* tcpPack;
        socket = getSocket(client_port);

        tcpPack = (tcp*)message->payload;
        tcpPack -> srcPort = socket.src.addr;
        tcpPack -> flags = 8;

        makePack(&message, TOS_NODE_ID, socket.dest.addr, 20, 4, 0, tcpPack, TCP_MAX_PAYLOAD_SIZE);
        //call Sender.send(message, socket.dest.addr);
        //dbg(CHAT_CHANNEL,"msg %d %d!\r\n", username, message);
        dbg(CHAT_CHANNEL,"msg Hello World!\r\n");
        
    }

    command void Chat.unicast(uint16_t srcPort, uint16_t destPort, pack*  message){
        socket_t socket;
        tcp* tcpPack;
        socket = getSocket(srcPort);

        tcpPack = (tcp*)message->payload;
        tcpPack -> destPort = destPort;
        tcpPack -> srcPort = socket.src.port;
        tcpPack -> flags = 9;

        makePack(&message, TOS_NODE_ID, socket.dest.addr, 20, 4, 0, tcpPack, TCP_MAX_PAYLOAD_SIZE);
        //call Sender.send(message, socket.dest.addr);
        //dbg(CHAT_CHANNEL,"whisper %d %d!\r\n", username, message);
        dbg(CHAT_CHANNEL,"whisper Stang32 Hi!\r\n");
    }

    command void Chat.printUser(uint16_t client_port){
        socket_t socket;
        pack sendUser;
        tcp* tcpPack;
        socket = getSocket(client_port);

        tcpPack -> destPort = socket.dest.port;
        tcpPack -> srcPort = socket.src.port;
        tcpPack -> flags = 10;

        makePack(&sendUser, TOS_NODE_ID, socket.dest.addr, 20, 4, 0, tcpPack, TCP_MAX_PAYLOAD_SIZE);
        //call Sender.send(sendUser, socket.dest.addr);
        dbg(CHAT_CHANNEL,"listusr stang32\r\n");
    }

    socket_t getSocket(uint16_t port) {
        socket_t socket;
        uint16_t i = 0;
        uint16_t size = 10;

        //size = call socketList.size();
        for(i = 0; i < size; i++) {
            //socket = call socketList.get(i);
            if(socket.src.port == port && socket.dest.port == NULL){
                return socket;
            }
        }
        dbg(CHAT_CHANNEL, "Socket not found!\n");
    }

    socket_t getserverSocket(uint16_t port) {
      
      socket_t socket;
      uint16_t i = 0;
      uint16_t size = 10;
      //size = call socketList.size();

        for(i = 0; i < size; i++){
            //socket = call socketList.get(i);
            if(socket.state == ESTABLISHED && socket.src.port == port){
                return socket;
            }         
        }
      dbg(TRANSPORT_CHANNEL, "Socket not found\n");
   }

    void makePack(pack* Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package -> src = src;
        Package -> dest = dest;
        Package -> TTL = TTL;
        Package -> seq = seq;
        Package -> protocol = protocol;
        memcpy(Package-> payload, payload, length);
    }
}