//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

int distance(int start, int end, interval_t interval)
{   /* Genomic gap between query [start, end) and interval; 0 if overlapping */

    long left  = (long)interval.start - end;   // > 0 if interval lies right of query
    long right = (long)start - interval.end;    // > 0 if interval lies left of query
    long gap = left > right ? left : right;
    if (gap < 0)
    {
        gap = 0;
    }

    return (int)gap;
}


int sum_distances(float *distances, int k)
{
    float sum = 0;
    int i;
    for (i = 0; i < k; i++)
    {
        sum += distances[i];
    }
    return sum;
}

int find_max_distance(float *distances, int k)
{
    int max_index = 0;
    int i;
    for (i = 0; i < k; i++)
    {
        if (distances[i] > distances[max_index])
        {
            max_index = i;
        }
    }

    return max_index;
}

ailist_t *ailist_closest(int start, int end, ailist_t *ail, int k)
{   /* Find closest intervals to given interval */

    float max_distance = MAXFLOAT;
    int max_index = 0;
    //float sum_distance = 0;
    float *distances = (float*) malloc (sizeof(float) * k);
    int *index = (int*) malloc (sizeof(int) * k);

    // Initialize distances
    int i;
    for (i = 0; i < k; i++)
    {
        distances[i] = MAXFLOAT;
        index[i] = -1;
    }

    // Iterate over intervals
    for (i = 0; i < ail->nr; i++)
    {
        float current_distance = distance(start, end, ail->interval_list[i]);
        if (current_distance < max_distance)
        {
            distances[max_index] = current_distance;
            index[max_index] = i;
            max_index = find_max_distance(distances, k);
            max_distance = distances[max_index];
        }
    }

    // Sort slots ascending by distance (selection sort over k slots).
    // Unfilled slots hold MAXFLOAT/-1 and sort to the end.
    int j;
    for (i = 0; i < k; i++)
    {
        int min_j = i;
        for (j = i + 1; j < k; j++)
        {
            if (distances[j] < distances[min_j])
            {
                min_j = j;
            }
        }
        if (min_j != i)
        {
            float dtmp = distances[i];
            distances[i] = distances[min_j];
            distances[min_j] = dtmp;
            int itmp = index[i];
            index[i] = index[min_j];
            index[min_j] = itmp;
        }
    }

    // Create new list (skip unfilled slots when k > ail->nr)
    ailist_t *closest_list = ailist_init();
    for (i = 0; i < k; i++)
    {
        if (index[i] < 0)
        {
            continue;
        }
        ailist_add(closest_list, ail->interval_list[index[i]].start, ail->interval_list[index[i]].end, ail->interval_list[index[i]].id_value);
    }

    // Free working buffers
    free(distances);
    free(index);

    return closest_list;
}