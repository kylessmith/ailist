//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------
// Basic logic for queries
//=============================================================================

void labeled_aiarray_query(labeled_aiarray_t *laia, labeled_aiarray_t *overlaps, const char *label, uint32_t qs, uint32_t qe)
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
                    if (p->ail->interval_list[t].end > qs)
                    {               	
                        labeled_aiarray_add(overlaps, p->ail->interval_list[t].start,  p->ail->interval_list[t].end, label);
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (p->ail->interval_list[t].start < qe && p->ail->interval_list[t].end > qs)
                    {
                        labeled_aiarray_add(overlaps, p->ail->interval_list[t].start,  p->ail->interval_list[t].end, label);
                    }
                }                      
            }
        }
    }

    return;                         
}


void labeled_aiarray_query_length(labeled_aiarray_t *laia, labeled_aiarray_t *overlaps, const char *label, 
                                  uint32_t qs, uint32_t qe, int min_length, int max_length)
{   /* Base query logic filtered by length */
    
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
                    if (p->ail->interval_list[t].end > qs)
                    {
                        int length = p->ail->interval_list[t].end - p->ail->interval_list[t].start;
                        if (length < max_length && length > min_length)
                        {
                            labeled_aiarray_add(overlaps, p->ail->interval_list[t].start,  p->ail->interval_list[t].end, label);
                        }
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (p->ail->interval_list[t].start < qe && p->ail->interval_list[t].end > qs)
                    {
                        int length = p->ail->interval_list[t].end - p->ail->interval_list[t].start;
                        if (length < max_length && length > min_length)
                        {
                            labeled_aiarray_add(overlaps, p->ail->interval_list[t].start,  p->ail->interval_list[t].end, label);
                        }
                    }
                }                      
            }
        }
    }

    return;    
}


//-----------------------------------------------------------------------------
// Non-labeled_aiarray returning functions
//=============================================================================


void labeled_aiarray_query_nhits(labeled_aiarray_t *laia, long *nhits, const char *label_name, uint32_t qs, uint32_t qe)
{   /* Base query logic for nhits */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }

    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Get nhits
        ailist_query_nhits(p->ail, nhits, qs, qe);
    }

    return;
}


void labeled_aiarray_query_nhits_length(labeled_aiarray_t *laia, long *nhits, const char *label_name, uint32_t qs,
                                        uint32_t qe, int min_length, int max_length)
{   /* Base query logic for nhits filtered by length */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }
    
    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Get nhits
        ailist_query_nhits_length(p->ail, nhits, qs, qe, min_length, max_length);
    }

    return;
}


void labeled_aiarray_query_has_hit(labeled_aiarray_t *laia, const char *label_name, uint8_t *has_hit, uint32_t qs, uint32_t qe)
{   /* Base query logic if present */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }
    
    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Get nhits
        ailist_query_has_hit(p->ail, has_hit, qs, qe);
    }

    return;
}

