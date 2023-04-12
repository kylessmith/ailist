//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

void ailist_length_filter(ailist_t *ail, ailist_t *filtered_ail, int min_length, int max_length)
{   /* Filter ailist by length */

    // Iterate over intervals and filter
    int length;
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        // Record length (excluding last position)
        length = ail->interval_list[i].end - ail->interval_list[i].start - 1;
        if (length >= min_length && length <= max_length)
        {
            ailist_add(filtered_ail, ail->interval_list[i].start, ail->interval_list[i].end, ail->interval_list[i].id_value);
        }
    }

    return;
}


ailist_t *ailist_downsample(ailist_t *ail, double proportion)
{   /* Randomly downsample */

    // Initialize downsampled ailist_t
    ailist_t *filtered_ail = ailist_init();

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
            ailist_add(filtered_ail, ail->interval_list[i].start, ail->interval_list[i].end, ail->interval_list[i].id_value);
        }
    }

    return filtered_ail;
}


