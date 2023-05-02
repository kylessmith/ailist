//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------


overlap_label_index_t *labeled_aiarray_exact_match(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2)
{   /* Return all exact matches between labeled_aiarrays */

    // Check construction
    if (laia1->is_constructed == 0)
    {
        labeled_aiarray_construct(laia1, 20);
    }
    if (laia2->is_constructed == 0)
    {
        labeled_aiarray_construct(laia2, 20);
    }

    // Check index is initialized
    if (laia1->id_index == NULL)
    {
        labeled_aiarray_cache_id(laia1);
    }
    if (laia2->id_index == NULL)
    {
        labeled_aiarray_cache_id(laia2);
    }
    
    // Initiatilize matched
    overlap_label_index_t *matched_laia = overlap_label_index_init();

    // Iterate over labels in laia1
    int i;
    for (i = 0; i < laia1->n_labels; i++)
    {
        // Determine if label is in laia2
        const char *label_name = laia1->labels[i].name;
        int32_t t = get_label(laia2, label_name);

        if (t != -1)
        {
            // Create sorted iterators
            label_sorted_iter_t *laia1_iter = label_sorted_iter_init(laia1, label_name);
            label_sorted_iter_t *laia2_iter = label_sorted_iter_init(laia2, label_name);
            
            // Iterate over ail1
            int laia2_end = label_sorted_iter_next(laia2_iter);
            while (label_sorted_iter_next(laia1_iter) != 0 && laia2_end != 0)
            {
                while (laia2_end !=0 && laia2_iter->intv->start <= laia1_iter->intv->start)
                {
                    if (laia1_iter->intv->start == laia2_iter->intv->start && laia1_iter->intv->end == laia2_iter->intv->end)
                    {
                        overlap_label_index_add(matched_laia, *laia1_iter->intv, label_name);
                    }
                    // Increment ail2 iterator
                    laia2_end = label_sorted_iter_next(laia2_iter);
                }
            }

            // Free iterators
            label_sorted_iter_destroy(laia1_iter);
            label_sorted_iter_destroy(laia2_iter);
            
        }
    }

    return matched_laia;
}


void labeled_aiarray_has_exact_match(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2, uint8_t has_match[])
{   /* Return all exact matches between labeled_aiarrays */

    // Check construction
    if (laia1->is_constructed == 0)
    {
        labeled_aiarray_construct(laia1, 20);
    }
    if (laia2->is_constructed == 0)
    {
        labeled_aiarray_construct(laia2, 20);
    }


    // Iterate over labels in laia1
    int i;
    for (i = 0; i < laia1->n_labels; i++)
    {
        // Determine if label is in laia2
        const char *label_name = laia1->labels[i].name;
        int32_t t = get_label(laia2, label_name);

        if (t != -1)
        {
            // Create sorted iterators
            label_sorted_iter_t *laia1_iter = label_sorted_iter_init(laia1, label_name);
            label_sorted_iter_t *laia2_iter = label_sorted_iter_init(laia2, label_name);
            
            // Iterate over ail1
            int laia2_end = label_sorted_iter_next(laia2_iter);
            while (label_sorted_iter_next(laia1_iter) != 0 && laia2_end != 0)
            {
                while (laia2_end !=0 && laia2_iter->intv->start <= laia1_iter->intv->start)
                {
                    if (laia1_iter->intv->start == laia2_iter->intv->start && laia1_iter->intv->end == laia2_iter->intv->end)
                    {
                        //has_match[laia1->id_index[laia1_iter->intv->id_value]] = 1;
                        has_match[laia1_iter->intv->id_value] = 1;
                    }
                    // Increment ail2 iterator
                    laia2_end = label_sorted_iter_next(laia2_iter);
                }
            }
            
            // Free iterators
            label_sorted_iter_destroy(laia1_iter);
            label_sorted_iter_destroy(laia2_iter);
        }
    }

    return;
}


void labeled_aiarray_is_exact_match(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2, uint8_t has_match_laia1[], uint8_t has_match_laia2[])
{   /* Return exact matches between labeled_aiarrays */

    // Check construction
    if (laia1->is_constructed == 0)
    {
        labeled_aiarray_construct(laia1, 20);
    }
    if (laia2->is_constructed == 0)
    {
        labeled_aiarray_construct(laia2, 20);
    }

    // Iterate over labels in laia1
    int i;
    for (i = 0; i < laia1->n_labels; i++)
    {
        // Determine if label is in laia2
        const char *label_name = laia1->labels[i].name;
        int32_t t = get_label(laia2, label_name);

        if (t != -1)
        {
            // Create sorted iterators
            label_sorted_iter_t *laia1_iter = label_sorted_iter_init(laia1, label_name);
            label_sorted_iter_t *laia2_iter = label_sorted_iter_init(laia2, label_name);
            
            // Iterate over ail1
            int laia2_end = label_sorted_iter_next(laia2_iter);
            while (label_sorted_iter_next(laia1_iter) != 0 && laia2_end != 0)
            {
                while (laia2_end !=0 && laia2_iter->intv->start <= laia1_iter->intv->start)
                {
                    if (laia1_iter->intv->start == laia2_iter->intv->start && laia1_iter->intv->end == laia2_iter->intv->end)
                    {
                        //has_match[laia1->id_index[laia1_iter->intv->id_value]] = 1;
                        //has_match_laia1[laia1->id_index[laia1_iter->intv->id_value]] = 1;
                        //has_match_laia2[laia2->id_index[laia2_iter->intv->id_value]] = 1;
                        has_match_laia1[laia1_iter->intv->id_value] = 1;
                        has_match_laia2[laia2_iter->intv->id_value] = 1;
                    }
                    // Increment ail2 iterator
                    laia2_end = label_sorted_iter_next(laia2_iter);
                }
            }

            // Free iterators
            label_sorted_iter_destroy(laia1_iter);
            label_sorted_iter_destroy(laia2_iter);
            
        }
    }

    return;
}


void labeled_aiarray_which_exact_match(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2, array_query_t *matches)
{   /* Return exact matches between labeled_aiarrays */

    // Check construction
    if (laia1->is_constructed == 0)
    {
        labeled_aiarray_construct(laia1, 20);
    }
    if (laia2->is_constructed == 0)
    {
        labeled_aiarray_construct(laia2, 20);
    }

    // Iterate over labels in laia1
    int i;
    for (i = 0; i < laia1->n_labels; i++)
    {
        // Determine if label is in laia2
        const char *label_name = laia1->labels[i].name;
        int32_t t = get_label(laia2, label_name);

        if (t != -1)
        {
            // Create sorted iterators
            label_sorted_iter_t *laia1_iter = label_sorted_iter_init(laia1, label_name);
            label_sorted_iter_t *laia2_iter = label_sorted_iter_init(laia2, label_name);
            
            // Iterate over ail1
            int laia2_end = label_sorted_iter_next(laia2_iter);
            while (label_sorted_iter_next(laia1_iter) != 0 && laia2_end != 0)
            {
                while (laia2_end !=0 && laia2_iter->intv->start <= laia1_iter->intv->start)
                {
                    if (laia1_iter->intv->start == laia2_iter->intv->start && laia1_iter->intv->end == laia2_iter->intv->end)
                    {
                        array_query_add(matches, laia1_iter->intv->id_value, laia2_iter->intv->id_value);
                    }
                    // Increment ail2 iterator
                    laia2_end = label_sorted_iter_next(laia2_iter);
                }
            }

            // Free iterators
            label_sorted_iter_destroy(laia1_iter);
            label_sorted_iter_destroy(laia2_iter);
            
        }
    }

    return;
}


int labeled_aiarray_where_interval(labeled_aiarray_t *laia, const char *label, uint32_t qs, uint32_t qe)
{   /* Base query logic */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }
    
    // Get label
    int32_t t = get_label(laia, label);

    // Check if label present
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Initialize overlaps
        int k;
        for (k = 0; k < p->ail->nc; k++)
        {   // Search each component
            int32_t cs = p->ail->idxC[k];
            int32_t ce = cs + p->ail->lenC[k];			
            int32_t t;

            if (p->ail->lenC[k] > 15)
            {
                t = binary_search(p->ail->interval_list, cs, ce, qe);

                while (t >= cs && p->ail->maxE[t] > qs)
                {
                    if (p->ail->interval_list[t].end == qe && p->ail->interval_list[t].start == qs)
                    {               	
                        return p->ail->interval_list[t].id_value;
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (p->ail->interval_list[t].end == qe && p->ail->interval_list[t].start == qs)
                    {
                        return p->ail->interval_list[t].id_value;
                    }
                }                      
            }
        }
    }

    return -1;                         
}

//-----------------------------------------------------------------------------
