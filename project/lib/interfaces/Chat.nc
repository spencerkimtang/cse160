interface Chat{
    command void setAppServer();
    command void setAppClient(uint16_t port, char* username);
    command void connectServer(uint16_t server_addr, uint16_t server_port, uint16_t client_port, pack* message);
    command void broadcast(uint16_t client_port, pack* message);
    command void unicast(uint16_t srcPort, uint16_t destPort, pack* message);
    command void printUser(uint16_t client_port);
}