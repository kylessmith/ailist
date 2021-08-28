//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

void labeled_aiarray_cache_id(labeled_aiarray_t *ail)
{   /* Record id positions by id */

    // Initialize id index
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


labeled_aiarray_t *labeled_aiarray_slice_index(labeled_aiarray_t *ail, const long ids[], int length)
{   /* Get intervals with ids */
    
    // Initialize interval
    labeled_aiarray_t *sliced_intervals = labeled_aiarray_init();

    // Determine if ail has cached ids
    if (ail->id_index != NULL)
    {
        // Iterate over ids
        int i;
        for (i = 0; i < length; i++)
        {   
            uint32_t id = ail->id_index[ids[i]];

            // Check values are present
            if (id < 0 || id > ail->nr)
            {
                labeled_aiarray_destroy(sliced_intervals);
                return NULL;
            }

            uint16_t label = ail->interval_list[id].label;
            const char *label_name = query_rev_label_map(ail, label);
            labeled_aiarray_add(sliced_intervals, ail->interval_list[id].start, ail->interval_list[id].end,
                                label_name);
        }
    } else {
        // Iterate over index
        int i;
        for (i = 0; i < length; i++)
        {
            int id = ids[i];

            // Check values are present
            if (id < 0 || id > ail->nr)
            {
                labeled_aiarray_destroy(sliced_intervals);
                return NULL;
            }

            uint16_t label = ail->interval_list[id].label;
            const char *label_name = query_rev_label_map(ail, label);
            labeled_aiarray_add(sliced_intervals, ail->interval_list[id].start, ail->interval_list[id].end,
                                label_name);
        }
    }
    
    return sliced_intervals;
}


labeled_aiarray_t *labeled_aiarray_slice_range(labeled_aiarray_t *ail, int start, int end, int step)
{   /* Get intervals with range */
    
    // Initialize intervals
    labeled_aiarray_t *sliced_intervals = labeled_aiarray_init();

    // Check values are present
    if (start < 0 || end > ail->nr)
    {
        return NULL;
    }

    // Determine if ail has cached ids
    if (ail->id_index != NULL)
    {
        // Iterate over ids
        int i;
        for (i = start; i < end; i+=step)
        {
            uint32_t id = ail->id_index[i];
            uint16_t label = ail->interval_list[id].label;
            const char *label_name = query_rev_label_map(ail, label);
            labeled_aiarray_add(sliced_intervals, ail->interval_list[id].start, ail->interval_list[id].end,
                                label_name);
        }
    } else {
        // Iterate over index
        int i;
        for (i = start; i < end; i+=step)
        {
            int id = i;
            uint16_t label = ail->interval_list[id].label;
            const char *label_name = query_rev_label_map(ail, label);
            labeled_aiarray_add(sliced_intervals, ail->interval_list[id].start, ail->interval_list[id].end,
                                label_name);
        }
    }
    
    return sliced_intervals;
}


labeled_aiarray_t *labeled_aiarray_slice_bool(labeled_aiarray_t *ail, uint8_t bool_index[])
{   /* Get intervals with boolean array */

    // Initialize intervals
    labeled_aiarray_t *sliced_intervals = labeled_aiarray_init();

    // Determine if ail has cached ids
    if (ail->id_index != NULL)
    {
        // Iterate over bool_index
        int i;
        for (i = 0; i < ail->nr; i++)
        {
            if (bool_index[i] == 1)
            {
                uint32_t id = ail->id_index[i];
                uint16_t label = ail->interval_list[id].label;
                const char *label_name = query_rev_label_map(ail, label);
                labeled_aiarray_add(sliced_intervals, ail->interval_list[id].start, ail->interval_list[id].end,
                                    label_name);
            }
        }
    } else {
        // Iterate over bool_index
        int i;
        for (i = 0; i < ail->nr; i++)
        {
            if (bool_index[i] == 1)
            {
                uint32_t id = ail->id_index[i];
                uint16_t label = ail->interval_list[id].label;
                const char *label_name = query_rev_label_map(ail, label);
                labeled_aiarray_add(sliced_intervals, ail->interval_list[id].start, ail->interval_list[id].end,
                                    label_name);
            }
        }
    }

    return sliced_intervals;
}


labeled_interval_t *labeled_aiarray_get_id(labeled_aiarray_t *ail, int id_value)
{   /* Get interval with id */

    // Initialize interval
    labeled_interval_t *id_interval;

    // Find interval
    if (ail->id_index != NULL)
    {
        id_interval = &ail->interval_list[ail->id_index[id_value]];
    } else {
        id_interval = &ail->interval_list[id_value];
    }
    
    return id_interval;
}


int labeled_aiarray_index_by_aiarray_inplace(labeled_aiarray_t *ail1, labeled_aiarray_t *ail2)
{   /* Index aiarray by another aiarray inplace */

    // Iterate over ail
    int label_start;
    int position_start;
    int position_end;

    // Determine label indices
    int *label_index = malloc(ail2->nl * sizeof(int));
    get_label_index_array(ail2, label_index);

    int i;
    for (i = 0; i < ail1->nr; i++)
    {   
        // Set ail1 start to start position in ail2
        position_start = ail1->interval_list[i].start;
        // Check position
        if (ail1->interval_list[i].label > ail2->nl || position_start < 0 || position_start >= ail2->nr)
        {
            return 1;
        }
        label_start = label_index[ail1->interval_list[i].label];
        ail1->interval_list[i].start = ail2->interval_list[label_start + position_start].start;

        // Set ail1 end to start position in ail2
        position_end = ail1->interval_list[i].end - 1;
        // Check position
        if (position_end < 0 || position_end >= ail2->nr)
        {
            return 1;
        }
        ail1->interval_list[i].end = ail2->interval_list[label_start + position_end].end;
        //printf("i: %d, start: %d, end: %d, label: %d, label_start: %d\n", i, position_start, position_end, ail1->interval_list[i].label, label_start);
    }

    // Change range
    for (i = 0; i < ail1->nl; i++)
    {
        position_start = ail1->first[i];
        position_end = ail1->last[i] - 1;
        label_start = label_index[i];
        ail1->first[i] = ail2->interval_list[label_start + position_start].start;
        ail1->last[i] = ail2->interval_list[label_start + position_end].end - 1;
    }

    return 0;
}