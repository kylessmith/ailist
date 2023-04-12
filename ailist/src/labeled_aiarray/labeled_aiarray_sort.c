//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-------------------------------------------------------------------------------


void labeled_aiarray_order_sort(labeled_aiarray_t *laia)
{   /* Sort intervals by actual order */

    // Iterate over labels
    int count = 0;
    int32_t l;
    for (l = 0; l < laia->n_labels; l++)
    {
        label_t *p = &laia->labels[l];
        
        // Iterate over intervals
        int32_t i;
        for (i = 0; i < p->ail->nr; i++)
        {
            p->ail->interval_list[i].id_value = count;
            count++;
        }
    }

    // Cache id_values
    labeled_aiarray_cache_id(laia);

    return;
}


void labeled_aiarray_sort_index(labeled_aiarray_t *laia, long *index)
{   /* Sort intervals by starts */

    // Iterate over labels
    int count = 0;
    int32_t l;
    for (l = 0; l < laia->n_labels; l++)
    {
        //label_t *p = &laia->labels[l];

        const char *label_name = laia->labels[l].name;
        label_sorted_iter_t *iter = label_sorted_iter_init(laia, label_name);

        while (label_sorted_iter_next(iter) != 0)
        {
            //index[iter->intv->id_value] = count;
            index[count] = iter->intv->id_value;
            count++;
        }

        // Free
        label_sorted_iter_destroy(iter);
    }

    return;
}

void labeled_aiarray_sort(labeled_aiarray_t *laia)
{   /* Sort intervals by starts */

    // Iterate over labels
    int count = 0;
    int32_t l;
    for (l = 0; l < laia->n_labels; l++)
    {
        //label_t *p = &laia->labels[l];

        const char *label_name = laia->labels[l].name;
        label_sorted_iter_t *iter = label_sorted_iter_init(laia, label_name);

        while (label_sorted_iter_next(iter) != 0)
        {
            iter->intv->id_value = count;
            count++;
        }

        // Free
        label_sorted_iter_destroy(iter);
    }

    // Cache id_values
    labeled_aiarray_cache_id(laia);

    return;
}
