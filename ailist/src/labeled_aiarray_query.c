//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

uint32_t binary_search_labeled(labeled_interval_t* As, uint32_t idxS, uint32_t idxE, uint32_t qe)
{   /* Find tE: index of the first item satisfying .s<qe from right */
    
    int tL = idxS;
    int tR = idxE - 1;
    int tM;
    int tE = -1;
    
    if(As[tR].start < qe)
    {
        return tR;
    } else if (As[tL].start >= qe) {
        return -1;
    }

    while (tL < tR - 1)
    {
        //tM = (tL + tR) / 2;
        tM = tL + (tR - tL) / 2;

        if (As[tM].start >= qe)
        {
            tR = tM - 1;
        } else {
            tL = tM;
        }
    }

    if (As[tR].start < qe)
    {
        tE = tR;
    } else if (As[tL].start < qe) {
        tE = tL;
    }

    return tE; 
}

//-----------------------------------------------------------------------------

void labeled_aiarray_query(labeled_aiarray_t *ail, labeled_aiarray_t *overlaps, uint32_t qs, uint32_t qe, const char *label_name)
{   /* Base query logic */

    // Check if label is present
    if (label_is_present(ail, label_name) == 1)
    {
        // Determine label
        uint16_t label = query_label_map(ail, label_name);
        
        // Find bounds for label
        uint32_t start = get_label_index(ail, label);
        //int nr = ail->label_index[label+1];
        int nc = ail->nc[label];
        int *idxC = &ail->idxC[(label * MAXC)];
        int *lenC = &ail->lenC[(label * MAXC)];
        uint32_t *maxE = &ail->maxE[start];

        labeled_interval_t *label_intervals = &ail->interval_list[start];

        int k;
        for (k = 0; k < nc; k++)
        {   // Search each component
            int32_t cs = idxC[k];
            int32_t ce = cs + lenC[k];			
            int32_t t;

            if (lenC[k] > 15)
            {
                t = binary_search_labeled(label_intervals, cs, ce, qe);

                while (t >= cs && maxE[t] > qs)
                {
                    if (label_intervals[t].end > qs)
                    {               	
                        labeled_aiarray_add(overlaps, label_intervals[t].start, label_intervals[t].end, label_name);
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (label_intervals[t].start < qe && label_intervals[t].end > qs)
                    {
                        labeled_aiarray_add(overlaps, label_intervals[t].start, label_intervals[t].end, label_name);
                    }
                }                      
            }
        }
    }

    return;
}


void labeled_aiarray_query_length(labeled_aiarray_t *ail, labeled_aiarray_t *overlaps, uint32_t qs, uint32_t qe, const char *label_name, int min_length, int max_length)
{   /* Base query logic filtered by length */

    // Determine if label is present
    if (label_is_present(ail, label_name) == 1)
    {
        // Determine label
        uint16_t label = query_label_map(ail, label_name);

        // Find bounds for label
        uint32_t start = get_label_index(ail, label);
        //int nr = ail->label_index[label+1];
        int nc = ail->nc[label];
        int *idxC = &ail->idxC[(label * MAXC)];
        int *lenC = &ail->lenC[(label * MAXC)];
        uint32_t *maxE = &ail->maxE[start];

        labeled_interval_t *label_intervals = &ail->interval_list[start];

        int k;
        for (k = 0; k < nc; k++)
        {   // Search each component
            int32_t cs = idxC[k];
            int32_t ce = cs + lenC[k];			
            int32_t t;

            if (lenC[k] > 15)
            {
                t = binary_search_labeled(label_intervals, cs, ce, qe);

                while (t >= cs && maxE[t] > qs)
                {
                    if (label_intervals[t].end > qs)
                    {   
                        int length = ail->interval_list[t].end - ail->interval_list[t].start;
                        if (length >= min_length && length < max_length)
                        {
                            labeled_aiarray_add(overlaps, label_intervals[t].start, label_intervals[t].end, label_name);
                        }
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (label_intervals[t].start < qe && label_intervals[t].end > qs)
                    {
                        int length = ail->interval_list[t].end - ail->interval_list[t].start;
                        if (length >= min_length && length < max_length)
                        {
                            labeled_aiarray_add(overlaps, label_intervals[t].start, label_intervals[t].end, label_name);
                        }
                    }
                }                      
            }
        }
    }

    return;
}


void labeled_aiarray_query_nhits(labeled_aiarray_t *ail, long *nhits, uint32_t qs, uint32_t qe, const char *label_name)
{   /* Base query logic for nhits */

    // Check if label is present
    if (label_is_present(ail, label_name) == 1)
    {
        // Determine label
        uint16_t label = query_label_map(ail, label_name);
        
        // Find bounds for label
        uint32_t start = get_label_index(ail, label);
        //int nr = ail->label_index[label+1];
        int nc = ail->nc[label];
        int *idxC = &ail->idxC[(label * MAXC)];
        int *lenC = &ail->lenC[(label * MAXC)];
        uint32_t *maxE = &ail->maxE[start];

        labeled_interval_t *label_intervals = &ail->interval_list[start];

        int k;
        for (k = 0; k < nc; k++)
        {   // Search each component
            int32_t cs = idxC[k];
            int32_t ce = cs + lenC[k];			
            int32_t t;

            if (lenC[k] > 15)
            {
                t = binary_search_labeled(label_intervals, cs, ce, qe);

                while (t >= cs && maxE[t] > qs)
                {
                    if (label_intervals[t].end > qs)
                    {               	
                        (*nhits)++;
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (label_intervals[t].start < qe && label_intervals[t].end > qs)
                    {
                        (*nhits)++;
                    }
                }                      
            }
        }
    }

    return;
}


void labeled_aiarray_query_nhits_length(labeled_aiarray_t *ail, long *nhits, uint32_t qs, uint32_t qe, const char *label_name, int min_length, int max_length)
{   /* Base query logic for nhits filtered by length */

    // Determine if label is present
    if (label_is_present(ail, label_name) == 1)
    {
        // Determine label
        uint16_t label = query_label_map(ail, label_name);

        // Find bounds for label
        uint32_t start = get_label_index(ail, label);
        //int nr = ail->label_index[label+1];
        int nc = ail->nc[label];
        int *idxC = &ail->idxC[(label * MAXC)];
        int *lenC = &ail->lenC[(label * MAXC)];
        uint32_t *maxE = &ail->maxE[start];

        labeled_interval_t *label_intervals = &ail->interval_list[start];

        int k;
        for (k = 0; k < nc; k++)
        {   // Search each component
            int32_t cs = idxC[k];
            int32_t ce = cs + lenC[k];			
            int32_t t;

            if (lenC[k] > 15)
            {
                t = binary_search_labeled(label_intervals, cs, ce, qe);

                while (t >= cs && maxE[t] > qs)
                {
                    if (label_intervals[t].end > qs)
                    {   
                        int length = ail->interval_list[t].end - ail->interval_list[t].start;
                        if (length >= min_length && length < max_length)
                        {
                            (*nhits)++;
                        }
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (label_intervals[t].start < qe && label_intervals[t].end > qs)
                    {
                        int length = ail->interval_list[t].end - ail->interval_list[t].start;
                        if (length >= min_length && length < max_length)
                        {
                            (*nhits)++;
                        }
                    }
                }                      
            }
        }
    }

    return;
}


void labeled_aiarray_query_with_index(labeled_aiarray_t *ail, overlap_label_index_t *overlaps, uint32_t qs, uint32_t qe, const char *label_name)
{   /* Base query logic with index */

    // Determine if label is present
    if (label_is_present(ail, label_name) == 1)
    {		
        // Determine label
        uint16_t label = query_label_map(ail, label_name);

        // Find bounds for label
        uint32_t start = get_label_index(ail, label);
        //int nr = ail->label_index[label+1];
        int nc = ail->nc[label];
        int *idxC = &ail->idxC[(label * MAXC)];
        int *lenC = &ail->lenC[(label * MAXC)];
        uint32_t *maxE = &ail->maxE[start];

        labeled_interval_t *label_intervals = &ail->interval_list[start];

        int k;
        for (k = 0; k < nc; k++)
        {   // Search each component
            int32_t cs = idxC[k];
            int32_t ce = cs + lenC[k];			
            int32_t t;

            if (lenC[k] > 15)
            {
                t = binary_search_labeled(label_intervals, cs, ce, qe);

                while (t >= cs && maxE[t] > qs)
                {
                    if (label_intervals[t].end > qs)
                    {               	
                        overlap_label_index_add(overlaps, label_intervals[t], label_name);
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (label_intervals[t].start < qe && label_intervals[t].end > qs)
                    {
                        overlap_label_index_add(overlaps, label_intervals[t], label_name);
                    }
                }                      
            }
        }
    }

    return;
}


void labeled_aiarray_query_only_index(labeled_aiarray_t *ail, array_query_t *overlaps, uint32_t qs, uint32_t qe, uint32_t id, const char *label_name)
{   /* Base query logic with index */

    // Determine if label is present
    if (label_is_present(ail, label_name) == 1)
    {
        // Determine label
        uint16_t label = query_label_map(ail, label_name);

        // Find bounds for label
        uint32_t start = get_label_index(ail, label);
        //int nr = ail->label_index[label+1];
        int nc = ail->nc[label];
        int *idxC = &ail->idxC[(label * MAXC)];
        int *lenC = &ail->lenC[(label * MAXC)];
        uint32_t *maxE = &ail->maxE[start];

        labeled_interval_t *label_intervals = &ail->interval_list[start];

        int k;
        for (k = 0; k < nc; k++)
        {   // Search each component
            int32_t cs = idxC[k];
            int32_t ce = cs + lenC[k];			
            int32_t t;

            if (lenC[k] > 15)
            {
                t = binary_search_labeled(label_intervals, cs, ce, qe);

                while (t >= cs && maxE[t] > qs)
                {
                    if (label_intervals[t].end > qs)
                    {               	
                        array_query_add(overlaps, id, label_intervals[t].id_value);
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (label_intervals[t].start < qe && label_intervals[t].end > qs)
                    {
                        array_query_add(overlaps, id, label_intervals[t].id_value);
                    }
                }                      
            }
        }
    }

    return;
}


void labeled_aiarray_query_has_hit(labeled_aiarray_t *ail, uint8_t has_hit[], uint32_t qs, uint32_t qe, const char *label_name)
{   /* Base query logic if present */

    // Determine if label is present
    if (label_is_present(ail, label_name) == 1)
    {
        // Determine label
        uint16_t label = query_label_map(ail, label_name);

        // Find bounds for label
        uint32_t start = get_label_index(ail, label);
        //int nr = ail->label_index[label+1];
        int nc = ail->nc[label];
        int *idxC = &ail->idxC[(label * MAXC)];
        int *lenC = &ail->lenC[(label * MAXC)];
        uint32_t *maxE = &ail->maxE[start];

        labeled_interval_t *label_intervals = &ail->interval_list[start];

        int k;
        for (k = 0; k < nc; k++)
        {   // Search each component
            int32_t cs = idxC[k];
            int32_t ce = cs + lenC[k];			
            int32_t t;

            if (lenC[k] > 15)
            {
                t = binary_search_labeled(label_intervals, cs, ce, qe);

                while (t >= cs && maxE[t] > qs)
                {
                    if (label_intervals[t].end > qs)
                    {               	
                        has_hit[label_intervals[t].id_value] = 1;
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (label_intervals[t].start < qe && label_intervals[t].end > qs)
                    {
                        has_hit[label_intervals[t].id_value] = 1;
                    }
                }                      
            }
        }
    }

    return;
}


//-----------------------------------------------------------------------------

labeled_aiarray_t *labeled_aiarray_query_single(labeled_aiarray_t *ail, uint32_t qs, uint32_t qe, const char *label_name)
{   /* Query interval */

    // Initialize overlaps
    labeled_aiarray_t *overlaps = labeled_aiarray_init();

    // Query interval
    labeled_aiarray_query(ail, overlaps, qs, qe, label_name);

    return overlaps;                            
}


labeled_aiarray_t *labeled_aiarray_query_single_length(labeled_aiarray_t *ail, uint32_t qs, uint32_t qe, const char *label_name, int min_length, int max_length)
{   /* Query aiarray intervals of a length */

    // Initialize overlaps
    labeled_aiarray_t *overlaps = labeled_aiarray_init();

    // Query interval
    labeled_aiarray_query_length(ail, overlaps, qs, qe, label_name, min_length, max_length);

    return overlaps;                            
}

//-----------------------------------------------------------------------------

void slice_str(const char *str, char *buffer, size_t start, size_t end)
{
    size_t j = 0;
    size_t i;
    for (i = start; i <= end; ++i)
    {
        buffer[j++] = str[i];
    }
    buffer[j] = '\0';
    //strncpy(buffer, str + start, end - start);
}

void slice_str2(const char *str, char *buffer, size_t start, size_t end)
{
    size_t j = 0;
    size_t i;
    for (i = start; i < end; ++i)
    {
        if (str[i]=='\0')
        {
            break;
        }

        buffer[j++] = str[i];
    }
    buffer[j] = '\0';
    //strncpy(buffer, str + start, end - start);
}

array_query_t *labeled_aiarray_query_from_array(labeled_aiarray_t *ail, const long starts[], const long ends[], const char label_names[], int length, int label_str_len)
{   /* Query aiarray intervals from arrays */
    
    // Initialize overlap indices
    array_query_t *aq = array_query_init();

    // Iterate over queries
    int i;
    for (i = 0; i < length; i++)
    {
        // Determine interval to query
        uint32_t qs = starts[i];
        uint32_t qe = ends[i];
        //const char *label_name = label_names[i];
        //const size_t len = strlen(label_names);
        char label_name[label_str_len + 1];
        slice_str2(label_names, label_name, (i*label_str_len), (i*label_str_len)+label_str_len);
        //printf("start:%d, end:%d, label:%s\n", qs, qe, label_name);

        // Query interval
        labeled_aiarray_query_only_index(ail, aq, qs, qe, i, label_name);
    }

    // Reallocate to remove extra memory
    aq->ref_index = (long *)realloc(aq->ref_index, sizeof(long) * aq->size);
    aq->query_index = (long *)realloc(aq->query_index, sizeof(long) * aq->size);
    aq->max_size = aq->size;

    return aq;                            
}


array_query_t *labeled_aiarray_query_from_labeled_aiarray(labeled_aiarray_t *ail, labeled_aiarray_t *ail2)
{   /* Query aiarray intervals from aiarray */
    
    // Intialize overlap indices
    array_query_t *aq = array_query_init();

    // Iterate over queries
    int i;
    for (i = 0; i < ail2->nr; i++)
    {
        // Determine interval to query
        uint32_t qs = ail2->interval_list[i].start;
        uint32_t qe = ail2->interval_list[i].end;
        uint32_t id = ail2->interval_list[i].id_value;
        uint16_t label = ail2->interval_list[i].label;

        // Determine label name
        const char *label_name = query_rev_label_map(ail2, label);

        // Query interval
        labeled_aiarray_query_only_index(ail, aq, qs, qe, id, label_name);
    }

    // reallocate to remove extra memory
    aq->ref_index = (long *)realloc(aq->ref_index, sizeof(long) * aq->size);
    aq->query_index = (long *)realloc(aq->query_index, sizeof(long) * aq->size);
    aq->max_size = aq->size;

    return aq;                            
}

//-----------------------------------------------------------------------------

overlap_label_index_t *labeled_aiarray_query_single_with_index(labeled_aiarray_t *ail, uint32_t qs, uint32_t qe, const char *label_name)
{   /* Query aiarray intervals and record original index */

    // Initialize overlaps
    overlap_label_index_t *overlaps = overlap_label_index_init();

    // Query overlaps
    labeled_aiarray_query_with_index(ail, overlaps, qs, qe, label_name);

    return overlaps;                            
}


overlap_label_index_t *labeled_aiarray_query_with_index_from_labeled_aiarray(labeled_aiarray_t *ail, labeled_aiarray_t *ail2)
{   /* Query aiarray intervals and record original index from labled_aiarray */

    // Initialize overlaps
    overlap_label_index_t *overlaps = overlap_label_index_init();

    // Iterate over queries
    int i;
    for (i = 0; i < ail2->nr; i++)
    {   
        // Determine interval to query
        uint32_t qs = ail2->interval_list[i].start;
        uint32_t qe = ail2->interval_list[i].end;
        //uint32_t id = ail2->interval_list[i].id_value;
        uint16_t label = ail2->interval_list[i].label;

        // Determine label name
        const char *label_name = query_rev_label_map(ail2, label);

        // Query interval
        labeled_aiarray_query_with_index(ail, overlaps, qs, qe, label_name);
    }

    // reallocate to remove extra memory
    overlaps->indices = (long *)realloc(overlaps->indices, sizeof(long) * overlaps->size);
    overlaps->max_size = overlaps->size;

    return overlaps;                            
}


//-----------------------------------------------------------------------------

