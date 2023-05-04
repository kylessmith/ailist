//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------


void labeled_aiarray_add_label(labeled_aiarray_t *laia, const char*label_name)
{	/* Expand and add label */

	//int ret_name;
    //int ret_label;

	khiter_t k;
	strhash_t *h = (strhash_t*)laia->label_lookup;

	k = kh_get(khStrInt, h, label_name);
	if (k == kh_end(h))
    {
		if (laia->n_labels == laia->max_labels)
        {
			EXPAND(laia->labels, laia->max_labels);
        }

		// Add label_name to label_map
        kh_name_set(khStrInt, h, label_name, laia->n_labels);
		laia->n_labels++;

		// Determine label code
		uint32_t t = kh_value(h, k);

		label_t *p = &laia->labels[t];
		p->name = strdup(label_name);
		p->ail = ailist_init();

	}

	return;

}


void labeled_aiarray_add(labeled_aiarray_t *laia, uint32_t s, uint32_t e, const char *label_name)
{
	// Check if start is greater than end
	if (s > e)
    {
        return;
    }

	// Add label to laia
	labeled_aiarray_add_label(laia, label_name);

	// Lookup label
	uint32_t t = get_label(laia, label_name);
	label_t *p = &laia->labels[t];

	// Add interval to laia
	ailist_add(p->ail, s, e, laia->total_nr);
	laia->total_nr++;

	// No longer constructed
	labeled_aiarray_deconstruct(laia);

	return;
}


void labeled_aiarray_multi_merge(labeled_aiarray_t *laia, labeled_aiarray_t **laia_array, int length)
{
	// Iterate over ail_array
	int i;
	for (i = 0; i < length; i++)
	{
		// Find label
		label_t p = laia_array[i]->labels[0];
		const char *label = p.name;
		
		// Add label
		int absent;
		khint_t k;
		strhash_t *h = (strhash_t*)laia->label_lookup;
		k = kh_put(khStrInt, h, label, &absent);
		if (laia->n_labels == laia->max_labels)
        {
			EXPAND(laia->labels, laia->max_labels);
        }
		kh_val(h, k) = laia->n_labels;
		laia->n_labels++;

		// Add interval_list
		int32_t kk = kh_val(h, k);
		laia->labels[kk] = laia_array[i]->labels[0];
		laia->total_nr = laia->total_nr + p.ail->nr;

	}

	// No longer constructed
	laia->is_constructed = 0;

	return;
}


void labeled_aiarray_from_array(labeled_aiarray_t *laia, const long starts[], const long ends[], const char label_names[], int length, int label_str_len)
{

    // Iterate over itervals and add
    int j = 0;
    int i;
    int total_length = length * label_str_len;
    for (i = 0; i < total_length; i+=label_str_len)
    {
        char label_name[label_str_len+1];
        slice_str(label_names, label_name, i, i+label_str_len);
        labeled_aiarray_add(laia, starts[j], ends[j], label_name);
        j++;
    }

	// No longer constructed
	laia->is_constructed = 0;

    return;
}


void labeled_aiarray_append(labeled_aiarray_t *laia, labeled_aiarray_t *laia2)
{   /* Add intervals from another labeled_aiarray */

	// Iterate over labels
	labeled_aiarray_iter_t *laia2_iter = labeled_aiarray_iter_init(laia2);

	while (labeled_aiarray_iter_next(laia2_iter))
	{

		labeled_aiarray_add(laia, laia2_iter->intv->i->start, laia2_iter->intv->i->end, laia2_iter->intv->name);
	}

	labeled_aiarray_iter_destroy(laia2_iter);

	// No longer constructed
	laia->is_constructed = 0;

    return;
}


labeled_aiarray_t *labeled_aiarray_copy(labeled_aiarray_t *laia)
{   /* Copy labeled_aiarray */

	// Initalize copy
    labeled_aiarray_t *laia_copy = labeled_aiarray_init();

	// Iterate over labels
	labeled_aiarray_iter_t *laia_iter = labeled_aiarray_iter_init(laia);

	while (labeled_aiarray_iter_next(laia_iter))
	{

		labeled_aiarray_add(laia_copy, laia_iter->intv->i->start, laia_iter->intv->i->end, laia_iter->intv->name);
	}

	labeled_aiarray_iter_destroy(laia_iter);

    return laia_copy;

}


void labeled_aiarray_append_ail(labeled_aiarray_t *laia, ailist_t *ail, const char *label_name)
{	/* Append AIList in labeled_aiarry */

	// Add intervals
	int i;
	for (i = 0; i < ail->nr; i++)
	{
		labeled_aiarray_add(laia, ail->interval_list[i].start, ail->interval_list[i].end, label_name);
	}

	return;
}


void labeled_aiarray_wrap_ail(labeled_aiarray_t *laia, ailist_t *ail, const char *label_name)
{	/* Wrap AIList in labeled_aiarry */

	// Add label
	labeled_aiarray_add_label(laia, label_name);
	
	// Wrap ailist_t
	int32_t t = get_label(laia, label_name);
	label_t *p = &laia->labels[t];
	ailist_destroy(p->ail);
	p->ail = ail;

	// Adjust ail id_value
	int i;
	for (i = 0; i < ail->nr; i++)
	{
		p->ail->interval_list[i].id_value = laia->total_nr + i;
	}

	// Adjust total_nr
	laia->total_nr = laia->total_nr + ail->nr;

	return;
}