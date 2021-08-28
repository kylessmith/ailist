//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------


overlap_label_index_t *has_exact_match(labeled_aiarray_t *ail1, labeled_aiarray_t *ail2)
{

    // Initiatilize matched
    overlap_label_index_t *matched_ail = overlap_label_index_init();

    // Iterate over labels in ail1
    int label1;
    for (label1 = 0; label1 < ail1->nl; label1++)
    {
        // Determine if label is in ail2
        const char *label_name = query_rev_label_map(ail1, label1);
        if (label_is_present(ail2, label_name) == 1)
        {
            // Create sorted iterators
            label_sorted_iter_t *ail1_iter = iter_init(ail1, label_name);
            label_sorted_iter_t *ail2_iter = iter_init(ail2, label_name);
            
            // Iterate over ail1
            int ail2_end = iter_next(ail2_iter);
            while (iter_next(ail1_iter) != 0 && ail2_end != 0)
            {
                while (ail2_end !=0 && ail2_iter->intv->start <= ail1_iter->intv->start)
                {
                    if (ail1_iter->intv->start == ail2_iter->intv->start && ail1_iter->intv->end == ail2_iter->intv->end)
                    {
                        overlap_label_index_add(matched_ail, *ail1_iter->intv, label_name);
                    }
                    // Increment ail2 iterator
                    ail2_end = iter_next(ail2_iter);
                }
            }
            
        }
    }

    return matched_ail;
}

//-----------------------------------------------------------------------------
