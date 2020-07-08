#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include "augmented_interval_list.h"


int find_maximum(interval_t *array, int size)
{   /* Get maximum start in array */
  
    int i;
    int maximum = -1;

    // Iterate over array, record max start
    for(i = 0; i < size; i++)
    {
        if((int)array[i].start > maximum)
        {
            maximum = (int)array[i].start;
        }
    }

    return maximum;
}


void radix_interval_sort(interval_t *array, int size)
{   /* Radix sort interval list */
    int i;
    interval_t *semi_sorted = (interval_t *)malloc(size * sizeof(interval_t));
    int significant_digit = 1;
    int maximum = find_maximum(array, size);

    // Loop until largest significant digit is reached
    while (maximum / significant_digit > 0)
    { 
        int bucket[10] = { 0 };

        // Counts the number of digits that will go into each bucket
        for (i = 0; i < size; i++)
        {
            bucket[(array[i].start / significant_digit) % 10]++;
        }

        // Add the count of the previous buckets,
        // Acquires the indexes after the end of each bucket location in the array
        for (i = 1; i < 10; i++)
        {
            bucket[i] += bucket[i - 1];
        }

        // Use the bucket to fill a semi_sorted array
        for (i = size - 1; i >= 0; i--)
        {
            semi_sorted[--bucket[(array[i].start / significant_digit) % 10]] = array[i];
        }

        for (i = 0; i < size; i++)
        {
            array[i] = semi_sorted[i];
        }

        // Move to next significant digit
        significant_digit *= 10;
    }

    free(semi_sorted);
}