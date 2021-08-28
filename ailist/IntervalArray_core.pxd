import numpy as np
cimport numpy as np
cimport cython
from libc.stdint cimport uint32_t, int32_t, int64_t
from libc.stdlib cimport malloc, free
from .Interval_core cimport *
from .array_query_core cimport *


cdef extern from "src/augmented_interval_array.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/overlap_index.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/aiarray_add.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/aiarray_construct.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/aiarray_index.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/aiarray_query.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/aiarray_nhits.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/aiarray_coverage.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/aiarray_wps.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/aiarray_merge.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/aiarray_filter.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/aiarray_extract.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/aiarray_ops.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/augmented_interval_array.h":

	# C aiarray struct
	ctypedef struct aiarray_t:
		int64_t nr, mr						# Number of intervals
		interval_t *interval_list			# List of interval_t objects
		int nc								# Number of components
		int lenC[10]						# Length of components
		int idxC[10]						# Index of components
		uint32_t *maxE						# Augmentation
		uint32_t first, last				# Record range of intervals
		uint32_t *id_index					# Record index values

	# C overlap_index struct
	ctypedef struct overlap_index_t:
		int size							# Current size
		int max_size						# Maximum size
		aiarray_t *ail						# Store ailist
		long *indices						# Store indices


	#-------------------------------------------------------------------------------------
	# augmented_interval_list.c
	#=====================================================================================

	# Initialize aiarray_t
	aiarray_t *aiarray_init() nogil

	# Free aiarray data
	void aiarray_destroy(aiarray_t *ail) nogil

	# Print aiarray
	void display_array(aiarray_t *ail) nogil

	# Calculate maximum length
	int aiarray_max_length(aiarray_t *ail) nogil

	# Calculate length distribution
	void aiarray_length_distribution(aiarray_t *ail, int distribution[]) nogil


	#-------------------------------------------------------------------------------------
	# overlap_index.c
	#=====================================================================================

	# Initialize overlap_index_t
	overlap_index_t *overlap_index_init() nogil

	# Free overlap_index memory
	void overlap_index_destroy(overlap_index_t *oi) nogil

	# Add interval and index to overlap_index
	void overlap_index_add(overlap_index_t *aq, interval_t *i) nogil


	#-------------------------------------------------------------------------------------
	# aiarray_add.c
	#=====================================================================================

	# Build aiarray from arrays
	void aiarray_from_array(aiarray_t *ail, const long starts[], const long ends[], int length) nogil

	# Add a interval_t interval
	void aiarray_add(aiarray_t *ail, uint32_t start, uint32_t end) nogil

	# Append two aiarray
	aiarray_t *aiarray_append(aiarray_t *ail1, aiarray_t *ail2) nogil


	#-------------------------------------------------------------------------------------
	# aiarray_construct.c
	#=====================================================================================

	# Construct aiarray: decomposition and augmentation
	void aiarray_construct(aiarray_t *ail, int cLen) nogil


	#-------------------------------------------------------------------------------------
	# aiarray_index.c
	#=====================================================================================

	# Record id positions by index
	void aiarray_cache_id(aiarray_t *ail) nogil

	# Get interval with id
	interval_t *aiarray_get_index(aiarray_t *ail, int index) nogil

	# Get intervals with ids
	aiarray_t *aiarray_get_index_array(aiarray_t *ail, const long indices[], int length) nogil

	# Index aiarray by array
	aiarray_t *aiarray_array_index(aiarray_t *ail, const long indices[], int length) nogil

	# Index aiarray by another aiarray
	aiarray_t *aiarray_index_by_aiarray(aiarray_t *ail1, aiarray_t *ail2) nogil

	# Index aiarray by another aiarray inplace
	int aiarray_index_by_aiarray_inplace(aiarray_t *ail1, aiarray_t *ail2) nogil

	#-------------------------------------------------------------------------------------
	# aiarray_query.c
	#=====================================================================================

	# Binary search
	uint32_t binary_search(interval_t* As, uint32_t idxS, uint32_t idxE, uint32_t qe) nogil

	# Query aiarray intervals
	aiarray_t *aiarray_query(aiarray_t *ail, uint32_t qs, uint32_t qe) nogil

	# Query aiarray intervals of a length
	aiarray_t *aiarray_query_length(aiarray_t *ail, uint32_t qs, uint32_t qe, int min_length, int max_length) nogil

	# Query aiarray intervals from arrays
	array_query_t *aiarray_query_from_array(aiarray_t *ail, const long starts[], const long ends[], int length) nogil

	# Find overlaps from aiarray
	array_query_t *aiarray_query_from_aiarray(aiarray_t *ail, aiarray_t *ail2) nogil

	# Query aiarray intervals and record original index
	overlap_index_t *aiarray_query_with_index(aiarray_t *ail, uint32_t qs, uint32_t qe) nogil


	#-------------------------------------------------------------------------------------
	# aiarray_nhits.c
	#=====================================================================================

	# Determine number of hits for each query interval
	void aiarray_nhits_from_array(aiarray_t *ail, const long starts[], const long ends[],
								int length, int nhits[]) nogil

	# Determine number of hits of a length for each query interval
	void aiarray_nhits_from_array_length(aiarray_t *ail, const long starts[], const long ends[],
										int length, int nhits[], int min_length,
										int max_length) nogil

	# Calculate n hits within bins
	void aiarray_bin_nhits(aiarray_t *ail, double coverage[], int bin_size) nogil

	# Calculate n hits of a length within bins
	void aiarray_bin_nhits_length(aiarray_t *ail, double coverage[], int bin_size, int min_length, int max_length) nogil


	#-------------------------------------------------------------------------------------
	# aiarray_coverage.c
	#=====================================================================================

	# Determine coverage for an interval
	void aiarray_interval_coverage(aiarray_t *ail, int start, int end, int coverage[]) nogil

	# Calculate coverage
	void aiarray_coverage(aiarray_t *ail, double coverage[]) nogil

	# Calculate coverage within bins
	void aiarray_bin_coverage(aiarray_t *ail, double coverage[], int bin_size) nogil

	# Calculate coverage within bins of a length
	void aiarray_bin_coverage_length(aiarray_t *ail, double coverage[], int bin_size, int min_length, int max_length) nogil


	#-------------------------------------------------------------------------------------
	# aiarray_wps.c
	#=====================================================================================

	# Calculate Window Protection Score
	void aiarray_wps(aiarray_t *ail, double wps[], uint32_t protection) nogil

	# Calculate Window Protection Score of a length
	void aiarray_wps_length(aiarray_t *ail, double wps[], uint32_t protection, int min_length, int max_length) nogil


	#-------------------------------------------------------------------------------------
	# aiarray_merge.c
	#=====================================================================================

	# Get component index
	int *get_comp_bounds(aiarray_t *ail) nogil

	# Merge nearby intervals
	aiarray_t *aiarray_merge(aiarray_t *ail, uint32_t gap) nogil


	#-------------------------------------------------------------------------------------
	# aiarray_filter.c
	#=====================================================================================

	# Filter aiarray by length
	aiarray_t *aiarray_length_filter(aiarray_t *ail, int min_length, int max_length) nogil

	# Randomly downsample
	aiarray_t *aiarray_downsample(aiarray_t *ail, double proportion) nogil

	# Randomly downsample with original index
	overlap_index_t *aiarray_downsample_with_index(aiarray_t *ail, double proportion) nogil


	#-------------------------------------------------------------------------------------
	# aiarray_extract.c
	#=====================================================================================

	# Extract start for aiarray
	void aiarray_extract_starts(aiarray_t *ail, long starts[]) nogil

	# Extract end for aiarray
	void aiarray_extract_ends(aiarray_t *ail, long ends[]) nogil

	# Extract id for aiarray
	void aiarray_extract_ids(aiarray_t *ail, long ids[]) nogil


	#-------------------------------------------------------------------------------------
	# aiarray_ops.c
	#=====================================================================================

	# Subtract intervals from region
	void aiarray_subtract_intervals(aiarray_t *ref_ail, aiarray_t *result_ail, interval_t query_i, int j) nogil

	# Subtract two aiarray_t intervals
	aiarray_t *aiarray_subtract(aiarray_t *ref_ail, aiarray_t *query_ail) nogil

	# Subtract intervals from region
	void aiarray_common_intervals(aiarray_t *ref_ail, aiarray_t *result_ail, interval_t query_i, int j) nogil

	# Subtract two aiarray_t intervals
	aiarray_t *aiarray_common(aiarray_t *ref_ail, aiarray_t *query_ail) nogil


cpdef object rebuild_IntervalArray(bytes data, bytes b_length)

cdef class IntervalArray(object):
	"""
	Wrapper for C aiarray_t
	"""

	# Object attributes
	cdef aiarray_t *c_aiarray
	cdef public bint is_constructed
	cdef public bint is_closed
	cdef public bint is_frozen

	# Methods for serialization
	cdef bytes _get_data(self)
	cdef aiarray_t *_set_data(self, bytes data, bytes b_length)

	# Methods to implement C functions
	cdef void set_list(IntervalArray self, aiarray_t *input_list)
	cdef void _insert(IntervalArray self, int start, int end)
	cdef void _construct(IntervalArray self, int min_length)
	cdef aiarray_t *_array_index(IntervalArray self, const long[::1] ids)
	cdef np.ndarray _get_comp_bounds(IntervalArray self)
	cdef aiarray_t *_intersect(IntervalArray self, int start, int end)
	cpdef _intersect_from_array(IntervalArray self, const long[::1] starts, const long[::1] ends)
	cpdef _intersect_from_aiarray(IntervalArray self, IntervalArray ail)
	cpdef _intersect_with_index(IntervalArray self, int start, int end)
	cdef np.ndarray _coverage(IntervalArray self)
	cdef np.ndarray _bin_coverage(IntervalArray self, int bin_size)
	cdef np.ndarray _bin_coverage_length(IntervalArray self, int bin_size, int min_length, int max_length)
	cdef np.ndarray _bin_nhits(IntervalArray self, int bin_size)
	cdef np.ndarray _bin_nhits_length(IntervalArray self, int bin_size, int min_length, int max_length)
	cdef np.ndarray _wps(IntervalArray self, int protection)
	cdef np.ndarray _wps_length(IntervalArray self, int protection, int min_length, int max_length)
	cdef np.ndarray _length_dist(IntervalArray self)
	cdef np.ndarray _nhits_from_array(IntervalArray self, const long[::1] starts, const long[::1] ends)
	cdef np.ndarray _nhits_from_array_length(IntervalArray self, const long[::1] starts, const long[::1] ends, int min_length, int max_length)
	cdef np.ndarray _interval_coverage(IntervalArray self, int start, int end)
	cpdef _downsample_with_index(IntervalArray self, double proportion)