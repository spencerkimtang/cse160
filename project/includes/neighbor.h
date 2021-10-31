#ifndef NEIGHBOR_H
#define NEIGHBOR_H

typedef nx_struct Neighbor{
    nx_uint16_t address;
    nx_uint16_t age;
    nx_uint16_t source;
}Neighbor;

#endif