//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------


void labeled_aiarray_construct(labeled_aiarray_t *laia, int cLen)
{   //New continueous memory?    

    //#pragma omp parallel for shared(ail)
    int i;
	for(i = 0; i < laia->n_labels; i++)
    {
		//1. Decomposition
		label_t *p = &laia->labels[i];
		ailist_construct(p->ail, cLen);
	}

	// Record
	laia->is_constructed = 1;
	laia->id_index = NULL;

    return;
}

int labeled_aiarray_validate_construction(labeled_aiarray_t *laia)
{
	int res;
	int i;
	for(i = 0; i < laia->n_labels; i++)
    {
		//1. Decomposition
		label_t *p = &laia->labels[i];
		res = ailist_validate_construction(p->ail);

		if (res == 0)
		{
			return 0;
		}
	}

	return 1;
}

void labeled_aiarray_deconstruct(labeled_aiarray_t *laia)
{
	if (laia->id_index)
    {
        free(laia->id_index);
		laia->id_index = NULL;
    }

	laia->is_constructed = 0;
}