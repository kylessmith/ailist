#ifndef __ARRAY_QUERY_H__
#define __ARRAY_QUERY_H__
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct {
    long *ref_index;
    long *query_index;
    int size;
    int max_size;
} array_query_t;


array_query_t *array_query_init(void);

void array_query_destroy(array_query_t *aq);

void array_query_add(array_query_t *aq, long ref, long query);

#endif