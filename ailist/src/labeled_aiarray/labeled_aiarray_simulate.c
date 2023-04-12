//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------


void labeled_aiarray_simulate(labeled_aiarray_t *laia, labeled_aiarray_t *sim_laia)
{	/* Simulate intervals */

	// Iterate over labels
	int t;
	for (t = 0; t < laia->n_labels; t++)
	{
		// Get label
		label_t *p = &laia->labels[t];
		const char *label_name = p->name;

		// Add label
		labeled_aiarray_add_label(sim_laia, label_name);
		int32_t t2 = get_label(sim_laia, label_name);
		label_t *p2 = &sim_laia->labels[t2];

		// Simulate
		ailist_simulate(p->ail, p2->ail, p->ail->nr);

		// Adjust total regions
		sim_laia->total_nr = sim_laia->total_nr + p2->ail->nr;
	}

	// Re-order
	labeled_aiarray_order_sort(sim_laia);

	return;
}