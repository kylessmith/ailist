//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

ailist_t *ailist_merge(ailist_t *ail, uint32_t gap)
{   /* Merge intervals in constructed ailist_t object */
    int previous_end = ail->interval_list[0].end;
    int previous_start = ail->interval_list[0].start;
    int previous_id = ail->interval_list[0].id_value;
    int i;
    ailist_t *merged_list = ailist_init();

    // Iterate over regions
    for (i = 1; i < ail->nr; i++)
    {
        // If previous
        if (previous_end > (int)(ail->interval_list[i].start - gap))
        {
            previous_end = MAX(previous_end, (int)ail->interval_list[i].end);
        }
        else
        {
            ailist_add(merged_list, previous_start, previous_end, previous_id);
            previous_start = ail->interval_list[i].start;
            previous_end = ail->interval_list[i].end;
            previous_id = ail->interval_list[i].id_value;
        }
    }

    // Add last interval
    ailist_add(merged_list, previous_start, previous_end, previous_id);

    return merged_list;
}