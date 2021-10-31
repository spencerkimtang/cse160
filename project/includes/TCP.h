#ifndef TCP_H
#define TCP_H

#include "protocol.h"
#include "channels.h"

#define DATA_FLAG 0
#define DATA_ACK_FLAG 1
#define SYN_FLAG 2
#define SYN_ACK_FLAG 3
#define ACK_FLAG 4
#define FIN_FLAG 5
#define FIN_ACK 6
#define HELLO 7
#define BROADCAST 8
#define UNICAST 9
#define PRINTUSER 10

enum{
	TCP_HEADER_LENGTH = 8,
	TCP_MAX_PAYLOAD_SIZE = 12
};

typedef nx_struct tcp{
	nx_uint8_t destPort;
	nx_uint8_t srcPort;
	nx_uint8_t seq;
	nx_uint8_t ACK;
	nx_uint8_t lastACK;
	nx_uint8_t flags;
	nx_uint8_t window;
	nx_uint8_t payload[TCP_MAX_PAYLOAD_SIZE];
}tcp;

#endif