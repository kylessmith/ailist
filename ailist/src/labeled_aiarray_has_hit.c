//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-------------------------------------------------------------------------------

void labeled_aiarray_has_hit_from_array(labeled_aiarray_t *ail, const long starts[], const long ends[],
                                        const char label_names[], int length, int label_str_len, uint8_t has_hit[])
{   /* Determine if hit is present for each query interval */

    // Iterate over query intervals
    int i;
    for (i = 0; i < length; i++)
    {
        // Determine interval to query
        uint32_t qs = starts[i];
        uint32_t qe = ends[i];
        char label_name[label_str_len + 1];
        slice_str2(label_names, label_name, (i*label_str_len), (i*label_str_len)+label_str_len);

        // Determine number of overlaps
        labeled_aiarray_query_has_hit(ail, has_hit, qs, qe, label_name);
    }

    return;
}

