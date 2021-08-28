import numpy as np
cimport numpy as np
cimport cython
from libc.stdint cimport uint32_t, int32_t, int64_t, uint16_t
from libc.stdlib cimport malloc, free
from .LabeledInterval_core cimport *
from .array_query_core cimport *
ctypedef np.uint8_t uint8


cdef extern from "src/labeled_augmented_array.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/overlap_label_index.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_add.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_get.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_construct.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_index.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_query.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_has_hit.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_nhits.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_wps.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_coverage.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_merge.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_filter.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_extract.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_iter.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray_match.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/khash.h":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_augmented_array.h":

	ctypedef struct labeled_aiarray_t:
		int64_t nr							# Number of intervals
		int64_t mr							# Max number of intervals
		int64_t nl							# Number of unique labels
		int64_t ml							# Max number of unique labels
		labeled_interval_t *interval_list	# List of interval_t objects
		int *nc								# Number of components
		int *lenC							# Length of components
		int *idxC							# Index of components in interval_list
		uint32_t *maxE						# Augmentation
		uint32_t *first						# Record first position of intervals
		uint32_t *last						# Record last position of intervals
		uint32_t *label_count				# Record number of label values
		void *label_map						# Hash table to convert labels to int
		void *rev_label_map					# Hash table to convert labels to int
	
	# C overlap_label_index struct
	ctypedef struct overlap_label_index_t:
		int size							# Current size
		int max_size						# Maximum size
		labeled_aiarray_t *ail				# Store labeled_aiarray
		long *indices						# Store indices

	ctypedef struct label_sorted_iter_t:
		labeled_aiarray_t *ail				# Labeled array
		uint16_t label						# Label
		int nc								# Number of components
		int label_start						# First index for label
		int label_end						# Last index for label
		int *label_comp_bounds				# Label component bounds
		int *label_comp_used				# Components used
		labeled_interval_t *intv			# Interval
		int n								# Current position


	#-------------------------------------------------------------------------------------
	# labeled_augmented_array.c
	#=====================================================================================

	# Initialize aiarray_t
	labeled_aiarray_t *labeled_aiarray_init() nogil

	# Free aiarray data
	void labeled_aiarray_destroy(labeled_aiarray_t *ail) nogil

	# Print aiarray
	void labeled_display_list(labeled_aiarray_t *ail) nogil

	# Print label map
	void display_label_map(labeled_aiarray_t *ail) nogil

	# Calculate maximum length
	int labeled_aiarray_max_length(labeled_aiarray_t *ail) nogil

	# Calculate length distribution
	void labeled_aiarray_length_distribution(labeled_aiarray_t *ail, int distribution[]) nogil


	#-------------------------------------------------------------------------------------
	# overlap_label_index.c
	#=====================================================================================

	# Initialize overlap_label_index_t
	overlap_label_index_t *overlap_label_index_init() nogil

	# Free overlap_label_index memory
	void overlap_label_index_destroy(overlap_label_index_t *oi) nogil

	# Add interval and index to overlap_label_index
	void overlap_label_index_add(overlap_label_index_t *aq, labeled_interval_t i, const char *label_name) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_add.c
	#=====================================================================================

	# Add a interval_t from array
	void labeled_aiarray_from_array(labeled_aiarray_t *ail, const long starts[], const long ends[], const char label_names[], int length, int label_str_len) nogil

	# Add a interval_t interval
	void labeled_aiarray_add(labeled_aiarray_t *ail, uint32_t start, uint32_t end, const char *label_name) nogil

	# Add intervals from another labeled_aiarray
	void labeled_aiarray_append(labeled_aiarray_t *ail, labeled_aiarray_t *ail2) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_get.c
	#=====================================================================================

	# Determine if label_name is in array
	int label_is_present(labeled_aiarray_t *ail, const char *label_name) nogil

	# Query label map for label name
	uint16_t query_label_map(labeled_aiarray_t *ail, const char *label_name) nogil

	# Query rev_label_map for label
	const char *query_rev_label_map(labeled_aiarray_t *ail, uint16_t label) nogil

	# Get intervals with label name
	labeled_aiarray_t *get_label(labeled_aiarray_t *ail, const char *label_name) nogil

	# Get intervals with label name and original index
	overlap_label_index_t *get_label_with_index(labeled_aiarray_t *ail, const char *label_name) nogil

	# Get intervals with labels names from array
	labeled_aiarray_t *get_label_array(labeled_aiarray_t *ail, const char *label_names[], int length) nogil

	# Get intervals with labels from array and original index
	overlap_label_index_t *get_label_array_with_index(labeled_aiarray_t *ail, const char label_names[], int n_labels, int label_str_len) nogil

	# Get index start of label
	int get_label_index(labeled_aiarray_t *ail, int label) nogil

	# Determine label indices
	void get_label_index_array(labeled_aiarray_t *ail, int *label_index) nogil

	# Get ids for labels in a label array
	void get_label_array_ids(labeled_aiarray_t *ail, const char *label_names[], int n_labels, long index[]) nogil

	# Determine if an index is of a label array
	void get_label_array_presence(labeled_aiarray_t *ail, const char label_names[], int n_labels, uint8 index[], int label_str_len) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_construct.c
	#=====================================================================================

	# Sort intervals in aiarray
	void labeled_aiarray_sort(labeled_aiarray_t *ail) nogil

	# Sort intervals by label
	void labeled_aiarray_radix_label_sort(labeled_aiarray_t *ail) nogil

	# Construct aiarray: decomposition and augmentation
	void labeled_aiarray_construct(labeled_aiarray_t *ail, int cLen_init) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_iter.c
	#=====================================================================================

	# Get component index for label
	int *get_label_comp_bounds(labeled_aiarray_t *ail, int label) nogil

	label_sorted_iter_t *iter_init(labeled_aiarray_t *ail, const char *label_name) nogil

	int iter_next(label_sorted_iter_t *iterator) nogil

	void iter_destroy(label_sorted_iter_t *iterator) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_match.c
	#=====================================================================================

	overlap_label_index_t *has_exact_match(labeled_aiarray_t *ail1, labeled_aiarray_t *ail2) nogil

	#-------------------------------------------------------------------------------------
	# labeled_aiarray_index.c
	#=====================================================================================

	# Record id positions by id
	void labeled_aiarray_cache_id(labeled_aiarray_t *ail) nogil

	# Get intervals with ids
	labeled_aiarray_t *labeled_aiarray_slice_index(labeled_aiarray_t *ail, const long ids[], int length) nogil

	# Get intervals with range
	labeled_aiarray_t *labeled_aiarray_slice_range(labeled_aiarray_t *ail, int start, int end, int step) nogil

	# Get intervals with boolean array
	labeled_aiarray_t *labeled_aiarray_slice_bool(labeled_aiarray_t *ail, uint8 bool_index[]) nogil

	# Get interval with id
	labeled_interval_t *labeled_aiarray_get_id(labeled_aiarray_t *ail, int id_value) nogil

	# Index aiarray by another aiarray inplace
	int labeled_aiarray_index_by_aiarray_inplace(labeled_aiarray_t *ail1, labeled_aiarray_t *ail2) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_query.c
	#=====================================================================================

	# Binary search
	uint32_t binary_search_labeled(labeled_interval_t* As, uint32_t idxS, uint32_t idxE, uint32_t qe) nogil

	# Base query logic
	void labeled_aiarray_query(labeled_aiarray_t *ail, labeled_aiarray_t *overlaps, uint32_t qs, uint32_t qe, const char *label_name) nogil

	# Base query logic filtered by length
	void labeled_aiarray_query_length(labeled_aiarray_t *ail, labeled_aiarray_t *overlaps, uint32_t qs, uint32_t qe, const char *label_name, int min_length, int max_length) nogil

	# Base query logic for nhits
	void labeled_aiarray_query_nhits(labeled_aiarray_t *ail, long *nhits, uint32_t qs, uint32_t qe, const char *label_name) nogil

	# Base query logic for nhits filtered by length
	void labeled_aiarray_query_nhits_length(labeled_aiarray_t *ail, long *nhits, uint32_t qs, uint32_t qe, const char *label_name, int min_length, int max_length) nogil

	# Base query logic with index
	void labeled_aiarray_query_with_index(labeled_aiarray_t *ail, overlap_label_index_t *overlaps, uint32_t qs, uint32_t qe, const char *label_name) nogil

	# Base query logic with index
	void labeled_aiarray_query_only_index(labeled_aiarray_t *ail, array_query_t *overlaps, uint32_t qs, uint32_t qe, uint32_t id_value, const char *label_name) nogil

	# Base query logic if present
	void labeled_aiarray_query_has_hit(labeled_aiarray_t *ail, uint8 has_hit[], uint32_t qs, uint32_t qe, const char *label_name) nogil

	# Query interval
	labeled_aiarray_t *labeled_aiarray_query_single(labeled_aiarray_t *ail, uint32_t qs, uint32_t qe, const char *label_name) nogil

	# Query aiarray intervals of a length
	labeled_aiarray_t *labeled_aiarray_query_single_length(labeled_aiarray_t *ail, uint32_t qs, uint32_t qe, const char *label_name, int min_length, int max_length) nogil

	# Query aiarray intervals from arrays
	array_query_t *labeled_aiarray_query_from_array(labeled_aiarray_t *ail, const long starts[], const long ends[], const char label_names[], int length, int label_str_len) nogil

	# Query aiarray intervals from aiarray
	array_query_t *labeled_aiarray_query_from_labeled_aiarray(labeled_aiarray_t *ail, labeled_aiarray_t *ail2) nogil

	# Query aiarray intervals and record original index
	overlap_label_index_t *labeled_aiarray_query_single_with_index(labeled_aiarray_t *ail, uint32_t qs, uint32_t qe, const char *label_name) nogil

	# Query aiarray intervals and record original index from labled_aiarray
	overlap_label_index_t *labeled_aiarray_query_with_index_from_labeled_aiarray(labeled_aiarray_t *ail, labeled_aiarray_t *ail2) nogil

	
	#-------------------------------------------------------------------------------------
	# labeled_aiarray_has_hits.c
	#=====================================================================================

	# Determine if hit is present for each query interval
	void labeled_aiarray_has_hit_from_array(labeled_aiarray_t *ail, const long starts[], const long ends[],
                                        const char label_names[], int length, int label_str_len, uint8 has_hit[]) nogil

	#-------------------------------------------------------------------------------------
	# labeled_aiarray_nhits.c
	#=====================================================================================

	# Determine number of hits for interval
	long labeled_aiarray_nhits(labeled_aiarray_t *ail, long start, long end, const char *label_name) nogil

	# Determine number of hits for interval of a length
	long labeled_aiarray_nhits_length(labeled_aiarray_t *ail, long start, long end, const char *label_name, int min_length, int max_length) nogil

	# Determine number of hits for each query interval
	void labeled_aiarray_nhits_from_array(labeled_aiarray_t *ail, const long starts[], const long ends[],
											const char *label_names[], int length, int nhits[]) nogil

	# Determine number of hits of a length for each query interval
	void labeled_aiarray_nhits_from_array_length(labeled_aiarray_t *ail, const long starts[], const long ends[],
												const char *label_names[], int length, int nhits[], int min_length,
												int max_length) nogil

	# Calculate n hits within bins
	void labeled_aiarray_bin_nhits(labeled_aiarray_t *ail, labeled_aiarray_t *bins, double nhits[], int bin_size) nogil

	# Calculate n hits of a length within bins
	void labeled_aiarray_bin_nhits_length(labeled_aiarray_t *ail, labeled_aiarray_t *bins, double nhits[], int bin_size,
											int min_length, int max_length) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_wps.c
	#=====================================================================================

	# Calculate Window Protection Score for a label
	void labeled_aiarray_label_wps(labeled_interval_t *interval_list, double wps[], uint32_t protection, int nr, int first, int last) nogil

	# Calculate Window Protection Score
	void labeled_aiarray_wps(labeled_aiarray_t *ail, double wps[], uint32_t protection) nogil

	# Calculate Window Protection Score for a label of a length
	void labeled_aiarray_label_wps_length(labeled_interval_t *interval_list, double wps[], uint32_t protection, int nr, int first, int last,
											int min_length, int max_length) nogil

	# Calculate Window Protection Score of a length
	void labeled_aiarray_wps_length(labeled_aiarray_t *ail, double wps[], uint32_t protection, int min_length, int max_length) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_coverage.c
	#=====================================================================================

	# Determine coverage for an interval
	void labeled_aiarray_interval_coverage(labeled_aiarray_t *ail, int start, int end, const char *label_name, int coverage[]) nogil

	# Calculate coverage for a label
	void labeled_aiarray_label_coverage(labeled_interval_t *interval_list, double coverage[], const char *label_name, int nr) nogil

	# Calculate coverage
	void labeled_aiarray_coverage(labeled_aiarray_t *ail, double coverage[]) nogil

	#-------------------------------------------------------------------------------------
	# labeled_aiarray_merge.c
	#=====================================================================================

	# Merge nearby intervals
	labeled_aiarray_t *labeled_aiarray_merge(labeled_aiarray_t *ail, uint32_t gap) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_filter.c
	#=====================================================================================

	# Filter labeled_aiarray by length
	labeled_aiarray_t *labeled_aiarray_length_filter(labeled_aiarray_t *ail, int min_length, int max_length) nogil

	# Randomly downsample
	labeled_aiarray_t *labeled_aiarray_downsample(labeled_aiarray_t *ail, double proportion) nogil

	# Randomly downsample with original index
	overlap_label_index_t *labeled_aiarray_downsample_with_index(labeled_aiarray_t *ail, double proportion) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_extract.c
	#=====================================================================================

	# Extract start for labeled_aiarray
	void labeled_aiarray_extract_starts(labeled_aiarray_t *ail, long starts[]) nogil

	# Extract end for labeled_aiarray
	void labeled_aiarray_extract_ends(labeled_aiarray_t *ail, long ends[]) nogil

	# Extract id for labeled_aiarray
	void labeled_aiarray_extract_ids(labeled_aiarray_t *ail, long ids[]) nogil


cpdef object rebuild_LabeledIntervalArray(bytes data, bytes b_length, bytes b_label_list)

cdef class LabeledIntervalArray(object):
	"""
	Wrapper for C aiarray_t
	"""

	# Define class properties
	cdef labeled_aiarray_t *ail
	cdef public bint is_constructed
	cdef public bint is_closed
	cdef public bint is_frozen

	# Functions for serialization
	cdef bytes _get_data(self)
	cdef labeled_aiarray_t *_set_data(self, bytes data, bytes b_length, bytes b_label_list)

	# Class methods
	cdef void set_list(LabeledIntervalArray self, labeled_aiarray_t *input_list)

	cdef labeled_aiarray_t *_array_index(LabeledIntervalArray self, const long[::1] ids)
	cdef np.ndarray _get_index(LabeledIntervalArray self, str label)
	cdef np.ndarray _get_index_multi(LabeledIntervalArray self, np.ndarray labels)

	cdef void _insert(LabeledIntervalArray self, int start, int end, const char *label)
	cdef void _construct(LabeledIntervalArray self, int min_length)
	cdef void _from_array(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, const char *label_names, int array_length, int label_str_len)
	cdef void _append(LabeledIntervalArray self, LabeledIntervalArray other_ail)

	cdef int _get_label_index(LabeledIntervalArray self, int label)
	cdef np.ndarray _get_label_comp_bounds(LabeledIntervalArray self, int label)
	cdef np.ndarray _get_label_comp_length(LabeledIntervalArray self, int label)
	cdef labeled_aiarray_t *get_labels(LabeledIntervalArray self, const char[:,::1] labels, int length)
	cdef overlap_label_index_t *get_labels_with_index(LabeledIntervalArray self, const char *label_names, int str_label_len, int length)

	cdef labeled_aiarray_t *_intersect(LabeledIntervalArray self, int start, int end, const char *label_name)
	cpdef _intersect_from_array(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, const char *labels, int label_str_len)
	cpdef _has_hit_from_array(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, uint8[::1] has_hit, const char *labels, int label_str_len)
	cpdef _intersect_from_labeled_aiarray(LabeledIntervalArray self, LabeledIntervalArray ail)
	cpdef _intersect_with_index(LabeledIntervalArray self, int start, int end, const char *label_name)
	cpdef _intersect_with_index_from_LabeledIntervalArray(LabeledIntervalArray self, LabeledIntervalArray ail2)

	cdef np.ndarray _nhits_from_array(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, const char[:,::1] labels)
	cdef np.ndarray _nhits_from_array_length(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, const char[:,::1] labels, int min_length, int max_length)

	cdef labeled_aiarray_t *_determine_bins(LabeledIntervalArray self, int bin_size)
	cdef np.ndarray _bin_nhits(LabeledIntervalArray self, labeled_aiarray_t *bins, int bin_size)
	cdef np.ndarray _bin_nhits_length(LabeledIntervalArray self, labeled_aiarray_t *bins, int bin_size, int min_length, int max_length)

	cdef np.ndarray _wps(LabeledIntervalArray self, int protection)
	cdef np.ndarray _wps_length(LabeledIntervalArray self, int protection, int min_length, int max_length)

	cdef np.ndarray _coverage(LabeledIntervalArray self)

	cpdef _downsample_with_index(LabeledIntervalArray self, double proportion)
	cdef np.ndarray _length_dist(LabeledIntervalArray self)
	cpdef _filter_exact_match(LabeledIntervalArray self, LabeledIntervalArray other_aiarray)
	cdef np.ndarray _has_exact_match(LabeledIntervalArray self, LabeledIntervalArray other_aiarray)
	cdef int _index_with_aiarray(LabeledIntervalArray self, LabeledIntervalArray other_aiarray)
	cdef void _get_locs(LabeledIntervalArray self, uint8[::1] locs_view, char *label_names, int label_str_len, int n_labels)