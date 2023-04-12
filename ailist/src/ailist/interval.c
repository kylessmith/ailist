//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "interval.h"

//-----------------------------------------------------------------------------

interval_t *interval_init(uint32_t start, uint32_t end, int32_t id_value)
{   /* Create interval_t */

    // Initialize interval
    interval_t *i = (interval_t *)malloc(sizeof(interval_t));

    // Check if memory was allocated
    if (i == NULL)
    {
        fprintf (stderr, "Out of memory!!! (init)\n");
        exit(1);
    }

    // Set new interval values
    i->start = start;
	i->end = end;
    i->id_value = id_value;

	return i;
}
