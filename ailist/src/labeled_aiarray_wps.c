//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-------------------------------------------------------------------------------

void labeled_aiarray_label_wps(labeled_interval_t *interval_list, double wps[], uint32_t protection, int nr, int first, int last)
{   /* Calculate Window Protection Score for a label */
    int half_window = protection / 2;

    // Iterate over regions
    int i;
    for (i = 0; i < nr; i++)
    {
        // Find regions around end points
        int head_start = MAX(first, (int)(interval_list[i].start - half_window));
        int head_end = MIN((int)interval_list[i].start + half_window, (int)interval_list[i].end);
        int tail_start = MAX(head_end, (int)(interval_list[i].end - half_window)); // if overlap, set not to overlap
        int tail_end = MIN((int)interval_list[i].end + half_window, last);

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


void labeled_aiarray_wps(labeled_aiarray_t *ail, double wps[], uint32_t protection)
{   /* Calculate Window Protection Score */

    // Iterate over label index
    uint32_t wps_shift = 0;
    uint16_t label;
    for (label = 0; label < ail->nl; label++)
    {
        if (ail->label_count[label] != 0)
        {
            // Find bounds for labels
            uint32_t ail_label_start = get_label_index(ail, label);
            uint32_t ail_label_end = get_label_index(ail, label + 1);
            int first = (int)ail->first[label];
            int last = (int)ail->last[label];
            int length = last - first;
            int nr = ail_label_end - ail_label_start;

            // Subset ail by label
            labeled_aiarray_label_wps(&ail->interval_list[ail_label_start], &wps[wps_shift], protection, nr, first, last);

            // Increment wps_shift
            wps_shift = wps_shift + length;
        }
    }
}

//-------------------------------------------------------------------------------

void labeled_aiarray_label_wps_length(labeled_interval_t *interval_list, double wps[], uint32_t protection, int nr, int first, int last, int min_length, int max_length)
{   /* Calculate Window Protection Score for a label of a length */
    int half_window = protection / 2;

    // Iterate over regions
    int i;
    for (i = 0; i < nr; i++)
    {
        // Check if length is in range
        int length = interval_list[i].end - interval_list[i].start;
        if (length >= min_length && length < max_length)
        {
            // Find regions around end points
            int head_start = MAX(first, (int)(interval_list[i].start - half_window));
            int head_end = MIN((int)interval_list[i].start + half_window, (int)interval_list[i].end);
            int tail_start = MAX(head_end, (int)(interval_list[i].end - half_window)); // if overlap, set not to overlap
            int tail_end = MIN((int)interval_list[i].end + half_window, last);

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


void labeled_aiarray_wps_length(labeled_aiarray_t *ail, double wps[], uint32_t protection, int min_length, int max_length)
{   /* Calculate Window Protection Score of a length */

    // Iterate over label index
    uint32_t wps_shift = 0;
    uint16_t label;
    for (label = 0; label < ail->nl; label++)
    {
        if (ail->label_count[label] != 0)
        {
            // Find bounds for labels
            uint32_t ail_label_start = get_label_index(ail, label);
            uint32_t ail_label_end = get_label_index(ail, label + 1);
            int first = (int)ail->first[label];
            int last = (int)ail->last[label];
            int length = last - first;
            int nr = ail_label_end - ail_label_start;

            // Subset ail by label
            labeled_aiarray_label_wps_length(&ail->interval_list[ail_label_start], &wps[wps_shift], protection, nr, first, last, min_length, max_length);

            // Increment wps_shift
            wps_shift = wps_shift + length;
        }
    }
}