//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

//const int khStrInt = 33;
//KHASH_MAP_INIT_STR(khStrInt, int32_t)
//typedef khash_t(khStrInt) strhash_t;
//const int khIntStr = 32;
//KHASH_MAP_INIT_INT(khIntStr, char*)
//typedef khash_t(khIntStr) inthash_t;

//-----------------------------------------------------------------------------

int label_is_present(labeled_aiarray_t *ail, const char *label_name)
{   /* Determine if label_name is in array */

    int name_absent;
    strhash_t *h = (strhash_t*)ail->label_map;
    int k = kh_put(khStrInt, h, label_name, &name_absent);
    if (name_absent)
    {
        return 0;
    }

    return 1;
}


uint16_t query_label_map(labeled_aiarray_t *ail, const char *label_name)
{   /* Query label map for label name */
    
    int name_absent;
    strhash_t *h = (strhash_t*)ail->label_map;
    int k = kh_put(khStrInt, h, label_name, &name_absent);
    if (name_absent)
    {
        printf("KeyError\n");
    }

    uint16_t label = kh_val(h, k);

    return label;
}


const char *query_rev_label_map(labeled_aiarray_t *ail, uint16_t label)
{   /* Query rev_label_map for label */
    
    int label_absent;
    inthash_t *h = (inthash_t*)ail->rev_label_map;
    int k = kh_put(khIntStr, h, label, &label_absent);
    if (label_absent)
    {
        printf("KeyError\n");
    }
    const char *label_name = kh_val(h, k);

    return label_name;
}


labeled_aiarray_t *get_label(labeled_aiarray_t *ail, const char *label_name)
{   /* Get intervals with label name */

    // Initialize interval
    labeled_aiarray_t *label_intervals = labeled_aiarray_init();

    // Check that label is present
    if (label_is_present(ail, label_name) == 0)
    {
        return label_intervals;
    }

    // Determine label
    uint16_t label = query_label_map(ail, label_name);

    // Find intervals
    int i;
    if (ail->label_count[label] != 0)
    {
        for (i = get_label_index(ail, label); i < get_label_index(ail, label + 1); i++)
        {
            labeled_aiarray_add(label_intervals, ail->interval_list[i].start, ail->interval_list[i].end, label_name);
        }
    }
    
    return label_intervals;
}


overlap_label_index_t *get_label_with_index(labeled_aiarray_t *ail, const char *label_name)
{   /* Get intervals with label name and original index */

    // Initialize interval
    overlap_label_index_t *label_intervals = overlap_label_index_init();

    // Check that label is present
    if (label_is_present(ail, label_name) == 0)
    {
        return label_intervals;
    }

    // Determine label
    uint16_t label = query_label_map(ail, label_name);

    // Find intervals
    int i;
    if (ail->label_count[label] != 0)
    {
        for (i = get_label_index(ail, label); i < get_label_index(ail, label + 1); i++)
        {
            overlap_label_index_add(label_intervals, ail->interval_list[i], label_name);
        }
    }
    
    return label_intervals;
}


labeled_aiarray_t *get_label_array(labeled_aiarray_t *ail, const char *label_names[], int length)
{   /* Get intervals with labels names from array */

    // Initialize interval
    labeled_aiarray_t *label_intervals = labeled_aiarray_init();

    // Find intervals
    int j;
    for (j = 0; j < length; j++)
    {
        // Find label name
        const char *label_name = label_names[j];
        
        // Check that label is present
        if (label_is_present(ail, label_name) == 0)
        {
            return label_intervals;
        }

        // Determine label
        uint16_t label = query_label_map(ail, label_name);

        // Find intervals
        int i;
        if (ail->label_count[label] != 0)
        {
            for (i = get_label_index(ail, label); i < get_label_index(ail, label + 1); i++)
            {
                labeled_aiarray_add(label_intervals, ail->interval_list[i].start, ail->interval_list[i].end, label_name);
            }
        }
    }
    
    
    return label_intervals;
}


overlap_label_index_t *get_label_array_with_index(labeled_aiarray_t *ail, const char label_names[], int n_labels, int label_str_len)
{   /* Get intervals with labels from array and original index */

    // Initialize interval
    overlap_label_index_t *label_intervals = overlap_label_index_init();

    // Find intervals
    int j;
    for (j = 0; j < n_labels; j++)
    {
        // Find label name
        char label_name[label_str_len + 1];
        slice_str2(label_names, label_name, (j*label_str_len), (j*label_str_len)+label_str_len);

        // Check that label is present
        if (label_is_present(ail, label_name) == 0)
        {
            return label_intervals;
        }

        // Determine label
        uint16_t label = query_label_map(ail, label_name);

        // Find intervals
        int label_start;
        int label_end;
        int i;

        if (ail->label_count[label] != 0)
        {
            label_start = get_label_index(ail, label);
            if (label + 1 > ail->nl)
            {
                label_end = ail->nr;
            } else {
                label_end = label_start + ail->label_count[label];
            }

            for (i = label_start; i < label_end; i++)
            {
                overlap_label_index_add(label_intervals, ail->interval_list[i], label_name);
            }
        }
    }
    
    
    return label_intervals;
}


int get_label_index(labeled_aiarray_t *ail, int label)
{   /* Get index start of label */

    // Initialize position
    int count = 0;

    // Iterate over labels
    int i;
    for (i = 0; i < label; i++)
    {
        count = count + ail->label_count[i];
    }

    return count;
}


void get_label_index_array(labeled_aiarray_t *ail, int *label_index)
{   /* Determine label indices */

    // Initialize position
    int count = 0;

    // Iterate over labels
    int i;
    for (i = 0; i < ail->nl; i++)
    {
        label_index[i] = count;
        count = count + ail->label_count[i];
    }

    return;
}


void get_label_array_ids(labeled_aiarray_t *ail, const char *label_names[], int n_labels, long index[])
{   /* Get ids for labels in a label array */

    // Find intervals
    int index_i = 0;
    int i;
    for (i = 0; i < n_labels; i++)
    {
        // Find label name
        const char *label_name = label_names[i];

        // Check that label is present
        if (label_is_present(ail, label_name) == 0)
        {
            return;
        }

        // Determine label
        uint16_t label = query_label_map(ail, label_name);

        // Find intervals
        int label_start;
        int label_end;
        int j;

        if (ail->label_count[label] != 0)
        {
            label_start = get_label_index(ail, label);
            if (label + 1 > ail->nl)
            {
                label_end = ail->nr;
            } else {
                label_end = label_start + ail->label_count[label];
            }

            for (j = label_start; j < label_end; j++)
            {
                index[index_i] = ail->interval_list[j].id_value;
                index_i++;
            }
        }
    }

    return;
}


void get_label_array_presence(labeled_aiarray_t *ail, const char label_names[], int n_labels, uint8_t index[], int label_str_len)
{   /* Determine if an index is of a label array */

    // Find intervals
    int i;
    for (i = 0; i < n_labels; i++)
    {
        // Find label name
        char label_name[label_str_len + 1];
        slice_str2(label_names, label_name, (i*label_str_len), (i*label_str_len)+label_str_len);

        // Check that label is present
        if (label_is_present(ail, label_name) == 0)
        {
            return;
        }

        // Determine label
        uint16_t label = query_label_map(ail, label_name);

        // Find intervals
        int label_start;
        int label_end;
        int j;

        if (ail->label_count[label] != 0)
        {
            label_start = get_label_index(ail, label);
            if (label + 1 > ail->nl)
            {
                label_end = ail->nr;
            } else {
                label_end = label_start + ail->label_count[label];
            }

            for (j = label_start; j < label_end; j++)
            {
                index[ail->interval_list[j].id_value] = 1;
            }
        }
    }

    return;
}