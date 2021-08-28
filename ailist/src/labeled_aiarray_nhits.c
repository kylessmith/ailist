//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-------------------------------------------------------------------------------

void labeled_aiarray_nhits_from_array(labeled_aiarray_t *ail, const long starts[], const long ends[],
                                     const char *label_names[], int length, int nhits[])
{   /* Determine number of hits for each query interval */

    // Iterate over query intervals
    int i;
    for (i = 0; i < length; i++)
    {
        // Determine number of overlaps
        labeled_aiarray_t *overlaps = labeled_aiarray_query_single(ail, starts[i], ends[i], label_names[i]);
        nhits[i] = overlaps->nr;
    }

    return;
}

long labeled_aiarray_nhits_length(labeled_aiarray_t *ail, long start, long end, const char *label_name, int min_length, int max_length)
{   /* Determine number of hits for interval of a length */

    // Determine number of overlaps
    long nhits = 0;
    labeled_aiarray_query_nhits_length(ail, &nhits, start, end, label_name, min_length, max_length);

    return nhits;
}

long labeled_aiarray_nhits(labeled_aiarray_t *ail, long start, long end, const char *label_name)
{   /* Determine number of hits for interval */

    // Determine number of overlaps
    long nhits = 0;
    labeled_aiarray_query_nhits(ail, &nhits, start, end, label_name);

    return nhits;
}


void labeled_aiarray_nhits_from_array_length(labeled_aiarray_t *ail, const long starts[], const long ends[],
                                            const char *label_names[], int length, int nhits[], int min_length,
                                            int max_length)
{   /* Determine number of hits of a length for each query interval */

    // Iterate over query intervals
    int i;
    for (i = 0; i < length; i++)
    {
        // Determine number of overlaps
        labeled_aiarray_t *overlaps = labeled_aiarray_query_single_length(ail, starts[i], ends[i], label_names[i], min_length, max_length);
        nhits[i] = overlaps->nr;
    }

    return;
}


void labeled_aiarray_bin_nhits(labeled_aiarray_t *ail, labeled_aiarray_t *bins, double nhits[], int bin_size)
{   /* Calculate n hits within bins */

    // Iterate over label index
    uint16_t label;
    for (label = 0; label < ail->nl; label++)
    {
        if (ail->label_count[label] != 0)
        {
            // Find bounds for labels
            uint32_t ail_label_start = get_label_index(ail, label);
            uint32_t ail_label_end = get_label_index(ail, label + 1);
            uint32_t bins_label_start = get_label_index(bins, label);
            //uint32_t bins_label_end = bins->label_index[label + 1];

            // Initialize starting bin
            int start = (int)(ail->interval_list[ail_label_start].start / bin_size);
            
            // Iterate over intervals
            uint32_t i;
            for (i = ail_label_start; i < ail_label_end; i++)
            {
                // Interval start bin
                int start_bin = ail->interval_list[i].start / bin_size;
                
                // Find number of bins overlapping
                double length = (double)(ail->interval_list[i].end - ail->interval_list[i].start);
                int n_bins = ceil(((double)(ail->interval_list[i].start % bin_size) / bin_size) + (length / bin_size));
                int n;
                // Iterate over bins included in interval
                for (n = 0; n < n_bins; n++)
                {
                    int bin = bins_label_start + (start_bin - start) + n;
                    nhits[bin] = nhits[bin] + 1;
                }
            }
        }
    }

    return;
}


void labeled_aiarray_bin_nhits_length(labeled_aiarray_t *ail, labeled_aiarray_t *bins, double nhits[], int bin_size, int min_length, int max_length)
{   /* Calculate n hits of a length within bins */

    // Iterate over label index
    uint16_t label;
    for (label = 0; label < ail->nl; label++)
    {   
        if (ail->label_count[label] != 0)
        {
            // Determine label name
            const char *label_name = query_rev_label_map(ail, label);
            
            // Find bounds for labels
            uint32_t ail_label_start = get_label_index(ail, label);
            uint32_t ail_label_end = get_label_index(ail, label + 1);
            uint32_t bins_label_start = get_label_index(bins, label);
            //uint32_t bins_label_end = bins->label_index[label + 1];

            // Initialize starting bin
            int start = (int)(ail->interval_list[ail_label_start].start / bin_size);
            
            // Iterate over intervals
            uint32_t i;
            for (i = ail_label_start; i < ail_label_end; i++)
            {
                // Interval start bin
                int start_bin = ail->interval_list[i].start / bin_size;
                
                // Find number of bins overlapping
                double length = (double)(ail->interval_list[i].end - ail->interval_list[i].start);
                if (length >= min_length && length < max_length)
                {
                    int n_bins = ceil(((double)(ail->interval_list[i].start % bin_size) / bin_size) + (length / bin_size));
                    int n;
                    // Iterate over bins included in interval
                    for (n = 0; n < n_bins; n++)
                    {
                        int bin = bins_label_start + (start_bin - start) + n;
                        nhits[bin] = nhits[bin] + 1;
                    }
                }
            }
        }
    }

    return;
}