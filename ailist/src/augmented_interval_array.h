//=====================================================================================
// Common structs, parameters, functions
// Original: https://github.com/databio/aiarray/tree/master/src
// by Kyle S. Smith and Jianglin Feng
//-------------------------------------------------------------------------------------
#ifndef __AIARRAY_H__
#define __AIARRAY_H__
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>
#include <math.h>
#include <assert.h>
#include "utilities.h"
#include "array_query_utilities.h"
#include "interval.h"

//-------------------------------------------------------------------------------------

typedef struct {
	int64_t nr, mr;						// Number of intervals
	interval_t *interval_list;			// List of interval_t objects
	int nc, lenC[MAXC], idxC[MAXC];		// Components
	uint32_t *maxE;						// Augmentation
	uint32_t first, last;				// Record range of intervals
	uint32_t *id_index;					// Record id index values
} aiarray_t;

typedef struct {
	int size;							// Current size
    int max_size;						// Maximum size
	aiarray_t *ail;						// Store aiarray
	long *indices;						// Store indices
} overlap_index_t;

//-------------------------------------------------------------------------------------
// augmented_interval_list.c
//=====================================================================================

// Initialize aiarray_t
aiarray_t *aiarray_init(void);

// Free aiarray data
void aiarray_destroy(aiarray_t *ail);

// Print aiarray
void display_array(aiarray_t *ail);

// Calculate maximum length
int aiarray_max_length(aiarray_t *ail);

// Calculate length distribution
void aiarray_length_distribution(aiarray_t *ail, int distribution[]);


//-------------------------------------------------------------------------------------
// overlap_index.c
//=====================================================================================

// Initialize overlap_index_t
overlap_index_t *overlap_index_init(void);

// Free overlap_index memory
void overlap_index_destroy(overlap_index_t *oi);

// Add interval and index to overlap_index
void overlap_index_add(overlap_index_t *aq, interval_t *i);


//-------------------------------------------------------------------------------------
// aiarray_add.c
//=====================================================================================

// Build aiarray from arrays
void aiarray_from_array(aiarray_t *ail, const long starts[], const long ends[], int length);

// Add a interval_t interval
void aiarray_add(aiarray_t *ail, uint32_t start, uint32_t end);

// Append two aiarray
aiarray_t *aiarray_append(aiarray_t *ail1, aiarray_t *ail2);


//-------------------------------------------------------------------------------------
// aiarray_construct.c
//=====================================================================================

// Construct aiarray: decomposition and augmentation
void aiarray_construct(aiarray_t *ail, int cLen);


//-------------------------------------------------------------------------------------
// aiarray_index.c
//=====================================================================================

// Record id positions by index
void aiarray_cache_id(aiarray_t *ail);

// Get interval with id
interval_t *aiarray_get_index(aiarray_t *ail, int index);

// Get intervals with ids
aiarray_t *aiarray_get_index_array(aiarray_t *ail, const long indices[], int length);

// Index aiarray by array
aiarray_t *aiarray_array_index(aiarray_t *ail, const long indices[], int length);

// Index aiarray by another aiarray
aiarray_t *aiarray_index_by_aiarray(aiarray_t *ail1, aiarray_t *ail2);

// Index aiarray by another aiarray inplace
int aiarray_index_by_aiarray_inplace(aiarray_t *ail1, aiarray_t *ail2);

//-------------------------------------------------------------------------------------
// aiarray_query.c
//=====================================================================================

// Binary search
uint32_t binary_search(interval_t* As, uint32_t idxS, uint32_t idxE, uint32_t qe);

// Query aiarray intervals
aiarray_t *aiarray_query(aiarray_t *ail, uint32_t qs, uint32_t qe);

// Query aiarray intervals of a length
aiarray_t *aiarray_query_length(aiarray_t *ail, uint32_t qs, uint32_t qe, int min_length, int max_length);

// Query aiarray intervals from arrays
array_query_t *aiarray_query_from_array(aiarray_t *ail, const long starts[], const long ends[], int length);

// Find overlaps from aiarray
array_query_t *aiarray_query_from_aiarray(aiarray_t *ail, aiarray_t *ail2);

// Query aiarray intervals and record original index
overlap_index_t *aiarray_query_with_index(aiarray_t *ail, uint32_t qs, uint32_t qe);


//-------------------------------------------------------------------------------------
// aiarray_nhits.c
//=====================================================================================

// Determine number of hits for each query interval
void aiarray_nhits_from_array(aiarray_t *ail, const long starts[], const long ends[],
							 int length, int nhits[]);

// Determine number of hits of a length for each query interval
void aiarray_nhits_from_array_length(aiarray_t *ail, const long starts[], const long ends[],
									int length, int nhits[], int min_length,
									int max_length);

// Calculate n hits within bins
void aiarray_bin_nhits(aiarray_t *ail, double coverage[], int bin_size);

// Calculate n hits of a length within bins
void aiarray_bin_nhits_length(aiarray_t *ail, double coverage[], int bin_size, int min_length, int max_length);


//-------------------------------------------------------------------------------------
// aiarray_coverage.c
//=====================================================================================

// Determine coverage for an interval
void aiarray_interval_coverage(aiarray_t *ail, int start, int end, int coverage[]);

// Calculate coverage
void aiarray_coverage(aiarray_t *ail, double coverage[]);

// Calculate coverage within bins
void aiarray_bin_coverage(aiarray_t *ail, double coverage[], int bin_size);

// Calculate coverage within bins of a length
void aiarray_bin_coverage_length(aiarray_t *ail, double coverage[], int bin_size, int min_length, int max_length);

//-------------------------------------------------------------------------------------
// aiarray_wps.c
//=====================================================================================

// Calculate Window Protection Score
void aiarray_wps(aiarray_t *ail, double wps[], uint32_t protection);

// Calculate Window Protection Score of a length
void aiarray_wps_length(aiarray_t *ail, double wps[], uint32_t protection, int min_length, int max_length);


//-------------------------------------------------------------------------------------
// aiarray_merge.c
//=====================================================================================

// Get component index
int *get_comp_bounds(aiarray_t *ail);

// Merge nearby intervals
aiarray_t *aiarray_merge(aiarray_t *ail, uint32_t gap);


//-------------------------------------------------------------------------------------
// aiarray_filter.c
//=====================================================================================

// Filter aiarray by length
aiarray_t *aiarray_length_filter(aiarray_t *ail, int min_length, int max_length);

// Randomly downsample
aiarray_t *aiarray_downsample(aiarray_t *ail, double proportion);

// Randomly downsample with original index
overlap_index_t *aiarray_downsample_with_index(aiarray_t *ail, double proportion);


//-------------------------------------------------------------------------------------
// aiarray_extract.c
//=====================================================================================

// Extract start for aiarray
void aiarray_extract_starts(aiarray_t *ail, long starts[]);

// Extract end for aiarray
void aiarray_extract_ends(aiarray_t *ail, long ends[]);

// Extract id for aiarray
void aiarray_extract_ids(aiarray_t *ail, long ids[]);


//-------------------------------------------------------------------------------------
// aiarray_ops.c
//=====================================================================================

// Subtract intervals from region
void aiarray_subtract_intervals(aiarray_t *ref_ail, aiarray_t *result_ail, interval_t query_i, int j);

// Subtract two aiarray_t intervals
aiarray_t *aiarray_subtract(aiarray_t *ref_ail, aiarray_t *query_ail);

// Subtract intervals from region
void aiarray_common_intervals(aiarray_t *ref_ail, aiarray_t *result_ail, interval_t query_i, int j);

// Subtract two aiarray_t intervals
aiarray_t *aiarray_common(aiarray_t *ref_ail, aiarray_t *query_ail);

#endif
