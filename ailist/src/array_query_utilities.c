#include "array_query_utilities.h"


array_query_t *array_query_init(void)
{
    // Initialize variables
    array_query_t *aq = (array_query_t *)malloc(sizeof(array_query_t));
    if (aq == NULL)
    {
        printf("Memory allocation failed");
        exit(1); // exit the program
    }
    aq->size = 0;
    aq->max_size = 64;
    aq->ref_index = (long *)malloc(sizeof(long) * 64);
    if (aq->ref_index == NULL)
    {
        printf("Memory allocation failed");
        exit(1); // exit the program
    }
    aq->query_index = (long *)malloc(sizeof(long) * 64);
    if (aq->query_index == NULL)
    {
        printf("Memory allocation failed");
        exit(1); // exit the program
    }

    return aq;
}


void array_query_destroy(array_query_t *aq)
{
    free(aq->ref_index);
    free(aq->query_index);
    free(aq);
}


void array_query_add(array_query_t *aq, long ref, long query)
{

    // Check if size needs to be increased
    if (aq->size == aq->max_size)
    {
        aq->max_size = aq->max_size + 64;
        aq->ref_index = (long *)realloc(aq->ref_index, sizeof(long) * aq->max_size);
        if (aq->ref_index == NULL)
        {
            printf("Memory allocation failed");
            exit(1); // exit the program
        }
        aq->query_index = (long *)realloc(aq->query_index, sizeof(long) * aq->max_size);
        if (aq->query_index == NULL)
        {
            printf("Memory allocation failed");
            exit(1); // exit the program
        }
    }

    // Increment size
    aq->size++;

    // Add new indices
    aq->ref_index[aq->size-1] = ref;
    aq->query_index[aq->size-1] = query;
}