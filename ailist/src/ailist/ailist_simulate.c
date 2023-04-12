//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

void ailist_simulate(ailist_t *ail, ailist_t *simulation, int n)
{   /* Merge intervals in constructed ailist_t object */

    // Set bounds
    int maximum = ail->last;
    int minimum = ail->first;
    
    // Set random seed
	srand(time(NULL));

    int k;
    for (k = 0; k < n; k++)
    {
        // Randomly assign length
        int i = rand() % ail->nr;
        int length = ail->interval_list[i].end - ail->interval_list[i].start;

        // Randomly assign start
        int start = (rand() % ((maximum - length) - minimum + 1)) + minimum;
        int end = start + length;

        // Add simulated interval
        ailist_add(simulation, start, end, k);
    }

    return;
   
}