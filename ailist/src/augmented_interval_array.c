//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------
#include "augmented_interval_array.h"

//-----------------------------------------------------------------------------

aiarray_t *aiarray_init(void)
{   /* Initialize aiarray_t object */

    // Initialize variables
    aiarray_t *ail = (aiarray_t *)malloc(sizeof(aiarray_t));
    ail->nr = 0;
    ail->mr = 64;
    ail->first = INT32_MAX;
    ail->last = 0;
	ail->maxE = NULL;
    ail->id_index = NULL;

    // Initialize arrays
    ail->interval_list = malloc(ail->mr * sizeof(interval_t));

    // Check if memory was allocated
    if (ail == NULL && ail->interval_list == NULL)
    {
        fprintf (stderr, "Out of memory!!! (init)\n");
        exit(1);
    }

	return ail;
}


//-----------------------------------------------------------------------------

void aiarray_destroy(aiarray_t *ail)
{   /* Free aiarray_t object */

    // Check that ail exists
	if (ail == 0)
    {
        return;
    }
	
    // Free intervals
	free(ail->interval_list);
	
    // Free maxE
	if (ail->maxE)
	{
		free(ail->maxE);
	}

    // Free indices
    if (ail->id_index)
	{
		free(ail->id_index);
	}

    // Free aiarray
	free(ail);
}

//-------------------------------------------------------------------------------

int aiarray_max_length(aiarray_t *ail)
{   /* Calculate maximum length */
	
    // Iterate over intervals and record length
    int length;
    int maximum = 0;
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        // Record length (excluding last position)
        length = ail->interval_list[i].end - ail->interval_list[i].start - 1;
	    maximum = MAX(maximum, length);
    }

    return maximum;
}


void aiarray_length_distribution(aiarray_t *ail, int distribution[])
{   /* Calculate length distribution */
    
    // Iterate over intervals and record length
    int length;
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        // Record length (excluding last position)
        length = ail->interval_list[i].end - ail->interval_list[i].start - 1;
        distribution[length] += 1;
    }

    return;
}


void display_array(aiarray_t *ail)
{
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        printf("(%d-%d) ", ail->interval_list[i].start, ail->interval_list[i].end);
    }
    printf("\n");
    return;
}
