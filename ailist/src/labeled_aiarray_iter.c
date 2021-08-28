//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------


int *get_label_comp_bounds(labeled_aiarray_t *ail, int label)
{   /* Get component index for label */

    int label_start = get_label_index(ail, label);
    int *idxC = &ail->idxC[label * 10];
    int n_comps = ail->nc[label];
    int *comps_bounds = malloc((n_comps + 1) * sizeof(int));
    int i;
    for (i = 0; i < n_comps; i++)
    {
        comps_bounds[i] = label_start + idxC[i];
    }

    //comps_bounds[n_comps] = get_label_index(ail, label + 1);
    if (label + 1 >= ail->nl)
    {
        comps_bounds[n_comps] = ail->nr;
    } else
    {
        comps_bounds[n_comps] = get_label_index(ail, label + 1);
    }

    return comps_bounds;
}


label_sorted_iter_t *iter_init(labeled_aiarray_t *ail, const char *label_name)
{

    // Initialize variables
    label_sorted_iter_t *iter = (label_sorted_iter_t *)malloc(sizeof(label_sorted_iter_t));
    iter->ail = ail;
    iter->label = query_label_map(ail, label_name);
    iter->label_comp_bounds = get_label_comp_bounds(ail, iter->label);
    iter->nc = ail->nc[iter->label];
    iter->label_comp_used = malloc(iter->nc+1 * sizeof(int));
    memcpy(&iter->label_comp_used, &iter->label_comp_bounds, sizeof(int));
    iter->label_start = get_label_index(ail, iter->label);
    iter->label_end = get_label_index(ail, iter->label + 1);
    iter->intv = &ail->interval_list[iter->label_start];
    iter->n = -1;

    return iter;
}


int iter_next(label_sorted_iter_t *iter)
{
    // Increment position
    iter->n++;
    if (iter->n >= iter->label_end - iter->label_start)
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
        if (iter->label_comp_used[j] != iter->label_comp_bounds[j + 1])
        {
            position = iter->label_comp_used[j];
            iter->intv = &iter->ail->interval_list[position];
            break;
        }
    }

    for (j = 0; j < iter->nc; j++)
    {
        // Check component has intervals left to investigate
        if (iter->label_comp_used[j] == iter->label_comp_bounds[j + 1])
        {
            continue;
        }

        // Determine position
        position = iter->label_comp_used[j];
        // Check for lower start
        if (iter->ail->interval_list[position].start < iter->intv->start)
        {
            iter->intv = &iter->ail->interval_list[position];
            selected_comp = j;
        }

        // Increment label_comp_counter for selected comp
        iter->label_comp_used[selected_comp] = iter->label_comp_used[selected_comp] + 1;
    }

    return 1;
}


void iter_destroy(label_sorted_iter_t *iter)
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
