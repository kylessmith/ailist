//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------


labeled_aiarray_t *labeled_aiarray_init(void)
{   /* Initialize labeled_aiarray */

    // Reserve memory
    labeled_aiarray_t *laia = malloc(1 * sizeof(labeled_aiarray_t));
    if (laia == NULL)
    {
        fprintf (stderr, "Out of memory!!! (init)\n");
        exit(1);
    }

    // Set attributes
	laia->label_lookup = kh_init(khStrInt);
	laia->n_labels = 0;
	laia->max_labels = 32;
	laia->labels = malloc(laia->max_labels * sizeof(label_t));
    laia->total_nr = 0;
    laia->first = NULL;
    laia->last = NULL;
    laia->id_index = NULL;
    laia->is_constructed = 0;

    // Check if memory was allocated
    if (laia->label_lookup == NULL || laia->labels == NULL)
    {
        fprintf (stderr, "Out of memory!!! (init)\n");
        exit(1);
    }

	return laia;
}


labeled_interval_t *labeled_interval_init(interval_t *i, const char* label_name)
{
    labeled_interval_t *li = malloc(1 * sizeof(labeled_interval_t));
    li->i = i;
    li->name = label_name;

    return li;
}


void labeled_aiarray_destroy(labeled_aiarray_t *laia)
{   /* Free labeled_aiarray */
	
    int32_t i;
	if (laia == 0) 
    {
        return;
    }

	for (i = 0; i < laia->n_labels; ++i)
    {
		free((char*)laia->labels[i].name);
		// Borrowed (view) ails are owned elsewhere; do not free them
		if (laia->labels[i].is_view == 0)
		{
			ailist_destroy(laia->labels[i].ail);
		}
	}
	free(laia->labels);
	kh_destroy(khStrInt, (strhash_t*)laia->label_lookup);

    if (laia->first)
    {
        free(laia->first);
    }

    if (laia->last)
    {
        free(laia->last);
    }

    if (laia->id_index)
    {
        free(laia->id_index);
    }

	free(laia);
}


//-----------------------------------------------------------------------------
// labeled_aiarray utility functions
//=============================================================================

int32_t get_label(const labeled_aiarray_t *laia, const char *label)
{   /* Return index for given label */
	
    khint_t k;
	strhash_t *h = (strhash_t*)laia->label_lookup;
	k = kh_get(khStrInt, h, label);
    
	return k == kh_end(h)? -1 : kh_val(h, k);
}


void slice_str(const char *str, char *buffer, size_t start, size_t end)
{   /* Extract strings from array */
    
    size_t j = 0;
    size_t i;
    for (i = start; i < end; ++i)
    {
        if (str[i]=='\0')
        {
            break;
        }

        buffer[j++] = str[i];
    }
    buffer[j] = '\0';
    //strncpy(buffer, str + start, end - start);
}


void labeled_aiarray_print(labeled_aiarray_t *laia)
{   /* Print labeled_aiarray */

    int t;
    for (t = 0; t < laia->n_labels; t++)
    {
        label_t *p = &laia->labels[t];
        ailist_t *ail = p->ail;
        int i;
        for (i = 0; i < ail->nr; i++)
        {
            printf("(%s, %d-%d)\n", p->name, ail->interval_list[i].start, ail->interval_list[i].end);
        }
    }

    return;
}


int labeled_aiarray_max_length(labeled_aiarray_t *laia)
{   /* Record maximum length */

    // Iterate over intervals and record length
    int length;
    int maximum = 0;
    int t;
    for (t = 0; t < laia->n_labels; t++)
    {
        label_t *p = &laia->labels[t];
        ailist_t *ail = p->ail;
        int i;
        for (i = 0; i < ail->nr; i++)
        {
            // Record length (excluding last position)
            length = ail->interval_list[i].end - ail->interval_list[i].start - 1;
	        maximum = MAX(maximum, length);
        }
    }

    return maximum;
}


void labeled_aiarray_length_distribution(labeled_aiarray_t *laia, int distribution[])
{   /* Calculate length distribution */
    
    // Iterate over intervals and record length
    int length;
    int t;
    for (t = 0; t < laia->n_labels; t++)
    {
        label_t *p = &laia->labels[t];
        ailist_t *ail = p->ail;
        int i;
        for (i = 0; i < ail->nr; i++)
        {
            // Record length (excluding last position). Computed as signed to avoid
            // uint32 underflow on degenerate (end <= start) intervals.
            length = (int)ail->interval_list[i].end - (int)ail->interval_list[i].start - 1;
            if (length >= 0)
            {
                distribution[length] += 1;
            }
        }
    }

    return;
}


// Benchmark / smoke-test entry point. Guarded so this translation unit can be
// linked as a library (no duplicate `main`). Build with -DLAIA_MAIN to enable.
#ifdef LAIA_MAIN
#include <inttypes.h>

int main()
{
    labeled_aiarray_t *ail1 = labeled_aiarray_init();
    labeled_aiarray_t *ail2 = labeled_aiarray_init();

    labeled_aiarray_add(ail1, 1, 12, "0");
    labeled_aiarray_add(ail1, 10, 12, "0");
    labeled_aiarray_add(ail1, 5, 12, "0");
    labeled_aiarray_add(ail1, 10, 22, "0");
    
    labeled_aiarray_add(ail2, 1, 13, "1");
    labeled_aiarray_add(ail2, 1, 13, "2");
    
    int i;
    //#pragma omp parallel for
    for (i = 0; i < 10000000; i++)
    {
        if ((i % 2) == 1)
        {
            labeled_aiarray_add(ail1, i, i+10, "0");
        } else {
            labeled_aiarray_add(ail2, i, i+10, "1");
        }
    }

    printf("ail1->total_nr: %" PRId64 "\n", ail1->total_nr);
    printf("ail2->total_nr: %" PRId64 "\n", ail2->total_nr);

    labeled_aiarray_t *ail3 = labeled_aiarray_init();
    labeled_aiarray_t *ail_array[] = {ail1, ail2};
    labeled_aiarray_multi_merge(ail3, ail_array, 2);

    printf("ail3->total_nr: %" PRId64 "\n", ail3->total_nr);

    labeled_aiarray_construct(ail3, 20);

    // NOTE: ail1/ail2 are not destroyed here because multi_merge transfers their
    // interval-data ownership to ail3 (destroying both would double-free). This
    // leaks the ail1/ail2 container structs (labels array + label_lookup khash).
    // Resolve once multi_merge ownership semantics are confirmed.
    labeled_aiarray_destroy(ail3);

    return 0;
}
#endif