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

void labeled_aiarray_add(labeled_aiarray_t *ail, uint32_t start, uint32_t end, const char *label_name)
{   /* Add interval to aiarray_t object */

	// If start is greater than end, invalid interval
    if (start > end)
    {
        return;
    }

    // Determine if
    int ret_name;
    int ret_label;
    //khint_t ks;
	khiter_t ks;
    khiter_t ki;
	strhash_t *hs = (strhash_t*)ail->label_map;
    inthash_t *hi = (inthash_t*)ail->rev_label_map;
	//ks = kh_put(khStrInt, hs, label_name, &ret_name);
    ks = kh_get(khStrInt, hs, label_name);
	if (ks == kh_end(hs))
    {
		// Add label_name to label_map
        ret_name = kh_name_set(khStrInt, hs, label_name, ail->nl);
        //ks = kh_put(khStrInt, hs, label_name, &ret_name);
        //kh_value(hs, ks) = ail->nl;		
		//kh_key(hs, ks) = label_name;

        // Add label to label_map
        //uint16_t n_labels = (uint16_t)ail->nl;
        ret_label = kh_label_set(khIntStr, hi, ail->nl, label_name);
        //ki = kh_put(khIntStr, hi, ail->nl, &ret_label);
        //kh_value(hi, ki) = label_name;
        //kh_key(hi, ki) = ail->nl;

        //printf("   adding key:%s, val:%lld\n", label_name, ail->nl);
	}

    //printf("   label_name:%s, present:%d\n", label_name, name_absent);

    // Determine label code
    uint16_t label = kh_value(hs, ks);

    // If max region reached, expand array
	if (ail->nr + 1 == ail->mr)
    {
		EXPAND(ail->interval_list, ail->mr);
    }
    // If max label reached, expand array
	while (label >= ail->ml)
    {
        uint32_t max_labels = ail->ml;
        // Record max labels
		EXPAND(ail->label_count, ail->ml);
        memset(&ail->label_count[ail->nl], 0, (ail->ml - ail->nl) * sizeof(uint32_t));

        // Reset max labels because EXPAND increments
        ail->ml = max_labels;
        EXPAND(ail->first, ail->ml);
        // Set new values to INT32_MAX
        memset(&ail->first[ail->nl], INT32_MAX, (ail->ml - ail->nl) * sizeof(uint32_t));

        // Reset max labels because EXPAND increments
        ail->ml = max_labels;
        EXPAND(ail->last, ail->ml);
        // Set new values to 0
        memset(&ail->last[ail->nl], 0, (ail->ml - ail->nl) * sizeof(uint32_t));
    }

    // Update first
    ail->first[label] = MIN(ail->first[label], start);
    // Update last
    ail->last[label] = MAX(ail->last[label], end);

    // Determine if label is new
    if (label >= ail->nl)
    {
        ail->nl = label + 1;
    }

    // Increment label_index as running count
    // Once constructed, becomes index
    ail->label_count[label]++;

    // Set new interval values
	labeled_interval_t *i = &ail->interval_list[ail->nr++];
	i->start = start;
	i->end = end;
    i->id_value = ail->nr - 1;
    i->label = label;

	return;
}


void labeled_aiarray_from_array(labeled_aiarray_t *ail, const long starts[], const long ends[], const char label_names[], int length, int label_str_len)
{
    
    //const size_t len = strlen(label_names);
    //const size_t len = sizeof(label_names) / sizeof(label_names[0]);
    //printf("   strlen:%zu\n", len);

    // Iterate over itervals and add
    int j = 0;
    int i;
    int total_length = length * label_str_len;
    for (i = 0; i < total_length; i+=label_str_len)
    {
        //char label_name[len + 1];
        char label_name[label_str_len+1];
        slice_str2(label_names, label_name, i, i+label_str_len);
        //const char *final_name = label_name;
        labeled_aiarray_add(ail, starts[j], ends[j], label_name);
        j++;
        //printf("start:%d, end:%d, label:%d, label_name:%s\n", ail->interval_list[i].start, ail->interval_list[i].end, ail->interval_list[i].label, label_name);
        //display_label_map(ail);
        //printf("\n\n");
    }

    return;
}


void labeled_aiarray_append(labeled_aiarray_t *ail, labeled_aiarray_t *ail2)
{   /* Add intervals from another labeled_aiarray */
    
    int i;
    for (i = 0; i < ail2->nr; i++)
    {
        const char *label_name = query_rev_label_map(ail2, ail2->interval_list[i].label);
        labeled_aiarray_add(ail, ail2->interval_list[i].start, ail2->interval_list[i].end, label_name);
    }

    return;
}