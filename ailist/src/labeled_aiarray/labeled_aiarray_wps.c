//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-------------------------------------------------------------------------------

void labeled_aiarray_label_wps(labeled_aiarray_t *laia, double wps[], uint32_t protection, const char *label_name)
{   /* Calculate Window Protection Score for a label */
    
    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Get nhits
        ailist_wps(p->ail, wps, protection);
    }

    return;
}


void labeled_aiarray_label_wps_length(labeled_aiarray_t *laia, double wps[], uint32_t protection, int min_length, int max_length, const char *label_name)
{   /* Calculate Window Protection Score for a label of a length */
    
    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Get nhits
        ailist_wps_length(p->ail, wps, protection, min_length, max_length);
    }

    return;
}
