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
        //tM = (tL + tR) / 2;
        tM = tL + (tR - tL)/2;

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

void ailist_query(ailist_t *ail, ailist_t *overlaps, uint32_t qs, uint32_t qe)
{   /* Query ailist intervals */

    int k;
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

    return;                            
}


void ailist_query_length(ailist_t *ail, ailist_t *overlaps, uint32_t qs, uint32_t qe, int min_length, int max_length)
{   

    int k;
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

    return;                            
}


void ailist_query_from_array(ailist_t *ail, ailist_t *overlaps, const long starts[], const long ends[], int length)
{   /* Query ailist intervals from arrays */

    int k;
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

    return;                            
}


void ailist_query_from_ailist(ailist_t *ail, ailist_t *ail2, ailist_t *overlaps)
{   /* Query ailist intervals from another ailist */

    int k;
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

    return;                            
}


//-----------------------------------------------------------------------------
// Queries for nhits
//-----------------------------------------------------------------------------

void ailist_query_nhits(ailist_t *ail, long *nhits, uint32_t qs, uint32_t qe)
{   /* Query number of hits in ailist intervals */

    int k;
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
                    (*nhits)++;
                }

                t--;
            }
        } 
        else {
            for (t = cs; t < ce; t++)
            {
                if (ail->interval_list[t].start < qe && ail->interval_list[t].end > qs)
                {
                    (*nhits)++;
                }
            }                      
        }
    }

    return;                            
}


void ailist_query_nhits_length(ailist_t *ail, long *nhits, uint32_t qs, uint32_t qe, int min_length, int max_length)
{   /* Query number of hits in ailist intervals within a length */

    int k;
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
                        (*nhits)++;
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
                        (*nhits)++;
                    }
                }
            }                      
        }
    }

    return;                            
}


void ailist_query_has_hit(ailist_t *ail, uint8_t *has_hit, uint32_t qs, uint32_t qe)
{   /* Query if interval has any overlap in ailist intervals */

    int k;
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
                    *has_hit = (uint32_t)1;
                    return;
                }

                t--;
            }
        } 
        else {
            for (t = cs; t < ce; t++)
            {
                if (ail->interval_list[t].start < qe && ail->interval_list[t].end > qs)
                {
                    *has_hit = (uint32_t)1;
                    return;
                }
            }                      
        }
    }

    return;                            
}

//-----------------------------------------------------------------------------
// Queries returning overlap_index_t objects
//-----------------------------------------------------------------------------

void ailist_query_with_index(ailist_t *ail, overlap_index_t *overlaps, uint32_t qs, uint32_t qe)
{   /* Query aiarray intervals and record original index */

    // Initialize overlaps
    int k;
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
                    overlap_index_add(overlaps, &ail->interval_list[t]);
                }

                t--;
            }
        } 
        else {
            for (t = cs; t < ce; t++)
            {
                if (ail->interval_list[t].start < qe && ail->interval_list[t].end > qs)
                {
                    overlap_index_add(overlaps, &ail->interval_list[t]);
                }
            }                      
        }
    }

    // reallocate to remove extra memory
    overlaps->indices = (long *)realloc(overlaps->indices, sizeof(long) * overlaps->size);
    overlaps->max_size = overlaps->size;

    return;                            
}

//-----------------------------------------------------------------------------
// Queries returning array_query_t objects
//-----------------------------------------------------------------------------

void ailist_query_only_index(ailist_t *ail, array_query_t *aq, uint32_t qs, uint32_t qe, uint32_t id)
{   /* Query aiarray intervals and record original index */

    // Initialize overlaps
    int k;
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

    return;                            
}


void ailist_query_id_from_array(ailist_t *ail, array_query_t *aq, const long starts[], const long ends[], const long ids[], int length)
{   /* Query ailist interval ids from array */
    
    int k;
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

    return;                            
}


void ailist_query_id_from_ailist(ailist_t *ail, ailist_t *ail2, array_query_t *aq)
{   /* Query ailist interval ids from another ailist */
    
    int k;
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

    return;                           
}

