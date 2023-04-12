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
    aq->max_size = 32;
    aq->ref_index = (long *)malloc(sizeof(long) * 32);
    if (aq->ref_index == NULL)
    {
        printf("Memory allocation failed");
        exit(1); // exit the program
    }
    aq->query_index = (long *)malloc(sizeof(long) * 32);
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

    // Push values to array query
    push_array_query(aq, ref, query);

    return;

}