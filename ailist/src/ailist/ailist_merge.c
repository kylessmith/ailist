//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

ailist_t *ailist_merge(ailist_t *ail, uint32_t gap)
{   /* Merge intervals in constructed ailist_t object */

    // Initialize merged atrributes
    int previous_end = ail->interval_list[0].end;
    int previous_start = ail->interval_list[0].start;
    int previous_id = ail->interval_list[0].id_value;
    ailist_t *merged_list = ailist_init();
    interval_t *intv;

    // Create sorted iterators
    ailist_sorted_iter_t* ail_iter = ailist_sorted_iter_init(ail);
    intv = ail_iter->intv;
    while (ailist_sorted_iter_next(ail_iter) != 0)
    {
        intv = ail_iter->intv;
        
        // Check if intervals merge
        if (previous_end > (int)(intv->start - gap))
            {
                previous_end = MAX(previous_end, (int)intv->end);
            }
            else
            {
                ailist_add(merged_list, previous_start, previous_end, previous_id);
                previous_start = intv->start;
                previous_end = intv->end;
                previous_id = intv->id_value;
            }
    }

    // Check if intervals merge
    if (previous_end > (int)(intv->start - gap))
        {
            previous_end = MAX(previous_end, (int)intv->end);
        }
        else
        {
            ailist_add(merged_list, previous_start, previous_end, previous_id);
            previous_start = intv->start;
            previous_end = intv->end;
            previous_id = intv->id_value;
        }

    // Destroy iterator
    ailist_sorted_iter_destroy(ail_iter);

    // Add last interval
    ailist_add(merged_list, previous_start, previous_end, previous_id);

    return merged_list;
}