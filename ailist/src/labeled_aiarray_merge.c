//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-------------------------------------------------------------------------------


labeled_aiarray_t *labeled_aiarray_merge(labeled_aiarray_t *ail, uint32_t gap)
{   /* Merge nearby intervals */

    // Initialize merged atrributes
    int previous_end = ail->interval_list[0].end;
    int previous_start = ail->interval_list[0].start;
    int previous_id = ail->interval_list[0].id_value;
    int previous_label = ail->interval_list[0].label;
    const char *previous_label_name = query_rev_label_map(ail, previous_label);
    labeled_aiarray_t *merged_list = labeled_aiarray_init();
    
    // Iterate over labels
    int label;
    for (label = 0; label < ail->nl; label++)
    {
        if (ail->label_count[label] > 0)
        {
            // Determine label component bounds
            int *comp_bounds = get_label_comp_bounds(ail, label);
            int nc = ail->nc[label];

            // Record number used per component
            int *label_comp_used = malloc(nc+1 * sizeof(int));
            memcpy(&label_comp_used, &comp_bounds, sizeof(int));

            // Determine label bounds
            int label_start = get_label_index(ail, label);
            int label_end = get_label_index(ail, label + 1);
            
            // Iterate over component intervals
            labeled_interval_t *intv = &ail->interval_list[label_start];
            int position;
            int n;
            for (n = label_start; n < label_end; n++)
            {
                int selected_comp = 0;
                // Iterate over other components
                int j;
                for (j = 0; j < nc; j++)
                {
                    // Check component has intervals left to investigate
                    if (label_comp_used[j] == comp_bounds[j + 1])
                    {
                        continue;
                    }

                    // Determine position
                    position = label_comp_used[j];
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
                if (previous_end > (int)(intv->start - gap) && previous_label == intv->label)
                {
                    previous_end = MAX(previous_end, (int)intv->end);
                }
                else
                {
                    labeled_aiarray_add(merged_list, previous_start, previous_end, previous_label_name);
                    previous_start = intv->start;
                    previous_end = intv->end;
                    previous_id = intv->id_value;
                    previous_label = intv->label;
                    previous_label_name = query_rev_label_map(ail, previous_label);
                }

                // Increment label_comp_counter for selected comp
                label_comp_used[selected_comp] = label_comp_used[selected_comp] + 1;
                // Iterate over components
                for (j = 0; j < nc; j++)
                {
                    // If position is available, assign next interval
                    if (label_comp_used[j] != comp_bounds[j + 1])
                    {
                        position = label_comp_used[j];
                        intv = &ail->interval_list[position];
                        break;
                    }
                }
            }
        }

        // Free
        //free(comp_bounds);
        //free(label_comp_used);
    }

    // Add last interval
    labeled_aiarray_add(merged_list, previous_start, previous_end, previous_label_name);

    return merged_list;
}

