//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

void labeled_aiarray_interval_coverage(labeled_aiarray_t *laia, int start, int end, const char *label_name, int coverage[])
{   /* Determine coverage for an interval */

    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Get coverage
        ailist_interval_coverage(p->ail, start, end, coverage);
    }

    return;
}


//-------------------------------------------------------------------------------


void labeled_aiarray_label_coverage(labeled_aiarray_t *laia, double coverage[], const char *label_name)
{   /* Calculate coverage for a label */
    
    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Get coverage
        ailist_coverage(p->ail, coverage);
    }

    return;
}


void labeled_aiarray_label_coverage_length(labeled_aiarray_t *laia, double coverage[], const char *label_name,
                                            int min_length, int max_length)
{   /* Calculate coverage for a label of a length */
    
    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Get coverage
        ailist_coverage_length(p->ail, coverage, min_length, max_length);
    }

    return;
}


void labeled_aiarray_label_bin_coverage(labeled_aiarray_t *laia, double coverage[], int bin_size, const char *label_name)
{   /* Calculate coverage within bins */

    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Get coverage
        ailist_bin_coverage(p->ail, coverage, bin_size);
    }

    return;
}


void labeled_aiarray_label_bin_coverage_length(labeled_aiarray_t *laia, double coverage[], int bin_size, const char *label_name,
                                                int min_length, int max_length)
{   /* Calculate coverage of intervals of a given length within bins */

    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Get coverage
        ailist_bin_coverage_length(p->ail, coverage, bin_size, min_length, max_length);
    }

    return;

}

//-------------------------------------------------------------------------------


void labeled_aiarray_label_midpoint_coverage(labeled_aiarray_t *laia, double coverage[], const char *label_name)
{   /* Calculate interval midpoint coverage */

    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Get coverage
        ailist_midpoint_coverage(p->ail, coverage);
    }

    return;
}


void labeled_aiarray_label_midpoint_coverage_length(labeled_aiarray_t *laia, double coverage[], const char *label_name,
                                                    int min_length, int max_length)
{   /* Calculate interval midpoint coverage */

    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Get coverage
        ailist_midpoint_coverage_length(p->ail, coverage, min_length, max_length);
    }

    return;
}