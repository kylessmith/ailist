//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------
#include "augmented_interval_list.h"
#include "radix_interval_sort.c"


uint32_t binary_search(interval_t* As, uint32_t idxS, uint32_t idxE, uint32_t qe)
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
        tM = (tL + tR) / 2; 

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


ailist_t *ailist_init(void)
{   /* Initialize ailist_t object */

    // Initialize variables
    ailist_t *ail = (ailist_t *)malloc(sizeof(ailist_t));
    ail->nr = 0;
    ail->mr = 64;
    ail->first = INT32_MAX;
    ail->last = 0;
	ail->maxE = NULL;

    // Initialize arrays
    ail->interval_list = malloc(ail->mr * sizeof(interval_t));

    // Check if memory was allocated
    if (ail == NULL && ail->interval_list == NULL)
    {
        fprintf (stderr, "Out of memory!!! (init)\n");
        exit(1);
    }

	return ail;
}


void ailist_destroy(ailist_t *ail)
{   /* Free ailist_t object */

	if (ail == 0) {return;}
	
	free(ail->interval_list);
	
	if (ail->maxE)
	{
		free(ail->maxE);
	}

	free(ail);
}


void ailist_add(ailist_t *ail, uint32_t start, uint32_t end, int32_t index, double_t value)
{   /* Add interval to ailist_t object */

	if (start > end) {return;}

    // Update first and last
    ail->first = MIN(ail->first, start);
    ail->last = MAX(ail->last, end);

    // If max region reached, expand array
	if (ail->nr == ail->mr)
		EXPAND(ail->interval_list, ail->mr);

    // Set new interval values
	interval_t *i = &ail->interval_list[ail->nr++];
	i->start = start;
	i->end   = end;
    i->index = index;
    i->value = value;

	return;
}


interval_t *interval_init(uint32_t start, uint32_t end, int32_t index, double_t value)
{   /* Create interval_t */

    // Initialize interval
    interval_t *i = (interval_t *)malloc(sizeof(interval_t));

    // Check if memory was allocated
    if (i == NULL)
    {
        fprintf (stderr, "Out of memory!!! (init)\n");
        exit(1);
    }

    // Set new interval values
    i->start = start;
	i->end   = end;
    i->index = index;
    i->value = value;

	return i;
}

//-------------------------------------------------------------------------------

void ailist_sort(ailist_t *ail)
{   /* Sort intervals in ailist */
    radix_interval_sort(ail->interval_list, ail->nr);

    return;
}


void ailist_construct(ailist_t *ail, int cLen)
{   /* Construct ailist_t object */  

    int cLen1 = cLen / 2;
    int j1, nr;
    int minL = MAX(64, cLen);     
    cLen += cLen1;      
    int lenT, len, iter, j, k, k0, t;  

    //1. Decomposition
    interval_t *L1 = ail->interval_list;					//L1: to be rebuilt
    nr = ail->nr;
    radix_interval_sort(L1, nr);

    if (nr <= minL)
    {        
        ail->nc = 1;
        ail->lenC[0] = nr;
        ail->idxC[0] = 0;                
    } else {         
        interval_t *L0 = malloc(nr * sizeof(interval_t)); 	//L0: serve as input list
        interval_t *L2 = malloc(nr * sizeof(interval_t));   //L2: extracted list 
        memcpy(L0, L1, nr * sizeof(interval_t));			
        iter = 0;
        k = 0;
        k0 = 0;
        lenT = nr;

        while (iter < MAXC && lenT > minL)
        {   
            len = 0;            
            for (t = 0; t < lenT - cLen; t++)
            {
                uint32_t tt = L0[t].end;
                j=1;
                j1=1;

                while (j < cLen && j1 < cLen1)
                {
                    if (L0[j + t].end >= tt) {j1++;}
                    j++;
                }
                
                if (j1 < cLen1)
                {
                    memcpy(&L2[len++], &L0[t], sizeof(interval_t));
                } else {
                    memcpy(&L1[k++], &L0[t], sizeof(interval_t));
                }               
            } 

            memcpy(&L1[k], &L0[lenT - cLen], cLen * sizeof(interval_t));   
            k += cLen;
            lenT = len;               
            ail->idxC[iter] = k0;
            ail->lenC[iter] = k - k0;
            k0 = k;
            iter++;

            if (lenT <= minL || iter == MAXC - 2)
            {	//exit: add L2 to the end
                if (lenT > 0)
                {
                    memcpy(&L1[k], L2, lenT * sizeof(interval_t));
                    ail->idxC[iter] = k;
                    ail->lenC[iter] = lenT;
                    iter++;
                }
                ail->nc = iter;                   
            } else {
                memcpy(L0, L2, lenT * sizeof(interval_t));
            }
        }
        free(L2);
        free(L0);     
    }

    //2. Augmentation
    ail->maxE = malloc(nr * sizeof(uint32_t)); 
    for (j = 0; j < ail->nc; j++)
    { 
        k0 = ail->idxC[j];
        k = k0 + ail->lenC[j];
        uint32_t tt = L1[k0].end;
        ail->maxE[k0] = tt;

        for (t = k0 + 1; t < k; t++)
        {
            if (L1[t].end > tt)
            {
                tt = L1[t].end;
            }

            ail->maxE[t] = tt;  
        }             
    }
    return;
}


ailist_t *ailist_query(ailist_t *ail, uint32_t qs, uint32_t qe)
{   
    int k;

    ailist_t *overlaps = ailist_init();

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
                if (ail->interval_list[t].end > qs)
                {               	
                    ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].index, ail->interval_list[t].value);
                }

                t--;
            }
        } 
        else {
            for (t = cs; t < ce; t++)
            {
                if (ail->interval_list[t].start < qe && ail->interval_list[t].end > qs)
                {
                    ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].index, ail->interval_list[t].value);
                }
            }                      
        }
    }

    return overlaps;                            
}


ailist_t *ailist_query_length(ailist_t *ail, uint32_t qs, uint32_t qe, int min_length, int max_length)
{   
    int k;

    ailist_t *overlaps = ailist_init();

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
                if (ail->interval_list[t].end > qs)
                {               	
                    int length = ail->interval_list[t].end - ail->interval_list[t].start;
                    if (length >= min_length && length < max_length)
                    {
                        ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].index, ail->interval_list[t].value);
                    }
                }

                t--;
            }
        } 
        else {
            for (t = cs; t < ce; t++)
            {
                if (ail->interval_list[t].start < qe && ail->interval_list[t].end > qs)
                {
                    int length = ail->interval_list[t].end - ail->interval_list[t].start;
                    if (length >= min_length && length < max_length)
                    {
                        ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].index, ail->interval_list[t].value);
                    }
                }
            }                      
        }
    }

    return overlaps;                            
}


array_query_t *ailist_query_from_array(ailist_t *ail, const long starts[], const long ends[], const long indices[], int length)
{   /* Find overlaps from array */
    int k;

    array_query_t *aq = array_query_init();

    // Iterate over queries
    int i;
    for (i = 0; i < length; i++)
    {
        uint32_t qs = starts[i];
        uint32_t qe = ends[i];
        uint32_t index = indices[i];

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
                    if (ail->interval_list[t].end > qs)
                    {               	
                        array_query_add(aq, index, ail->interval_list[t].index);
                        //ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].index, (double)index);
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (ail->interval_list[t].start < qe && ail->interval_list[t].end > qs)
                    {
                        array_query_add(aq, index, ail->interval_list[t].index);
                        //ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].index, (double)index);
                    }
                }                      
            }
        }
    }

    // reallocate to remove extra memory
    aq->ref_index = (long *)realloc(aq->ref_index, sizeof(long) * aq->size);
    aq->query_index = (long *)realloc(aq->query_index, sizeof(long) * aq->size);
    aq->max_size = aq->size;

    return aq;                            
}


array_query_t *ailist_query_from_ailist(ailist_t *ail, ailist_t *ail2)
{   /* Find overlaps from ailist */
    int k;

    array_query_t *aq = array_query_init();

    // Iterate over queries
    int i;
    for (i = 0; i < ail2->nr; i++)
    {
        uint32_t qs = ail2->interval_list[i].start;
        uint32_t qe = ail2->interval_list[i].end;
        uint32_t index = ail2->interval_list[i].index;

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
                    if (ail->interval_list[t].end > qs)
                    {               	
                        array_query_add(aq, index, ail->interval_list[t].index);
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (ail->interval_list[t].start < qe && ail->interval_list[t].end > qs)
                    {
                        array_query_add(aq, index, ail->interval_list[t].index);
                    }
                }                      
            }
        }
    }

    // reallocate to remove extra memory
    aq->ref_index = (long *)realloc(aq->ref_index, sizeof(long) * aq->size);
    aq->query_index = (long *)realloc(aq->query_index, sizeof(long) * aq->size);
    aq->max_size = aq->size;

    return aq;                           
}


//-------------------------------------------------------------------------------

ailist_t *ailist_append(ailist_t *ail1, ailist_t *ail2)
{
    // Initialize appended ailist
    ailist_t *appended_ailist = ailist_init();
    
    // Append ail1
    int i;
    for (i = 0; i < ail1->nr; i++)
    {
        ailist_add(appended_ailist, ail1->interval_list[i].start, ail1->interval_list[i].end,
                   ail1->interval_list[i].index, ail1->interval_list[i].value);
    }

    // Append ail2
    for (i = 0; i < ail2->nr; i++)
    {
        ailist_add(appended_ailist, ail2->interval_list[i].start, ail2->interval_list[i].end,
                   ail2->interval_list[i].index, ail2->interval_list[i].value);
    }

    return appended_ailist;
}


void ailist_extract_index(ailist_t *ail, long indices[])
{   /* Extract index for ailist */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        indices[i] = ail->interval_list[i].index;
    }

    return;
}


void ailist_extract_starts(ailist_t *ail, long starts[])
{   /* Extract start for ailist */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        starts[i] = ail->interval_list[i].start;
    }

    return;
}


void ailist_extract_ends(ailist_t *ail, long ends[])
{   /* Extract end for ailist */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        ends[i] = ail->interval_list[i].end;
    }

    return;
}


void ailist_extract_values(ailist_t *ail, double values[])
{   /* Extract value for ailist */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        values[i] = ail->interval_list[i].value;
    }

    return;
}


void ailist_coverage(ailist_t *ail, double coverage[])
{   /* Calculate coverage */
    int length;
    int n;
    int i;
    int position;
    int start = (int)ail->first;

    for (i = 0; i < ail->nr; i++)
    {
        length = ail->interval_list[i].end - ail->interval_list[i].start;
        for (n = 0; n < length; n++)
        {
            position = (ail->interval_list[i].start - start) + n;
            coverage[position] = coverage[position] + 1;
        }
    }

    return;
}


void ailist_bin_coverage(ailist_t *ail, double coverage[], int bin_size)
{   /* Calculate coverage within bins */
    int start = (int)(ail->first / bin_size);
    
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        int start_bin = ail->interval_list[i].start / bin_size;
        
        double length = (double)(ail->interval_list[i].end - ail->interval_list[i].start);
        int n_bins = ceil(((double)(ail->interval_list[i].start % bin_size) / bin_size) + (length / bin_size));
        int n;
        for (n = 0; n < n_bins; n++)
        {
            int bin = (start_bin - start) + n;
            int bin_start_position = ((start_bin + n) * bin_size);
            int i_start_position = MAX(bin_start_position, (int)ail->interval_list[i].start);
            int i_end_position = MIN((bin_start_position + bin_size), (int)ail->interval_list[i].end);
            int coverage_value = i_end_position - i_start_position;
            coverage[bin] = coverage[bin] + coverage_value;
        }
    }

    return;
}


void ailist_bin_coverage_length(ailist_t *ail, double coverage[], int bin_size, int min_length, int max_length)
{   /* Calculate coverage within bins of a length */
    int start = (int)(ail->first / bin_size);
    
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        int start_bin = ail->interval_list[i].start / bin_size;
        
        double length = (double)(ail->interval_list[i].end - ail->interval_list[i].start);
        if (length >= min_length && length < max_length)
        {
            int n_bins = ceil(((double)(ail->interval_list[i].start % bin_size) / bin_size) + (length / bin_size));
            int n;
            for (n = 0; n < n_bins; n++)
            {
                int bin = (start_bin - start) + n;
                int bin_start_position = ((start_bin + n) * bin_size);
                int i_start_position = MAX(bin_start_position, (int)ail->interval_list[i].start);
                int i_end_position = MIN((bin_start_position + bin_size), (int)ail->interval_list[i].end);
                int coverage_value = i_end_position - i_start_position;
                coverage[bin] = coverage[bin] + coverage_value;
            }
        }
    }

    return;
}


void ailist_bin_nhits(ailist_t *ail, double coverage[], int bin_size)
{   /* Calculate n hits within bins */
    int start = (int)(ail->first / bin_size);
    
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        int start_bin = ail->interval_list[i].start / bin_size;
        
        double length = (double)(ail->interval_list[i].end - ail->interval_list[i].start);
        int n_bins = ceil(((double)(ail->interval_list[i].start % bin_size) / bin_size) + (length / bin_size));
        int n;
        for (n = 0; n < n_bins; n++)
        {
            int bin = (start_bin - start) + n;
            coverage[bin] = coverage[bin] + 1;
        }
    }

    return;
}


void ailist_bin_nhits_length(ailist_t *ail, double coverage[], int bin_size, int min_length, int max_length)
{   /* Calculate n hits of a length within bins */
    int start = (int)(ail->first / bin_size);
    
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        int start_bin = ail->interval_list[i].start / bin_size;
        
        double length = (double)(ail->interval_list[i].end - ail->interval_list[i].start);
        if (length >= min_length && length < max_length)
        {
            int n_bins = ceil(((double)(ail->interval_list[i].start % bin_size) / bin_size) + (length / bin_size));
            int n;
            for (n = 0; n < n_bins; n++)
            {
                int bin = (start_bin - start) + n;
                coverage[bin] = coverage[bin] + 1;
            }
        }
    }

    return;
}


void ailist_bin_sums(ailist_t *ail, double sum_values[], int bin_size)
{   /* Calculate average values within bins */
    int start = (int)(ail->first / bin_size);
    
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        int start_bin = ail->interval_list[i].start / bin_size;
        
        double length = (double)(ail->interval_list[i].end - ail->interval_list[i].start);
        int n_bins = ceil(((double)(ail->interval_list[i].start % bin_size) / bin_size) + (length / bin_size));
        int n;
        for (n = 0; n < n_bins; n++)
        {
            int bin = (start_bin - start) + n;
            sum_values[bin] = sum_values[bin] + ail->interval_list[i].value;
        }
    }

    return;
}


void ailist_from_array(ailist_t *ail, const long starts[], const long ends[], const long index[], const double values[], int length)
{
    
    // Iterate over itervals and add
    int i;
    for (i = 0; i < length; i++)
    {
        ailist_add(ail, starts[i], ends[i], index[i], values[i]);
    }

    return;
}


void subtract_intervals(ailist_t *ref_ail, ailist_t *result_ail, interval_t query_i, int j)
{   /* Subtract intervals from region*/

    int previous_start = ref_ail->interval_list[j].start;
    int previous_end = ref_ail->interval_list[j].end;
    int s_start = query_i.start;
    int s_end = query_i.end;

    // Iterate over regions
    int i = j+1;
    while (i < ref_ail->nr && (int)query_i.start < previous_end && (int)query_i.end > previous_start)
    {        
        if (previous_end > (int)ref_ail->interval_list[i].start)
        {   // If previous overlaps current, merge
            previous_end = MAX(previous_end, (int)ref_ail->interval_list[i].end);
        }
        else
        {
            // Find subtracted bounds
            if ((int)query_i.start < previous_start)
            {
                // Record new bounds
                s_start = query_i.start;
                s_end = previous_start;
                // Add new bounds to result
                ailist_add(result_ail, s_start, s_end, query_i.index, query_i.value);

                // If query is larger than ref_ail interval
                if ((int)query_i.end > previous_end)
                {
                    query_i.start = previous_end;
                }
            }
            else
            {
                s_start = previous_end;
                s_end = query_i.end;

                // If query is larger than ref_ail interval
                if ((int)query_i.end > previous_end)
                {
                    // Update query_i bounds
                    query_i.start = previous_end;
                }
            }
            

            previous_start = ref_ail->interval_list[i].start;
            previous_end = ref_ail->interval_list[i].end;
        }

        i++;
    }

    // Check last interval
    if ((int)query_i.start < previous_end && (int)query_i.end > previous_start)
    {
        // Find subtracted bounds
        if ((int)query_i.start < previous_start)
        {
            // Record new bounds
            s_start = query_i.start;
            s_end = previous_start;
            // Add new bounds to result
            ailist_add(result_ail, s_start, s_end, query_i.index, query_i.value);

            // If query is larger than ref_ail interval
            if ((int)query_i.end > previous_end)
            {
                query_i.start = previous_end;
                // Add new bounds to result
                ailist_add(result_ail, query_i.start, query_i.end, query_i.index, query_i.value);
            }
        }
        else
        {
            s_start = previous_end;
            s_end = query_i.end;

            // Add new bounds to result
            if ((s_end - s_start) > 0)
            {
                ailist_add(result_ail, s_start, s_end, query_i.index, query_i.value);
            }

            // Update query_i bounds
            query_i.start = previous_end;
        }
    }
    else if (s_end > s_start)
    {
        // Add new bounds to result
        ailist_add(result_ail, s_start, s_end, query_i.index, query_i.value);
    }
    

}


ailist_t *ailist_subtract(ailist_t *ref_ail, ailist_t *query_ail)
{   /* Subtract two ailist_t intervals */
    int previous_end = ref_ail->interval_list[0].end;
    int previous_start = ref_ail->interval_list[0].start;
    int j = 0;
    int n_merged = 1;

    ailist_t *result_ail = ailist_init();

    // Iterate over regions
    int i;
    for (i = 1; i < ref_ail->nr; i++)
    {
        // If previous overlaps current, merge
        if (previous_end > (int)ref_ail->interval_list[i].start)
        {
            previous_end = MAX(previous_end, (int)ref_ail->interval_list[i].end);
            n_merged++;
        }
        else
        {   
            // Add intervals until caught up with ail1
            while (j < query_ail->nr && (int)query_ail->interval_list[j].end < previous_start)
            {
                ailist_add(result_ail, query_ail->interval_list[j].start, query_ail->interval_list[j].end,
                           query_ail->interval_list[j].index, query_ail->interval_list[j].value);
                j++;
            }

            // Subtract merged ail1 interval from overlapping ail1 intervals
            while (j < query_ail->nr && (int)query_ail->interval_list[j].start < previous_end && (int)query_ail->interval_list[j].end > previous_start)
            {
                subtract_intervals(ref_ail, result_ail, query_ail->interval_list[j], i-n_merged);
                j++;
            }

            previous_start = ref_ail->interval_list[i].start;
            previous_end = ref_ail->interval_list[i].end;
            n_merged = 1;
        }
    }

    // Subtract merged ail1 interval from overlapping ail1 intervals
    while (j < query_ail->nr && (int)query_ail->interval_list[j].start < previous_end && (int)query_ail->interval_list[j].end > previous_start)
    {
        subtract_intervals(ref_ail, result_ail, query_ail->interval_list[j], i-n_merged);
        j++;
    }

    // Add remaining intervals
    while (j < query_ail->nr)
    {
        // Check if intervals don't overlap
        if ((int)query_ail->interval_list[j].start > previous_end || (int)query_ail->interval_list[j].end < previous_start)
        {
            ailist_add(result_ail, query_ail->interval_list[j].start, query_ail->interval_list[j].end,
                    query_ail->interval_list[j].index, query_ail->interval_list[j].value);
        }
        j++;
    }

    return result_ail;
}


void common_intervals(ailist_t *ref_ail, ailist_t *result_ail, interval_t query_i, int j)
{   /* Subtract intervals from region*/

    int previous_start = ref_ail->interval_list[j].start;
    int previous_end = ref_ail->interval_list[j].end;

    // Iterate over regions
    int i = j+1;
    while (i < ref_ail->nr && (int)query_i.start < previous_end && (int)query_i.end > previous_start)
    {        
        if (previous_end > (int)ref_ail->interval_list[i].start)
        {   // If previous overlaps current, merge
            previous_end = MAX(previous_end, (int)ref_ail->interval_list[i].end);
        }
        else
        {
            int c_start;
            int c_end;

            // Find subtracted bounds
            if ((int)query_i.start <= previous_start)
            {
                // Record new bounds
                c_start = previous_start;
                c_end = query_i.end;

                // If query is larger than ref_ail interval
                if ((int)query_i.end > previous_end)
                {
                    c_end = previous_end;
                    query_i.start = previous_end;
                }

                // Add new bounds to result
                ailist_add(result_ail, c_start, c_end, query_i.index, query_i.value);
            }
            else
            {
                c_start = query_i.start;
                c_end = query_i.end;

                // If query is larger than ref_ail interval
                if ((int)query_i.end > previous_end)
                {
                    c_end = previous_end;
                    // Update query_i bounds
                    query_i.start = previous_end;
                }

                // Add new bounds to result
                ailist_add(result_ail, c_start, c_end, query_i.index, query_i.value);
            }
            

            previous_start = ref_ail->interval_list[i].start;
            previous_end = ref_ail->interval_list[i].end;
        }

        i++;
    }

    // Check last interval
    if ((int)query_i.start < previous_end && (int)query_i.end > previous_start)
    {
        int c_start;
        int c_end;
        // Find subtracted bounds
        if ((int)query_i.start <= previous_start)
        {
            // Record new bounds
            c_start = previous_start;
            c_end = query_i.end;

            // If query is larger than ref_ail interval
            if ((int)query_i.end > previous_end)
            {
                c_end = previous_end;
                query_i.start = previous_end;
            }

            // Add new bounds to result
            ailist_add(result_ail, c_start, c_end, query_i.index, query_i.value);
        }
        else
        {
            c_start = query_i.start;
            c_end = query_i.end;

            // If query is larger than ref_ail interval
            if ((int)query_i.end > previous_end)
            {
                c_end = previous_end;
                query_i.start = previous_end;
            }

            // Add new bounds to result
            ailist_add(result_ail, c_start, c_end, query_i.index, query_i.value);
        }
    }
}


ailist_t *ailist_common(ailist_t *ref_ail, ailist_t *query_ail)
{   /* Subtract two ailist_t intervals */
    int previous_end = ref_ail->interval_list[0].end;
    int previous_start = ref_ail->interval_list[0].start;
    int j = 0;
    int n_merged = 1;

    ailist_t *result_ail = ailist_init();

    // Iterate over regions
    int i;
    for (i = 1; i < ref_ail->nr; i++)
    {
        // If previous overlaps current, merge
        if (previous_end > (int)ref_ail->interval_list[i].start)
        {
            previous_end = MAX(previous_end, (int)ref_ail->interval_list[i].end);
            n_merged++;
        }
        else
        {   
            // Add intervals until caught up with ail1
            while (j < query_ail->nr && (int)query_ail->interval_list[j].end < previous_start)
            {
                j++;
            }

            // Subtract merged ail1 interval from overlapping ail1 intervals
            while (j < query_ail->nr && (int)query_ail->interval_list[j].start < previous_end && (int)query_ail->interval_list[j].end > previous_start)
            {
                common_intervals(ref_ail, result_ail, query_ail->interval_list[j], i-n_merged);
                j++;
            }

            previous_start = ref_ail->interval_list[i].start;
            previous_end = ref_ail->interval_list[i].end;
            n_merged = 1;
        }
    }

    // Subtract merged ail1 interval from overlapping ail1 intervals
    while (j < query_ail->nr && (int)query_ail->interval_list[j].start < previous_end && (int)query_ail->interval_list[j].end > previous_start)
    {
        common_intervals(ref_ail, result_ail, query_ail->interval_list[j], i-n_merged);
        j++;
    }

    return result_ail;
}


ailist_t *ailist_merge(ailist_t *ail, uint32_t gap)
{   /* Merge intervals in constructed ailist_t object */
    int previous_end = ail->interval_list[0].end;
    int previous_start = ail->interval_list[0].start;
    int previous_index = ail->interval_list[0].index;
    int i;
    ailist_t *merged_list = ailist_init();

    // Iterate over regions
    for (i = 1; i < ail->nr; i++)
    {
        // If previous
        if (previous_end > (int)(ail->interval_list[i].start - gap))
        {
            previous_end = MAX(previous_end, (int)ail->interval_list[i].end);
        }
        else
        {
            ailist_add(merged_list, previous_start, previous_end, previous_index, 0.0);
            previous_start = ail->interval_list[i].start;
            previous_end = ail->interval_list[i].end;
            previous_index = ail->interval_list[i].index;
        }
    }

    // Add last interval
    ailist_add(merged_list, previous_start, previous_end, previous_index, 0.0);

    return merged_list;
}


void ailist_wps(ailist_t *ail, double wps[], uint32_t protection)
{   /* Calculate Window Protection Score */
    int half_window = protection / 2;
    int first = (int)ail->first;

    // Iterate over regions
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        // Find regions around end points
        int head_start = MAX(first, (int)(ail->interval_list[i].start - half_window));
        int head_end = MIN((int)ail->interval_list[i].start + half_window, (int)ail->interval_list[i].end);
        int tail_start = MAX(head_end, (int)(ail->interval_list[i].end - half_window)); // if overlap, set not to overlap
        int tail_end = MIN((int)ail->interval_list[i].end + half_window, (int)ail->last);

        // Decrement region around head
        int head_length = head_end - head_start;
        int j;
        for (j = (head_start - first); j < (head_length + (head_start - first)); j++)
        {
            wps[j] = wps[j] - 1;
        }

        // Decrement region around tail
        int tail_length = tail_end - tail_start;
        for (j = (tail_start - first); j < (tail_length + (tail_start - first)); j++)
        {
            wps[j] = wps[j] - 1;
        }

        // If head and tail region don't overlap
        if (head_end != tail_start)
        {
            for (j = (head_end - first); j < (tail_start - first); j++)
            {
                wps[j] = wps[j] + 1;
            }
        }
    }

    return;
}


void ailist_wps_length(ailist_t *ail, double wps[], uint32_t protection, int min_length, int max_length)
{   /* Calculate Window Protection Score */
    int half_window = protection / 2;
    int first = (int)ail->first;

    // Iterate over regions
    int i;
    for (i = 0; i < ail->nr; i++)
    {   
        // Check if length is in range
        int length = ail->interval_list[i].end - ail->interval_list[i].start;
        if (length >= min_length && length < max_length)
        {
            // Find regions around end points
            int head_start = MAX(first, (int)(ail->interval_list[i].start - half_window));
            int head_end = MIN((int)ail->interval_list[i].start + half_window, (int)ail->interval_list[i].end);
            int tail_start = MAX(head_end, (int)(ail->interval_list[i].end - half_window)); // if overlap, set not to overlap
            int tail_end = MIN((int)ail->interval_list[i].end + half_window, (int)ail->last);

            // Decrement region around head
            int head_length = head_end - head_start;
            int j;
            for (j = (head_start - first); j < (head_length + (head_start - first)); j++)
            {
                wps[j] = wps[j] - 1;
            }

            // Decrement region around tail
            int tail_length = tail_end - tail_start;
            for (j = (tail_start - first); j < (tail_length + (tail_start - first)); j++)
            {
                wps[j] = wps[j] - 1;
            }

            // If head and tail region don't overlap
            if (head_end != tail_start)
            {
                for (j = (head_end - first); j < (tail_start - first); j++)
                {
                    wps[j] = wps[j] + 1;
                }
            }
        }
    }

    return;
}


ailist_t *ailist_length_filter(ailist_t *ail, int min_length, int max_length)
{   /* Filter ailist by length */
    // Initiatize filtered ailist
    ailist_t *filtered_ail = ailist_init();

    // Iterate over intervals and filter
    int length;
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        // Record length (excluding last position)
        length = ail->interval_list[i].end - ail->interval_list[i].start - 1;
        if (length >= min_length && length <= max_length)
        {
            ailist_add(filtered_ail, ail->interval_list[i].start, ail->interval_list[i].end, ail->interval_list[i].index, ail->interval_list[i].value);
        }
    }

    return filtered_ail;
}


int ailist_max_length(ailist_t *ail)
{   /* Calculate maximum length */
	
    // Iterate over intervals and record length
    int length;
    int maximum = 0;
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        // Record length (excluding last position)
        length = ail->interval_list[i].end - ail->interval_list[i].start - 1;
	    maximum = MAX(maximum, length);
    }

    return maximum;
}


void ailist_length_distribution(ailist_t *ail, int distribution[])
{   /* Calculate length distribution */
    // Iterate over intervals and record length
    int length;
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        // Record length (excluding last position)
        length = ail->interval_list[i].end - ail->interval_list[i].start - 1;
        distribution[length] += 1;
    }

    return;
}


void ailist_nhits_from_array(ailist_t *ail, const long starts[], const long ends[], int length, int nhits[])
{
    int i;
    for (i = 0; i < length; i++)
    {
        ailist_t *overlaps = ailist_query(ail, starts[i], ends[i]);
        nhits[i] = overlaps->nr;
    }

    return;
}


void ailist_nhits_from_array_length(ailist_t *ail, const long starts[], const long ends[], int length, int nhits[], int min_length, int max_length)
{
    int i;
    for (i = 0; i < length; i++)
    {
        ailist_t *overlaps = ailist_query_length(ail, starts[i], ends[i], min_length, max_length);
        nhits[i] = overlaps->nr;
    }

    return;
}


void ailist_interval_coverage(ailist_t *ail, int start, int end, int coverage[])
{
    
    // Query overlaps
    ailist_t *overlaps = ailist_query(ail, start, end);

    // Iterate over overlaps
    int j;
    for (j = 0; j < overlaps->nr; j++)
    {
        int overlap_start = MAX(start, (int)overlaps->interval_list[j].start);
        int overlap_end = MIN(end, (int)overlaps->interval_list[j].end);

        // Iterate over overlapping postions
        int k;
        for (k = overlap_start; k < overlap_end; k++)
        {
            coverage[k - start] += 1;
        }
    }

    return;
}


ailist_t *ailist_downsample(ailist_t *ail, double proportion)
{

    // Initialize downsampled ailist_t
    ailist_t *filtered_ail = ailist_init();

    // Set random seed
	srand(time(NULL));

    // Iterate over ail
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        // Randomly determine if interval is added
        double r = (double)rand() / (double)RAND_MAX;
        if (r < proportion)
        {
            ailist_add(filtered_ail, ail->interval_list[i].start, ail->interval_list[i].end, ail->interval_list[i].index, ail->interval_list[i].value);
        }
    }

    return filtered_ail;
}


void ailist_reset_index(ailist_t *ail)
{   /* Reset index to be in order */

    // Iterate over ail
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        ail->interval_list[i].index = i;
    }

    return;
}


void display_list(ailist_t *ail)
{
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        printf("(%d-%d) ", ail->interval_list[i].start, ail->interval_list[i].end);
    }
    printf("\n");
    return;
}


/* Driver program to test above functions*/
int main(void)
{ 
    printf("Initializing AIList...\n");
    ailist_t *ail = ailist_init();

    printf("Adding intervals...\n");
    ailist_add(ail, 15, 20, 1, 0.0); 
    ailist_add(ail, 10, 30, 2, 0.0); 
    ailist_add(ail, 17, 19, 3, 0.0); 
    ailist_add(ail, 5, 20, 4, 0.0); 
    ailist_add(ail, 12, 15, 5, 0.0); 
    ailist_add(ail, 30, 40, 6, 0.0); 

    //int i;
    /* for (i = 1000; i < 1000000000; i+=100) 
    {
        ailist_add(ail, i, i+2000, 0);
    } */
    display_list(ail);
    
    printf("Constructing AIList...\n");
    ailist_construct(ail, 20);
    display_list(ail);

    // Merge intervals
    printf("Merging AIList...\n");
    ailist_t *merged_ail = ailist_merge(ail, 1);
    display_list(merged_ail);

    printf("Finding overlaps...for (10-15)\n");
    ailist_t *overlaps;

    overlaps = ailist_query(ail, 10, 15);
    display_list(overlaps);

    return 0;
}