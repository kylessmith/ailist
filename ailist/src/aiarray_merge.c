//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_array.h"

//-----------------------------------------------------------------------------


int *get_comp_bounds(aiarray_t *ail)
{   /* Get component index */

    //int label_start = ail->label_index[label];
    int *idxC = ail->idxC;
    int n_comps = ail->nc;
    int *comps_bounds = malloc((n_comps + 1) * sizeof(int));
    int i;
    for (i = 0; i < n_comps; i++)
    {
        comps_bounds[i] = idxC[i];
    }

    comps_bounds[n_comps] = ail->nr;

    return comps_bounds;
}


aiarray_t *aiarray_merge(aiarray_t *ail, uint32_t gap)
{   /* Merge nearby intervals */

    // Initialize merged atrributes
    int previous_end = ail->interval_list[0].end;
    int previous_start = ail->interval_list[0].start;
    int previous_id = ail->interval_list[0].id_value;
    aiarray_t *merged_list = aiarray_init();
    
    // Determine label component bounds
    int *comp_bounds = get_comp_bounds(ail);
    int nc = ail->nc;

    // Record number used per component
    int *comp_used = malloc(nc+1 * sizeof(int));
    memcpy(&comp_used, &comp_bounds, sizeof(int));

    // Determine label bounds
    //int label_start = ail->label_index[label];
    //int label_end = ail->label_index[label + 1];
    
    // Iterate over component intervals
    interval_t *intv = &ail->interval_list[0];
    int position;
    int n;
    for (n = 0; n < ail->nr; n++)
    {
        int selected_comp = 0;
        // Iterate over other components
        int j;
        for (j = 0; j < nc; j++)
        {
            // Check component has intervals left to investigate
            if (comp_used[j] == comp_bounds[j + 1])
            {
                continue;
            }

            // Determine position
            position = comp_used[j];
            // Check for lower start
            if (ail->interval_list[position].start < intv->start)
            {
                intv = &ail->interval_list[position];
                selected_comp = j;
            }
        }

        // Sorted interval found
        //printf("(%d-%d, %d); (%d-%d, %d)\n", intv->start, intv->end, intv->label, previous_start, previous_end, previous_label);
        //printf("[%d, %d, %d]\n", label_comp_used[0], label_comp_used[1], label_comp_used[2]);
        // If previous
        if (previous_end > (int)(intv->start - gap))
        {
            previous_end = MAX(previous_end, (int)intv->end);
        }
        else
        {
            aiarray_add(merged_list, previous_start, previous_end);
            previous_start = intv->start;
            previous_end = intv->end;
            previous_id = intv->id_value;
        }

        // Increment comp_counter for selected comp
        comp_used[selected_comp] = comp_used[selected_comp] + 1;
        // Iterate over components
        for (j = 0; j < nc; j++)
        {
            // If position is available, assign next interval
            if (comp_used[j] != comp_bounds[j + 1])
            {
                position = comp_used[j];
                intv = &ail->interval_list[position];
                break;
            }
        }

        // Free
        //free(comp_bounds);
        //free(label_comp_used);
    }

    // Add last interval
    aiarray_add(merged_list, previous_start, previous_end);

    return merged_list;
}

