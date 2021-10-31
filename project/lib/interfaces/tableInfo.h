#ifndef TABLEINFO_H
#define TABLEINFO_H

typedef struct routingTables{
    uint16_t dest;
    uint16_t nextHop;
    uint16_t cost;
    uint16_t age;
}routingTables;

#endif