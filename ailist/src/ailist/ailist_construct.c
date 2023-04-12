//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

#define interval_t_key(r) ((r).start)
KRADIX_SORT_INIT(intv, interval_t, interval_t_key, 4)

//-----------------------------------------------------------------------------

void ailist_construct(ailist_t *ail, int cLen)
{   /* Construct ailist_t object */  

    int cLen1 = cLen / 2;
    int j1, nr;
    int minL = MAX(64, cLen);     
    cLen += cLen1;      
    int lenT, len, iter, j, k, k0, t;  

    //1. Decomposition
    interval_t *L1 = ail->interval_list;					//L1: to be rebuilt
    nr = ail->nr;
    //ailist_sort(L1);
    radix_sort_intv(L1, L1+nr);

    if (nr <= minL)
    {        
        ail->nc = 1;
        ail->lenC[0] = nr;
        ail->idxC[0] = 0;                
    } else {         
        interval_t *L0 = malloc(nr * sizeof(interval_t)); 	//L0: serve as input list
        interval_t *L2 = malloc(nr * sizeof(interval_t));   //L2: extracted list 
        memcpy(L0, L1, nr * sizeof(interval_t));			
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
                    if (L0[j + t].end >= tt) {j1++;}
                    j++;
                }
                
                if (j1 < cLen1)
                {
                    memcpy(&L2[len++], &L0[t], sizeof(interval_t));
                } else {
                    memcpy(&L1[k++], &L0[t], sizeof(interval_t));
                }               
            } 

            memcpy(&L1[k], &L0[lenT - cLen], cLen * sizeof(interval_t));   
            k += cLen;
            lenT = len;               
            ail->idxC[iter] = k0;
            ail->lenC[iter] = k - k0;
            k0 = k;
            iter++;

            if (lenT <= minL || iter == MAXC - 2)
            {	//exit: add L2 to the end
                if (lenT > 0)
                {
                    memcpy(&L1[k], L2, lenT * sizeof(interval_t));
                    ail->idxC[iter] = k;
                    ail->lenC[iter] = lenT;
                    iter++;
                }
                ail->nc = iter;                   
            } else {
                memcpy(L0, L2, lenT * sizeof(interval_t));
            }
        }
        free(L2);
        free(L0);     
    }

    //2. Augmentation
    ail->maxE = malloc(nr * sizeof(uint32_t)); 
    for (j = 0; j < ail->nc; j++)
    { 
        k0 = ail->idxC[j];
        k = k0 + ail->lenC[j];
        uint32_t tt = L1[k0].end;
        ail->maxE[k0] = tt;

        for (t = k0 + 1; t < k; t++)
        {
            if (L1[t].end > tt)
            {
                tt = L1[t].end;
            }

            ail->maxE[t] = tt;  
        }             
    }

    return;
}




void ailist_construct_v0(ailist_t *ail, int cLen)
{   /* Construct ailist: decomposition and augmentation */

    int cLen1 = cLen / 2;
    int nr;
    int minL = MAX(64, cLen);     
    cLen += cLen1;      
    int lenT;
    int len;
    int iter;
    int j;
    int k;
    int k0;
    int t;

    //1. Decomposition
    interval_t *L1 = ail->interval_list;			//L1: to be rebuilt
    nr = ail->nr;
    radix_sort_intv(L1, L1+nr);

    if (nr <= minL)
    {        
        ail->nc = 1;
        ail->lenC[0] = nr;
        ail->idxC[0] = 0;                
    } else {         
        interval_t *L0 = malloc(nr * sizeof(interval_t)); 	//L0: serve as input list
        interval_t *L2 = malloc(nr * sizeof(interval_t));   //L2: extracted list 
        //----------------------------------------
        interval_t *D0 = malloc(nr * sizeof(interval_t)); 	//D0:            
        int32_t *di = malloc(nr * sizeof(int32_t));	//int64_t?			  
        //----------------------------------------
        memcpy(L0, L1, nr*sizeof(interval_t));			
        iter = 0;
        k = 0;
        k0 = 0;
        lenT = nr;
        while (iter < MAXC && lenT > minL)
        {  
            //setup di---------------------------			
            for (j = 0; j < lenT; j++)          //L0:{.start= end, .end=idx, .value=idx1}
            {
                D0[j].start = L0[j].end;
                D0[j].end = j;
            }
            radix_sort_intv(D0, D0+lenT);
            
            for (j = 0; j < lenT; j++)          //assign i=29 to L0[i].end=2
            {
                t = D0[j].end;
                di[t] = j-t;					//>0 indicate containment
            }  
            //----------------------------------- 
            len = 0;
            for (t = 0; t < lenT - cLen; t++) 
            {
                if (di[t] > cLen)
                {
                    memcpy(&L2[len++], &L0[t], sizeof(interval_t));    			
                } else {
                    memcpy(&L1[k++], &L0[t], sizeof(interval_t));
                }
            }             
            memcpy(&L1[k], &L0[lenT-cLen], cLen*sizeof(interval_t));   
            k += cLen;
            lenT = len;                
            ail->idxC[iter] = k0;
            ail->lenC[iter] = k - k0;
            k0 = k;
            iter++;
            
            if (lenT <= minL || iter == MAXC-2)     //exit: add L2 to the end
            {
                if (lenT > 0)
                {
                    memcpy(&L1[k], L2, lenT*sizeof(interval_t));
                    ail->idxC[iter] = k;
                    ail->lenC[iter] = lenT;
                    iter++;
                    lenT = 0;						//exit!
                }
                ail->nc = iter;                   
            } else {
                memcpy(L0, L2, lenT*sizeof(interval_t));
            }
        }

        free(L2);
        free(L0);
        free(D0);
        free(di);   
    }

    //2. Augmentation
    ail->maxE = malloc(nr * sizeof(uint32_t)); 

    for (j = 0; j < ail->nc; j++)
    { 
        k0 = ail->idxC[j];
        k = k0 + ail->lenC[j];
        uint32_t tt = L1[k0].end;
        ail->maxE[k0]=tt;

        for (t = k0+1; t < k; t++)
        {
            if (L1[t].end > tt)
            {
                tt = L1[t].end;
            }

            ail->maxE[t] = tt;  
        }             
    } 

    return;
}


int ailist_validate_construction(ailist_t *ail)
{   /* Validation that construction ran */
    
    if (ail->maxE != NULL)
    {
        int lenC_sum = 0;
        int idxC_sum = 0;
        int i;
        for (i = 0; i < MAXC; i++)
        {
            lenC_sum = lenC_sum + ail->lenC[i];
            idxC_sum = idxC_sum + ail->idxC[i];
        }
        
        if (ail->nc > 1)
        {
            if (lenC_sum > 0 && idxC_sum > 0)
            {
                return 1;
            }
        } else {
            return 1;
        }
    }

    return 0;
}