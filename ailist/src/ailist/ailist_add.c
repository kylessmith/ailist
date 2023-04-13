//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

void ailist_add(ailist_t *ail, uint32_t start, uint32_t end, uint32_t id)
{   /* Add interval to ailist_t object */

	// If start is greater than end, invalid interval
    if (start > end)
    {
        return;
    }

    // Update first and last
    ail->first = MIN(ail->first, start);
    ail->last = MAX(ail->last, end);

    // If max region reached, expand array
	if (ail->nr == ail->mr)
    {
		EXPAND(ail->interval_list, ail->mr);
    }

    // Set new interval values
	interval_t *i = &ail->interval_list[ail->nr++];
	i->start = start;
	i->end = end;
    i->id_value = id;

	return;
}


void ailist_from_array(ailist_t *ail, const long starts[], const long ends[], const long ids[], int length)
{   /* Build ailist from arrays */
    
    // Iterate over itervals and add
    int i;
    for (i = 0; i < length; i++)
    {
        ailist_add(ail, starts[i], ends[i], ids[i]);
    }

    return;
}


ailist_t *ailist_append(ailist_t *ail1, ailist_t *ail2)
{   /* Append two ailist */
    
    // Initialize appended ailist
    ailist_t *appended_ailist = ailist_init();
    
    // Append ail1
    int i;
    for (i = 0; i < ail1->nr; i++)
    {
        ailist_add(appended_ailist, ail1->interval_list[i].start, ail1->interval_list[i].end, ail1->interval_list[i].id_value);
    }

    // Append ail2
    int j;
    for (j = 0; j < ail2->nr; j++)
    {
        ailist_add(appended_ailist, ail2->interval_list[j].start, ail2->interval_list[j].end,  ail2->interval_list[j].id_value);
    }

    return appended_ailist;
}


ailist_t *ailist_copy(ailist_t *ail)
{   /* Copy ailist */

	// Initalize copy
    ailist_t *ail_copy = ailist_init();


    // Iterate over intervals in p
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        ailist_add(ail_copy, ail->interval_list[i].start, ail->interval_list[i].end, i);
    }

    return ail_copy;

}