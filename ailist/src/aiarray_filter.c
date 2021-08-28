//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_array.h"

//-----------------------------------------------------------------------------

aiarray_t *aiarray_length_filter(aiarray_t *ail, int min_length, int max_length)
{   /* Filter aiarray by length */
    
    // Initiatize filtered aiarray
    aiarray_t *filtered_ail = aiarray_init();

    // Iterate over intervals and filter
    int length;
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        // Record length (excluding last position)
        length = ail->interval_list[i].end - ail->interval_list[i].start - 1;
        if (length >= min_length && length <= max_length)
        {
            aiarray_add(filtered_ail, ail->interval_list[i].start, ail->interval_list[i].end);
        }
    }

    return filtered_ail;
}


aiarray_t *aiarray_downsample(aiarray_t *ail, double proportion)
{   /* Randomly downsample */

    // Initialize downsampled aiarray_t
    aiarray_t *filtered_ail = aiarray_init();

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
            aiarray_add(filtered_ail, ail->interval_list[i].start, ail->interval_list[i].end);
        }
    }

    return filtered_ail;
}


overlap_index_t *aiarray_downsample_with_index(aiarray_t *ail, double proportion)
{   /* Randomly downsample with original index */

    // Initialize downsampled aiarray_t
    overlap_index_t *filtered_ail = overlap_index_init();

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
            overlap_index_add(filtered_ail, &ail->interval_list[i]);
        }
    }

    return filtered_ail;
}