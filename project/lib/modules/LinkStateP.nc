#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/lsp.h"
//#include "../../includes/neighbor.h"

// for dijkstra's algo i looked at :
//  https://www.thecrazyprogrammer.com/2014/03/dijkstra-algorithm-for-finding-shortest-path-of-a-graph.html
//  https://www.geeksforgeeks.org/dijkstras-shortest-path-algorithm-greedy-algo-7/

//for neighbor age
#define MAX_AGE 10
//for dijkstra's algo
//picked 30 for # of nodes and their neighbor 
//can be changed
#define MAX 30
//#define INFINITY 99

module LinkStateP{
    provides interface LinkState;

    //timer for lsp
    uses interface Timer<TMilli> as lsTimer;
    //timer for shortest path
    uses interface Timer<TMilli> as spTimer;
    //to flood nodes with LSP
    uses interface SimpleSend as lspSender;
    //to store neighbors
    uses interface List<pack> as neighborList;
    // to store cost
    uses interface List<lsp> as lspList;
    //to store routing table
    uses interface Hashmap<int> as routingTable;
    uses interface Random as random;
}

implementation {
    pack SendPackage;
    lsp lspLink;
    routingTables route[100];
    uint16_t age;
    int topo;
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
    void makeRoutingTable();

    command void LinkState.start(){
        //dbg(ROUTING_CHANNEL, "Routing is starting\n");
        //boots when nodes gets topo info
        call lsTimer.startPeriodic(1000);
        //starting the timer to run short-path
        call spTimer.startOneShot(100);
    }

    //prints the routing table
    command void LinkState.printRoutingTable(){
        //call hashmap and calls the size()
        uint16_t i;
        for(i = 1; i <= call routingTable.size();i++){
            dbg(ROUTING_CHANNEL, "Destination: %d \t nextHop: %d\n", i, call routingTable.get(i));
        }
    }

    //print out the tuple that contains neighbor and cost
    command void LinkState.print(){
        if(call lspList.size() > 0){
            uint16_t size = call lspList.size();
            uint16_t i;
            for(i = 0; i < size; i++){
                lsp packets =  call lspList.get(i);
                dbg(ROUTING_CHANNEL,"Source: %d\t Neighbor: %d\t cost: %d\n", packets.dest, packets.nextHop, packets.cost);
            }
        }
        else{
        dbg(COMMAND_CHANNEL, "no neighbors");
        }
    }

    command uint16_t LinkState.getNextHop(uint16_t dest){		
		uint32_t i = 0;	
		for (i = 0; i < call routingTable.size(); i++) {
			if (route[i].dest == dest && route[i].cost < 999) {
				return route[i].nextHop;
			}
		}
		
		return 999;
	}

    //to boot make routing table
    event void lsTimer.fired(){
        makeRoutingTable();
    }

    void makeRoutingTable(){
        uint16_t neighborSize = call neighborList.size();
        uint16_t lspSize = call lspList.size();
        uint16_t neighborhood[neighborSize];
        uint16_t i = 0;
        uint16_t j = 0;
        bool sendTable = TRUE;

        dbg(ROUTING_CHANNEL, "neighborhod size is %d\n", neighborSize);
        
        //age is 10(random # i picked)
        if (age == MAX_AGE){
            age = 0;
            for (i = 0; i < lspSize; i++){
                //gets rid of node
                call lspList.popfront();
            }
        }

        //checking if already in routing table
        //if already in don't add to table
        for (i = 0; i < neighborSize; i++){
            pack node = call neighborList.get(i);
            for (j = 0; j < lspSize; j++){
                lsp packet = call lspList.get(i);
                if (packet.dest == TOS_NODE_ID && node.dest == packet.nextHop){
                    sendTable = FALSE;
                }
            }

            //adding to routing table and setting cose to 5, random # i picked
            if (sendTable){
                lspLink.dest = node.src;
                lspLink.nextHop = TOS_NODE_ID;
                lspLink.cost = 5;
                call lspList.pushback(lspLink);
                //calling Dijkstra algo with timer
                // sets timer here 
                call spTimer.startOneShot(10000 + (uint16_t)(call random.rand16()));
            }

            if (neighborhood[i] == neighborSize){
                neighborhood[i] = node.src;
                dbg(ROUTING_CHANNEL, "adding to routing table");
            }
            else {
                dbg(ROUTING_CHANNEL, "already there");
            }

            makePack(&SendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_LINKEDLIST, neighborSize, (uint8_t*) neighborhood, neighborSize);
            call lspSender.send(SendPackage, AM_BROADCAST_ADDR);
            dbg(ROUTING_CHANNEL, "sending lsp");
        }
    }

    //dijkstra algo
    event void spTimer.fired(){
        // # of nodes neighbor
        int neighbor[MAX];
        // number of node
        int size = call lspList.size();
        int nodes = MAX;
        int i,j;
        int nextHop;
        //all for LSP
        //backup is for when node fails
        int cost[MAX][MAX], distance[MAX], backUp[MAX];
        // for shortest path algo
        int visited[MAX], counter, shortest, nextNode;
        int start = TOS_NODE_ID;
        bool matrix[MAX][MAX];

        //initializing 
        for (i = 0; i < nodes; i++){
            distance[i] = cost[start][i];
            backUp[i] = start;
            visited[i];
        }

        distance[start] = 0;
        visited[start] = 1;
        counter = 1;

        //start of dijkstra's algo with things added for LSP
        for (i = 0; i < nodes; j++){
            for (j = 0; j < nodes; j++){
            matrix[i][j] = FALSE;
            }
        }

        for (j = 0; i < size; i++){
            lsp inList = call lspList.get(i);
            matrix[inList.dest][inList.nextHop] = TRUE;
        }

        for (i = 0; i < nodes; i++){
            for (j = 0; i < nodes; j++){
                if (matrix[i][j] == 0){
                cost[i][j] = 999;
                }
                else {
                    cost[i][j] = matrix[i][j];
                }
            }
        }

        //start of finding shortest path
        //nextNode tells us the shortest distance
        while (counter < nodes - 1){
            shortest = 999;

            for (i = 0; i < nodes; i++){
                if (distance[i] <= shortest && !visited[i]){
                    shortest = distance[i];
                    nextNode = i;
                }
            }

            //checks for a better path
            visited[nextNode] = 1;
            for (i = 0; i < nodes; i++){
                if (!visited[i]){
                    if (shortest + cost[nextNode][i] < distance[i]){
                        distance[i] = shortest + cost[nextNode][i];
                        backUp[i] = nextNode;
                    }
                }
            }
            counter++;
        }

        //printing path and shortest distance for each node
        for (i = 0; i < nodes; i++){
            nextHop = TOS_NODE_ID;
            if (distance[i] != 999){
                if (i != start){
                    j = i;
                    do{
                        if (j != start){
                            nextHop = j;
                        }
                        j = backUp[j]; 
                    } while (j != start);
                }
                else {
                    nextHop = start;
                }
                
                if (nextHop != 0){
                    call routingTable.insert(i, nextHop);
                }
            }
        }
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
