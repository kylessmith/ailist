//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------
#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

ailist_t *ailist_init(void)
{   /* Initialize ailist_t object */

    // Initialize variables
    ailist_t *ail = (ailist_t *)malloc(sizeof(ailist_t));
    ail->nr = 0;
    ail->mr = 64;
    ail->first = INT32_MAX;
    ail->last = 0;
	ail->maxE = NULL;

    // Initialize arrays
    ail->interval_list = malloc(ail->mr * sizeof(interval_t));

    // Check if memory was allocated
    if (ail == NULL && ail->interval_list == NULL)
    {
        fprintf (stderr, "Out of memory!!! (init)\n");
        exit(1);
    }

    // Assign values to NULL
    int i;
    for (i = 0; i < MAXC; i++)
    {
        ail->idxC[i] = 0;
        ail->lenC[i] = 0;
    }

	return ail;
}

//-----------------------------------------------------------------------------

void ailist_destroy(ailist_t *ail)
{   /* Free ailist_t object */

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

    // Free ailist
	free(ail);
}

//-------------------------------------------------------------------------------

int ailist_max_length(ailist_t *ail)
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


void ailist_length_distribution(ailist_t *ail, int distribution[])
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


void display_list(ailist_t *ail)
{
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        printf("(%d-%d) ", ail->interval_list[i].start, ail->interval_list[i].end);
    }
    printf("\n");
    return;
}


/* Driver program to test above functions*/
//int main(void)
//{ 
    
//    int x = 0;
//    int *y;
//    y = &x;

//    x = 3;
//    *y = 4;

//    printf("x: %d\n", x);
//    printf("y: %d\n", *y);
    
//    return 0;
//}