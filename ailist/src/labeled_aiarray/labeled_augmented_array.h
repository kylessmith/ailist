//=====================================================================================
// Common structs, parameters, functions
// Original: https://github.com/databio/aiarray/tree/master/src
// by Kyle S. Smith and Jianglin Feng
//-------------------------------------------------------------------------------------
#ifndef __LABELED_AIARRAY_H__
#define __LABELED_AIARRAY_H__
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>
#include <math.h>
#include <assert.h>
//#include <omp.h>

//-------------------------------------------------------------------------------------

#include "../ailist/augmented_interval_list.h"
#include "khash.h"
#include "kvec.h"

//-------------------------------------------------------------------------------------

static const int khStrInt = 32;
KHASH_MAP_INIT_STR(khStrInt, uint32_t);
typedef khash_t(khStrInt) strhash_t;

#define kh_name_set(kname, hash, key, val) ({int ret; k = kh_put(kname, hash,key,&ret); kh_value(hash,k) = val, kh_key(hash,k) = strdup(key); ret;})

//-------------------------------------------------------------------------------------

typedef struct{
	const char *name;    				// Name of the label
	ailist_t *ail;						// AIList object
} label_t;

typedef struct{
	const char *name;
	interval_t *i;
} labeled_interval_t;

typedef struct {	
	label_t *labels;        			// List of Labels (of size _n_ctg_)
	int32_t n_labels, max_labels; 		// Number and max number of labels
	void *label_lookup;             	// Dict for converting label names to int
	uint32_t *first;					// Record first position of intervals
	uint32_t *last;						// Record last position of intervals
	int64_t total_nr;					// Total number of regions
	uint32_t *id_index;					// Record id index values
	int16_t is_constructed;				// Flag for whether constructed or not
} labeled_aiarray_t;

typedef struct {
	const char *name;					// Label
	ailist_sorted_iter_t *ail_iter;		// Sorted AIList iterator
	interval_t *intv;					// Interval
} label_sorted_iter_t;

typedef struct {
	labeled_aiarray_t *laia;			// Labeled aiarray
	int n;								// Current position
	labeled_interval_t *intv;			// Interval
	const char *name;					// Label
} labeled_aiarray_iter_t;

typedef struct {
	labeled_aiarray_t *ref_laia;		// Labeled aiarray
	labeled_aiarray_iter_t *query_iter;	// Query iterator
	labeled_aiarray_t *overlaps;		// Overlaps
} labeled_aiarray_overlap_iter_t;

typedef struct {
	int size;							// Current size
    int max_size;						// Maximum size
	labeled_aiarray_t *laia;			// Store labeled_aiarray
	long *indices;						// Store indices
} overlap_label_index_t;


//-------------------------------------------------------------------------------------
// labeled_augmented_array.c
//=====================================================================================

// Initialize aiarray_t
labeled_aiarray_t *labeled_aiarray_init(void);

labeled_interval_t *labeled_interval_init(interval_t *i, const char* label_name);

// Free aiarray data
void labeled_aiarray_destroy(labeled_aiarray_t *laia);

// Return index for given label
int32_t get_label(const labeled_aiarray_t *laia, const char *label);

// Extract strings from array
void slice_str(const char *str, char *buffer, size_t start, size_t end);

// Print labeled_aiarray
void labeled_aiarray_print(labeled_aiarray_t *laia);

// Calculate maximum length
int labeled_aiarray_max_length(labeled_aiarray_t *laia);

// Calculate length distribution
void labeled_aiarray_length_distribution(labeled_aiarray_t *laia, int distribution[]);

//-------------------------------------------------------------------------------------
// overlap_label_index.c
//=====================================================================================

// Initialize overlap_index
overlap_label_index_t *overlap_label_index_init(void);

// Free overlap_label_index memory
void overlap_label_index_destroy(overlap_label_index_t *oi);

// Add interval to overlap_label_index
void overlap_label_index_add(overlap_label_index_t *oi, interval_t i, const char *label_name);

void overlap_label_index_wrap_ail(overlap_label_index_t * oi, ailist_t *ail, const char *label_name);


//-------------------------------------------------------------------------------------
// labeled_aiarray_add.c
//=====================================================================================

// Expand and add label
void labeled_aiarray_add_label(labeled_aiarray_t *laia, const char*label);

// Add a interval_t interval
void labeled_aiarray_add(labeled_aiarray_t *laia, uint32_t s, uint32_t e, const char *label);

// Link memory of single label labeled_aiarrays and transfer data owership
void labeled_aiarray_multi_merge(labeled_aiarray_t *laia, labeled_aiarray_t **laia_array, int length);

// Add a interval_t from array
void labeled_aiarray_from_array(labeled_aiarray_t *laia, const long starts[], const long ends[], const char label_names[], int length, int label_str_len);

// Add intervals from another labeled_aiarray
void labeled_aiarray_append(labeled_aiarray_t *laia, labeled_aiarray_t *laia2);

// Copy labeled_aiarray
labeled_aiarray_t *labeled_aiarray_copy(labeled_aiarray_t *laia);

// Append AIList in labeled_aiarry
void labeled_aiarray_append_ail(labeled_aiarray_t *laia, ailist_t *ail, const char *label_name);

// Wrap AIList in labeled_aiarry
void labeled_aiarray_wrap_ail(labeled_aiarray_t *laia, ailist_t *ail, const char *label_name);


//-------------------------------------------------------------------------------------
// labeled_aiarray_construct.c
//=====================================================================================

// Construct aiarray: decomposition and augmentation
void labeled_aiarray_construct(labeled_aiarray_t *laia, int cLen);

// Validation construction ran
int labeled_aiarray_validate_construction(labeled_aiarray_t *laia);

// Deconstruct
void labeled_aiarray_deconstruct(labeled_aiarray_t *laia);


//-------------------------------------------------------------------------------------
// labeled_aiarray_query_single.c
//=====================================================================================

// Base query logic
void labeled_aiarray_query(labeled_aiarray_t *laia, labeled_aiarray_t *overlaps, const char *label, uint32_t qs, uint32_t qe);

// Base query logic filtered by length
void labeled_aiarray_query_length(labeled_aiarray_t *laia, labeled_aiarray_t *overlaps, const char *label_name, 
                                  uint32_t qs, uint32_t qe, int min_length, int max_length);

// Base query logic for nhits
void labeled_aiarray_query_nhits(labeled_aiarray_t *laia, long *nhits, const char *label_name, uint32_t qs, uint32_t qe);

// Base query logic for nhits filtered by length
void labeled_aiarray_query_nhits_length(labeled_aiarray_t *laia, long *nhits, const char *label_name, uint32_t qs,
                                        uint32_t qe, int min_length, int max_length);

// Base query logic if present
void labeled_aiarray_query_has_hit(labeled_aiarray_t *laia, const char *label_name, uint8_t *has_hit, uint32_t qs, uint32_t qe);


//-------------------------------------------------------------------------------------
// labeled_aiarray_query_index.c
//=====================================================================================

// Base query logic with index
void labeled_aiarray_query_with_index(labeled_aiarray_t *laia, const char *label_name, overlap_label_index_t *overlaps, uint32_t qs, uint32_t qe);

// Query with index from arrays
void labeled_aiarray_query_with_index_from_array(labeled_aiarray_t *laia, overlap_label_index_t *overlaps, const char label_names[], const long starts[], const long ends[], int length, int label_str_len);

// Query with index from labeled_aiarray
void labeled_aiarray_query_with_index_from_labeled_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *other_laia, overlap_label_index_t *overlaps);


//-------------------------------------------------------------------------------------
// labeled_aiarray_query_array.c
//=====================================================================================

// Base query logic with index
void labeled_aiarray_query_only_index(labeled_aiarray_t *laia, const char *label_name, array_query_t *overlaps, uint32_t qs, uint32_t qe, uint32_t id);

// Query aiarray intervals from array
array_query_t *labeled_aiarray_query_index_from_array(labeled_aiarray_t *laia, const char label_names[], const long starts[], const long ends[], int length, int label_str_len);

// Query intervals from array
void labeled_aiarray_query_from_array(labeled_aiarray_t *laia, labeled_aiarray_t *overlaps, const char label_names[], const long starts[], const long ends[], int length, int label_str_len);

// Query array if present
void labeled_aiarray_query_has_hit_from_array(labeled_aiarray_t *laia, const char label_names[], const long starts[], const long ends[], int length, int label_str_len, uint8_t has_hit[]);

// Query aiarray intervals from aiarray
void labeled_aiarray_query_from_labeled_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *laia2, labeled_aiarray_t *overlaps);

// Query aiarray intervals from aiarray
void labeled_aiarray_query_index_from_labeled_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *laia2, array_query_t *aq);


//-------------------------------------------------------------------------------------
// labeled_aiarray_index.c
//=====================================================================================

void labeled_aiarray_cache_id(labeled_aiarray_t *ail);

labeled_interval_t *labeled_aiarray_get_index(labeled_aiarray_t *ail, int32_t i);

labeled_aiarray_t *labeled_aiarray_slice_index(labeled_aiarray_t *laia, const long ids[], int length);

labeled_aiarray_t *labeled_aiarray_slice_range(labeled_aiarray_t *laia, int start, int end, int step);

labeled_aiarray_t *labeled_aiarray_slice_bool(labeled_aiarray_t *laia, uint8_t bool_index[]);

int labeled_aiarray_index_with_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *other_laia);


//-------------------------------------------------------------------------------------
// labeled_aiarray_iter.c
//=====================================================================================

label_sorted_iter_t *label_sorted_iter_init(labeled_aiarray_t *laia, const char *label_name);

int label_sorted_iter_next(label_sorted_iter_t *iter);

void label_sorted_iter_destroy(label_sorted_iter_t *iter);

labeled_aiarray_iter_t *labeled_aiarray_iter_init(labeled_aiarray_t *laia);

int labeled_aiarray_iter_next(labeled_aiarray_iter_t *iter);

void labeled_aiarray_iter_destroy(labeled_aiarray_iter_t *iter);

labeled_aiarray_overlap_iter_t *labeled_aiarray_overlap_iter_init(labeled_aiarray_t *ref_laia, labeled_aiarray_t *query_laia);

int labeled_aiarray_overlap_iter_next(labeled_aiarray_overlap_iter_t *iter);

void labeled_aiarray_overlap_iter_destroy(labeled_aiarray_overlap_iter_t *iter);


//-------------------------------------------------------------------------------------
// labeled_aiarray_nhits.c
//=====================================================================================

void labeled_aiarray_nhits(labeled_aiarray_t *laia, long *nhits, const char *label_name, uint32_t qs, uint32_t qe);

void labeled_aiarray_nhits_length(labeled_aiarray_t *laia, long *nhits, const char *label_name, uint32_t qs,
                                        uint32_t qe, int min_length, int max_length);

void labeled_aiarray_nhits_from_array(labeled_aiarray_t *laia, const char label_names[], const long starts[], const long ends[],
										int length, int label_str_len, long *nhits);

void labeled_aiarray_nhits_from_array_length(labeled_aiarray_t *laia, const char label_names[], const long starts[], const long ends[],
                                        int length, int label_str_len, long *nhits, int min_length, int max_length);

void labeled_aiarray_nhits_from_labeled_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *other_laia,
                                                long *nhits);

void labeled_aiarray_nhits_from_labeled_aiarray_length(labeled_aiarray_t *laia, labeled_aiarray_t *other_laia,
                                                long *nhits, int min_length, int max_length);

void labeled_aiarray_has_hit(labeled_aiarray_t *laia, const char *label_name, uint8_t has_hit[], uint32_t qs, uint32_t qe);

void labeled_aiarray_bin_nhits(labeled_aiarray_t *laia, long *nhits, int bin_size);

void labeled_aiarray_bin_nhits_length(labeled_aiarray_t *laia, long *nhits, int bin_size, int min_length, int max_length);


//-------------------------------------------------------------------------------------
// labeled_aiarray_coverage.c
//=====================================================================================

// Determine coverage for an interval
void labeled_aiarray_interval_coverage(labeled_aiarray_t *laia, int start, int end, const char *label_name, int coverage[]);

// Calculate coverage for a label
void labeled_aiarray_label_coverage(labeled_aiarray_t *laia, double coverage[], const char *label_name);

// Calculate coverage for a label of a length
void labeled_aiarray_label_coverage_length(labeled_aiarray_t *laia, double coverage[], const char *label_name,
                                            int min_length, int max_length);

// Calculate coverage within bins
void labeled_aiarray_label_bin_coverage(labeled_aiarray_t *laia, double coverage[], int bin_size, const char *label_name);

// Calculate coverage of intervals of a given length within bins
void labeled_aiarray_label_bin_coverage_length(labeled_aiarray_t *laia, double coverage[], int bin_size, const char *label_name,
                                                int min_length, int max_length);

// Calculate interval midpoint coverage
void labeled_aiarray_label_midpoint_coverage(labeled_aiarray_t *laia, double coverage[], const char *label_name);

// Calculate interval midpoitn coverage with lengths
void labeled_aiarray_label_midpoint_coverage_length(labeled_aiarray_t *laia, double coverage[], const char *label_name,
                                                    int min_length, int max_length);


//-------------------------------------------------------------------------------------
// labeled_aiarray_wps.c
//=====================================================================================

// Calculate Window Protection Score for a label
void labeled_aiarray_label_wps(labeled_aiarray_t *laia, double wps[], uint32_t protection, const char *label_name);

// Calculate Window Protection Score for a label of a length
void labeled_aiarray_label_wps_length(labeled_aiarray_t *laia, double wps[], uint32_t protection, int min_length, int max_length, const char *label_name);


//-------------------------------------------------------------------------------------
// labeled_aiarray_merge.c
//=====================================================================================

// Merge nearby intervals
labeled_aiarray_t *labeled_aiarray_merge(labeled_aiarray_t *laia, uint32_t gap);


//-------------------------------------------------------------------------------------
// labeled_aiarray_filter.c
//=====================================================================================

// Filter labeled_aiarray by length 
labeled_aiarray_t *labeled_aiarray_length_filter(labeled_aiarray_t *laia, int min_length, int max_length);

// Randomly downsample 
labeled_aiarray_t *labeled_aiarray_downsample(labeled_aiarray_t *laia, double proportion);

overlap_label_index_t *labeled_aiarray_downsample_with_index(labeled_aiarray_t *laia, double proportion);

//-------------------------------------------------------------------------------------
// labeled_aiarray_extract.c
//=====================================================================================

// Extract start for labeled_aiarray
void labeled_aiarray_extract_starts(labeled_aiarray_t *laia, long starts[]);

// Extract end for labeled_aiarray
void labeled_aiarray_extract_ends(labeled_aiarray_t *laia, long ends[]);

// Extract id for labeled_aiarray
void labeled_aiarray_extract_ids(labeled_aiarray_t *laia, long ids[]);


//-------------------------------------------------------------------------------------
// labeled_aiarray_match.c
//=====================================================================================

// Return all exact matches between labeled_aiarrays
overlap_label_index_t *labeled_aiarray_exact_match(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2);

void labeled_aiarray_has_exact_match(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2, uint8_t has_match[]);

// Return exact matches between labeled_aiarrays
void labeled_aiarray_is_exact_match(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2, uint8_t has_match_laia1[], uint8_t has_match_laia2[]);

// Return exact matches between labeled_aiarrays
void labeled_aiarray_which_exact_match(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2, array_query_t *matches);

// Return exact match between labeled_aiarray and an interval
int labeled_aiarray_where_interval(labeled_aiarray_t *laia, const char *label, uint32_t qs, uint32_t qe);


//-------------------------------------------------------------------------------------
// labeled_aiarray_get.c
//=====================================================================================

// Get intervals with label name
labeled_aiarray_t *labeled_aiarray_get_label(labeled_aiarray_t *laia, const char *label_name);

// Get intervals with label name
labeled_aiarray_t *labeled_aiarray_view_label(labeled_aiarray_t *laia, const char *label_name);

// Get intervals with label name and original index
overlap_label_index_t *labeled_aiarray_get_label_with_index(labeled_aiarray_t *laia, const char *label_name);

// Get intervals with labels names from array
labeled_aiarray_t *labeled_aiarray_get_label_array(labeled_aiarray_t *laia, const char label_names[], int n_labels, int label_str_len);

// Get intervals with labels from array and original index
overlap_label_index_t *labeled_aiarray_get_label_array_with_index(labeled_aiarray_t *laia, const char label_names[], int n_labels, int label_str_len);

// Determine if an index is of a label array
void labeled_aiarray_get_label_array_presence(labeled_aiarray_t *ail, const char label_names[], int n_labels, uint8_t index[], int label_str_len);


//-------------------------------------------------------------------------------------
// labeled_aiarray_sort.c
//=====================================================================================

// Sort intervals by actual order
void labeled_aiarray_order_sort(labeled_aiarray_t *laia);

// Sort intervals by starts
void labeled_aiarray_sort_index(labeled_aiarray_t *laia, long *index);

// Sort intervals by starts
void labeled_aiarray_sort(labeled_aiarray_t *laia);


//-------------------------------------------------------------------------------------
// labeled_aiarray_simulate.c
//=====================================================================================

// Simulate intervals
void labeled_aiarray_simulate(labeled_aiarray_t *laia, labeled_aiarray_t *sim_laia);

//-------------------------------------------------------------------------------------
// labeled_aiarray_ops.c
//=====================================================================================

// Find common intervals between two labeled_aiarrays
labeled_aiarray_t *labeled_aiarray_common(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2);

// Subtract intervals from laia1 that are in laia2
labeled_aiarray_t *labeled_aiarray_subtract(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2);

// Find union of intervals between two labeled_aiarrays
labeled_aiarray_t *labeled_aiarray_union(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2);


//-------------------------------------------------------------------------------------
// labeled_aiarray_percent.c
//=====================================================================================

// Find percent coverage of intervals in laia1 that are in laia2
void labeled_aiarray_percent_coverage(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2, double coverage[]);

int main();

#endif