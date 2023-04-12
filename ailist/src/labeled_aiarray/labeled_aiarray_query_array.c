//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------
// Queries that record only index
//=============================================================================


void labeled_aiarray_query_only_index(labeled_aiarray_t *laia, const char *label_name, array_query_t *overlaps, uint32_t qs, uint32_t qe, uint32_t id)
{   /* Base query logic with index */

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

        // Get overlaps
        ailist_query_only_index(p->ail, overlaps, qs, qe, id);
    }

    return;
}


array_query_t *labeled_aiarray_query_index_from_array(labeled_aiarray_t *laia, const char label_names[], const long starts[], const long ends[], int length, int label_str_len)
{   /* Query aiarray intervals from arrays */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }
    
    // Initialize overlap indices
    array_query_t *aq = array_query_init();

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
        labeled_aiarray_query_only_index(laia, label_name, aq, qs, qe, i);
    }

    return aq; 
}


void labeled_aiarray_query_from_array(labeled_aiarray_t *laia, labeled_aiarray_t *overlaps, const char label_names[], const long starts[], const long ends[], int length, int label_str_len)
{   /* Query aiarray intervals from arrays */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
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
        labeled_aiarray_query(laia, overlaps, label_name, qs, qe);
    }

    return; 
}


void labeled_aiarray_query_has_hit_from_array(labeled_aiarray_t *laia, const char label_names[], const long starts[], const long ends[], int length, int label_str_len, uint8_t has_hit[])
{   /* Query array if present */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
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
        labeled_aiarray_query_has_hit(laia, label_name, has_hit, qs, qe);
    }

    return; 
}


void labeled_aiarray_query_from_labeled_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *laia2, labeled_aiarray_t *overlaps)
{   /* Query aiarray intervals from aiarray */
    
    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }

    // Iterate over queries
    int t2;
    for (t2 = 0; t2 < laia2->n_labels; t2++)
    {
        label_t *p2 = &laia2->labels[t2];
        ailist_t *l2 = p2->ail;
        
        int i;
        for (i = 0; i < l2->nr; i++)
        {
            // Determine interval to query
            uint32_t qs = l2->interval_list[i].start;
            uint32_t qe = l2->interval_list[i].end;

            // Query interval
            labeled_aiarray_query(laia, overlaps, p2->name, qs, qe);

        }
    }

    return;                            
}


void labeled_aiarray_query_index_from_labeled_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *laia2, array_query_t *aq)
{   /* Query aiarray intervals from aiarray */
    
    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }

    // Iterate over queries
    int t2;
    for (t2 = 0; t2 < laia2->n_labels; t2++)
    {
        label_t *p2 = &laia2->labels[t2];
        ailist_t *l2 = p2->ail;
        
        int i;
        for (i = 0; i < l2->nr; i++)
        {
            // Determine interval to query
            uint32_t qs = l2->interval_list[i].start;
            uint32_t qe = l2->interval_list[i].end;
            uint32_t id = l2->interval_list[i].id_value;

            // Query interval
            labeled_aiarray_query_only_index(laia, p2->name, aq, qs, qe, id);

        }
    }

    return;                   
}

