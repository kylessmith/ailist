//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-------------------------------------------------------------------------------


labeled_aiarray_t *labeled_aiarray_merge(labeled_aiarray_t *laia, uint32_t gap)
{   /* Merge nearby intervals */

    // Initialize label_aiarray
    labeled_aiarray_t *merged_laia = labeled_aiarray_init();

    // Iterate over labels
    int32_t i;
    for (i = 0; i < laia->n_labels; i++)
    {
        label_t *p = &laia->labels[i];
        ailist_t *merged_ail = ailist_merge(p->ail, gap);
        labeled_aiarray_wrap_ail(merged_laia, merged_ail, p->name);
    }

    // Re-sort
    labeled_aiarray_order_sort(merged_laia);

    return merged_laia;
}



