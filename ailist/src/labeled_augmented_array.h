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

//-------------------------------------------------------------------------------------
#include "utilities.h"
#include "array_query_utilities.h"
#include "labeled_interval.h"
#include "khash.h"

//-------------------------------------------------------------------------------------

static const int khStrInt = 32;
KHASH_MAP_INIT_STR(khStrInt, uint16_t)
typedef khash_t(khStrInt) strhash_t;

static const int khIntStr = 75;
KHASH_MAP_INIT_INT(khIntStr, const char*)
typedef khash_t(khIntStr) inthash_t;

#define kh_name_set(kname, hash, key, val) ({int ret; ks = kh_put(kname, hash,key,&ret); kh_value(hash,ks) = val, kh_key(hash,ks) = strdup(key); ret;})
#define kh_label_set(kname, hash, key, val) ({int ret; ki = kh_put(kname, hash,key,&ret); kh_value(hash,ki) = strdup(val); ret;})

//-------------------------------------------------------------------------------------

typedef struct {
	int64_t nr, mr;						// Number of intervals
	int64_t nl, ml;						// Number of unique labels
	labeled_interval_t *interval_list;	// List of interval_t objects
	int *nc;							// Number of components
	int *lenC;							// Length of components
	int *idxC;							// Index of components in interval_list
	uint32_t *maxE;						// Augmentation
	uint32_t *first;					// Record first position of intervals
	uint32_t *last;						// Record last position of intervals
	uint32_t *label_count;				// Record number of label values
	uint32_t *id_index;					// Record id index values
	void *label_map;					// Hash table to convert labels to int
	void *rev_label_map;				// Hash table to convert labels to int
} labeled_aiarray_t;

typedef struct {
	int size;							// Current size
    int max_size;						// Maximum size
	labeled_aiarray_t *ail;				// Store labeled_aiarray
	long *indices;						// Store indices
} overlap_label_index_t;

typedef struct {
	labeled_aiarray_t *ail;				// Labeled array
	uint16_t label;						// Label
	int nc;								// Number of components
	int label_start;					// First index for label
	int label_end;						// Last index for label
	int *label_comp_bounds;				// Label component bounds
	int *label_comp_used;				// Components used
	labeled_interval_t *intv;			// Interval
	int n;								// Current position
} label_sorted_iter_t;

//-------------------------------------------------------------------------------------
// labeled_augmented_array.c
//=====================================================================================

// Initialize aiarray_t
labeled_aiarray_t *labeled_aiarray_init(void);

// Free aiarray data
void labeled_aiarray_destroy(labeled_aiarray_t *ail);

// Print aiarray
void labeled_display_list(labeled_aiarray_t *ail);

// Print label map
void display_label_map(labeled_aiarray_t *ail);

// Calculate maximum length
int labeled_aiarray_max_length(labeled_aiarray_t *ail);

// Calculate length distribution
void labeled_aiarray_length_distribution(labeled_aiarray_t *ail, int distribution[]);


//-------------------------------------------------------------------------------------
// overlap_label_index.c
//=====================================================================================

// Initialize overlap_label_index_t
overlap_label_index_t *overlap_label_index_init(void);

// Free overlap_label_index memory
void overlap_label_index_destroy(overlap_label_index_t *oi);

// Add interval and index to overlap_label_index
void overlap_label_index_add(overlap_label_index_t *aq, labeled_interval_t i, const char *label_name);


//-------------------------------------------------------------------------------------
// labeled_aiarray_add.c
//=====================================================================================

// Add a interval_t from array
void labeled_aiarray_from_array(labeled_aiarray_t *ail, const long starts[], const long ends[], const char label_names[], int length, int label_str_len);

// Add a interval_t interval
void labeled_aiarray_add(labeled_aiarray_t *ail, uint32_t start, uint32_t end, const char *label_name);

// Add intervals from another labeled_aiarray
void labeled_aiarray_append(labeled_aiarray_t *ail, labeled_aiarray_t *ail2);

// Copy labeled_aiarray
labeled_aiarray_t *labeled_aiarray_copy(labeled_aiarray_t *ail);


//-------------------------------------------------------------------------------------
// labeled_aiarray_get.c
//=====================================================================================

// Determine if label_name is in array
int label_is_present(labeled_aiarray_t *ail, const char *label_name);

// Query label map for label name
uint16_t query_label_map(labeled_aiarray_t *ail, const char *label_name);

// Query rev_label_map for label
const char *query_rev_label_map(labeled_aiarray_t *ail, uint16_t label);

// Get intervals with label name
labeled_aiarray_t *get_label(labeled_aiarray_t *ail, const char *label_name);

// Get intervals with label name and original index
overlap_label_index_t *get_label_with_index(labeled_aiarray_t *ail, const char *label_name);

// Get intervals with labels names from array
labeled_aiarray_t *get_label_array(labeled_aiarray_t *ail, const char *label_names[], int length);

// Get intervals with labels from array and original index
overlap_label_index_t *get_label_array_with_index(labeled_aiarray_t *ail, const char label_names[], int n_labels, int label_str_len);

// Get index start of label
int get_label_index(labeled_aiarray_t *ail, int label);

// Determine label indices
void get_label_index_array(labeled_aiarray_t *ail, int *label_index);

// Get ids for labels in a label array
void get_label_array_ids(labeled_aiarray_t *ail, const char *label_names[], int n_labels, long index[]);

// Determine if an index is of a label array
void get_label_array_presence(labeled_aiarray_t *ail, const char label_names[], int n_labels, uint8_t index[], int label_str_len);


//-------------------------------------------------------------------------------------
// labeled_aiarray_construct.c
//=====================================================================================

// Sort intervals in aiarray
void labeled_aiarray_sort(labeled_aiarray_t *ail);

// Sort intervals by label
void labeled_aiarray_radix_label_sort(labeled_aiarray_t *ail);

// Construct aiarray: decomposition and augmentation
void labeled_aiarray_construct(labeled_aiarray_t *ail, int cLen_init);


//-------------------------------------------------------------------------------------
// labeled_aiarray_iter.c
//=====================================================================================

// Get component index for label
int *get_label_comp_bounds(labeled_aiarray_t *ail, int label);

label_sorted_iter_t *iter_init(labeled_aiarray_t *ail, const char *label_name);

int iter_next(label_sorted_iter_t *iter);

void iter_destroy(label_sorted_iter_t *iter);


//-------------------------------------------------------------------------------------
// labeled_aiarray_match.c
//=====================================================================================

overlap_label_index_t *has_exact_match(labeled_aiarray_t *ail1, labeled_aiarray_t *ail2);

//-------------------------------------------------------------------------------------
// labeled_aiarray_index.c
//=====================================================================================

// Record id positions by id
void labeled_aiarray_cache_id(labeled_aiarray_t *ail);

// Get intervals with ids
labeled_aiarray_t *labeled_aiarray_slice_index(labeled_aiarray_t *ail, const long ids[], int length);

// Get intervals with range
labeled_aiarray_t *labeled_aiarray_slice_range(labeled_aiarray_t *ail, int start, int end, int step);

// Get intervals with boolean array
labeled_aiarray_t *labeled_aiarray_slice_bool(labeled_aiarray_t *ail, uint8_t bool_index[]);

// Get interval with id
labeled_interval_t *labeled_aiarray_get_id(labeled_aiarray_t *ail, int id_value);

// Index aiarray by another aiarray inplace
int labeled_aiarray_index_by_aiarray_inplace(labeled_aiarray_t *ail1, labeled_aiarray_t *ail2);


//-------------------------------------------------------------------------------------
// labeled_aiarray_query.c
//=====================================================================================

// Binary search
uint32_t binary_search_labeled(labeled_interval_t* As, uint32_t idxS, uint32_t idxE, uint32_t qe);

void slice_str(const char *str, char *buffer, size_t start, size_t end);

void slice_str2(const char *str, char *buffer, size_t start, size_t end);

// Base query logic
void labeled_aiarray_query(labeled_aiarray_t *ail, labeled_aiarray_t *overlaps, uint32_t qs, uint32_t qe, const char *label_name);

// Base query logic filtered by length
void labeled_aiarray_query_length(labeled_aiarray_t *ail, labeled_aiarray_t *overlaps, uint32_t qs, uint32_t qe, const char *label_name, int min_length, int max_length);

// Base query logic for nhits
void labeled_aiarray_query_nhits(labeled_aiarray_t *ail, long *nhits, uint32_t qs, uint32_t qe, const char *label_name);

// Base query logic for nhits filtered by length
void labeled_aiarray_query_nhits_length(labeled_aiarray_t *ail, long *nhits, uint32_t qs, uint32_t qe, const char *label_name, int min_length, int max_length);

// Base query logic with index
void labeled_aiarray_query_with_index(labeled_aiarray_t *ail, overlap_label_index_t *overlaps, uint32_t qs, uint32_t qe, const char *label_name);

// Base query logic with index
void labeled_aiarray_query_only_index(labeled_aiarray_t *ail, array_query_t *overlaps, uint32_t qs, uint32_t qe, uint32_t id, const char *label_name);

// Base query logic if present
void labeled_aiarray_query_has_hit(labeled_aiarray_t *ail, uint8_t has_hit[], uint32_t qs, uint32_t qe, const char *label_name);

// Query interval
labeled_aiarray_t *labeled_aiarray_query_single(labeled_aiarray_t *ail, uint32_t qs, uint32_t qe, const char *label_name);

// Query aiarray intervals of a length
labeled_aiarray_t *labeled_aiarray_query_single_length(labeled_aiarray_t *ail, uint32_t qs, uint32_t qe, const char *label_name, int min_length, int max_length);

// Query aiarray intervals from arrays
array_query_t *labeled_aiarray_query_from_array(labeled_aiarray_t *ail, const long starts[], const long ends[], const char label_names[], int length, int label_str_len);

// Query aiarray intervals from aiarray
array_query_t *labeled_aiarray_query_from_labeled_aiarray(labeled_aiarray_t *ail, labeled_aiarray_t *ail2);

// Query aiarray intervals and record original index
overlap_label_index_t *labeled_aiarray_query_single_with_index(labeled_aiarray_t *ail, uint32_t qs, uint32_t qe, const char *label_name);

// Query aiarray intervals and record original index from labled_aiarray
overlap_label_index_t *labeled_aiarray_query_with_index_from_labeled_aiarray(labeled_aiarray_t *ail, labeled_aiarray_t *ail2);


//-------------------------------------------------------------------------------------
// labeled_aiarray_has_hits.c
//=====================================================================================

// Determine if hit is present for each query interval
void labeled_aiarray_has_hit_from_array(labeled_aiarray_t *ail, const long starts[], const long ends[],
                                        const char label_names[], int length, int label_str_len, uint8_t has_hit[]);

//-------------------------------------------------------------------------------------
// labeled_aiarray_nhits.c
//=====================================================================================

// Determine number of hits for interval
long labeled_aiarray_nhits(labeled_aiarray_t *ail, long start, long end, const char *label_name);

// Determine number of hits for interval of a length
long labeled_aiarray_nhits_length(labeled_aiarray_t *ail, long start, long end, const char *label_name, int min_length, int max_length);

// Determine number of hits for each query interval
void labeled_aiarray_nhits_from_array(labeled_aiarray_t *ail, const long starts[], const long ends[],
										const char *label_names[], int length, int nhits[]);

// Determine number of hits of a length for each query interval
void labeled_aiarray_nhits_from_array_length(labeled_aiarray_t *ail, const long starts[], const long ends[],
											const char *label_names[], int length, int nhits[], int min_length,
											int max_length);

// Calculate n hits within bins
void labeled_aiarray_bin_nhits(labeled_aiarray_t *ail, labeled_aiarray_t *bins, double nhits[], int bin_size);

// Calculate n hits of a length within bins
void labeled_aiarray_bin_nhits_length(labeled_aiarray_t *ail, labeled_aiarray_t *bins, double nhits[], int bin_size,
										int min_length, int max_length);


//-------------------------------------------------------------------------------------
// labeled_aiarray_wps.c
//=====================================================================================

// Calculate Window Protection Score for a label
void labeled_aiarray_label_wps(labeled_interval_t *interval_list, double wps[], uint32_t protection, int nr, int first, int last);

// Calculate Window Protection Score
void labeled_aiarray_wps(labeled_aiarray_t *ail, double wps[], uint32_t protection);

// Calculate Window Protection Score for a label of a length
void labeled_aiarray_label_wps_length(labeled_interval_t *interval_list, double wps[], uint32_t protection, int nr, int first, int last,
										int min_length, int max_length);

// Calculate Window Protection Score of a length
void labeled_aiarray_wps_length(labeled_aiarray_t *ail, double wps[], uint32_t protection, int min_length, int max_length);


//-------------------------------------------------------------------------------------
// labeled_aiarray_coverage.c
//=====================================================================================

// Determine coverage for an interval
void labeled_aiarray_interval_coverage(labeled_aiarray_t *ail, int start, int end, const char *label_name, int coverage[]);

// Calculate coverage for a label
void labeled_aiarray_label_coverage(labeled_interval_t *interval_list, double coverage[], const char *label_name, int nr);

// Calculate coverage
void labeled_aiarray_coverage(labeled_aiarray_t *ail, double coverage[]);

//-------------------------------------------------------------------------------------
// labeled_aiarray_merge.c
//=====================================================================================

// Merge nearby intervals
labeled_aiarray_t *labeled_aiarray_merge(labeled_aiarray_t *ail, uint32_t gap);


//-------------------------------------------------------------------------------------
// labeled_aiarray_filter.c
//=====================================================================================

// Filter labeled_aiarray by length
labeled_aiarray_t *labeled_aiarray_length_filter(labeled_aiarray_t *ail, int min_length, int max_length);

// Randomly downsample
labeled_aiarray_t *labeled_aiarray_downsample(labeled_aiarray_t *ail, double proportion);

// Randomly downsample with original index
overlap_label_index_t *labeled_aiarray_downsample_with_index(labeled_aiarray_t *ail, double proportion);


//-------------------------------------------------------------------------------------
// labeled_aiarray_extract.c
//=====================================================================================

// Extract start for labeled_aiarray
void labeled_aiarray_extract_starts(labeled_aiarray_t *ail, long starts[]);

// Extract end for labeled_aiarray
void labeled_aiarray_extract_ends(labeled_aiarray_t *ail, long ends[]);

// Extract id for labeled_aiarray
void labeled_aiarray_extract_ids(labeled_aiarray_t *ail, long ids[]);


int main();

#endif