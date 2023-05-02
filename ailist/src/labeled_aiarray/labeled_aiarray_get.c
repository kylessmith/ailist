//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

labeled_aiarray_t *labeled_aiarray_get_label(labeled_aiarray_t *laia, const char *label_name)
{   /* Get intervals with label name */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }

    // Check index is initialized
    if (laia->id_index == NULL)
    {
        labeled_aiarray_cache_id(laia);
    }

    // Initialize interval
    labeled_aiarray_t *label_laia = labeled_aiarray_init();

    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        // Find intervals
        //labeled_aiarray_add_label(label_laia, laia->labels[t].name);
        int i;
        for (i = 0; i < laia->labels[t].ail->nr; i++)
        {
            labeled_aiarray_add(label_laia, laia->labels[t].ail->interval_list[i].start,
                                            laia->labels[t].ail->interval_list[i].end,
                                            laia->labels[t].name);
        }
    }
    
    return label_laia;
}


labeled_aiarray_t *labeled_aiarray_view_label(labeled_aiarray_t *laia, const char *label_name)
{   /* Get intervals with label name */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }

    // Check index is initialized
    if (laia->id_index == NULL)
    {
        labeled_aiarray_cache_id(laia);
    }

    // Initialize interval
    labeled_aiarray_t *label_laia = labeled_aiarray_init();

    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        // Find intervals
        labeled_aiarray_add_label(label_laia, laia->labels[t].name);
        labeled_aiarray_wrap_ail(label_laia, laia->labels[t].ail, laia->labels[t].name);
    }
    
    return label_laia;
}


overlap_label_index_t *labeled_aiarray_get_label_with_index(labeled_aiarray_t *laia, const char *label_name)
{   /* Get intervals with label name and original index */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }

    // Check index is initialized
    if (laia->id_index == NULL)
    {
        labeled_aiarray_cache_id(laia);
    }

    // Initialize interval
    overlap_label_index_t *label_laia = overlap_label_index_init();

    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    if (t != -1)
    {
        // Find intervals
        //labeled_aiarray_add_label(label_laia, laia->labels[t].name);
        int i;
        for (i = 0; i < laia->labels[t].ail->nr; i++)
        {
            overlap_label_index_add(label_laia, laia->labels[t].ail->interval_list[i],
                                            laia->labels[t].name);
        }
    }
    
    return label_laia;
}


labeled_aiarray_t *labeled_aiarray_get_label_array(labeled_aiarray_t *laia, const char label_names[], int n_labels, int label_str_len)
{   /* Get intervals with labels names from array */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }

    // Check index is initialized
    if (laia->id_index == NULL)
    {
        labeled_aiarray_cache_id(laia);
    }

    // Initialize interval
    labeled_aiarray_t *label_laia = labeled_aiarray_init();

    // Find intervals
    int j;
    for (j = 0; j < n_labels; j++)
    {
        // Find label name
        char label_name[label_str_len + 1];
        slice_str(label_names, label_name, (j*label_str_len), (j*label_str_len)+label_str_len);
        
        // Get label
        int32_t t = get_label(laia, label_name);

        // Check if label present
        if (t != -1)
        {

            // Find intervals
            //labeled_aiarray_add_label(label_laia, laia->labels[t].name);
            int i;
            for (i = 0; i < laia->labels[t].ail->nr; i++)
            {
                labeled_aiarray_add(label_laia, laia->labels[t].ail->interval_list[i].start,
                                                laia->labels[t].ail->interval_list[i].end,
                                                laia->labels[t].name);
            }
        }
    }
    
    
    return label_laia;
}


overlap_label_index_t *labeled_aiarray_get_label_array_with_index(labeled_aiarray_t *laia, const char label_names[], int n_labels, int label_str_len)
{   /* Get intervals with labels from array and original index */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }

    // Check index is initialized
    if (laia->id_index == NULL)
    {
        labeled_aiarray_cache_id(laia);
    }

    // Initialize interval
    overlap_label_index_t *label_intervals = overlap_label_index_init();

    // Find intervals
    int j;
    for (j = 0; j < n_labels; j++)
    {
        // Find label name
        char label_name[label_str_len + 1];
        slice_str(label_names, label_name, (j*label_str_len), (j*label_str_len)+label_str_len);

        // Get label
        int32_t t = get_label(laia, label_name);

        // Check if label present
        if (t != -1)
        {

            // Find intervals
            //labeled_aiarray_add_label(label_laia, laia->labels[t].name);
            int i;
            for (i = 0; i < laia->labels[t].ail->nr; i++)
            {
                overlap_label_index_add(label_intervals, laia->labels[t].ail->interval_list[i],
                                                laia->labels[t].name);
            }
        }
    }
    
    return label_intervals;
}


void labeled_aiarray_get_label_array_presence(labeled_aiarray_t *laia, const char label_names[], int n_labels, uint8_t index[], int label_str_len)
{   /* Determine if an index is of a label array */

    // Find intervals
    int i;
    for (i = 0; i < n_labels; i++)
    {
        // Find label name
        char label_name[label_str_len + 1];
        slice_str(label_names, label_name, (i*label_str_len), (i*label_str_len)+label_str_len);

        // Get label
        int32_t t = get_label(laia, label_name);

        // Check if label present
        if (t != -1)
        {
            // Find intervals
            //labeled_aiarray_add_label(label_laia, laia->labels[t].name);
            int i;
            for (i = 0; i < laia->labels[t].ail->nr; i++)
            {
                index[laia->labels[t].ail->interval_list[i].id_value] = 1;
            }
        }
    }

    return;
}