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
#include "array_query_utilities.h"

//-------------------------------------------------------------------------------------
#define MAX(X, Y) (((X) > (Y)) ? (X) : (Y))
#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))
#define MAXC 10							// Max number of components
//-------------------------------------------------------------------------------------

typedef struct {
    uint32_t start;      				// Region start: 0-based
    uint32_t end;    					// Region end: not inclusive
    int32_t index;
	double_t value;
} interval_t;

typedef struct {
	int64_t nr, mr;						// Number of intervals
	interval_t *interval_list;			// List of interval_t objects
	int nc, lenC[MAXC], idxC[MAXC];		// Components
	uint32_t *maxE;						// Augmentation
	uint32_t first, last;				// Record range of intervals
} ailist_t;

//-------------------------------------------------------------------------------------

// Initialize ailist_t
ailist_t *ailist_init(void);

// Initialize interval_t
interval_t *interval_init(uint32_t start, uint32_t end, int32_t index, double_t value);

// Add a interval_t interval
void ailist_add(ailist_t *ail, uint32_t start, uint32_t end, int32_t index, double_t value);

// Sort intervals in ailist
void ailist_sort(ailist_t *ail);

// Construct ailist: decomposition and augmentation
void ailist_construct(ailist_t *ail, int cLen);

// Binary search
uint32_t binary_search(interval_t* As, uint32_t idxS, uint32_t idxE, uint32_t qe);

// Query ailist intervals
ailist_t *ailist_query(ailist_t *ail, uint32_t qs, uint32_t qe);

// Find overlaps from array
array_query_t *ailist_query_from_array(ailist_t *ail, const long starts[], const long ends[], const long indices[], int length);

// Query ailist intervals within lengths
ailist_t *ailist_query_length(ailist_t *ail, uint32_t qs, uint32_t qe, int min_length, int max_length);

// Find overlaps from ailist
array_query_t *ailist_query_from_ailist(ailist_t *ail1, ailist_t *ail2);

// Free ailist data
void ailist_destroy(ailist_t *ail);

// Append intervals other ailist
ailist_t *ailist_append(ailist_t *ail1, ailist_t *ail2);

// Extract index for ailist
void ailist_extract_index(ailist_t *ail, long indices[]);

// Extract start for ailist
void ailist_extract_starts(ailist_t *ail, long starts[]);

// Extract end for ailist
void ailist_extract_ends(ailist_t *ail, long ends[]);

// Extract value for ailist
void ailist_extract_values(ailist_t *ail, double values[]);

// Calculate coverage
void ailist_coverage(ailist_t *ail, double coverage[]);

// Calculate coverage within bins
void ailist_bin_coverage(ailist_t *ail, double coverage[], int bin_size);

// Calculate coverage within bins of a length
void ailist_bin_coverage_length(ailist_t *ail, double coverage[], int bin_size, int min_length, int max_length);

// Calculate n hits within bins
void ailist_bin_nhits(ailist_t *ail, double coverage[], int bin_size);

// Calculate n hits of a length within bins
void ailist_bin_nhits_length(ailist_t *ail, double coverage[], int bin_size, int min_length, int max_length);

// Calculate average values within bins
void ailist_bin_sums(ailist_t *ail, double sum_values[], int bin_size);

// Add intervals from arrays
void ailist_from_array(ailist_t *ail, const long starts[], const long ends[], const long index[], const double values[], int length);

// Subtract intervals from region
void subtract_intervals(ailist_t *ref_ail, ailist_t *result_ail, interval_t query_i, int j);

// Subtract two ailist_t intervals
ailist_t *ailist_subtract(ailist_t *ail1, ailist_t *ail2);

// Common regions between intervals from region
void common_intervals(ailist_t *ref_ail, ailist_t *result_ail, interval_t query_i, int j);

// Common regions between two ailist_t intervals
ailist_t *ailist_common(ailist_t *ail1, ailist_t *ail2);

// Merge overlapping intervals
ailist_t *ailist_merge(ailist_t *ail, uint32_t gap);

// Calculate Window Protection Score
void ailist_wps(ailist_t *ail, double wps[], uint32_t protection);

// Calculate Window Protection Score within a length
void ailist_wps_length(ailist_t *ail, double wps[], uint32_t protection, int min_length, int max_length);

// Filter ailist by length
ailist_t *ailist_length_filter(ailist_t *ail, int min_length, int max_length);

// Calculate length distribution
void ailist_length_distribution(ailist_t *ail, int distribution[]);

// Calculate maximum length
int ailist_max_length(ailist_t *ail);

// Calculate number of overlaps from arrays
void ailist_nhits_from_array(ailist_t *ail, const long starts[], const long ends[], int length, int nhits[]);

// Calculate number of overlaps from arrays within lengths
void ailist_nhits_from_array_length(ailist_t *ail, const long starts[], const long ends[], int length, int nhits[], int min_length, int max_length);

// Calculate coverage across an interval
void ailist_interval_coverage(ailist_t *ail, int start, int end, int coverage[]);

// Randomly downsample ailist_t
ailist_t *ailist_downsample(ailist_t *ail, double proportion);

// Reset index to be in order
void ailist_reset_index(ailist_t *ail);

// Print AIList
void display_list(ailist_t *ail);


/*********************
 * Convenient macros *
 *********************/

#ifndef kroundup32
#define kroundup32(x) (--(x), (x)|=(x)>>1, (x)|=(x)>>2, (x)|=(x)>>4, (x)|=(x)>>8, (x)|=(x)>>16, ++(x))
#endif

#define CALLOC(type, len) ((type*)calloc((len), sizeof(type)))
#define REALLOC(ptr, len) ((ptr) = (__typeof__(ptr))realloc((ptr), (len) * sizeof(*(ptr))))

#define EXPAND(a, m) do { \
		(m) = (m)? (m) + ((m)>>1) : 16; \
		REALLOC((a), (m)); \
	}while (0) 

#endif
