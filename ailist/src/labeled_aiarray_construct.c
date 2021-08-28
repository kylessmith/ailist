//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "labeled_augmented_array.h"

// Setup sorting functions
#define labeled_interval_t_key(r) ((r).start)
#define labeled_interval_t_label(r) ((r).label)
KRADIX_SORT_INIT(lintv, labeled_interval_t, labeled_interval_t_key, 4)
KRADIX_SORT_INIT(label, labeled_interval_t, labeled_interval_t_label, 2)

//-----------------------------------------------------------------------------

void labeled_aiarray_radix_label_sort(labeled_aiarray_t *ail)
{   /* Sort intervals by label */

    // Radix sort
    labeled_interval_t *L1 = ail->interval_list;
    radix_sort_label(L1, L1+ail->nr);

    return;
}


void labeled_aiarray_sort(labeled_aiarray_t *ail)
{   /* Sort intervals in aiarray */

    // Iterate over labels
    int count = 0;
    int i;
    for (i = 0; i < ail->nl; i++)
    {   
        // Check any values seen
        if (ail->label_count[i] != 0)
        {
            // Find bounds for label
            uint32_t start = count;
            uint32_t end = count + ail->label_count[i];
            uint32_t length = end - start;

            // Radix sort
            labeled_interval_t *L1 = &ail->interval_list[start];
            radix_sort_lintv(L1, L1+length);
        }

        // Increment count
        count = count + ail->label_count[i];
    }

    return;
}


void labeled_aiarray_construct(labeled_aiarray_t *ail, int cLen_init)
{   /* Construct aiarray_t object */

    // Allocate memory for construction variables
    ail->nc = malloc(ail->nl * sizeof(int));
    ail->lenC = malloc((ail->nl * MAXC) * sizeof(int));
    ail->idxC = malloc((ail->nl * MAXC) * sizeof(int));
    ail->maxE = malloc(ail->nr * sizeof(uint32_t));

    // Iterate over labels
    int count = 0;
    int i;
    for (i = 0; i < ail->nl; i++)
    {   
        // Check any values seen
        if (ail->label_count[i] != 0)
        {
            // Find bounds for label
            uint32_t start = count;
            uint32_t end = count + ail->label_count[i];
            uint32_t length = end - start;

            // Initialize values for construction
            labeled_interval_t *L1 = &ail->interval_list[start];					//L1: to parse by label
            uint32_t *maxE = &ail->maxE[start];
            int nr = length;
            int *nc = &ail->nc[i];
            int *lenC = &ail->lenC[(i * MAXC)];
            int *idxC = &ail->idxC[(i * MAXC)];
            int cLen = cLen_init;

            // Construct label
            int cLen1 = cLen / 2;
            int j1;
            int minL = MAX(64, cLen);     
            cLen += cLen1;      
            int lenT, len, iter, j, k, k0, t;

            //1. Decomposition
            if (nr <= minL)
            {        
                *nc = 1;
                lenC[0] = nr;
                idxC[0] = 0;                
            } else {
                labeled_interval_t *L0 = malloc(nr * sizeof(labeled_interval_t)); 	//L0: serve as input list
                labeled_interval_t *L2 = malloc(nr * sizeof(labeled_interval_t));   //L2: extracted list 
                memcpy(L0, L1, nr * sizeof(labeled_interval_t));			
                iter = 0;
                k = 0;
                k0 = 0;
                lenT = nr;

                while (iter < MAXC && lenT > minL)
                {   
                    len = 0;            
                    for (t = 0; t < lenT - cLen; t++)
                    {
                        uint32_t tt = L0[t].end;
                        j=1;
                        j1=1;

                        while (j < cLen && j1 < cLen1)
                        {
                            if (L0[j + t].end >= tt)
                            {
                                j1++;
                            }

                            j++;
                        }
                        if (j1 < cLen1)
                        {
                            memcpy(&L2[len++], &L0[t], sizeof(labeled_interval_t));
                        } else {
                            memcpy(&L1[k++], &L0[t], sizeof(labeled_interval_t));
                        }               
                    } 

                    memcpy(&L1[k], &L0[lenT - cLen], cLen * sizeof(labeled_interval_t));
                    k += cLen;
                    lenT = len;
                    idxC[iter] = k0;
                    lenC[iter] = k - k0;
                    k0 = k;
                    iter++;

                    if (lenT <= minL || iter == MAXC - 2)
                    {	//exit: add L2 to the end
                        if (lenT > 0)
                        {
                            memcpy(&L1[k], L2, lenT * sizeof(labeled_interval_t));
                            idxC[iter] = k;
                            lenC[iter] = lenT;
                            iter++;
                        }
                        *nc = iter;
                    } else {
                        memcpy(L0, L2, lenT * sizeof(labeled_interval_t));
                    }
                }
                free(L2);
                free(L0);
            }

            //2. Augmentation
            for (j = 0; j < *nc; j++)
            { 
                k0 = idxC[j];
                k = k0 + lenC[j];
                uint32_t tt = L1[k0].end;
                maxE[k0] = tt;

                for (t = k0 + 1; t < k; t++)
                {
                    if (L1[t].end > tt)
                    {
                        tt = L1[t].end;
                    }

                    maxE[t] = tt;  
                }             
            }
        }

        count = count + ail->label_count[i];
    }

    return;
}
