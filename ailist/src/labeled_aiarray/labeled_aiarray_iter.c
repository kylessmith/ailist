//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------


label_sorted_iter_t *label_sorted_iter_init(labeled_aiarray_t *laia, const char *label_name)
{   /* Initialize sorted iterator */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }
    
    // Get label
    int32_t t = get_label(laia, label_name);

    // Check if label present
    label_sorted_iter_t *iter = NULL;
    if (t != -1)
    {
        label_t *p = &laia->labels[t];

        // Initialize variables
        iter = (label_sorted_iter_t *)malloc(sizeof(label_sorted_iter_t));
        iter->ail_iter = ailist_sorted_iter_init(p->ail);
        iter->name = label_name;
        iter->intv = iter->ail_iter->intv;
    }

    return iter;

}


int label_sorted_iter_next(label_sorted_iter_t *iter)
{
    int result = ailist_sorted_iter_next(iter->ail_iter);
    iter->intv = iter->ail_iter->intv;

    return result;
}


void label_sorted_iter_destroy(label_sorted_iter_t *iter)
{
    // Check that ail exists
	if (iter == 0)
    {
        return;
    }

    ailist_sorted_iter_destroy(iter->ail_iter);
    free(iter);

    return;
}

//-----------------------------------------------------------------------------


labeled_aiarray_iter_t *labeled_aiarray_iter_init(labeled_aiarray_t *laia)
{   /* Initialize iterator */

    // Determine if constructed yet
    if (laia->is_constructed == 0)
    {
        labeled_aiarray_construct(laia, 20);
    }
    
    // Initialiize variables
    labeled_aiarray_iter_t *iter = (labeled_aiarray_iter_t *)malloc(sizeof(labeled_aiarray_iter_t));
    iter->laia = laia;
    iter->n = -1;
    iter->intv = labeled_aiarray_get_index(laia, 0);

    return iter;
}


int labeled_aiarray_iter_next(labeled_aiarray_iter_t *iter)
{   /* Increment iterator */

    // Increment
    iter->n++;
    if (iter->n >= iter->laia->total_nr)
    {
        return 0;
    }
    
    iter->intv = labeled_aiarray_get_index(iter->laia, iter->n);
    iter->name = iter->intv->name;

    return 1;
}


void labeled_aiarray_iter_destroy(labeled_aiarray_iter_t *iter)
{   /* Free iterator */

    // Check that ail exists
	if (iter == 0)
    {
        return;
    }

    free(iter);

    return;
}


//-----------------------------------------------------------------------------


labeled_aiarray_overlap_iter_t *labeled_aiarray_overlap_iter_init(labeled_aiarray_t *ref_laia, labeled_aiarray_t *query_laia)
{
    
    // Determine if constructed yet
    if (ref_laia->is_constructed == 0)
    {
        labeled_aiarray_construct(ref_laia, 20);
    }
    if (query_laia->is_constructed == 0)
    {
        labeled_aiarray_construct(query_laia, 20);
    }
    
    // Initialiize variables
    labeled_aiarray_overlap_iter_t *iter = (labeled_aiarray_overlap_iter_t *)malloc(sizeof(labeled_aiarray_overlap_iter_t));
    iter->ref_laia = ref_laia;
    iter->query_iter = labeled_aiarray_iter_init(query_laia);
    iter->overlaps = labeled_aiarray_init();

    return iter;
}


int labeled_aiarray_overlap_iter_next(labeled_aiarray_overlap_iter_t *iter)
{
    // Increment
    int result = labeled_aiarray_iter_next(iter->query_iter);
    if (result == 0)
    {
        return 0;
    }

    // Free previous overlaps
    labeled_aiarray_destroy(iter->overlaps);
    iter->overlaps = labeled_aiarray_init();
    labeled_aiarray_query(iter->ref_laia, iter->overlaps, iter->query_iter->intv->name, iter->query_iter->intv->i->start, iter->query_iter->intv->i->end);

    return 1;
}


void labeled_aiarray_overlap_iter_destroy(labeled_aiarray_overlap_iter_t *iter)
{   /* Free iterator */

    // Check that ail exists
	if (iter == 0)
    {
        return;
    }

    //labeled_aiarray_destroy(iter->overlaps);
    labeled_aiarray_iter_destroy(iter->query_iter);
    free(iter);

    return;
}