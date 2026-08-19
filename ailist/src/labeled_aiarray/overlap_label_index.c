//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------


overlap_label_index_t *overlap_label_index_init(void)
{   /* Initialize overlap_index */
    
    // Initialize variables
    overlap_label_index_t *oi = (overlap_label_index_t *)malloc(sizeof(overlap_label_index_t));
    if (oi == NULL)
    {
        printf("Memory allocation failed");
        exit(1); // exit the program
    }
    oi->size = 0;
    oi->max_size = 64;
    oi->indices = (long *)malloc(sizeof(long) * 64);
    if (oi->indices == NULL)
    {
        printf("Memory allocation failed");
        exit(1); // exit the program
    }
    oi->laia = labeled_aiarray_init();

    return oi;
}


void overlap_label_index_destroy(overlap_label_index_t *oi)
{   /* Free overlap_label_index memory */

    labeled_aiarray_destroy(oi->laia);
    free(oi->indices);
    free(oi);

    return;
}


void overlap_label_index_add(overlap_label_index_t *oi, interval_t i, const char *label_name)
{   /* Add interval to overlap_label_index */

    // Check if size needs to be increased
    push_indices(oi, i.id_value);

    // Add new indices
    labeled_aiarray_add(oi->laia, i.start, i.end, label_name);

    return;
}


void overlap_label_index_wrap_ail(overlap_label_index_t * oi, ailist_t *ail, const char *label_name)
{
    // labeled_aiarray_wrap_ail refuses (and does NOT take ownership of `ail`) when
    // the label already exists. Skip entirely in that case so oi->indices stays in
    // lockstep with oi->laia.
    if (get_label(oi->laia, label_name) != -1)
    {
        fprintf(stderr, "overlap_label_index_wrap_ail: label '%s' already exists; skipping\n", label_name);
        return;
    }

    // Record each interval's ORIGINAL id_value before wrap_ail renumbers them in
    // place (it overwrites id_value with total_nr + j). This mirrors the add path,
    // where oi->indices stores the matched interval's original id. push_indices grows
    // oi->indices by doubling (was a linear +64 realloc here).
    int64_t j;
    for (j = 0; j < ail->nr; j++)
    {
        push_indices(oi, ail->interval_list[j].id_value);
    }

    // Transfer ownership of `ail` into oi->laia (renumbers ail's id_values).
    labeled_aiarray_wrap_ail(oi->laia, ail, label_name);

    return;
}