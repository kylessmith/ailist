//=====================================================================================
// Common structs, parameters, functions
// Original: https://github.com/kylessmith/AIList/
// by Kyle S. Smith
//-------------------------------------------------------------------------------------
#ifndef __ARRAY_QUERY_H__
#define __ARRAY_QUERY_H__
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

//-------------------------------------------------------------------------------------

typedef struct {
    long *ref_index;        // Reference index
    long *query_index;      // Query index
    int size;               // Length of ref_index
    int max_size;           // Maximum length
} array_query_t;


//-------------------------------------------------------------------------------------
// array_query_utilities.c
//=====================================================================================

// Initialize array_query struct
array_query_t *array_query_init(void);

// Free array_query struct memory
void array_query_destroy(array_query_t *aq);

// Add query to array_query struct
void array_query_add(array_query_t *aq, long ref, long query);

#endif