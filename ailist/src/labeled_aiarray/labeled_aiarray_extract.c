//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

void labeled_aiarray_extract_starts(labeled_aiarray_t *laia, long starts[])
{   /* Extract start for labeled_aiarray */

    int i;
    for (i = 0; i < laia->total_nr; i++)
    {
        labeled_interval_t *laia_i = labeled_aiarray_get_index(laia, i);
        starts[i] = laia_i->i->start;
    }

    return;
}


void labeled_aiarray_extract_ends(labeled_aiarray_t *laia, long ends[])
{   /* Extract end for labeled_aiarray */

    int i;
    for (i = 0; i < laia->total_nr; i++)
    {
        labeled_interval_t *laia_i = labeled_aiarray_get_index(laia, i);
        ends[i] = laia_i->i->end;
    }

    return;
}



void labeled_aiarray_extract_ids(labeled_aiarray_t *laia, long ids[])
{   /* Extract id for labeled_aiarray */

    int i;
    for (i = 0; i < laia->total_nr; i++)
    {
        labeled_interval_t *laia_i = labeled_aiarray_get_index(laia, i);
        ids[i] = laia_i->i->id_value;
    }

    return;
}