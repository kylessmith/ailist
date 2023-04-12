//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------


void labeled_aiarray_percent_coverage(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2, double coverage[])
{   /* Find percent coverage of intervals in laia1 that are in laia2 */

    
    
    // Iterate over labels
    labeled_aiarray_iter_t *iter = labeled_aiarray_iter_init(laia1);
    
    while (labeled_aiarray_iter_next(iter) != 0)
    {
        // Get label
        int32_t t = get_label(laia2, iter->name);

        // Check if label present
        if (t != -1)
        {
            label_t *p2 = &laia2->labels[t];

            ailist_t *result_ail = ailist_init();
            ailist_t *overlaps = ailist_init();
            ailist_query(p2->ail, overlaps, iter->intv->i->start, iter->intv->i->end);
            ailist_construct(overlaps, 20);
            ailist_common_intervals(iter->intv->i, overlaps, result_ail);

            // Iterate over common intervals
            int32_t k;
            for (k = 0; k < result_ail->nr; k++)
            {
                // Calculate percent coverage
                coverage[iter->n] += (double)(result_ail->interval_list[k].end - result_ail->interval_list[k].start);
            }

            // Calculate percent coverage
            coverage[iter->n] /= (double)(iter->intv->i->end - iter->intv->i->start);

            // Free memory
            ailist_destroy(overlaps);
            ailist_destroy(result_ail);
        }
        // If label not present, set coverage to 0
        else {
            coverage[iter->n] = 0;
        }
    }

    // Free memory
    labeled_aiarray_iter_destroy(iter);

    return;
}