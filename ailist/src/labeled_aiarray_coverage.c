//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

void labeled_aiarray_interval_coverage(labeled_aiarray_t *ail, int start, int end, const char *label_name, int coverage[])
{   /* Determine coverage for an interval */
    
    // Query overlaps
    labeled_aiarray_t *overlaps = labeled_aiarray_query_single(ail, start, end, label_name);

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


//-------------------------------------------------------------------------------


void labeled_aiarray_label_coverage(labeled_interval_t *interval_list, double coverage[], const char *label_names, int nr)
{   /* Calculate coverage for a label */
    int length;
    int n;

    // Iterate over regions
    int i;
    for (i = 0; i < nr; i++)
    {
        length = interval_list[i].end - interval_list[i].start;
        for (n = 0; n < length; n++)
        {
            coverage[i+n] = coverage[i+n] + 1;
        }
    }

    return;
}


void labeled_aiarray_coverage(labeled_aiarray_t *ail, double coverage[])
{   /* Calculate coverage */

    uint32_t cov_shift = 0;
    uint16_t label;
    for (label = 0; label < ail->nl; label++)
    {
        const char *label_name = query_rev_label_map(ail, label);
        if (ail->label_count[label] != 0)
        {
            // Find bounds for labels
            uint32_t ail_label_start = get_label_index(ail, label);
            uint32_t ail_label_end = get_label_index(ail, label + 1);
            int first = (int)ail->first[label];
            int last = (int)ail->last[label];
            int length = last - first;
            int nr = ail_label_end - ail_label_start;
            labeled_aiarray_label_coverage(&ail->interval_list[ail_label_start], &coverage[cov_shift], label_name, nr);

            // Increment cov_shift
            cov_shift = cov_shift + length;
        }
    }

    return;
}

//-------------------------------------------------------------------------------



//-------------------------------------------------------------------------------

