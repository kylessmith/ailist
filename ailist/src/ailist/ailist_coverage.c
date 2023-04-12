//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

void ailist_interval_coverage(ailist_t *ail, int start, int end, int coverage[])
{   /* Calculate coverage for a single interval */
    
    // Query overlaps
    ailist_t *overlaps = ailist_init();
    ailist_query(ail, overlaps, start, end);

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


void ailist_coverage_length(ailist_t *ail, double coverage[], int min_length, int max_length)
{   /* Calculate coverage of a length */
    int length;
    int n;
    int i;
    int position;
    int start = (int)ail->first;

    for (i = 0; i < ail->nr; i++)
    {
        length = ail->interval_list[i].end - ail->interval_list[i].start;
        if (length > min_length && length < max_length)
        {
            for (n = 0; n < length; n++)
            {
                position = (ail->interval_list[i].start - start) + n;
                coverage[position] = coverage[position] + 1;
            }
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


void ailist_midpoint_coverage(ailist_t *ail, double coverage[])
{   /* Calculate coverage of midpoints */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        int length = ail->interval_list[i].end - ail->interval_list[i].start;
        int midpoint = length / 2;
        coverage[midpoint] = coverage[midpoint] + 1;
    }

    return;
}


void ailist_midpoint_coverage_length(ailist_t *ail, double coverage[], int min_length, int max_length)
{   /* Calculate coverage of midpoints with lengths */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        int length = ail->interval_list[i].end - ail->interval_list[i].start;
        if (length > min_length && length < max_length)
        {
            int midpoint = length / 2;
            coverage[midpoint] = coverage[midpoint] + 1;
        }
    }

    return;
}