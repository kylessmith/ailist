//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------


void labeled_aiarray_nhits(labeled_aiarray_t *laia, long *nhits, const char *label_name, uint32_t qs, uint32_t qe)
{   /* Base query logic for nhits */

    // Check construction
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


void labeled_aiarray_nhits_length(labeled_aiarray_t *laia, long *nhits, const char *label_name, uint32_t qs,
                                        uint32_t qe, int min_length, int max_length)
{   /* Base query logic for nhits filtered by length */

    // Check construction
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


void labeled_aiarray_bin_nhits(labeled_aiarray_t *laia, long *nhits, int bin_size)
{
    // Check construction
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }
    
    int shift = 0;
    int32_t t;
    for (t = 0; t < laia->n_labels; t++)
    {
        label_t *p = &laia->labels[t];
        int first = p->ail->first;
        int last = p->ail->last;
		int n_bins = (ceil(last / bin_size) - (first / bin_size)) + 1;

        // Get nhits
        ailist_bin_nhits(p->ail, &nhits[shift], bin_size);
        shift = shift + n_bins;
    }

    return;
}


void labeled_aiarray_bin_nhits_length(labeled_aiarray_t *laia, long *nhits, int bin_size, int min_length, int max_length)
{
    // Check construction
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }
    
    int shift = 0;
    int32_t t;
    for (t = 0; t < laia->n_labels; t++)
    {
        label_t *p = &laia->labels[t];
        int first = p->ail->first;
        int last = p->ail->last;
		int n_bins = (ceil(last / bin_size) - (first / bin_size)) + 1;

        // Get nhits
        ailist_bin_nhits_length(p->ail, &nhits[shift], bin_size, min_length, max_length);
        shift = shift + n_bins;
    }

    return;
}


void labeled_aiarray_nhits_from_array(labeled_aiarray_t *laia, const char label_names[], const long starts[], const long ends[],
                                        int length, int label_str_len, long *nhits)
{   /* Query array if present */

    // Check construction
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
        labeled_aiarray_nhits(laia, &nhits[i], label_name, qs, qe);
    }

    return; 
}


void labeled_aiarray_nhits_from_array_length(labeled_aiarray_t *laia, const char label_names[], const long starts[], const long ends[],
                                        int length, int label_str_len, long *nhits, int min_length, int max_length)
{   /* Query array if present */

    // Check construction
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
        labeled_aiarray_nhits_length(laia, &nhits[i], label_name, qs, qe, min_length, max_length);
    }

    return; 
}


void labeled_aiarray_nhits_from_labeled_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *other_laia,
                                                long *nhits)
{   /* Query array if present */

    // Check construction
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }
    if (other_laia->is_constructed == 0)
    {
        labeled_aiarray_construct(other_laia, 20);
    }
    
    labeled_aiarray_iter_t *iter = labeled_aiarray_iter_init(other_laia);
    while (labeled_aiarray_iter_next(iter) == 1)
    {
        // Check if chromosome is in the 2bit file
        char const *label_name = iter->intv->name;
        int32_t t = get_label(laia, label_name);

        // Check if label present
        if (t != -1)
        {
            label_t *p = &laia->labels[t];
            // Get nhits
            long hits = 0;
            ailist_query_nhits(p->ail, &hits, iter->intv->i->start, iter->intv->i->end);
            nhits[iter->n] = nhits[iter->n] + hits;
        }
    }

    return;
}


void labeled_aiarray_nhits_from_labeled_aiarray_length(labeled_aiarray_t *laia, labeled_aiarray_t *other_laia,
                                                long *nhits, int min_length, int max_length)
{   /* Query array if present */

    // Check construction
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }
    if (other_laia->is_constructed == 0)
    {
        labeled_aiarray_construct(other_laia, 20);
    }

    labeled_aiarray_iter_t *iter = labeled_aiarray_iter_init(other_laia);
    while (labeled_aiarray_iter_next(iter) == 1)
    {
        // Check if chromosome is in the 2bit file
        char const *label_name = iter->intv->name;
        int32_t t = get_label(laia, label_name);

        // Check if label present
        if (t != -1)
        {
            label_t *p = &laia->labels[t];
            // Get nhits
            long hits = 0;
            ailist_query_nhits_length(p->ail, &hits, iter->intv->i->start, iter->intv->i->end, min_length, max_length);
            nhits[iter->n] = nhits[iter->n] + hits;
        }
    }

    return;
}


void labeled_aiarray_has_hit(labeled_aiarray_t *laia, const char *label_name, uint8_t *has_hit, uint32_t qs, uint32_t qe)
{   /* Base query logic if present */

    // Check construction
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

