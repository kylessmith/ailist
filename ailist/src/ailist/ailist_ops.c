//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

void ailist_subtract_intervals(interval_t *intv, ailist_t *ail, ailist_t *result_ail)
{

    // Initialize variables
    uint32_t start = intv->start;
    uint32_t end = intv->end;

    // Check if query interval is empty
    if (ail->nr == 0)
    {
        ailist_add(result_ail, start, end, intv->id_value);
        return;
    }

    // Initialize iterator
    ailist_sorted_iter_t *ail_iter = ailist_sorted_iter_init(ail);
    uint32_t iv_start;
    uint32_t iv_end;
    uint32_t i = 0;

    // Iterate through intervals    
    while (ailist_sorted_iter_next(ail_iter) != 0)
    {   
        iv_start = ail_iter->intv->start;
        iv_end = ail_iter->intv->end;

        if (end <= iv_start || start >= iv_end)
        {
            ailist_add(result_ail, start, end, i);
            i++;
        }
        else if (start < iv_start && end > iv_end)
        {
            ailist_add(result_ail, start, iv_start, i);
            i++;
            start = iv_end;
        }
        else if (start < iv_start && end <= iv_end)
        {
            ailist_add(result_ail, start, iv_start, i);
            i++;
        }
        else if (start >= iv_start && end > iv_end)
        {
            start = iv_end;
        }
        else if (start >= iv_start && end <= iv_end)
        {
            start = end;
            break;
        }
    }

    if (start < end && start >= iv_end)
    {
        ailist_add(result_ail, start, end, i);
    }

    // Free memory
    ailist_sorted_iter_destroy(ail_iter);

    return;
}


ailist_t *ailist_subtract(ailist_t *ail, ailist_t *other_ail)
{
    ailist_t *result_ail = ailist_init();
    
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        ailist_t *overlaps = ailist_init();
        ailist_query(other_ail, overlaps, ail->interval_list[i].start, ail->interval_list[i].end);
        ailist_construct(overlaps, 20);
        ailist_subtract_intervals(&ail->interval_list[i], overlaps, result_ail);

        // Free memory
        ailist_destroy(overlaps);
    }

    return result_ail;
}


void ailist_common_intervals(interval_t *intv, ailist_t *ail, ailist_t *result_ail)
{

    // Initialize variables
    uint32_t start = intv->start;
    uint32_t end = intv->end;

    // Check if query interval is empty
    if (ail->nr == 0)
    {
        return;
    }

    // Initialize iterator
    ailist_sorted_iter_t *ail_iter = ailist_sorted_iter_init(ail);
    ailist_sorted_iter_next(ail_iter);
    interval_t *current_com_intv;
    current_com_intv = ail_iter->intv;
    uint32_t common_start = current_com_intv->start;
    uint32_t common_end = current_com_intv->end;

    // Iterate through intervals    
    while (ailist_sorted_iter_next(ail_iter) != 0)
    {   
        // Get current interval
        current_com_intv = ail_iter->intv;

        // Check if current interval overlaps previous interval
        if (common_end > current_com_intv->start)
        {
            // If previous overlaps current, merge
            common_end = MAX(common_end, current_com_intv->end);
        }
        else
        {

            // Subtract previous interval from query interval
            start = MAX(common_start, start);
            end = MIN(common_end, end);

            // Update previous interval
            common_start = current_com_intv->start;
            common_end = current_com_intv->end;

            // Add subtracted interval to result
            ailist_add(result_ail, start, end, intv->id_value);
            start = common_start;
            end = intv->end;
        }
    }

    // Add last interval to result
    // If previous does not overlap current, subtract

    // Subtract previous interval from query interval
    start = MAX(common_start, start);
    end = MIN(common_end, end);

    if (start < end)
    {
        ailist_add(result_ail, start, end, intv->id_value);
    }

    // Free memory
    ailist_sorted_iter_destroy(ail_iter);

    return;
}


ailist_t *ailist_common(ailist_t *ail, ailist_t *other_ail)
{
    ailist_t *result_ail = ailist_init();
    
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        ailist_t *overlaps = ailist_init();
        ailist_query(other_ail, overlaps, ail->interval_list[i].start, ail->interval_list[i].end);
        ailist_construct(overlaps, 20);
        ailist_common_intervals(&ail->interval_list[i], overlaps, result_ail);

        // Free memory
        ailist_destroy(overlaps);
    }

    return result_ail;
}


ailist_t *ailist_union(ailist_t *ail, ailist_t *other_ail)
{
    ailist_t *result_ail = ailist_init();
    ailist_append(result_ail, ail);
    ailist_append(result_ail, other_ail);
    ailist_construct(result_ail, 20);
    
    return result_ail;
}