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

		// Determine label code: the value just assigned, taken before the increment.
		// (kh_name_set is a non-hygienic macro that also reassigns the local `k` to
		// the inserted bucket, so kh_value(h, k) would work too; reading n_labels
		// directly avoids depending on that macro side effect.)
		uint32_t t = laia->n_labels;
		laia->n_labels++;

		label_t *p = &laia->labels[t];
		p->name = strdup(label_name);
		p->ail = ailist_init();
		p->is_view = 0;

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
	// Iterate over ail_array (single-label inputs assumed: only labels[0] is merged)
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

		if (absent)
		{
			// New label: take ownership of the source's label struct
			if (laia->n_labels == laia->max_labels)
			{
				EXPAND(laia->labels, laia->max_labels);
			}
			kh_val(h, k) = laia->n_labels;
			int32_t kk = laia->n_labels;
			laia->n_labels++;

			laia->labels[kk] = laia_array[i]->labels[0];

			// Renumber transferred interval ids so global ids remain contiguous
			// in [0, total_nr) — cache_id indexes id_index[id_value] and assumes this.
			{
				int64_t base = laia->total_nr;
				int64_t j;
				for (j = 0; j < laia->labels[kk].ail->nr; j++)
				{
					laia->labels[kk].ail->interval_list[j].id_value = (int32_t)(base + j);
				}
			}
			laia->total_nr = laia->total_nr + p.ail->nr;

			// Ownership transferred to laia; clear the source so its eventual
			// destroy does not double-free the shared ail/name.
			laia_array[i]->labels[0].ail = NULL;
			laia_array[i]->labels[0].name = NULL;
		}
		else
		{
			// Label already present (duplicate across inputs): append the source
			// intervals into the existing ail, then consume the source label.
			// Without this guard the original code overwrote kh_val with a new
			// index, orphaning the existing label slot (leaking its ail) and
			// leaving the hash pointing only at the new copy.
			int32_t kk = kh_val(h, k);
			ailist_t *dst = laia->labels[kk].ail;
			int64_t j;
			for (j = 0; j < p.ail->nr; j++)
			{
				ailist_add(dst, p.ail->interval_list[j].start,
				                p.ail->interval_list[j].end,
				                laia->total_nr + j);
			}
			laia->total_nr = laia->total_nr + p.ail->nr;

			// Source label consumed (intervals copied out); free its data and
			// clear it so its destroy is a no-op.
			ailist_destroy(laia_array[i]->labels[0].ail);
			free((char*)laia_array[i]->labels[0].name);
			laia_array[i]->labels[0].ail = NULL;
			laia_array[i]->labels[0].name = NULL;
		}
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
{	/* Wrap AIList in labeled_aiarry.
	   Ownership of `ail` transfers to `laia`; the caller must NOT free `ail`
	   afterward (it will be freed by labeled_aiarray_destroy). */

	// Refuse to overwrite an existing label: doing so would destroy that label's
	// current intervals. Wrapping is only valid into a fresh label.
	if (get_label(laia, label_name) != -1)
	{
		fprintf(stderr, "labeled_aiarray_wrap_ail: label '%s' already exists; not overwriting\n", label_name);
		return;
	}

	// Add label
	labeled_aiarray_add_label(laia, label_name);
	
	// Wrap ailist_t
	int32_t t = get_label(laia, label_name);
	label_t *p = &laia->labels[t];
	ailist_destroy(p->ail);
	p->ail = ail;

	// Adjust ail id_value
	int64_t i;
	for (i = 0; i < ail->nr; i++)
	{
		p->ail->interval_list[i].id_value = laia->total_nr + i;
	}

	// Adjust total_nr
	laia->total_nr = laia->total_nr + ail->nr;

	return;
}