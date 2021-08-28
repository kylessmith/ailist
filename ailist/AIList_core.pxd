import numpy as np
cimport numpy as np
cimport cython
from libc.stdint cimport uint32_t, int32_t, int64_t
from libc.stdlib cimport malloc, free
from ailist.Interval_core cimport Interval, interval_init, interval_t
from ailist.array_query_core cimport *

cdef extern from "src/augmented_interval_list.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/ailist_add.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/ailist_construct.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/ailist_index.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/ailist_query.c":
	# C is include here so that it doesn't need to be compiled externally
	pass
	
cdef extern from "src/ailist_iter.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/ailist_coverage.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/ailist_nhits.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/ailist_wps.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/ailist_merge.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/ailist_extract.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/ailist_ops.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/ailist_filter.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/utilities.h":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/augmented_interval_list.h":

	ctypedef struct ailist_t:
		int64_t nr, mr  					# Number of regions
		interval_t *interval_list			# Regions data
		uint32_t first, last				# Record range of intervals
		int nc
		int lenC[10]
		int idxC[10]
		uint32_t *maxE
		
	ctypedef struct ailist_sorted_iter_t:
		ailist_t *ail						# Interval list
		int nc								# Number of components
		int *comp_bounds					# Label component bounds
		int *comp_used						# Components used
		interval_t *intv					# Interval
		int n								# Current position


	#-------------------------------------------------------------------------------------
	# augmented_interval_list.c
	#=====================================================================================

	# Initialize ailist_t
	ailist_t *ailist_init() nogil

	# Free ailist data
	void ailist_destroy(ailist_t *ail) nogil

	# Print AIList
	void display_list(ailist_t *ail) nogil

	# Calculate maximum length
	int ailist_max_length(ailist_t *ail) nogil

	# Calculate length distribution
	void ailist_length_distribution(ailist_t *ail, int distribution[]) nogil


	#-------------------------------------------------------------------------------------
	# ailist_add.c
	#=====================================================================================

	# Add interval to ailist_t object 
	void ailist_add(ailist_t *ail, uint32_t start, uint32_t end, uint32_t id) nogil

	# Build ailist from arrays
	void ailist_from_array(ailist_t *ail, const long starts[], const long ends[], const long ids[], int length) nogil

	# Append two ailist
	ailist_t *ailist_append(ailist_t *ail1, ailist_t *ail2) nogil


	#-------------------------------------------------------------------------------------
	# ailist_construct.c
	#=====================================================================================

	# Construct ailist: decomposition and augmentation
	void ailist_construct(ailist_t *ail, int cLen) nogil

	#-------------------------------------------------------------------------------------
	# ailist_index.c
	#=====================================================================================

	# Get intervals with id
	ailist_t *ailist_get_id(ailist_t *ail, int query_id) nogil

	# Get intervals with ids
	ailist_t *ailist_get_id_array(ailist_t *ail, const long ids[], int length) nogil


	#-------------------------------------------------------------------------------------
	# ailist_query.c
	#=====================================================================================

	# Binary search
	uint32_t binary_search(interval_t* As, uint32_t idxS, uint32_t idxE, uint32_t qe) nogil

	# Query ailist intervals
	ailist_t *ailist_query(ailist_t *ail, uint32_t qs, uint32_t qe) nogil

	# Query ailist intervals of a length
	ailist_t *ailist_query_length(ailist_t *ail, uint32_t qs, uint32_t qe, int min_length, int max_length) nogil

	# Query ailist intervals from arrays
	ailist_t *ailist_query_from_array(ailist_t *ail, const long starts[], const long ends[], int length) nogil

	# Query ailist intervals from another ailist
	ailist_t *ailist_query_from_ailist(ailist_t *ail, ailist_t *ail2) nogil

	# Query ailist interval ids from array
	array_query_t *ailist_query_id_from_array(ailist_t *ail, const long starts[], const long ends[], const long ids[], int length) nogil

	# Query ailist interval ids from another ailist
	array_query_t *ailist_query_id_from_ailist(ailist_t *ail, ailist_t *ail2) nogil
	
	
	#-------------------------------------------------------------------------------------
	# ailist_iter.c
	#=====================================================================================

	# Get component index
	int *get_comp_bounds(ailist_t *ail) nogil

	# 
	ailist_sorted_iter_t *ailist_sorted_iter_init(ailist_t *ail) nogil

	# 
	int ailist_sorted_iter_next(ailist_sorted_iter_t *iter) nogil

	# 
	void ailist_sorted_iter_destroy(ailist_sorted_iter_t *iter) nogil


	#-------------------------------------------------------------------------------------
	# ailist_coverage.c
	#=====================================================================================

	# Calculate coverage for a single interval
	void ailist_interval_coverage(ailist_t *ail, int start, int end, int coverage[]) nogil

	# Calculate coverage
	void ailist_coverage(ailist_t *ail, double coverage[]) nogil

	# Calculate coverage within bins
	void ailist_bin_coverage(ailist_t *ail, double coverage[], int bin_size) nogil

	# Calculate coverage within bins of a length
	void ailist_bin_coverage_length(ailist_t *ail, double coverage[], int bin_size, int min_length, int max_length) nogil


	#-------------------------------------------------------------------------------------
	# ailist_nhits.c
	#=====================================================================================

	# Determine number of hits for each query interval
	void ailist_nhits_from_array(ailist_t *ail, const long starts[], const long ends[],
								int length, int nhits[]) nogil

	# Determine number of hits of a length for each query interval
	void ailist_nhits_from_array_length(ailist_t *ail, const long starts[], const long ends[],
										int length, int nhits[], int min_length,
										int max_length) nogil

	# Calculate n hits within bins
	void ailist_bin_nhits(ailist_t *ail, double coverage[], int bin_size) nogil

	# Calculate n hits of a length within bins
	void ailist_bin_nhits_length(ailist_t *ail, double coverage[], int bin_size, int min_length, int max_length) nogil

	#-------------------------------------------------------------------------------------
	# ailist_wps.c
	#=====================================================================================

	# Calculate Window Protection Score
	void ailist_wps(ailist_t *ail, double wps[], uint32_t protection) nogil

	# Calculate Window Protection Score of a length
	void ailist_wps_length(ailist_t *ail, double wps[], uint32_t protection, int min_length, int max_length) nogil

	#-------------------------------------------------------------------------------------
	# ailist_merge.c
	#=====================================================================================

	# Merge nearby intervals
	ailist_t *ailist_merge(ailist_t *ail, uint32_t gap) nogil


	#-------------------------------------------------------------------------------------
	# ailist_extract.c
	#=====================================================================================

	# Extract start for ailist
	void ailist_extract_starts(ailist_t *ail, long starts[]) nogil

	# Extract end for ailist
	void ailist_extract_ends(ailist_t *ail, long ends[]) nogil

	# Extract index for ailist
	void ailist_extract_ids(ailist_t *ail, long ids[]) nogil


	#-------------------------------------------------------------------------------------
	# ailist_ops.c
	#=====================================================================================

	# Subtract intervals from region
	void subtract_intervals(ailist_t *ref_ail, ailist_t *result_ail, interval_t query_i, int j) nogil

	# Subtract two ailist_t intervals
	ailist_t *ailist_subtract(ailist_t *ref_ail, ailist_t *query_ail) nogil

	# Subtract intervals from region
	void common_intervals(ailist_t *ref_ail, ailist_t *result_ail, interval_t query_i, int j) nogil

	# Subtract two ailist_t intervals
	ailist_t *ailist_common(ailist_t *ref_ail, ailist_t *query_ail) nogil


	#-------------------------------------------------------------------------------------
	# ailist_filter.c
	#=====================================================================================

	# Filter ailist by length
	ailist_t *ailist_length_filter(ailist_t *ail, int min_length, int max_length) nogil

	# Randomly downsample
	ailist_t *ailist_downsample(ailist_t *ail, double proportion) nogil


cpdef object rebuild_AIList(bytes data, bytes b_length)


cdef class AIList(object):
	"""
	Wrapper for C ailist_t
	"""

	# AIList attributes
	cdef ailist_t *c_ailist
	cdef public bint is_constructed
	cdef public bint is_closed
	cdef public bint is_frozen

	# Methods for serialization
	cdef bytes _get_data(self)
	cdef ailist_t *_set_data(self, bytes data, bytes b_length)

	# AIList methods
	cdef void set_list(AIList self, ailist_t *input_list)
	cdef void _insert(AIList self, int start, int end, int id_value)
	cdef void _construct(AIList self, int min_length)
	cdef ailist_t *_array_id(AIList self, const long[::1] ids)
	cdef ailist_t *_interval_id(AIList self, int id_value)
	cdef ailist_t *_intersect(AIList self, int start, int end)
	cdef np.ndarray _intersect_ids(AIList self, int start, int end)
	cpdef _intersect_ids_from_array(AIList self, const long[::1] starts, const long[::1] ends, const long[::1] ids)
	cpdef _intersect_ids_from_ailist(AIList self, AIList ail)
	cdef np.ndarray _coverage(AIList self)
	cdef np.ndarray _bin_coverage(AIList self, int bin_size)
	cdef np.ndarray _bin_coverage_length(AIList self, int bin_size, int min_length, int max_length)
	cdef np.ndarray _bin_nhits(AIList self, int bin_size)
	cdef np.ndarray _bin_nhits_length(AIList self, int bin_size, int min_length, int max_length)
	cdef np.ndarray _wps(AIList self, int protection)
	cdef np.ndarray _wps_length(AIList self, int protection, int min_length, int max_length)
	cdef np.ndarray _length_dist(AIList self)
	cdef np.ndarray _nhits_from_array(AIList self, const long[::1] starts, const long[::1] ends)
	cdef np.ndarray _nhits_from_array_length(AIList self, const long[::1] starts, const long[::1] ends, int min_length, int max_length)
	cdef np.ndarray _interval_coverage(AIList self, int start, int end)