//=====================================================================================
// Common structs, parameters, functions
// Original: https://github.com/databio/AIList/tree/master/src
// by Kyle S. Smith and Jianglin Feng
//-------------------------------------------------------------------------------------
#ifndef __AILIST_H__
#define __AILIST_H__
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
} ailist_t;

typedef struct {
	ailist_t *ail;						// Interval list
	int nc;								// Number of components
	int *comp_bounds;					// Label component bounds
	int *comp_used;						// Components used
	interval_t *intv;					// Interval
	int n;								// Current position
} ailist_sorted_iter_t;

//-------------------------------------------------------------------------------------
// augmented_interval_list.c
//=====================================================================================

// Initialize ailist_t
ailist_t *ailist_init(void);

// Free ailist data
void ailist_destroy(ailist_t *ail);

// Print AIList
void display_list(ailist_t *ail);

// Calculate maximum length
int ailist_max_length(ailist_t *ail);

// Calculate length distribution
void ailist_length_distribution(ailist_t *ail, int distribution[]);


//-------------------------------------------------------------------------------------
// ailist_add.c
//=====================================================================================

// Add interval to ailist_t object 
void ailist_add(ailist_t *ail, uint32_t start, uint32_t end, uint32_t id);

// Build ailist from arrays
void ailist_from_array(ailist_t *ail, const long starts[], const long ends[], const long ids[], int length);

// Append two ailist
ailist_t *ailist_append(ailist_t *ail1, ailist_t *ail2);


//-------------------------------------------------------------------------------------
// ailist_construct.c
//=====================================================================================

// Construct ailist: decomposition and augmentation
void ailist_construct(ailist_t *ail, int cLen);


//-------------------------------------------------------------------------------------
// ailist_index.c
//=====================================================================================

// Get intervals with id
ailist_t *ailist_get_id(ailist_t *ail, int query_id);

// Get intervals with ids
ailist_t *ailist_get_id_array(ailist_t *ail, const long ids[], int length);


//-------------------------------------------------------------------------------------
// ailist_query.c
//=====================================================================================

// Binary search
uint32_t binary_search(interval_t* As, uint32_t idxS, uint32_t idxE, uint32_t qe);

// Query ailist intervals
ailist_t *ailist_query(ailist_t *ail, uint32_t qs, uint32_t qe);

// Query ailist intervals of a length
ailist_t *ailist_query_length(ailist_t *ail, uint32_t qs, uint32_t qe, int min_length, int max_length);

// Query ailist intervals from arrays
ailist_t *ailist_query_from_array(ailist_t *ail, const long starts[], const long ends[], int length);

// Query ailist intervals from another ailist
ailist_t *ailist_query_from_ailist(ailist_t *ail, ailist_t *ail2);

// Query ailist interval ids from array
array_query_t *ailist_query_id_from_array(ailist_t *ail, const long starts[], const long ends[], const long ids[], int length);

// Query ailist interval ids from another ailist
array_query_t *ailist_query_id_from_ailist(ailist_t *ail, ailist_t *ail2);


//-------------------------------------------------------------------------------------
// ailist_iter.c
//=====================================================================================

// Get component index
int *get_comp_bounds(ailist_t *ail);

// 
ailist_sorted_iter_t *ailist_sorted_iter_init(ailist_t *ail);

// 
int ailist_sorted_iter_next(ailist_sorted_iter_t *iter);

// 
void ailist_sorted_iter_destroy(ailist_sorted_iter_t *iter);


//-------------------------------------------------------------------------------------
// ailist_coverage.c
//=====================================================================================

// Calculate coverage for a single interval
void ailist_interval_coverage(ailist_t *ail, int start, int end, int coverage[]);

// Calculate coverage
void ailist_coverage(ailist_t *ail, double coverage[]);

// Calculate coverage within bins
void ailist_bin_coverage(ailist_t *ail, double coverage[], int bin_size);

// Calculate coverage within bins of a length
void ailist_bin_coverage_length(ailist_t *ail, double coverage[], int bin_size, int min_length, int max_length);


//-------------------------------------------------------------------------------------
// ailist_nhits.c
//=====================================================================================

// Determine number of hits for each query interval
void ailist_nhits_from_array(ailist_t *ail, const long starts[], const long ends[],
							 int length, int nhits[]);

// Determine number of hits of a length for each query interval
void ailist_nhits_from_array_length(ailist_t *ail, const long starts[], const long ends[],
									int length, int nhits[], int min_length,
									int max_length);

// Calculate n hits within bins
void ailist_bin_nhits(ailist_t *ail, double coverage[], int bin_size);

// Calculate n hits of a length within bins
void ailist_bin_nhits_length(ailist_t *ail, double coverage[], int bin_size, int min_length, int max_length);

//-------------------------------------------------------------------------------------
// ailist_wps.c
//=====================================================================================

// Calculate Window Protection Score
void ailist_wps(ailist_t *ail, double wps[], uint32_t protection);

// Calculate Window Protection Score of a length
void ailist_wps_length(ailist_t *ail, double wps[], uint32_t protection, int min_length, int max_length);

//-------------------------------------------------------------------------------------
// ailist_merge.c
//=====================================================================================

// Merge nearby intervals
ailist_t *ailist_merge(ailist_t *ail, uint32_t gap);


//-------------------------------------------------------------------------------------
// ailist_extract.c
//=====================================================================================

// Extract start for ailist
void ailist_extract_starts(ailist_t *ail, long starts[]);

// Extract end for ailist
void ailist_extract_ends(ailist_t *ail, long ends[]);

// Extract index for ailist
void ailist_extract_ids(ailist_t *ail, long ids[]);


//-------------------------------------------------------------------------------------
// ailist_ops.c
//=====================================================================================

// Subtract intervals from region
void subtract_intervals(ailist_t *ref_ail, ailist_t *result_ail, interval_t query_i, int j);

// Subtract two ailist_t intervals
ailist_t *ailist_subtract(ailist_t *ref_ail, ailist_t *query_ail);

// Subtract intervals from region
void common_intervals(ailist_t *ref_ail, ailist_t *result_ail, interval_t query_i, int j);

// Subtract two ailist_t intervals
ailist_t *ailist_common(ailist_t *ref_ail, ailist_t *query_ail);


//-------------------------------------------------------------------------------------
// ailist_filter.c
//=====================================================================================

// Filter ailist by length
ailist_t *ailist_length_filter(ailist_t *ail, int min_length, int max_length);

// Randomly downsample
ailist_t *ailist_downsample(ailist_t *ail, double proportion);

#endif