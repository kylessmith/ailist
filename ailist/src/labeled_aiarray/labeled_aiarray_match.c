//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

// Find an interval in `ail` (must be constructed) exactly matching [qs, qe).
// Returns its id_value, or -1 if none. Mirrors labeled_aiarray_where_interval's
// component traversal. Used by the exact-match family below.
static int32_t ail_exact_match_id(ailist_t *ail, uint32_t qs, uint32_t qe)
{
    int k;
    for (k = 0; k < ail->nc; k++)
    {   // Search each component
        int32_t cs = ail->idxC[k];
        int32_t ce = cs + ail->lenC[k];
        int32_t t;

        if (ail->lenC[k] > 15)
        {
            t = binary_search(ail->interval_list, cs, ce, qe);
            while (t >= cs && ail->maxE[t] > qs)
            {
                if (ail->interval_list[t].start == qs && ail->interval_list[t].end == qe)
                {
                    return ail->interval_list[t].id_value;
                }
                t--;
            }
        }
        else
        {
            for (t = cs; t < ce; t++)
            {
                if (ail->interval_list[t].start == qs && ail->interval_list[t].end == qe)
                {
                    return ail->interval_list[t].id_value;
                }
            }
        }
    }

    return -1;
}

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
            ailist_t *ail1 = laia1->labels[i].ail;
            ailist_t *ail2 = laia2->labels[t].ail;

            // For each laia1 interval, probe laia2 for an exact (start,end) match
            int64_t j;
            for (j = 0; j < ail1->nr; j++)
            {
                uint32_t qs = ail1->interval_list[j].start;
                uint32_t qe = ail1->interval_list[j].end;
                if (ail_exact_match_id(ail2, qs, qe) != -1)
                {
                    overlap_label_index_add(matched_laia, ail1->interval_list[j], label_name);
                }
            }
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
            ailist_t *ail1 = laia1->labels[i].ail;
            ailist_t *ail2 = laia2->labels[t].ail;

            int64_t j;
            for (j = 0; j < ail1->nr; j++)
            {
                uint32_t qs = ail1->interval_list[j].start;
                uint32_t qe = ail1->interval_list[j].end;
                if (ail_exact_match_id(ail2, qs, qe) != -1)
                {
                    has_match[ail1->interval_list[j].id_value] = 1;
                }
            }
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
            ailist_t *ail1 = laia1->labels[i].ail;
            ailist_t *ail2 = laia2->labels[t].ail;

            int64_t j;
            for (j = 0; j < ail1->nr; j++)
            {
                uint32_t qs = ail1->interval_list[j].start;
                uint32_t qe = ail1->interval_list[j].end;
                int32_t laia2_id = ail_exact_match_id(ail2, qs, qe);
                if (laia2_id != -1)
                {
                    has_match_laia1[ail1->interval_list[j].id_value] = 1;
                    has_match_laia2[laia2_id] = 1;
                }
            }
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
            ailist_t *ail1 = laia1->labels[i].ail;
            ailist_t *ail2 = laia2->labels[t].ail;

            int64_t j;
            for (j = 0; j < ail1->nr; j++)
            {
                uint32_t qs = ail1->interval_list[j].start;
                uint32_t qe = ail1->interval_list[j].end;
                int32_t laia2_id = ail_exact_match_id(ail2, qs, qe);
                if (laia2_id != -1)
                {
                    array_query_add(matches, ail1->interval_list[j].id_value, laia2_id);
                }
            }
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
