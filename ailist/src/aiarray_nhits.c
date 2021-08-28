//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_array.h"

//-----------------------------------------------------------------------------

void aiarray_nhits_from_array(aiarray_t *ail, const long starts[], const long ends[], int length, int nhits[])
{
    int i;
    for (i = 0; i < length; i++)
    {
        aiarray_t *overlaps = aiarray_query(ail, starts[i], ends[i]);
        nhits[i] = overlaps->nr;
    }

    return;
}


void aiarray_nhits_from_array_length(aiarray_t *ail, const long starts[], const long ends[], int length, int nhits[], int min_length, int max_length)
{
    int i;
    for (i = 0; i < length; i++)
    {
        aiarray_t *overlaps = aiarray_query_length(ail, starts[i], ends[i], min_length, max_length);
        nhits[i] = overlaps->nr;
    }

    return;
}


void aiarray_bin_nhits(aiarray_t *ail, double coverage[], int bin_size)
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


void aiarray_bin_nhits_length(aiarray_t *ail, double coverage[], int bin_size, int min_length, int max_length)
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