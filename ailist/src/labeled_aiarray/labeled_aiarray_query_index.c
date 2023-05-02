//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------
// Queries that record intervals and index
//=============================================================================


void labeled_aiarray_query_with_index(labeled_aiarray_t *laia, const char *label_name, overlap_label_index_t *overlaps, uint32_t qs, uint32_t qe)
{   /* Base query logic with index */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }

    // Check index is initialized
    if (laia->id_index == NULL)
    {
        labeled_aiarray_cache_id(laia);
    }
    
    // Get label
    int32_t l = get_label(laia, label_name);

    // Check if label present
    if (l != -1)
    {
        label_t *p = &laia->labels[l];

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
                        overlap_label_index_add(overlaps, p->ail->interval_list[t], label_name);
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (p->ail->interval_list[t].start < qe && p->ail->interval_list[t].end > qs)
                    {
                        overlap_label_index_add(overlaps, p->ail->interval_list[t], label_name);
                    }
                }                      
            }
        }

        // reallocate to remove extra memory
        //overlaps->indices = (long *)realloc(overlaps->indices, sizeof(long) * overlaps->size);
        //overlaps->max_size = overlaps->size;
    }

    return;
}


void labeled_aiarray_query_with_index_from_array(labeled_aiarray_t *laia, overlap_label_index_t *overlaps, const char label_names[], const long starts[], const long ends[], int length, int label_str_len)
{   /* Base query logic with index */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }

    // Check index is initialized
    if (laia->id_index == NULL)
    {
        labeled_aiarray_cache_id(laia);
    }
    
    // Iterate over queries
    int i;
    for (i = 0; i < length; i++)
    {
        // Determine interval to query
        uint32_t qs = starts[i];
        uint32_t qe = ends[i];
        char label_name[label_str_len + 1];
        slice_str(label_names, label_name, (i * label_str_len), (i * label_str_len) + label_str_len);

        // Query interval
        labeled_aiarray_query_with_index(laia, label_name, overlaps, qs, qe);
    
    }

    return;
}


void labeled_aiarray_query_with_index_from_labeled_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *other_laia, overlap_label_index_t *overlaps)
{   /* Query with index from labeled_aiarray */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }

    // Check index is initialized
    if (laia->id_index == NULL)
    {
        labeled_aiarray_cache_id(laia);
    }

    // Iterate over queries
    int t2;
    for (t2 = 0; t2 < other_laia->n_labels; t2++)
    {
        label_t *p2 = &other_laia->labels[t2];
        ailist_t *l2 = p2->ail;
        
        int i;
        for (i = 0; i < l2->nr; i++)
        {
            // Determine interval to query
            uint32_t qs = l2->interval_list[i].start;
            uint32_t qe = l2->interval_list[i].end;

            // Query interval
            labeled_aiarray_query_with_index(laia, p2->name, overlaps, qs, qe);

        }
    }

    return;
}

