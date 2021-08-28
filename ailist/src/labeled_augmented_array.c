//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

//-----------------------------------------------------------------------------

//const int khStrInt = 33;
//KHASH_MAP_INIT_STR(khStrInt, int32_t)
//typedef khash_t(khStrInt) strhash_t;
//const int khIntStr = 32;
//KHASH_MAP_INIT_INT(khIntStr, char*)
//typedef khash_t(khIntStr) inthash_t;

//-----------------------------------------------------------------------------

labeled_aiarray_t *labeled_aiarray_init(void)
{   /* Initialize labeled_aiarray_t object */

    // Initialize variables
    labeled_aiarray_t *ail = (labeled_aiarray_t *)malloc(sizeof(labeled_aiarray_t));
    ail->nr = 0;
    ail->mr = 64;
    ail->nl = 0;
    ail->ml = 64;
	ail->maxE = NULL;
    ail->nc = NULL;
    ail->lenC = NULL;
    ail->idxC = NULL;
    ail->id_index = NULL;
    ail->label_map = kh_init(khStrInt);
    ail->rev_label_map = kh_init(khIntStr);

    // Initialize arrays
    ail->interval_list = malloc(ail->mr * sizeof(labeled_interval_t));
    ail->label_count = calloc(ail->ml, sizeof(uint32_t)); 
    //ail->label_count[0] = 0;
    // Initialize label ranges
    ail->first = malloc(ail->ml * sizeof(uint32_t));
    memset(ail->first, INT32_MAX, ail->ml * sizeof(uint32_t));
    ail->last = malloc(ail->ml * sizeof(uint32_t));
    memset(ail->last, 0, ail->ml * sizeof(uint32_t));

    // Check if memory was allocated
    if (ail == NULL && ail->interval_list == NULL)
    {
        fprintf (stderr, "Out of memory!!! (init)\n");
        exit(1);
    }

	return ail;
}

//-----------------------------------------------------------------------------

void labeled_aiarray_destroy(labeled_aiarray_t *ail)
{   /* Free labeled_aiarray_t object */

    // Check that ail exists
	if (ail == 0)
    {
        return;
    }
	
    // Free intervals
    if (ail->interval_list)
    {
        free(ail->interval_list);
    }
	
    // Free maxE
	if (ail->maxE)
	{
		free(ail->maxE);
	}

    // Free label_count
    if (ail->label_count)
	{
		free(ail->label_count);
	}

    // Free nc
	if (ail->nc)
	{
		free(ail->nc);
	}

    // Free lenC
	if (ail->lenC)
	{
		free(ail->lenC);
	}

    // Free idxC
	if (ail->idxC)
	{
		free(ail->idxC);
	}

    // Free id_index
    if (ail->id_index)
    {
        free(ail->id_index);
    }

    // Free first
    if (ail->first)
    {
        free(ail->first);
    }

    // Free last
    if (ail->last)
    {
        free(ail->last);
    }

    // Free label hash table
    kh_destroy(khStrInt, (strhash_t*)ail->label_map);

    // Free reverse label hash table
    kh_destroy(khIntStr, (inthash_t*)ail->rev_label_map);

    // Free ailist
	free(ail);
}


//-----------------------------------------------------------------------------


void labeled_display_list(labeled_aiarray_t *ail)
{
    int i;
    for (i = 0; i < ail->nr; i++)
    {
        printf("(%d-%d, %d) ", ail->interval_list[i].start, ail->interval_list[i].end, ail->interval_list[i].label);
    }
    printf("\n");
    return;
}


void display_label_map(labeled_aiarray_t *ail)
{
    khiter_t k;
    uint64_t tval;
    khash_t(khStrInt) *h = ail->label_map;
    for (k = kh_begin(h); k != kh_end(h); ++k)
    {
      if (kh_exist(h, k))
      {
         const char *key = kh_key(h,k);
         tval = kh_value(h, k);
         printf("key=%s  val=%llu\n", key, tval);
      }
   }
}


int labeled_aiarray_max_length(labeled_aiarray_t *ail)
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


void labeled_aiarray_length_distribution(labeled_aiarray_t *ail, int distribution[])
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


int main()
{
    labeled_aiarray_t *ail = labeled_aiarray_init();
    labeled_aiarray_add(ail, 1, 12, "0");
    labeled_aiarray_add(ail, 10, 12, "0");
    labeled_aiarray_add(ail, 1, 13, "1");
    labeled_aiarray_add(ail, 1, 13, "2");
    labeled_aiarray_add(ail, 1, 13, "3");
    labeled_aiarray_add(ail, 10, 22, "0");
    labeled_aiarray_add(ail, 1, 13, "13");
    labeled_display_list(ail);

    labeled_aiarray_construct(ail, 20);
    labeled_display_list(ail);

    printf("nl:%lld, ml:%lld\n", ail->nl, ail->ml);
    int i;
    for (i = 0; i < ail->ml; i++)
    {
        printf("index_label:%d\n", ail->label_count[i]);
    }
    labeled_aiarray_destroy(ail);

    return 0;
}