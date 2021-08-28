//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

void labeled_aiarray_extract_starts(labeled_aiarray_t *ail, long starts[])
{   /* Extract start for labeled_aiarray */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        starts[i] = ail->interval_list[i].start;
    }

    return;
}


void labeled_aiarray_extract_ends(labeled_aiarray_t *ail, long ends[])
{   /* Extract end for labeled_aiarray */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        ends[i] = ail->interval_list[i].end;
    }

    return;
}



void labeled_aiarray_extract_ids(labeled_aiarray_t *ail, long ids[])
{   /* Extract id for labeled_aiarray */

    int i;
    for (i = 0; i < ail->nr; i++)
    {
        ids[i] = ail->interval_list[i].id_value;
    }

    return;
}