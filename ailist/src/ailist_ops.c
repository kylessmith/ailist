//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

void subtract_intervals(ailist_t *ref_ail, ailist_t *result_ail, interval_t query_i, int j)
{   /* Subtract intervals from region */

    int previous_start = ref_ail->interval_list[j].start;
    int previous_end = ref_ail->interval_list[j].end;
    int previous_id = ref_ail->interval_list[j].id_value;
    int s_start = query_i.start;
    int s_end = query_i.end;
    int s_id = query_i.id_value;

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
                s_id = query_i.id_value;
                // Add new bounds to result
                ailist_add(result_ail, s_start, s_end, s_id);

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
                s_id = query_i.id_value;

                // If query is larger than ref_ail interval
                if ((int)query_i.end > previous_end)
                {
                    // Update query_i bounds
                    query_i.start = previous_end;
                }
            }
            

            previous_start = ref_ail->interval_list[i].start;
            previous_end = ref_ail->interval_list[i].end;
            previous_id = ref_ail->interval_list[i].id_value;
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
            s_id = query_i.id_value;
            // Add new bounds to result
            ailist_add(result_ail, s_start, s_end, s_id);

            // If query is larger than ref_ail interval
            if ((int)query_i.end > previous_end)
            {
                query_i.start = previous_end;
                // Add new bounds to result
                ailist_add(result_ail, query_i.start, query_i.end, query_i.id_value);
            }
        }
        else
        {
            s_start = previous_end;
            s_end = query_i.end;
            s_id = query_i.id_value;

            // Add new bounds to result
            if ((s_end - s_start) > 0)
            {
                ailist_add(result_ail, s_start, s_end, s_id);
            }

            // Update query_i bounds
            query_i.start = previous_end;
        }
    }
    else if (s_end > s_start)
    {
        // Add new bounds to result
        ailist_add(result_ail, s_start, s_end, s_id);
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
                ailist_add(result_ail, query_ail->interval_list[j].start, query_ail->interval_list[j].end, query_ail->interval_list[j].id_value);
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
            ailist_add(result_ail, query_ail->interval_list[j].start, query_ail->interval_list[j].end, query_ail->interval_list[j].id_value);
        }
        j++;
    }

    return result_ail;
}


void common_intervals(ailist_t *ref_ail, ailist_t *result_ail, interval_t query_i, int j)
{   /* Subtract intervals from region */

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
            int c_id;

            // Find subtracted bounds
            if ((int)query_i.start <= previous_start)
            {
                // Record new bounds
                c_start = previous_start;
                c_end = query_i.end;
                c_id = query_i.id_value;

                // If query is larger than ref_ail interval
                if ((int)query_i.end > previous_end)
                {
                    c_end = previous_end;
                    query_i.start = previous_end;
                }

                // Add new bounds to result
                ailist_add(result_ail, c_start, c_end, c_id);
            }
            else
            {
                c_start = query_i.start;
                c_end = query_i.end;
                c_id = query_i.id_value;

                // If query is larger than ref_ail interval
                if ((int)query_i.end > previous_end)
                {
                    c_end = previous_end;
                    // Update query_i bounds
                    query_i.start = previous_end;
                }

                // Add new bounds to result
                ailist_add(result_ail, c_start, c_end, c_id);
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
        int c_id;
        // Find subtracted bounds
        if ((int)query_i.start <= previous_start)
        {
            // Record new bounds
            c_start = previous_start;
            c_end = query_i.end;
            c_id = query_i.id_value;

            // If query is larger than ref_ail interval
            if ((int)query_i.end > previous_end)
            {
                c_end = previous_end;
                query_i.start = previous_end;
            }

            // Add new bounds to result
            ailist_add(result_ail, c_start, c_end, c_id);
        }
        else
        {
            c_start = query_i.start;
            c_end = query_i.end;
            c_id = query_i.id_value;

            // If query is larger than ref_ail interval
            if ((int)query_i.end > previous_end)
            {
                c_end = previous_end;
                query_i.start = previous_end;
            }

            // Add new bounds to result
            ailist_add(result_ail, c_start, c_end, c_id);
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
