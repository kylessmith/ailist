import numpy as np
cimport numpy as np
from libc.stdint cimport uint32_t, int32_t, int64_t, int16_t
from .AIList_core cimport *
from .Interval_core cimport interval_init
from .array_query_core cimport *
ctypedef np.uint8_t uint8


cdef extern from "src/labeled_aiarray/labeled_augmented_array.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/overlap_label_index.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_add.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_get.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_construct.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_index.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_query_single.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_query_index.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_query_array.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_nhits.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_wps.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_coverage.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_merge.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_filter.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_extract.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_iter.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_match.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_sort.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_simulate.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_ops.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_aiarray_percent.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/khash.h":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_aiarray/labeled_augmented_array.h":

	ctypedef struct label_t:
		const char *name    				# Name of the label
		ailist_t *ail						# AIList object

	ctypedef struct labeled_interval_t:
		const char *name
		interval_t *i

	ctypedef struct labeled_aiarray_t:
		label_t *labels        				# List of Labels (of size _n_ctg_)
		int32_t n_labels, max_labels 		# Number and max number of labels
		void *label_lookup           	  	# Dict for converting label names to int
		uint32_t *first						# Record first position of intervals
		uint32_t *last						# Record last position of intervals
		int64_t total_nr					# Total number of regions
		uint32_t *id_index					# Record id index values
		int16_t is_constructed				# Flag for whether constructed or not

	ctypedef struct label_sorted_iter_t:
		const char *name					# Label
		ailist_sorted_iter_t *ail_iter		# Sorted AIList iterator
		interval_t *intv					# Interval

	ctypedef struct labeled_aiarray_iter_t:
		labeled_aiarray_t *laia				# Labeled aiarray
		int n								# Current position
		labeled_interval_t *intv			# Interval
		const char *name					# Label

	ctypedef struct labeled_aiarray_overlap_iter_t:
		labeled_aiarray_t *ref_laia		# Labeled aiarray
		labeled_aiarray_iter_t *query_iter	# Reference iterator
		labeled_aiarray_t *overlaps			# Overlaps

	ctypedef struct overlap_label_index_t:
		int size							# Current size
		int max_size						# Maximum size
		labeled_aiarray_t *laia				# Store labeled_aiarray
		long *indices						# Store indices


	#-------------------------------------------------------------------------------------
	# labeled_augmented_array.c
	#=====================================================================================

	# Initialize aiarray_t
	labeled_aiarray_t *labeled_aiarray_init() nogil

	# Free aiarray data
	void labeled_aiarray_destroy(labeled_aiarray_t *laia) nogil

	# Return index for given label
	int32_t get_label(const labeled_aiarray_t *laia, const char *label) nogil

	# Extract strings from array
	void slice_str(const char *str, char *buffer, size_t start, size_t end) nogil

	# Print labeled_aiarray
	void labeled_aiarray_print(labeled_aiarray_t *laia) nogil

	# Calculate maximum length
	int labeled_aiarray_max_length(labeled_aiarray_t *laia) nogil

	# Calculate length distribution
	void labeled_aiarray_length_distribution(labeled_aiarray_t *laia, int distribution[]) nogil

	#-------------------------------------------------------------------------------------
	# overlap_label_index.c
	#=====================================================================================

	# Initialize overlap_index
	overlap_label_index_t *overlap_label_index_init() nogil

	# Free overlap_label_index memory
	void overlap_label_index_destroy(overlap_label_index_t *oi) nogil

	# Add interval to overlap_label_index
	void overlap_label_index_add(overlap_label_index_t *oi, interval_t i, const char *label_name) nogil

	void overlap_label_index_wrap_ail(overlap_label_index_t * oi, ailist_t *ail, const char *label_name) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_add.c
	#=====================================================================================

	# Expand and add label
	void labeled_aiarray_add_label(labeled_aiarray_t *laia, const char*label) nogil

	# Add a interval_t interval
	void labeled_aiarray_add(labeled_aiarray_t *laia, uint32_t s, uint32_t e, const char *label) nogil

	# Link memory of single label labeled_aiarrays and transfer data owership
	void labeled_aiarray_multi_merge(labeled_aiarray_t *laia, labeled_aiarray_t **laia_array, int length) nogil

	# Add a interval_t from array
	void labeled_aiarray_from_array(labeled_aiarray_t *laia, const long starts[], const long ends[], const char label_names[], int length, int label_str_len) nogil

	# Add intervals from another labeled_aiarray
	void labeled_aiarray_append(labeled_aiarray_t *laia, labeled_aiarray_t *laia2) nogil

	# Copy labeled_aiarray
	labeled_aiarray_t *labeled_aiarray_copy(labeled_aiarray_t *laia) nogil

	# Append AIList in labeled_aiarry
	void labeled_aiarray_append_ail(labeled_aiarray_t *laia, ailist_t *ail, const char *label_name) nogil

	# Wrap AIList in labeled_aiarry
	void labeled_aiarray_wrap_ail(labeled_aiarray_t *laia, ailist_t *ail, const char *label_name) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_construct.c
	#=====================================================================================

	# Construct aiarray: decomposition and augmentation
	void labeled_aiarray_construct(labeled_aiarray_t *laia, int cLen) nogil

	# Validation construction ran
	int labeled_aiarray_validate_construction(labeled_aiarray_t *laia) nogil

	# Deconstruct
	void labeled_aiarray_deconstruct(labeled_aiarray_t *laia) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_query_single.c
	#=====================================================================================

	# Base query logic
	void labeled_aiarray_query(labeled_aiarray_t *laia, labeled_aiarray_t *overlaps, const char *label, uint32_t qs, uint32_t qe) nogil

	# Base query logic filtered by length
	void labeled_aiarray_query_length(labeled_aiarray_t *laia, labeled_aiarray_t *overlaps, const char *label_name, 
									uint32_t qs, uint32_t qe, int min_length, int max_length) nogil

	# Base query logic for nhits
	void labeled_aiarray_query_nhits(labeled_aiarray_t *laia, long *nhits, const char *label_name, uint32_t qs, uint32_t qe) nogil

	# Base query logic for nhits filtered by length
	void labeled_aiarray_query_nhits_length(labeled_aiarray_t *laia, long *nhits, const char *label_name, uint32_t qs,
											uint32_t qe, int min_length, int max_length) nogil

	# Base query logic if present
	void labeled_aiarray_query_has_hit(labeled_aiarray_t *laia, const char *label_name, uint8_t *has_hit, uint32_t qs, uint32_t qe) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_query_index.c
	#=====================================================================================

	# Base query logic with index
	void labeled_aiarray_query_with_index(labeled_aiarray_t *laia, const char *label_name, overlap_label_index_t *overlaps, uint32_t qs, uint32_t qe) nogil

	# Query with index from arrays
	void labeled_aiarray_query_with_index_from_array(labeled_aiarray_t *laia, overlap_label_index_t *overlaps, const char label_names[], const long starts[], const long ends[], int length, int label_str_len) nogil

	# Query with index from labeled_aiarray
	void labeled_aiarray_query_with_index_from_labeled_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *other_laia, overlap_label_index_t *overlaps) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_query_array.c
	#=====================================================================================

	# Base query logic with index
	void labeled_aiarray_query_only_index(labeled_aiarray_t *laia, const char *label_name, array_query_t *overlaps, uint32_t qs, uint32_t qe, uint32_t id) nogil

	# Query aiarray intervals from array
	array_query_t *labeled_aiarray_query_index_from_array(labeled_aiarray_t *laia, const char label_names[], const long starts[], const long ends[], int length, int label_str_len) nogil

	# Query intervals from array
	void labeled_aiarray_query_from_array(labeled_aiarray_t *laia, labeled_aiarray_t *overlaps, const char label_names[], const long starts[], const long ends[], int length, int label_str_len) nogil	

	# Query array if present
	void labeled_aiarray_query_has_hit_from_array(labeled_aiarray_t *laia, const char label_names[], const long starts[], const long ends[], int length, int label_str_len, uint8_t has_hit[]) nogil

	# Query aiarray intervals from aiarray
	void labeled_aiarray_query_from_labeled_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *laia2, labeled_aiarray_t *overlaps) nogil

	# Query aiarray intervals from aiarray
	void labeled_aiarray_query_index_from_labeled_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *laia2, array_query_t *aq) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_index.c
	#=====================================================================================

	void labeled_aiarray_cache_id(labeled_aiarray_t *ail) nogil

	labeled_interval_t *labeled_aiarray_get_index(labeled_aiarray_t *ail, int32_t i) nogil

	labeled_aiarray_t *labeled_aiarray_slice_index(labeled_aiarray_t *laia, const long ids[], int length) nogil

	labeled_aiarray_t *labeled_aiarray_slice_range(labeled_aiarray_t *laia, int start, int end, int step) nogil

	labeled_aiarray_t *labeled_aiarray_slice_bool(labeled_aiarray_t *laia, uint8_t bool_index[]) nogil

	int labeled_aiarray_index_with_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *other_laia) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_iter.c
	#=====================================================================================

	label_sorted_iter_t *label_sorted_iter_init(labeled_aiarray_t *laia, const char *label_name) nogil

	int label_sorted_iter_next(label_sorted_iter_t *iter) nogil

	void label_sorted_iter_destroy(label_sorted_iter_t *iter) nogil

	labeled_aiarray_iter_t *labeled_aiarray_iter_init(labeled_aiarray_t *laia) nogil

	int labeled_aiarray_iter_next(labeled_aiarray_iter_t *iter) nogil

	void labeled_aiarray_iter_destroy(labeled_aiarray_iter_t *iter) nogil

	labeled_aiarray_overlap_iter_t *labeled_aiarray_overlap_iter_init(labeled_aiarray_t *ref_laia, labeled_aiarray_t *query_laia) nogil

	int labeled_aiarray_overlap_iter_next(labeled_aiarray_overlap_iter_t *iter) nogil

	void labeled_aiarray_overlap_iter_destroy(labeled_aiarray_overlap_iter_t *iter) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_nhits.c
	#=====================================================================================

	void labeled_aiarray_nhits(labeled_aiarray_t *laia, long *nhits, const char *label_name, uint32_t qs, uint32_t qe) nogil

	void labeled_aiarray_nhits_length(labeled_aiarray_t *laia, long *nhits, const char *label_name, uint32_t qs,
											uint32_t qe, int min_length, int max_length) nogil

	void labeled_aiarray_nhits_from_array(labeled_aiarray_t *laia, const char label_names[], const long starts[], const long ends[],
											int length, int label_str_len, long *nhits) nogil

	void labeled_aiarray_nhits_from_array_length(labeled_aiarray_t *laia, const char label_names[], const long starts[], const long ends[],
											int length, int label_str_len, long *nhits, int min_length, int max_length) nogil

	void labeled_aiarray_nhits_from_labeled_aiarray(labeled_aiarray_t *laia, labeled_aiarray_t *other_laia,
													long *nhits) nogil

	void labeled_aiarray_nhits_from_labeled_aiarray_length(labeled_aiarray_t *laia, labeled_aiarray_t *other_laia,
													long *nhits, int min_length, int max_length) nogil

	void labeled_aiarray_has_hit(labeled_aiarray_t *laia, const char *label_name, uint8_t has_hit[], uint32_t qs, uint32_t qe) nogil

	void labeled_aiarray_bin_nhits(labeled_aiarray_t *laia, long *nhits, int bin_size) nogil

	void labeled_aiarray_bin_nhits_length(labeled_aiarray_t *laia, long *nhits, int bin_size, int min_length, int max_length) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_coverage.c
	#=====================================================================================

	# Determine coverage for an interval
	void labeled_aiarray_interval_coverage(labeled_aiarray_t *laia, int start, int end, const char *label_name, int coverage[]) nogil

	# Calculate coverage for a label
	void labeled_aiarray_label_coverage(labeled_aiarray_t *laia, double coverage[], const char *label_name) nogil

	# Calculate coverage for a label of a length
	void labeled_aiarray_label_coverage_length(labeled_aiarray_t *laia, double coverage[], const char *label_name,
												int min_length, int max_length) nogil

	# Calculate coverage within bins
	void labeled_aiarray_label_bin_coverage(labeled_aiarray_t *laia, double coverage[], int bin_size, const char *label_name) nogil

	# Calculate coverage of intervals of a given length within bins
	void labeled_aiarray_label_bin_coverage_length(labeled_aiarray_t *laia, double coverage[], int bin_size, const char *label_name,
													int min_length, int max_length) nogil
	
	# Calculate interval midpoint coverage
	void labeled_aiarray_label_midpoint_coverage(labeled_aiarray_t *laia, double coverage[], const char *label_name) nogil

	# Calculate interval midpoitn coverage with lengths
	void labeled_aiarray_label_midpoint_coverage_length(labeled_aiarray_t *laia, double coverage[], const char *label_name,
														int min_length, int max_length) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_wps.c
	#=====================================================================================

	# Calculate Window Protection Score for a label
	void labeled_aiarray_label_wps(labeled_aiarray_t *laia, double wps[], uint32_t protection, const char *label_name) nogil

	# Calculate Window Protection Score for a label of a length
	void labeled_aiarray_label_wps_length(labeled_aiarray_t *laia, double wps[], uint32_t protection, int min_length, int max_length, const char *label_name) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_merge.c
	#=====================================================================================

	# Merge nearby intervals
	labeled_aiarray_t *labeled_aiarray_merge(labeled_aiarray_t *laia, uint32_t gap) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_filter.c
	#=====================================================================================

	# Filter labeled_aiarray by length 
	labeled_aiarray_t *labeled_aiarray_length_filter(labeled_aiarray_t *laia, int min_length, int max_length) nogil

	# Randomly downsample 
	labeled_aiarray_t *labeled_aiarray_downsample(labeled_aiarray_t *laia, double proportion) nogil

	overlap_label_index_t *labeled_aiarray_downsample_with_index(labeled_aiarray_t *laia, double proportion) nogil

	#-------------------------------------------------------------------------------------
	# labeled_aiarray_extract.c
	#=====================================================================================

	# Extract start for labeled_aiarray
	void labeled_aiarray_extract_starts(labeled_aiarray_t *laia, long starts[]) nogil

	# Extract end for labeled_aiarray
	void labeled_aiarray_extract_ends(labeled_aiarray_t *laia, long ends[]) nogil

	# Extract id for labeled_aiarray
	void labeled_aiarray_extract_ids(labeled_aiarray_t *laia, long ids[]) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_match.c
	#=====================================================================================

	# Return all exact matches between labeled_aiarrays
	overlap_label_index_t *labeled_aiarray_exact_match(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2) nogil

	void labeled_aiarray_has_exact_match(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2, uint8_t has_match[]) nogil

	# Return exact matches between labeled_aiarrays
	void labeled_aiarray_is_exact_match(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2, uint8_t has_match_laia1[], uint8_t has_match_laia2[]) nogil

	# Return exact matches between labeled_aiarrays
	void labeled_aiarray_which_exact_match(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2, array_query_t *matches) nogil

	# Return exact match between labeled_aiarray and an interval
	int labeled_aiarray_where_interval(labeled_aiarray_t *laia, const char *label, uint32_t qs, uint32_t qe) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_get.c
	#=====================================================================================

	# Get intervals with label name
	labeled_aiarray_t *labeled_aiarray_get_label(labeled_aiarray_t *laia, const char *label_name) nogil

	# Get intervals with label name
	labeled_aiarray_t *labeled_aiarray_view_label(labeled_aiarray_t *laia, const char *label_name) nogil

	# Get intervals with label name and original index
	overlap_label_index_t *labeled_aiarray_get_label_with_index(labeled_aiarray_t *laia, const char *label_name) nogil

	# Get intervals with labels names from array
	labeled_aiarray_t *labeled_aiarray_get_label_array(labeled_aiarray_t *laia, const char label_names[], int n_labels, int label_str_len) nogil

	# Get intervals with labels from array and original index
	overlap_label_index_t *labeled_aiarray_get_label_array_with_index(labeled_aiarray_t *laia, const char label_names[], int n_labels, int label_str_len) nogil

	# Determine if an index is of a label array
	void labeled_aiarray_get_label_array_presence(labeled_aiarray_t *ail, const char label_names[], int n_labels, uint8_t index[], int label_str_len) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_sort.c
	#=====================================================================================

	# Sort intervals by actual order
	void labeled_aiarray_order_sort(labeled_aiarray_t *laia) nogil

	# Sort intervals by starts
	void labeled_aiarray_sort_index(labeled_aiarray_t *laia, long *index) nogil

	# Sort intervals by starts
	void labeled_aiarray_sort(labeled_aiarray_t *laia) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_simulate.c
	#=====================================================================================

	# Simulate intervals
	void labeled_aiarray_simulate(labeled_aiarray_t *laia, labeled_aiarray_t *sim_laia) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_ops.c
	#=====================================================================================

	# Find common intervals between two labeled_aiarrays
	labeled_aiarray_t *labeled_aiarray_common(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2) nogil

	# Subtract intervals from laia1 that are in laia2
	labeled_aiarray_t *labeled_aiarray_subtract(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2) nogil

	# Find union of intervals between two labeled_aiarrays
	labeled_aiarray_t *labeled_aiarray_union(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2) nogil


	#-------------------------------------------------------------------------------------
	# labeled_aiarray_percent.c
	#=====================================================================================

	# Find percent coverage of intervals in laia1 that are in laia2
	void labeled_aiarray_percent_coverage(labeled_aiarray_t *laia1, labeled_aiarray_t *laia2, double coverage[]) nogil


#cpdef object rebuild_LabeledIntervalArray(bytes data, bytes b_length, bytes b_label_list)

cdef class LabeledInterval(object):
	"""
	Wrapper for C labeled interval
	"""

	# Define attributes
	cdef str _label

	# C instance of struct
	cdef interval_t *i

	# Methods for serialization
	cdef void set_i(self, interval_t *i, str label)


cdef class LabeledIntervalArray(object):
	"""
	Wrapper for C aiarray_t
	"""

	# Define class properties
	cdef labeled_aiarray_t *laia
	cdef public bint is_closed
	cdef public bint is_frozen

	# Functions for serialization
	#cdef bytes _get_data(self)
	#cdef labeled_aiarray_t *_set_data(self, bytes data, bytes b_length, bytes b_label_list)

	# Class methods
	cdef void set_list(LabeledIntervalArray self, labeled_aiarray_t *input_list)
	cdef ailist_t *_get_ail(LabeledIntervalArray self, char *label_name)

	cdef labeled_aiarray_t *_array_index(LabeledIntervalArray self, const long[::1] ids)
	cdef np.ndarray _get_index(LabeledIntervalArray self, str label)
	cdef np.ndarray _get_index_multi(LabeledIntervalArray self, np.ndarray labels)

	cdef void _insert(LabeledIntervalArray self, int start, int end, const char *label)
	cdef void _construct(LabeledIntervalArray self, int min_length)
	cdef void _from_array(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, const char *label_names, int array_length, int label_str_len)
	cdef void _append(LabeledIntervalArray self, LabeledIntervalArray other_laia)

	#cdef int _get_label_index(LabeledIntervalArray self, int label)
	#cdef np.ndarray _get_label_comp_bounds(LabeledIntervalArray self, int label)
	#cdef np.ndarray _get_label_comp_length(LabeledIntervalArray self, int label)
	cdef labeled_aiarray_t *get_labels(LabeledIntervalArray self, const char *label_names, int str_label_len, int length)
	cdef overlap_label_index_t *get_labels_with_index(LabeledIntervalArray self, const char *label_names, int str_label_len, int length)

	cdef labeled_aiarray_t *_intersect(LabeledIntervalArray self, int start, int end, const char *label_name)
	cdef labeled_aiarray_t *_intersect_from_array(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, const char *labels, int label_str_len)
	cpdef _intersect_from_array_only_index(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, const char *labels, int label_str_len)
	
	cdef void _has_hit_from_array(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, uint8[::1] has_hit, const char *labels, int label_str_len)
	cdef labeled_aiarray_t *_intersect_from_labeled_aiarray(LabeledIntervalArray self, LabeledIntervalArray laia)
	cpdef _intersect_index_from_labeled_aiarray(LabeledIntervalArray self, LabeledIntervalArray laia)
	cpdef _intersect_with_index(LabeledIntervalArray self, int start, int end, const char *label_name)
	cpdef _intersect_with_index_from_labeled_aiarray(LabeledIntervalArray self, LabeledIntervalArray ail2)
	cpdef _intersect_from_array_with_index(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, const char *labels, int label_str_len)

	cdef void _nhits_from_array(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, long[::1] nhits,
								const char *labels, int label_str_len)
	cdef void _nhits_from_array_length(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, long[::1] nhits,
										const char *labels, int label_str_len, int min_length, int max_length)

	cdef labeled_aiarray_t *_determine_bins(LabeledIntervalArray self, int bin_size)
	cdef void _bin_nhits(LabeledIntervalArray self, long[::1] nhits, int bin_size)
	cdef void _bin_nhits_length(LabeledIntervalArray self, long[::1] nhits, int bin_size, int min_length, int max_length)

	cdef np.ndarray _wps(LabeledIntervalArray self, const char *label_name, int protection)
	cdef np.ndarray _wps_length(LabeledIntervalArray self, const char *label_name, int protection, int min_length, int max_length)

	cdef np.ndarray _coverage(LabeledIntervalArray self, const char *label_name)
	cdef np.ndarray _coverage_length(LabeledIntervalArray self, const char *label_name, int min_length, int max_length)

	cpdef _downsample_with_index(LabeledIntervalArray self, double proportion)
	cdef np.ndarray _length_dist(LabeledIntervalArray self)
	cpdef _filter_exact_match(LabeledIntervalArray self, LabeledIntervalArray other_aiarray)
	cdef void _has_exact_match(LabeledIntervalArray self, LabeledIntervalArray other_aiarray, uint8_t[::1] has_match)
	cdef void _is_exact_match(LabeledIntervalArray self, LabeledIntervalArray other_aiarray, uint8_t[::1] has_match1, uint8_t[::1] has_match2)
	cpdef _which_exact_match(LabeledIntervalArray self, LabeledIntervalArray other_aiarray)
	cdef int _where_interval(LabeledIntervalArray self, int start, int end, const char *label_name)
	cdef int _index_with_aiarray(LabeledIntervalArray self, LabeledIntervalArray other_aiarray)
	cdef void _get_locs(LabeledIntervalArray self, uint8[::1] locs_view, char *label_names, int label_str_len, int n_labels)

	cdef void _create_bin(LabeledIntervalArray self, int bin_size, int bin_range, const char* label_name)
	cdef np.ndarray _midpoint_coverage(LabeledIntervalArray self, const char *label_name)

	cdef np.ndarray _percent_coverage(LabeledIntervalArray self, LabeledIntervalArray other_laia)

