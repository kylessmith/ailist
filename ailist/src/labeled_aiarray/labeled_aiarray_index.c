//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

void labeled_aiarray_cache_id(labeled_aiarray_t *laia)
{   /* Record id positions by id */

    // Initialize id index
    if (laia->id_index == NULL)
    {
        laia->id_index = malloc(laia->total_nr * sizeof(uint32_t));
    }
    else {
        free(laia->id_index);
        laia->id_index = malloc(laia->total_nr * sizeof(uint32_t));
    }

    // Iterate over intervals
    int count = 0;
    int t;
    for (t = 0; t < laia->n_labels; t++)
    {
        label_t *p = &laia->labels[t];
        int i;
        for (i = 0; i < p->ail->nr; i++)
        {
            laia->id_index[p->ail->interval_list[i].id_value] = count;
            count++;
        }
    }

    return;
}


labeled_interval_t *labeled_aiarray_get_index(labeled_aiarray_t *laia, int32_t i)
{   /* Retrieve labeled_interval given index */

    // Initialize interval
    labeled_interval_t *id_interval = NULL;
    
    // Check i is in id_index
    if (i > laia->total_nr)
    {
        printf("IndexError: index outside of bounds.");
        return id_interval;
    }
    
    // Check index is initialized
    if (laia->id_index == NULL)
    {
        labeled_aiarray_cache_id(laia);
    }

    int index = laia->id_index[i];
    int count = 0;
    int t;
    
    for (t = 0; t < laia->n_labels; t++)
    {
        label_t *p = &laia->labels[t];
        if (index > (p->ail->nr + count - 1))
        {
            count = count + p->ail->nr;
            continue;
        }
        else {
            int id_value = index - count;
            id_interval = labeled_interval_init(&p->ail->interval_list[id_value], p->name);
            break;
        }
    }

    return id_interval;

}


labeled_aiarray_t *labeled_aiarray_slice_index(labeled_aiarray_t *laia, const long ids[], int length)
{   /* Get intervals with ids */
    
    // Initialize interval
    labeled_aiarray_t *sliced_laia = labeled_aiarray_init();

    // Iterate over ids
    int i;
    for (i = 0; i < length; i++)
    {   
        // Check values are present
        if (ids[i] < 0 || ids[i] > laia->total_nr)
        {
            labeled_aiarray_destroy(sliced_laia);
            return NULL;
        }

        // Fetch true id
        labeled_interval_t *i_laia = labeled_aiarray_get_index(laia, ids[i]);

        // Add interval
        if (i_laia != NULL)
        {
            labeled_aiarray_add(sliced_laia, i_laia->i->start,
                                            i_laia->i->end,
                                            i_laia->name);
        }
    }
    
    return sliced_laia;
}


labeled_aiarray_t *labeled_aiarray_slice_range(labeled_aiarray_t *laia, int start, int end, int step)
{   /* Get intervals with range */
    
    // Initialize intervals
    labeled_aiarray_t *sliced_laia = labeled_aiarray_init();

    // Check values are present
    if (start < 0 || end > laia->total_nr)
    {
        return NULL;
    }

    // Iterate over ids
    int i;
    for (i = start; i < end; i+=step)
    {
        // Fetch true id
        labeled_interval_t *i_laia = labeled_aiarray_get_index(laia, i);
        
        // Add interval
        if (i_laia != NULL)
        {
            labeled_aiarray_add(sliced_laia, i_laia->i->start,
                                            i_laia->i->end,
                                            i_laia->name);
        }
    }
    
    
    return sliced_laia;
}


labeled_aiarray_t *labeled_aiarray_slice_bool(labeled_aiarray_t *laia, uint8_t bool_index[])
{   /* Get intervals with boolean array */

    // Initialize intervals
    labeled_aiarray_t *sliced_laia = labeled_aiarray_init();

    // Iterate over bool_index
    int i;
    for (i = 0; i < laia->total_nr; i++)
    {
        if (bool_index[i] == 1)
        {
            // Fetch true id
            labeled_interval_t *i_laia = labeled_aiarray_get_index(laia, i);
            
            // Add interval
            if (i_laia != NULL)
            {
                labeled_aiarray_add(sliced_laia, i_laia->i->start,
                                                i_laia->i->end,
                                                i_laia->name);
            }
        }
    }

    return sliced_laia;
}


int labeled_aiarray_index_with_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *other_laia)
{   /* Re-assign interval bounds based on other given intervals */

    // Iterate over labels
    int l;
    for (l = 0; l < other_laia->n_labels; l++)
    {
        const char *label_name = other_laia->labels[l].name;
        uint32_t t = get_label(laia, label_name);

        if (t >= 0)
        {
            label_t *p1 = &laia->labels[t];
            label_t *p2 = &other_laia->labels[l];

            int first = 0;
            int last = 0;
            int i;
            for (i = 0; i < p1->ail->nr; i++)
            {
                uint32_t position_start = p1->ail->interval_list[i].start;
                // Check position
                if (position_start < 0 || position_start >= p2->ail->nr)
                {
                    return 1;
                }
                p1->ail->interval_list[i].start = p2->ail->interval_list[position_start].start;
                first = MIN(INT32_MAX, p1->ail->interval_list[i].start);

                uint32_t position_end = p1->ail->interval_list[i].end - 1;
                // Check position
                if (position_end < 0 || position_end >= p2->ail->nr)
                {
                    return 1;
                }
                p1->ail->interval_list[i].end = p2->ail->interval_list[position_end].end;
                last = MAX(0, p1->ail->interval_list[i].end);
            }

            p1->ail->first = first;
            p1->ail->last = last;
        
        } else {

            return 1;
        }
    }

    return 0;
}