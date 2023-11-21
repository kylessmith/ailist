//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------


int *get_comp_bounds(ailist_t *ail)
{   /* Get component index */

    int *idxC = &ail->idxC[0];
    int *comps_bounds = (int *)malloc((ail->nc + 1) * sizeof(int));
    int i;
    for (i = 0; i < ail->nc; i++)
    {
        comps_bounds[i] = idxC[i];
    }

    comps_bounds[ail->nc] = ail->nr;

    return comps_bounds;
}


ailist_sorted_iter_t *ailist_sorted_iter_init(ailist_t *ail)
{

    // Initialize variables
    ailist_sorted_iter_t *iter = (ailist_sorted_iter_t *)malloc(sizeof(ailist_sorted_iter_t));
    iter->ail = ail;
    iter->comp_bounds = get_comp_bounds(ail);
    iter->nc = ail->nc;
    iter->comp_used = (int *)malloc((iter->nc + 1) * sizeof(int));
    int i;
    for (i = 0; i < iter->nc + 1; i++)
    {
        iter->comp_used[i] = iter->comp_bounds[i];
    }
    //memcpy(&iter->comp_used, &iter->comp_bounds, sizeof(int));
    iter->intv = &ail->interval_list[0];
    iter->n = -1;

    return iter;
}


int ailist_sorted_iter_next(ailist_sorted_iter_t *iter)
{
    // Increment position
    iter->n++;
    if (iter->n >= iter->ail->nr)
    {
        return 0;
    }

    int selected_comp = 0;
    // Iterate over other components
    int position;
    // Iterate over components
    int j;
    for (j = 0; j < iter->nc; j++)
    {
        // If position is available, assign next interval
        if (iter->comp_used[j] != iter->comp_bounds[j + 1])
        {
            position = iter->comp_used[j];
            iter->intv = &iter->ail->interval_list[position];
            break;
        }
    }

    for (j = 0; j < iter->nc; j++)
    {
        // Check component has intervals left to investigate
        if (iter->comp_used[j] == iter->comp_bounds[j + 1])
        {
            continue;
        }

        // Determine position
        position = iter->comp_used[j];
        // Check for lower start
        if (iter->ail->interval_list[position].start < iter->intv->start)
        {
            iter->intv = &iter->ail->interval_list[position];
            selected_comp = j;
        }

    }

     // Increment label_comp_counter for selected comp
    iter->comp_used[selected_comp] = iter->comp_used[selected_comp] + 1;

    return 1;
}


void ailist_sorted_iter_destroy(ailist_sorted_iter_t *iter)
{
    // Check that ail exists
	if (iter == 0)
    {
        return;
    }

    // Free ail
	//if (iter->ail)
	//{
        //free(iter->ail);
    //}

    // Free intv
	//if (iter->intv)
	//{
        //free(iter->intv);
    //}
    
    // Free label_comp_bounds
	//if (iter->label_comp_bounds)
	//{
        //free(iter->label_comp_bounds);
    //}

    // Free label_comp_used
	//if (iter->label_comp_used)
	//{
        //free(iter->label_comp_used);
    //}

    free(iter);

    return;
}

//-----------------------------------------------------------------------------
