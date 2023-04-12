//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------


ailist_t *ailist_get_id(ailist_t *ail, int query_id)
{   /* Get intervals with id */

    // Initialize ailist_t to return
    ailist_t *id_intervals = ailist_init();

    // Iterate over intervals and pull all those with id
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        if (ail->interval_list[i].id_value == query_id)
        {
            ailist_add(id_intervals, ail->interval_list[i].start, ail->interval_list[i].end, ail->interval_list[i].id_value);
        }
    }
    
    return id_intervals;
}


ailist_t *ailist_get_id_array(ailist_t *ail, const long ids[], int length)
{   /* Get intervals with ids */
    
    // Initialize ailist_t to return
    ailist_t *id_intervals = ailist_init();

    // Iterate over intervals and pull all those with id
    int i;
    for (i = 0; i < length; i++)
    {
        int32_t query_id = ids[i];
        int j;
        for (j = 0; j < ail->nr; j++)
        {
            if (ail->interval_list[j].id_value == query_id)
            {
                ailist_add(id_intervals, ail->interval_list[j].start, ail->interval_list[j].end, ail->interval_list[j].id_value);
            }
        }
    }
    
    return id_intervals;
}


void ailist_reset_id(ailist_t *ail)
{   /* Reset id_values */

    // Iterate over ailist
    int i;
    for (i = 0; i < ail->nr; ++i)
    {
        ail->interval_list[i].id_value = i;
    }

    return;
}


void ailist_reset_id_shift(ailist_t *ail, int shift)
{   /* Reset id_values with shift */

    // Iterate over ailist
    int i;
    for (i = 0; i < ail->nr; ++i)
    {
        ail->interval_list[i].id_value = i + shift;
    }

    return;
}