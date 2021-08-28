//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_array.h"

//-----------------------------------------------------------------------------

void aiarray_cache_id(aiarray_t *ail)
{   /* Record id positions by index */

    // Initialize id_index
    if (ail->id_index == NULL)
    {
        ail->id_index = malloc(ail->nr * sizeof(uint32_t));
    }
    else {
        free(ail->id_index);
        ail->id_index = malloc(ail->nr * sizeof(uint32_t));
    }

    // Iterate over intervals
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        ail->id_index[ail->interval_list[i].id_value] = i;
    }

    return;

}


interval_t *aiarray_get_index(aiarray_t *ail, int id_value)
{   /* Get interval with id */

    interval_t *id_interval;

    if (ail->id_index != NULL)
    {
        id_interval = &ail->interval_list[ail->id_index[id_value]];
    } else {
        id_interval = &ail->interval_list[id_value];
    }
    
    return id_interval;
}


aiarray_t *aiarray_get_index_array(aiarray_t *ail, const long ids[], int length)
{   /* Get intervals with ids */
    
    aiarray_t *id_intervals;

    if (ail->id_index != NULL)
    {
        id_intervals = aiarray_init();

        int i;
        for (i = 0; i < length; i++)
        {
            uint32_t id_i = ail->id_index[ids[i]];
            aiarray_add(id_intervals, ail->interval_list[id_i].start, ail->interval_list[id_i].end);
        }
    } else {
        id_intervals = aiarray_array_index(ail, ids, length);
    }
    
    return id_intervals;
}


aiarray_t *aiarray_array_index(aiarray_t *ail, const long idxs[], int length)
{   /* Index aiarray by array */
	
	// Initialize indexed aiarray
	aiarray_t *indexed_ail = aiarray_init();
	
    // Iterate over index
    int i;
    for (i = 0; i < length; i++)
    {
        int position = idxs[i];
		aiarray_add(indexed_ail, ail->interval_list[position].start, ail->interval_list[position].end);
    }

    return indexed_ail;
}


aiarray_t *aiarray_index_by_aiarray(aiarray_t *ail1, aiarray_t *ail2)
{   /* Index aiarray by another aiarray */

    // Initialize downsampled aiarray_t
    aiarray_t *indexed_ail = aiarray_init();

    // Iterate over ail
    int start;
    int end;
    int position_start;
    int position_end;
    int i;
    for (i = 0; i < ail1->nr; i++)
    {   
        // Record info
        position_start = ail1->interval_list[i].start;
        // Check position
        if (position_start < 0 || position_start >= ail2->nr)
        {
            return indexed_ail;
        }
        position_end = ail1->interval_list[i].end - 1;
        // Check position
        if (position_end < 0 || position_end >= ail2->nr)
        {
            return indexed_ail;
        }

        start = ail2->interval_list[position_start].start;
        end = ail2->interval_list[position_end].end;

        aiarray_add(indexed_ail, start, end);
    }

    return indexed_ail;
}


int aiarray_index_by_aiarray_inplace(aiarray_t *ail1, aiarray_t *ail2)
{   /* Index aiarray by another aiarray inplace */

    // Iterate over ail
    int position_start;
    int position_end;
    int i;
    for (i = 0; i < ail1->nr; i++)
    {   
        // Set ail1 start to start position in ail2
        position_start = ail1->interval_list[i].start;
        // Check position
        if (position_start < 0 || position_start >= ail2->nr)
        {
            return 1;
        }
        ail1->interval_list[i].start = ail2->interval_list[position_start].start;

        // Set ail1 end to start position in ail2
        position_end = ail1->interval_list[i].end - 1;
        // Check position
        if (position_end < 0 || position_end >= ail2->nr)
        {
            return 1;
        }
        ail1->interval_list[i].end = ail2->interval_list[position_end].end;
    }

    // Change range
    position_start = ail1->first;
    position_end = ail1->last - 1;
    ail1->first = ail2->interval_list[position_start].start;
    ail1->last = ail2->interval_list[position_end].end - 1;

    return 0;
}