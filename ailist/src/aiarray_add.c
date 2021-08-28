//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_array.h"

//-----------------------------------------------------------------------------

void aiarray_add(aiarray_t *ail, uint32_t start, uint32_t end)
{   /* Add interval to aiarray_t object */

	// If start is greater than end, invalid interval
    if (start > end) {return;}

    // Update first and last
    ail->first = MIN(ail->first, start);
    ail->last = MAX(ail->last, end);

    // If max region reached, expand array
	if (ail->nr == ail->mr)
		EXPAND(ail->interval_list, ail->mr);

    // Set new interval values
	interval_t *i = &ail->interval_list[ail->nr++];
	i->start = start;
	i->end = end;
    i->id_value = ail->nr - 1;

	return;
}


void aiarray_from_array(aiarray_t *ail, const long starts[], const long ends[], int length)
{   /* Build aiarray from arrays */
    
    // Iterate over itervals and add
    int i;
    for (i = 0; i < length; i++)
    {
        aiarray_add(ail, starts[i], ends[i]);
    }

    return;
}


aiarray_t *aiarray_append(aiarray_t *ail1, aiarray_t *ail2)
{   /* Append two aiarray */
    
    // Initialize appended aiarray
    aiarray_t *appended_aiarray = aiarray_init();
    
    // Append ail1
    int i;
    for (i = 0; i < ail1->nr; i++)
    {
        aiarray_add(appended_aiarray, ail1->interval_list[i].start, ail1->interval_list[i].end);
    }

    // Append ail2
    int j;
    for (j = 0; j < ail2->nr; j++)
    {
        aiarray_add(appended_aiarray, ail2->interval_list[j].start, ail2->interval_list[j].end);
    }

    return appended_aiarray;
}
