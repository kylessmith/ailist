//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

labeled_aiarray_t *labeled_aiarray_length_filter(labeled_aiarray_t *ail, int min_length, int max_length)
{   /* Filter labeled_aiarray by length */
    
    // Initiatize filtered labeled_aiarray
    labeled_aiarray_t *filtered_ail = labeled_aiarray_init();

    // Iterate over intervals and filter
    int length;
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        // Record length (excluding last position)
        length = ail->interval_list[i].end - ail->interval_list[i].start - 1;
        if (length >= min_length && length <= max_length)
        {
            const char *label_name = query_rev_label_map(ail, ail->interval_list[i].label);
            labeled_aiarray_add(filtered_ail, ail->interval_list[i].start, ail->interval_list[i].end, label_name);
        }
    }

    return filtered_ail;
}


labeled_aiarray_t *labeled_aiarray_downsample(labeled_aiarray_t *ail, double proportion)
{   /* Randomly downsample */

    // Initialize downsampled aiarray_t
    labeled_aiarray_t *filtered_ail = labeled_aiarray_init();

    // Set random seed
	srand(time(NULL));

    // Iterate over ail
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        // Randomly determine if interval is added
        double r = (double)rand() / (double)RAND_MAX;
        if (r < proportion)
        {
            const char *label_name = query_rev_label_map(ail, ail->interval_list[i].label);
            labeled_aiarray_add(filtered_ail, ail->interval_list[i].start, ail->interval_list[i].end, label_name);
        }
    }

    return filtered_ail;
}


overlap_label_index_t *labeled_aiarray_downsample_with_index(labeled_aiarray_t *ail, double proportion)
{   /* Randomly downsample with original index */

    // Initialize downsampled aiarray_t
    overlap_label_index_t *filtered_ail = overlap_label_index_init();

    // Set random seed
	srand(time(NULL));

    // Iterate over ail
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        // Randomly determine if interval is added
        double r = (double)rand() / (double)RAND_MAX;
        if (r < proportion)
        {
            const char *label_name = query_rev_label_map(ail, ail->interval_list[i].label);
            overlap_label_index_add(filtered_ail, ail->interval_list[i], label_name);
        }
    }

    return filtered_ail;
}

//-----------------------------------------------------------------------------
