//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_array.h"

//-----------------------------------------------------------------------------

void aiarray_interval_coverage(aiarray_t *ail, int start, int end, int coverage[])
{   /* Determine coverage for an interval */
    
    // Query overlaps
    aiarray_t *overlaps = aiarray_query(ail, start, end);

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


void aiarray_coverage(aiarray_t *ail, double coverage[])
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


void aiarray_bin_coverage(aiarray_t *ail, double coverage[], int bin_size)
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


void aiarray_bin_coverage_length(aiarray_t *ail, double coverage[], int bin_size, int min_length, int max_length)
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

