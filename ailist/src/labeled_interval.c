//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_interval.h"

//-----------------------------------------------------------------------------

labeled_interval_t *labeled_interval_init(uint32_t start, uint32_t end, int32_t id_value, uint16_t label)
{   /* Create labeled_interval_t */

    // Initialize interval
    labeled_interval_t *i = (labeled_interval_t *)malloc(sizeof(labeled_interval_t));

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
    i->label = label;

	return i;
}
