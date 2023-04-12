//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

void ailist_extract_starts(ailist_t *ail, long starts[])
{   /* Extract start for ailist */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        starts[i] = ail->interval_list[i].start;
    }

    return;
}


void ailist_extract_ends(ailist_t *ail, long ends[])
{   /* Extract end for ailist */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        ends[i] = ail->interval_list[i].end;
    }

    return;
}


void ailist_extract_ids(ailist_t *ail, long ids[])
{   /* Extract index for ailist */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        ids[i] = ail->interval_list[i].id_value;
    }

    return;
}