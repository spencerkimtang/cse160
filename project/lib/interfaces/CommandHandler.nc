interface CommandHandler{
   // Events
   event void ping(uint16_t destination, uint8_t *payload);
   event void printNeighbors();
   event void printRouteTable();
   event void printLinkState();
   event void printDistanceVector();
   event void setTestServer();
   event void setTestClient();
   event void setAppServer();
   event void settingAppClient(uint16_t port, uint8_t *username);
   event void clientClose();
   event void connectServer(uint16_t server_addr, uint16_t server_port, uint16_t client_port, pack *message);
   event void broadcast(uint16_t client_port, pack *message);
   event void unicast(uint16_t srcPort, uint16_t destPort, pack* message);
   event void printUser(uint16_t client_port);
}
