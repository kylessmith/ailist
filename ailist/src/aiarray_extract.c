//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_array.h"

//-----------------------------------------------------------------------------

void aiarray_extract_starts(aiarray_t *ail, long starts[])
{   /* Extract start for aiarray */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        starts[i] = ail->interval_list[i].start;
    }

    return;
}


void aiarray_extract_ends(aiarray_t *ail, long ends[])
{   /* Extract end for aiarray */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        ends[i] = ail->interval_list[i].end;
    }

    return;
}



void aiarray_extract_ids(aiarray_t *ail, long ids[])
{   /* Extract id for aiarray */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        ids[i] = ail->interval_list[i].id_value;
    }

    return;
}