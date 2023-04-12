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


//-------------------------------------------------------------------------------------

#define push_indices(oi, value) do {												\
    if (oi->size == oi->max_size){													\
		oi->max_size = oi->max_size? oi->max_size<<1 : 2;							\
		oi->indices = (long*)realloc(oi->indices, sizeof(long) * oi->max_size);		\
	}																				\
	oi->indices[oi->size++] = (value);												\
} while (0)

#define push_array_query(aq, value1, value2) do {											\
    if (aq->size == aq->max_size){													        \
		aq->max_size = aq->max_size? aq->max_size<<1 : 2;							        \
		aq->ref_index = (long*)realloc(aq->ref_index, sizeof(long) * aq->max_size);		\
        aq->query_index = (long*)realloc(aq->query_index, sizeof(long) * aq->max_size);	\
	}																				        \
	aq->ref_index[aq->size] = (value1);												    \
    aq->query_index[aq->size++] = (value2);												    \
} while (0)


#endif