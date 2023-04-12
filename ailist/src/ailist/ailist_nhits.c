//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

void ailist_nhits_from_array(ailist_t *ail, const long starts[], const long ends[], int length, int nhits[])
{
    int i;
    for (i = 0; i < length; i++)
    {
        ailist_t *overlaps = ailist_init();
        ailist_query(ail, overlaps, starts[i], ends[i]);
        nhits[i] = overlaps->nr;
    }

    return;
}


void ailist_nhits_from_array_length(ailist_t *ail, const long starts[], const long ends[], int length, int nhits[], int min_length, int max_length)
{
    int i;
    for (i = 0; i < length; i++)
    {
        ailist_t *overlaps = ailist_init();
        ailist_query_length(ail, overlaps, starts[i], ends[i], min_length, max_length);
        nhits[i] = overlaps->nr;
    }

    return;
}


void ailist_bin_nhits(ailist_t *ail, long coverage[], int bin_size)
{   /* Calculate n hits within bins */
    int start = (int)(ail->first / bin_size);
    //printf("   start: %d\n", start);
    
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        int start_bin = ail->interval_list[i].start / bin_size;
        
        double length = (double)(ail->interval_list[i].end - ail->interval_list[i].start);
        int n_bins = ceil(((double)(ail->interval_list[i].start % bin_size) / bin_size) + (length / bin_size));
        //printf("    interval length: %f covers %d bins\n", length, n_bins);
        int n;
        for (n = 0; n < n_bins; n++)
        {
            int bin = (start_bin - start) + n;
            //printf("      putiting in bin : %d\n", bin);
            coverage[bin] = coverage[bin] + 1;
        }
    }

    return;
}


void ailist_bin_nhits_length(ailist_t *ail, long coverage[], int bin_size, int min_length, int max_length)
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