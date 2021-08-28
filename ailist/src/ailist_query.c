//=============================================================================
// Quick and efficient storing/querying of intervals 
// by Kyle S. Smith and Jianglin Feng
//
//-----------------------------------------------------------------------------

#include "augmented_interval_list.h"

//-----------------------------------------------------------------------------

uint32_t binary_search(interval_t* As, uint32_t idxS, uint32_t idxE, uint32_t qe)
{   /* Find tE: index of the first item satisfying .s<qe from right */
    
    int tL = idxS;
    int tR = idxE - 1;
    int tM;
    int tE = -1;
    
    if(As[tR].start < qe)
    {
        return tR;
    } else if (As[tL].start >= qe) {
        return -1;
    }

    while (tL < tR - 1)
    {
        tM = (tL + tR) / 2; 

        if (As[tM].start >= qe)
        {
            tR = tM - 1;
        } else {
            tL = tM;
        }
    }

    if (As[tR].start < qe)
    {
        tE = tR;
    } else if (As[tL].start < qe) {
        tE = tL;
    }

    return tE; 
}

//-----------------------------------------------------------------------------
// Queries returning ailist_t objects
//-----------------------------------------------------------------------------

ailist_t *ailist_query(ailist_t *ail, uint32_t qs, uint32_t qe)
{   /* Query ailist intervals */

    // Initialize overlaps
    int k;
    ailist_t *overlaps = ailist_init();

    for (k = 0; k < ail->nc; k++)
    {   // Search each component
        int32_t cs = ail->idxC[k];
        int32_t ce = cs + ail->lenC[k];			
        int32_t t;

        if (ail->lenC[k] > 15)
        {
            t = binary_search(ail->interval_list, cs, ce, qe);

            while (t >= cs && ail->maxE[t] > qs)
            {
                if (ail->interval_list[t].end > qs)
                {               	
                    ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].id_value);
                }

                t--;
            }
        } 
        else {
            for (t = cs; t < ce; t++)
            {
                if (ail->interval_list[t].start < qe && ail->interval_list[t].end > qs)
                {
                    ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].id_value);
                }
            }                      
        }
    }

    return overlaps;                            
}


ailist_t *ailist_query_length(ailist_t *ail, uint32_t qs, uint32_t qe, int min_length, int max_length)
{   
    // Initialize overlaps
    int k;
    ailist_t *overlaps = ailist_init();

    for (k = 0; k < ail->nc; k++)
    {   // Search each component
        int32_t cs = ail->idxC[k];
        int32_t ce = cs + ail->lenC[k];			
        int32_t t;

        if (ail->lenC[k] > 15)
        {
            t = binary_search(ail->interval_list, cs, ce, qe);

            while (t >= cs && ail->maxE[t] > qs)
            {
                if (ail->interval_list[t].end > qs)
                {               	
                    int length = ail->interval_list[t].end - ail->interval_list[t].start;
                    if (length >= min_length && length < max_length)
                    {
                        ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].id_value);
                    }
                }

                t--;
            }
        } 
        else {
            for (t = cs; t < ce; t++)
            {
                if (ail->interval_list[t].start < qe && ail->interval_list[t].end > qs)
                {
                    int length = ail->interval_list[t].end - ail->interval_list[t].start;
                    if (length >= min_length && length < max_length)
                    {
                        ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].id_value);
                    }
                }
            }                      
        }
    }

    return overlaps;                            
}


ailist_t *ailist_query_from_array(ailist_t *ail, const long starts[], const long ends[], int length)
{   /* Query ailist intervals from arrays */

    // Initialize overlaps
    int k;
    ailist_t *overlaps = ailist_init();

    // Iterate over queries
    int i;
    for (i = 0; i < length; i++)
    {
        uint32_t qs = starts[i];
        uint32_t qe = ends[i];

        for (k = 0; k < ail->nc; k++)
        {   // Search each component
            int32_t cs = ail->idxC[k];
            int32_t ce = cs + ail->lenC[k];			
            int32_t t;

            if (ail->lenC[k] > 15)
            {
                t = binary_search(ail->interval_list, cs, ce, qe);

                while (t >= cs && ail->maxE[t] > qs)
                {
                    if (ail->interval_list[t].end > qs)
                    {               	
                        ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].id_value);
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (ail->interval_list[t].start < qe && ail->interval_list[t].end > qs)
                    {
                        ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].id_value);
                    }
                }                      
            }
        }
    }

    return overlaps;                            
}


ailist_t *ailist_query_from_ailist(ailist_t *ail, ailist_t *ail2)
{   /* Query ailist intervals from another ailist */

    // Initialize overlaps
    int k;
    ailist_t *overlaps = ailist_init();

    // Iterate over queries
    int i;
    for (i = 0; i < ail2->nr; i++)
    {
        uint32_t qs = ail2->interval_list[i].start;
        uint32_t qe = ail2->interval_list[i].end;

        for (k = 0; k < ail->nc; k++)
        {   // Search each component
            int32_t cs = ail->idxC[k];
            int32_t ce = cs + ail->lenC[k];			
            int32_t t;

            if (ail->lenC[k] > 15)
            {
                t = binary_search(ail->interval_list, cs, ce, qe);

                while (t >= cs && ail->maxE[t] > qs)
                {
                    if (ail->interval_list[t].end > qs)
                    {               	
                        ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].id_value);
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (ail->interval_list[t].start < qe && ail->interval_list[t].end > qs)
                    {
                        ailist_add(overlaps, ail->interval_list[t].start, ail->interval_list[t].end, ail->interval_list[t].id_value);
                    }
                }                      
            }
        }
    }

    return overlaps;                            
}


//-----------------------------------------------------------------------------
// Queries returning array_query_t objects
//-----------------------------------------------------------------------------

array_query_t *ailist_query_id_from_array(ailist_t *ail, const long starts[], const long ends[], const long ids[], int length)
{   /* Query ailist interval ids from array */
    
    // Initialize overlaps
    int k;
    array_query_t *aq = array_query_init();

    // Iterate over queries
    int i;
    for (i = 0; i < length; i++)
    {
        uint32_t qs = starts[i];
        uint32_t qe = ends[i];
        uint32_t id = ids[i];

        for (k = 0; k < ail->nc; k++)
        {   // Search each component
            int32_t cs = ail->idxC[k];
            int32_t ce = cs + ail->lenC[k];			
            int32_t t;

            if (ail->lenC[k] > 15)
            {
                t = binary_search(ail->interval_list, cs, ce, qe);

                while (t >= cs && ail->maxE[t] > qs)
                {
                    if (ail->interval_list[t].end > qs)
                    {               	
                        array_query_add(aq, id, ail->interval_list[t].id_value);
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (ail->interval_list[t].start < qe && ail->interval_list[t].end > qs)
                    {
                        array_query_add(aq, id, ail->interval_list[t].id_value);
                    }
                }                      
            }
        }
    }

    // reallocate to remove extra memory
    aq->ref_index = (long *)realloc(aq->ref_index, sizeof(long) * aq->size);
    aq->query_index = (long *)realloc(aq->query_index, sizeof(long) * aq->size);
    aq->max_size = aq->size;

    return aq;                            
}


array_query_t *ailist_query_id_from_ailist(ailist_t *ail, ailist_t *ail2)
{   /* Query ailist interval ids from another ailist */
    int k;

    array_query_t *aq = array_query_init();

    // Iterate over queries
    int i;
    for (i = 0; i < ail2->nr; i++)
    {
        uint32_t qs = ail2->interval_list[i].start;
        uint32_t qe = ail2->interval_list[i].end;
        uint32_t id = ail2->interval_list[i].id_value;

        for (k = 0; k < ail->nc; k++)
        {   // Search each component
            int32_t cs = ail->idxC[k];
            int32_t ce = cs + ail->lenC[k];			
            int32_t t;

            if (ail->lenC[k] > 15)
            {
                t = binary_search(ail->interval_list, cs, ce, qe);

                while (t >= cs && ail->maxE[t] > qs)
                {
                    if (ail->interval_list[t].end > qs)
                    {               	
                        array_query_add(aq, id, ail->interval_list[t].id_value);
                    }

                    t--;
                }
            } 
            else {
                for (t = cs; t < ce; t++)
                {
                    if (ail->interval_list[t].start < qe && ail->interval_list[t].end > qs)
                    {
                        array_query_add(aq, id, ail->interval_list[t].id_value);
                    }
                }                      
            }
        }
    }

    // reallocate to remove extra memory
    aq->ref_index = (long *)realloc(aq->ref_index, sizeof(long) * aq->size);
    aq->query_index = (long *)realloc(aq->query_index, sizeof(long) * aq->size);
    aq->max_size = aq->size;

    return aq;                           
}

