//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

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

