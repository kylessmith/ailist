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

    // Iterate over labels in ail
    const char *label_name;
    label_sorted_iter_t *ail_iter;
    labeled_interval_t *intv;
    int label;
    for (label = 0; label < ail->nl; label++)
    {
        label_name = query_rev_label_map(ail, label);
        // Create sorted iterators
        ail_iter = iter_init(ail, label_name);
        while (iter_next(ail_iter) != 0)
        {
            intv = ail_iter->intv;

            // Check if intervals merge
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
        }

        // Check if intervals merge
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

        // Destroy iterator
        iter_destroy(ail_iter);
    }

    // Add last interval
    labeled_aiarray_add(merged_list, previous_start, previous_end, previous_label_name);

    return merged_list;
}



