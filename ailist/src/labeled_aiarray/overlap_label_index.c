//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------


overlap_label_index_t *overlap_label_index_init(void)
{   /* Initialize overlap_index */
    
    // Initialize variables
    overlap_label_index_t *oi = (overlap_label_index_t *)malloc(sizeof(overlap_label_index_t));
    if (oi == NULL)
    {
        printf("Memory allocation failed");
        exit(1); // exit the program
    }
    oi->size = 0;
    oi->max_size = 64;
    oi->indices = (long *)malloc(sizeof(long) * 64);
    if (oi->indices == NULL)
    {
        printf("Memory allocation failed");
        exit(1); // exit the program
    }
    oi->laia = labeled_aiarray_init();

    return oi;
}


void overlap_label_index_destroy(overlap_label_index_t *oi)
{   /* Free overlap_label_index memory */

    labeled_aiarray_destroy(oi->laia);
    free(oi->indices);
    free(oi);

    return;
}


void overlap_label_index_add(overlap_label_index_t *oi, interval_t i, const char *label_name)
{   /* Add interval to overlap_label_index */

    // Check if size needs to be increased
    push_indices(oi, i.id_value);

    // Add new indices
    labeled_aiarray_add(oi->laia, i.start, i.end, label_name);

    return;
}


void overlap_label_index_wrap_ail(overlap_label_index_t * oi, ailist_t *ail, const char *label_name)
{
    labeled_aiarray_wrap_ail(oi->laia, ail, label_name);

    int j;
    for (j = 0; j < ail->nr; j++)
    {
        interval_t i = ail->interval_list[j];

        // Check if size needs to be increased
        if (oi->size == oi->max_size)
        {
            oi->max_size = oi->max_size + 64;
            oi->indices = (long *)realloc(oi->indices, sizeof(long) * oi->max_size);
            if (oi->indices == NULL)
            {
                printf("Memory allocation failed");
                exit(1); // exit the program
            }
        }

        // Increment size
        oi->size++;

        // Add new indices
        oi->indices[oi->size-1] = i.id_value;
    }

    return;
}