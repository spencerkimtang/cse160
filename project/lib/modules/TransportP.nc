#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include "../../includes/socket.h"
#include "../../includes/TCP.h"

module TransportP{
	
    uses interface Timer<TMilli> as Timer;
	uses interface SimpleSend as Sender;
	uses interface List<socket_t> as SocketList;
	uses interface Queue<pack> as packetQueue;
	//uses interface LinkState;
	//uses interface Forwarder;

	provides interface Transport;
}

implementation {
    socket_t getSocket(uint8_t destPort, uint8_t srcPort);
	socket_t getServerSocket(uint8_t destPort);
    void connectDone(socket_t socket);

    event void Timer.fired(){
        pack newMsg = call packetQueue.head();
        pack sendMsg;
        tcp* myTCP = (tcp*)(newMsg.payload);
        socket_t mySocket = getSocket(myTCP -> srcPort, myTCP -> destPort);

        if (mySocket.dest.port){
            call SocketList.pushback(mySocket);
            call Transport.makePack(&sendMsg, TOS_NODE_ID, mySocket.dest.port, 15, 4, 0, myTCP, PACKET_MAX_PAYLOAD_SIZE);
            call Sender.send(sendMsg, mySocket.dest.port);
        }
    }

    //geting client socket
    socket_t getSocket(uint8_t destPort, uint8_t srcPort){
        socket_t mySocket;
        uint16_t i = 0;
        uint16_t size = call SocketList.size();

        for (i = 0; i < size; i++){
            mySocket = call SocketList.get(i);
            if (mySocket.dest.port == srcPort && mySocket.src.port == destPort){
                return mySocket;
            }
        }
	}

    //getting server socket
    socket_t getServerSocket(uint8_t destPort){
        socket_t mySocket;
        bool found;
        uint16_t i = 0;
        uint16_t size = call SocketList.size();

        for (i = 0; i < size; i++){
            mySocket = call SocketList.get(i);
            if (mySocket.src.port == destPort && mySocket.state == LISTEN){
                dbg (TRANSPORT_CHANNEL, "socket found\n");
                return mySocket;
            }
        }
        dbg (TRANSPORT_CHANNEL, " no socket\n");
	}

    command error_t Transport.connected(socket_t found){
        pack newMsg;
        tcp* myTCP;
        socket_t mySocket = found;

        myTCP = (tcp*)(newMsg.payload);
        myTCP -> destPort = mySocket.dest.port;
        myTCP -> srcPort = mySocket.src.port;
        myTCP -> ACK = 0;
        myTCP -> seq = 1;
        myTCP -> flags = SYN_FLAG;

        call Transport.makePack(&newMsg, TOS_NODE_ID, mySocket.dest.addr, 15, 4, 0, myTCP, PACKET_MAX_PAYLOAD_SIZE);
        mySocket.state = SYN_SENT;
        dbg(ROUTING_CHANNEL,"Node %d state is %d\n", mySocket.src.addr, mySocket.state);
        call Sender.send(newMsg, mySocket.dest.port);
    }

    command error_t Transport.receive(pack* message){
		uint16_t srcPort, destPort, seq, lastACK, flags;
        uint16_t key, socket;
        uint16_t buffer = TCP_MAX_PAYLOAD_SIZE;
        uint16_t i, j;
        socket_t mySocket;

        tcp* newMsg = (tcp*)(message -> payload);
        tcp* tcpPack;
        pack newPack;

        srcPort = newMsg ->srcPort;
        destPort = newMsg -> destPort;
        seq = newMsg -> seq;
        lastACK = newMsg-> ACK;
        flags = newMsg -> flags;

        if (flags == SYN_FLAG){
            dbg (TRANSPORT_CHANNEL, " got syn\n");
            mySocket = getServerSocket(destPort);
            if (mySocket.state == LISTEN){
                mySocket.state = SYN_RCVD;
                mySocket.dest.port = srcPort;
                mySocket.dest.addr = message -> src;
                call SocketList.pushback(mySocket);

                tcpPack = (tcp*)(newPack.payload);
                tcpPack -> destPort = mySocket.dest.port;
                tcpPack -> srcPort = mySocket.src.port;
                tcpPack -> seq = 1;
                tcpPack -> ACK = seq + 1;
                tcpPack -> flags = SYN_ACK_FLAG;
                dbg (TRANSPORT_CHANNEL,"sending syn ack\n");
                call Transport.makePack(&newPack, TOS_NODE_ID, mySocket.dest.addr, 15, 4, 0, tcpPack, PACKET_MAX_PAYLOAD_SIZE);
                call Sender.send(newPack, mySocket.dest.addr);
            }
        }

        if (flags == SYN_ACK_FLAG){
            dbg (TRANSPORT_CHANNEL," got ack\n");
            mySocket = getSocket(destPort, srcPort);
            mySocket.state = ESTABLISHED;
            call SocketList.pushback(mySocket);

            tcpPack = (tcp*)(newMsg -> payload);
            tcpPack -> destPort = mySocket.dest.port;
            tcpPack -> srcPort = mySocket.src.port;
            tcpPack -> seq = 1;
            tcpPack -> ACK = seq + 1;
            tcpPack -> flags = ACK_FLAG;
            dbg (TRANSPORT_CHANNEL,"sending ack\n");
            call Transport.makePack(&newPack, TOS_NODE_ID, mySocket.dest.addr, 15, 4, 0, tcpPack, PACKET_MAX_PAYLOAD_SIZE);
            call Sender.send(newPack, mySocket.dest.addr);

            connectDone(mySocket);

            //below is when it is connected
            //pack newMsg;
            //tcp* tcpPack;
            //mySocket = fd;
            // i = 0;

            // tcpPack = (tcp*)(newMsg -> payload);
            // tcpPack->destPort = mySocket.dest.port;
            // tcpPack->srcPort = mySocket.src.port;
            // tcpPack->flags = DATA_FLAG;
            // tcpPack->seq = 0;

            // while(i < TCP_MAX_PAYLOAD_SIZE && i <= mySocket.effectiveWindow){
			//     tcpPack->payload[i] = i;
			//     i++;
		    // }

            // tcpPack->ACK = i;
            
            // call Transport.makePack(&newPack, TOS_NODE_ID, mySocket.dest.addr, 15, 4, 0, tcpPack, PACKET_MAX_PAYLOAD_SIZE);
            
            // dbg(ROUTING_CHANNEL, "Node %u State is %u \n", mySocket.src.addr, mySocket.state);
            // dbg(ROUTING_CHANNEL, "SERVER CONNECTED\n");
            
            // call packetQueue.enqueue(newPack);
            // call Timer.startOneShot(140000);
            // call Sender.send(newPack, mySocket.dest.addr);
        }

        if (flags == ACK_FLAG){
            dbg(TRANSPORT_CHANNEL," got ACK\n");
            mySocket = getSocket(destPort, srcPort);
            if (mySocket.state = SYN_RCVD){
                mySocket.state = ESTABLISHED;
                call SocketList.pushback(mySocket);
            }
        }

        if (flags == DATA_FLAG || flags == DATA_ACK_FLAG){

            if(flags == DATA_FLAG){
                mySocket = getSocket(destPort, srcPort);
                if(mySocket.state == ESTABLISHED){
                    tcpPack = (tcp*)(newPack.payload);
                        if(newMsg->payload[0] != 0){
                            i = mySocket.lastRcvd + 1;
                            j = 0;
                            while(j < newMsg->ACK){
                                mySocket.rcvdBuff[i] = newMsg->payload[j];
                                mySocket.lastRcvd = newMsg->payload[j];
                                i++;
                                j++;
                            }
                        }
                        else{
                            i = 0;
                            while(i < newMsg->ACK){
                                mySocket.rcvdBuff[i] = newMsg->payload[i];
                                mySocket.lastRcvd = newMsg->payload[i];
                                i++;
                            }
                        }

                    mySocket.effectiveWindow = SOCKET_BUFFER_SIZE - mySocket.lastRcvd + 1;
                    call SocketList.pushback(mySocket);
                
                    tcpPack->destPort = mySocket.dest.port;
                    tcpPack->srcPort = mySocket.src.port;
                    tcpPack->seq = seq;
                    tcpPack->ACK = seq + 1;
                    tcpPack->lastACK = mySocket.lastRcvd;
                    tcpPack->window = mySocket.effectiveWindow;
                    tcpPack->flags = DATA_ACK_FLAG;
                    dbg(TRANSPORT_CHANNEL, "sending data ack \n");
                    call Transport.makePack(&newPack, TOS_NODE_ID, mySocket.dest.addr, 15, 4, 0 , tcpPack, PACKET_MAX_PAYLOAD_SIZE);
                    call Sender.send(newPack, mySocket.dest.addr);
                }
            }

            else if (flags == DATA_ACK_FLAG){
                mySocket = getSocket(destPort, srcPort);
                if(mySocket.state == ESTABLISHED){
                    if(newMsg->window != 0 && newMsg->lastACK != mySocket.effectiveWindow){
                        tcpPack = (tcp*)(newPack.payload);
                        i = newMsg->lastACK + 1;
                        j = 0;
                        
                        while(j < newMsg->window && j < TCP_MAX_PAYLOAD_SIZE && i <= mySocket.effectiveWindow){
                            tcpPack->payload[j] = i;
                            i++;
                            j++;
                        }
                        
                        call SocketList.pushback(mySocket);
                        tcpPack->flags = DATA_FLAG;
                        tcpPack->destPort = mySocket.dest.port;
                        tcpPack->srcPort = mySocket.src.port;
                        tcpPack->ACK = i - 1 - newMsg->lastACK;
                        tcpPack->seq = lastACK;
                        
                        call Transport.makePack(&newPack, TOS_NODE_ID, mySocket.dest.addr, 15, 4, 0, tcpPack, PACKET_MAX_PAYLOAD_SIZE);
                        call packetQueue.dequeue();
                        call packetQueue.enqueue(newPack);
                        
                        dbg(TRANSPORT_CHANNEL, "send new data \n");
                        call Sender.send(newPack, mySocket.dest.addr);
                    }
                }
            }
            else {
                mySocket.state = FIN_FLAG;
                call SocketList.pushback(mySocket);
                tcpPack = (tcp*)(newMsg -> payload);
                tcpPack->destPort = mySocket.dest.port;
                tcpPack->srcPort = mySocket.src.port;
                tcpPack->seq = 1;
                tcpPack->ACK = seq + 1;
                tcpPack->flags = FIN_FLAG;
                call Transport.makePack(&newPack, TOS_NODE_ID, mySocket.dest.addr, 15, 4, 0, tcpPack, PACKET_MAX_PAYLOAD_SIZE);
                call Sender.send(newPack, mySocket.dest.addr);
            }
        }

        if(flags == FIN_FLAG){
            dbg(TRANSPORT_CHANNEL, "got fin flag \n");
            mySocket = getSocket(destPort, srcPort);
            mySocket.state = CLOSED;
            mySocket.dest.port = srcPort;
            mySocket.dest.addr = message->src;
    
            tcpPack = (tcp*)(newMsg -> payload);
            tcpPack->destPort = mySocket.dest.port;
            tcpPack->srcPort = mySocket.src.port;
            tcpPack->seq = 1;
            tcpPack->ACK = seq + 1;
            tcpPack->flags = FIN_ACK;
            
            call Transport.makePack(&newPack, TOS_NODE_ID, mySocket.dest.addr, 15, 4, 0, tcpPack, PACKET_MAX_PAYLOAD_SIZE);
            call Sender.send(newPack, mySocket.dest.addr);
        }

        if(flags == FIN_ACK){
            dbg(TRANSPORT_CHANNEL, "got fin ack \n");
            mySocket = getSocket(destPort, srcPort);
            mySocket.state = CLOSED;
        }
    }

    void connectDone(socket_t socket){
		pack newMsg;
		tcp* tcpPack;
		socket_t mySocket = socket;
		uint16_t i = 0;

		tcpPack = (tcp*)(newMsg.payload);
		tcpPack->destPort = mySocket.dest.port;
		tcpPack->srcPort = mySocket.src.port;
		tcpPack->flags = DATA_FLAG;
		tcpPack->seq = 0;

		i = 0;
		while(i < TCP_MAX_PAYLOAD_SIZE && i <= mySocket.effectiveWindow){
			tcpPack->payload[i] = i;
			i++;
		}

		tcpPack->ACK = i;
		call Transport.makePack(&newMsg, TOS_NODE_ID, mySocket.dest.addr, 15, 4, 0, tcpPack, PACKET_MAX_PAYLOAD_SIZE);
		dbg(ROUTING_CHANNEL, "Node %u State is %u \n", mySocket.src.addr, mySocket.state);
		dbg(ROUTING_CHANNEL, "SERVER CONNECTED\n");
		call packetQueue.enqueue(newMsg);
		call Timer.startOneShot(100000);
		call Sender.send(newMsg, mySocket.dest.addr);
    }	

    command void Transport.setTestServer(){
		socket_t mySocket;
		socket_addr_t myAddr;
		
		myAddr.addr = TOS_NODE_ID;
		myAddr.port = 50;
		
		mySocket.src = myAddr;
		mySocket.state = LISTEN;
    
        printf("set server\n");
		call SocketList.pushback(mySocket);
	}

	command void Transport.setTestClient(){
		socket_t mySocket;
		socket_addr_t myAddr;

		myAddr.addr = TOS_NODE_ID;
		myAddr.port = 50;

		mySocket.dest.port = 17;
		mySocket.dest.addr = 1;
		mySocket.src = myAddr;
		
        printf("set client\n");
		call SocketList.pushback(mySocket);
		call Transport.connected(mySocket);
	}

    command void Transport.makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
		Package->src = src;
		Package->dest = dest;
		Package->TTL = TTL;
		Package->seq = seq;
		Package->protocol = protocol;
		memcpy(Package->payload, payload, length);
    }
}