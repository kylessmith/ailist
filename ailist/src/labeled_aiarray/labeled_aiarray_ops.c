//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

labeled_aiarray_t *labeled_aiarray_common(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2)
{   /* Find common intervals between two labeled_aiarrays */

    // Initialize label_aiarray
    labeled_aiarray_t *common_laia = labeled_aiarray_init();

    // Iterate over labels
    int32_t i;
    for (i = 0; i < laia1->n_labels; i++)
    {
        label_t *p1 = &laia1->labels[i];
        // Get label
        int32_t t = get_label(laia2, p1->name);

        // Check if label present
        if (t != -1)
        {
            label_t *p2 = &laia2->labels[t];
            ailist_t *common_ail = ailist_common(p1->ail, p2->ail);
            labeled_aiarray_wrap_ail(common_laia, common_ail, p1->name);
        }
    }

    return common_laia;
}


labeled_aiarray_t *labeled_aiarray_subtract(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2)
{   /* Subtract intervals from laia1 that are in laia2 */

    // Initialize label_aiarray
    labeled_aiarray_t *subtracted_laia = labeled_aiarray_init();

    // Iterate over labels
    int32_t i;
    for (i = 0; i < laia1->n_labels; i++)
    {
        label_t *p1 = &laia1->labels[i];
        // Get label
        int32_t t = get_label(laia2, p1->name);

        // Check if label present
        if (t != -1)
        {
            label_t *p2 = &laia2->labels[t];
            ailist_t *subtracted_ail = ailist_subtract(p1->ail, p2->ail);
            labeled_aiarray_wrap_ail(subtracted_laia, subtracted_ail, p1->name);
        }

        // If label not present, add to subtracted_laia
        else
        {
            labeled_aiarray_append_ail(subtracted_laia, p1->ail, p1->name);
        }
    }

    return subtracted_laia;
}


labeled_aiarray_t *labeled_aiarray_union(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2)
{   /* Find union of intervals between two labeled_aiarrays */

    // Initialize label_aiarray
    labeled_aiarray_t *union_laia = labeled_aiarray_init();
    labeled_aiarray_append(union_laia, laia1);
    labeled_aiarray_append(union_laia, laia2);

    return union_laia;
}