//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

labeled_aiarray_t *labeled_aiarray_length_filter(labeled_aiarray_t *laia, int min_length, int max_length)
{   /* Filter labeled_aiarray by length */
    
    // Initialize label_aiarray
    labeled_aiarray_t *filtered_laia = labeled_aiarray_init();

    // Iterate over labels
    int32_t i;
    for (i = 0; i < laia->n_labels; i++)
    {
        label_t *p1 = &laia->labels[i];

        int32_t j;
        for (j = 0; j < p1->ail->nr; j++)
        {   
            int length = p1->ail->interval_list[j].end - p1->ail->interval_list[j].start;
            if (length > min_length && length < max_length)
            {
                labeled_aiarray_add(filtered_laia, p1->ail->interval_list[j].start, p1->ail->interval_list[j].end, p1->name);
            }
        }
    }

    return filtered_laia;
}


labeled_aiarray_t *labeled_aiarray_downsample(labeled_aiarray_t *laia, double proportion)
{   /* Randomly downsample */

    // Initialize label_aiarray
    labeled_aiarray_t *filtered_laia = labeled_aiarray_init();

    // Iterate over labels
    int32_t i;
    for (i = 0; i < laia->n_labels; i++)
    {
        label_t *p = &laia->labels[i];
        ailist_t *filtered_ail = ailist_downsample(p->ail, proportion);
        labeled_aiarray_wrap_ail(filtered_laia, filtered_ail, p->name);
    }

    return filtered_laia;
}


overlap_label_index_t *labeled_aiarray_downsample_with_index(labeled_aiarray_t *laia, double proportion)
{   /* Randomly downsample */

    // Initialize label_aiarray
    overlap_label_index_t *filtered_oi = overlap_label_index_init();

    // Iterate over labels
    int32_t i;
    for (i = 0; i < laia->n_labels; i++)
    {
        label_t *p = &laia->labels[i];
        ailist_t *filtered_ail = ailist_downsample(p->ail, proportion);
        overlap_label_index_wrap_ail(filtered_oi, filtered_ail, p->name);
    }

    return filtered_oi;
}


//-----------------------------------------------------------------------------
