#ifndef LSP_H
#define LSP_H

typedef nx_struct lsp{
    nx_uint16_t dest;
    nx_uint16_t cost;
    nx_uint16_t nextHop;
}lsp;

#endif