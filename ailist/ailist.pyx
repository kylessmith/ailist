"""
Main classes.
"""

#cython: embedsignature=True
#cython: profile=False

import os
import sys
import numpy as np
cimport numpy as np
import math
cimport cython
import pandas as pd
from libc.string cimport memcpy
np.import_array()
from time import time

# Set byteorder for __reduce__
byteorder = sys.byteorder


def get_include():
	"""
	Get file directory if C headers

	Arguments:
	---------
		None

	Returns:
	---------
		str (Directory to header files)
	"""

	return os.path.split(os.path.realpath(__file__))[0]


cpdef AIList rebuild(bytes data, bytes b_length):
	"""
	Rebuild function for __reduce__()

	Arguments:
	---------
		data: bytes (Bytes representation of ailist_t)
		b_length: bytes (Length of ailist_t)

	Returns:
	---------
		c: ailist_t* (Translated ailist_t from data)
	"""

	# Initialize new AIList
	c = AIList()

	# Build ailist from serialized data
	cdef ailist_t *interval_list = c._set_data(data, b_length)
	c.set_list(interval_list)

	return c


cdef np.ndarray pointer_to_numpy_array(void *ptr, np.npy_intp size):
	"""
	Convert c pointer to numpy array.
	The memory will be freed as soon as the ndarray is deallocated.
	"""

	cdef extern from "numpy/arrayobject.h":
		void PyArray_ENABLEFLAGS(np.ndarray arr, int flags)

	cdef np.npy_intp dims[1]
	dims[0] = size

	cdef np.ndarray arr = np.PyArray_SimpleNewFromData(1, &dims[0], np.NPY_LONG, ptr)
	
	#PyArray_ENABLEFLAGS(arr, np.NPY_OWNDATA)
	np.PyArray_UpdateFlags(arr, arr.flags.num | np.NPY_OWNDATA)

	return arr


cdef class Interval(object):
	"""
	Wrapper of C interval_t

	:class:`~ailist.Interval` stores an interval
	
	Parameters
	----------
	None
	"""

	# Set the interval
	cdef void set_i(Interval self, interval_t i):
		"""
		Initialize wrapper of C interval

		Params
		---------
			i
				interval_t (C interval_t to be wrapped)

		Returns
		---------
			None
		"""

		# Set i
		self.i = i


	@property
	def start(self):
		"""
		Start of interval
		"""
		return self.i.start

	@property
	def end(self):
		"""
		End of interval
		"""
		return self.i.end
	
	@property
	def index(self):
		"""
		Index of interval
		"""
		return self.i.index

	@property
	def value(self):
		"""
		Value of interval
		"""
		return self.i.value


	def __str__(self):
		format_string = "Interval(%d-%d, %s, %s)" % (self.start, self.end, self.index, self.value)
		return format_string


	def __repr__(self):
		format_string = "Interval(%d-%d, %s, %s)" % (self.start, self.end, self.index, self.value)
		return format_string


@cython.auto_pickle(True)
cdef class AIList(object):
	"""
	Wrapper for C ailist_t

	:class:`~ailist.AIList` stores a list of intervals
	
	Parameters
	----------
	None
	"""

	def __cinit__(self):
		"""
		Initialize AIList object
		"""

		self.interval_list = ailist_init()
		self.is_constructed = False
		self.is_sorted = False
		self.is_closed = False


	def __dealloc__(self):
		"""
		Free AIList.interval_list
		"""
		
		if hasattr(self, "interval_list"):
			ailist_destroy(self.interval_list)


	cdef bytes _get_data(self):
		"""
		Function to convert ailist_t to bytes
		for serialization by __reduce__()
		"""

		return <bytes>(<char*>self.interval_list.interval_list)[:(sizeof(interval_t)*self.interval_list.nr)]

	cdef ailist_t *_set_data(self, bytes data, bytes b_length):
		"""
		Function to build ailist_t object from
		serialized bytes using __reduce__()

		Params
		---------
			data
				bytes (Bytes representation of ailist_t)
			b_length
				bytes (Length of ailist_t)

		Returns
		---------
			interval_list
				ailist_t* (Translated ailist_t for bytes)
		"""
		
		# Convert bytes to ints
		cdef int length = int.from_bytes(b_length, byteorder)
		
		# Create new ailist_t
		cdef ailist_t *ail = ailist_init()
		cdef interval_t *interval_list = <interval_t*>malloc(length * sizeof(interval_t))
		memcpy(interval_list, <char*>data, sizeof(interval_t)*length)

		# Iteratively add intervals to interval_list		
		cdef int i
		for i in range(length):
			ailist_add(ail, interval_list[i].start, interval_list[i].end, interval_list[i].index, interval_list[i].value)

		return ail


	def __reduce__(self):
		"""
		Used for pickling. Convert ailist to bytes and back.
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")
		
		# Convert ints to bytes
		b_length = int(self.interval_list.nr).to_bytes(4, byteorder)

		# Convert ailist_t to bytes
		data = self._get_data()

		return (rebuild, (data, b_length))


	@property	
	def size(self):
		"""
		Number of intervals in AIList
		"""
		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		return self.interval_list.nr
	
	@property
	def first(self):
		"""
		Start of first interval in AIList
		"""
		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")
		
		# Check if ther are any intervals
		if self.size == 0:
			return None
		else:
			return self.interval_list.first

	@property
	def last(self):
		"""
		End of last intervals in AIList
		"""
		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if there are any intervals
		if self.size == 0:
			return None
		else:
			return self.interval_list.last

	@property
	def range(self):
		"""
		AIList.last - AIList.first
		"""
		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if ther are any intervals
		if self.size == 0:
			return 0
		else:
			return self.last - self.first
		

	def __len__(self):
		"""
		Return size of interval_list
		"""
		
		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		return self.size

	
	def __iter__(self):
		"""
		Iterate over AIList object
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Iterate over interval list
		cdef Interval interval
		for i in range(self.size):
			interval = Interval()
			interval.set_i(self.interval_list.interval_list[i])
			
			yield interval


	def __sub__(self, AIList query_ail):
		"""
		Subtract values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		return self.subtract(query_ail)


	def __add__(self, AIList query_ail):
		"""
		Common values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		return self.common(query_ail)


	def __or__(self, AIList query_ail):
		"""
		Common values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		return self.append(query_ail)


	def __getitem__(self, key):
		"""
		Index Intervals by value
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")
		
		# Check if key is greater than length
		if key > self.interval_list.nr:
			raise IndexError("Value larger than ailist length")

		# Check if negative
		if key < 0:
			return self.__getitem__(self.interval_list.nr + key)

		# Create Interval wrapper
		output_interval = Interval()
		output_interval.set_i(self.interval_list.interval_list[key])
		
		return output_interval


	def __repr__(self):
		"""
		Representation of ailist object
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize string
		repr_string = "AIList\n"
		if self.size == 0:
			repr_string += " range: (None-None)\n"
		else:
			repr_string += " range: (%d-%d)\n" % (self.first, self.last)

		# Iterate over interval_list
		if self.interval_list.nr > 10:
			for i in range(5):
				repr_string += "   (%d-%d, %s, %s)\n" % (self[i].start, self[i].end, self[i].index, self[i].value)
			repr_string += "   ...\n"
			for i in range(-5, -1, 1):
				repr_string += "   (%d-%d, %s, %s)\n" % (self[i].start, self[i].end, self[i].index, self[i].value)
		else:
			for i in range(self.interval_list.nr):
				repr_string += "   (%d-%d, %s, %s)\n" % (self[i].start, self[i].end, self[i].index, self[i].value)

		return repr_string		


	cdef void set_list(AIList self, ailist_t *input_list):
		"""
		Set wrapper of C ailist

		Params
		---------
			input_list
				ailist_t* (ailist_t to replace existing one)

		Returns
		---------
			Nothing
		"""

		# Free old skiplist
		if self.interval_list:
			ailist_destroy(self.interval_list)
		
		# Replace new skiplist
		self.interval_list = input_list
		self.is_closed = False


	cdef void _insert(AIList self, int start, int end, double value):
		ailist_add(self.interval_list, start, end, self.interval_list.nr, value)

	def add(self, int start, int end, double value=0.0):
		"""
		Add an interval to AIList inplace
		
		Params
		---------
			start
				int (Start position of interval)
			end
				int (End position of interval)
			value
				double (Value of interval [default = 0.0])

		Returns
		---------
			Nothing
		"""
		
		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		self._insert(start, end, value)
		self.is_constructed = False
		self.is_sorted = False


	def from_array(self, const long[::1] starts, const long[::1] ends, const long[::1] index, const double[::1] values):
		"""
		Add an intervals from arrays to AIList inplace
		
		Params
		---------
			starts
				numpy.ndarray{long} (Start positions of intervals)
			ends
				numpy.ndarray{long} (End positions of intervals)
			index
				numpy.ndarray{long} (Index of intervals)
			values
				numpy.ndarray{double} (Values of intervals)

		Returns
		---------
			Nothing
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		cdef int array_length = len(starts)
		ailist_from_array(self.interval_list, &starts[0], &ends[0], &index[0], &values[0], array_length)
		self.is_constructed = False
		self.is_sorted = False


	cdef void _construct(AIList self, int min_length):
		ailist_construct(self.interval_list, min_length)

	def construct(self, int min_length=20):
		"""
		Construct ailist_t *Required to call intersect
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if already constructed
		if self.is_constructed == False:
			self._construct(min_length)
			self.is_constructed = True
			self.is_sorted = True
		else:
			pass
	

	cdef void _sort(AIList self):
		ailist_sort(self.interval_list)

	def sort(self):
		"""
		Sort intervals inplace
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		self._sort()
		self.is_sorted = True


	cdef ailist_t *_intersect(AIList self, int start, int end):
		cdef ailist_t *overlaps = ailist_query(self.interval_list, start, end)

		return overlaps

	def intersect(self, int start, int end):
		"""
		Find intervals overlapping given range
		
		Params
		---------
			start
				int (Start position of query range)
			end
				int (End position of query range)

		Returns
		---------
			overlaps
				AIList (Overlapping intervals)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		if self.is_constructed == False:
			self.construct()

		cdef ailist_t *i_list = self._intersect(start, end)
		cdef AIList overlaps = AIList()
		overlaps.set_list(i_list)

		return overlaps


	cdef np.ndarray _intersect_index(AIList self, int start, int end):
		cdef ailist_t *overlaps = ailist_query(self.interval_list, start, end)
		cdef long[::1] indices = np.zeros(overlaps.nr, dtype=np.long)

		ailist_extract_index(overlaps, &indices[0])

		return np.asarray(indices)

	def intersect_index(self, int start, int end):
		"""
		Find interval indices overlapping given range
		
		Params
		---------
			start
				int (Start position of query range)
			end
				int (End position of query range)

		Returns
		---------
			indice
				np.ndarray{int} (Overlapping interval indices)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if object has been constructed
		if self.is_constructed == False:
			self.construct()

		cdef np.ndarray indices = self._intersect_index(start, end)

		return indices


	@cython.boundscheck(False)
	@cython.wraparound(False)
	@cython.initializedcheck(False)
	cpdef _intersect_from_array(AIList self, const long[::1] starts, const long[::1] ends, const long[::1] indices):
		cdef int length = len(starts)
		cdef array_query_t *total_overlaps = ailist_query_from_array(self.interval_list, &starts[0], &ends[0], &indices[0], length)

		cdef np.ndarray ref_index = pointer_to_numpy_array(total_overlaps.ref_index, total_overlaps.size)
		cdef np.ndarray query_index = pointer_to_numpy_array(total_overlaps.query_index, total_overlaps.size)

		return ref_index, query_index

	def intersect_from_array(self, const long[::1] starts, const long[::1] ends, const long[::1] index):
		"""
		Find interval indices overlapping given ranges
		
		Params
		---------
			starts
				numpy.ndarray{long} (Start positions of intervals)
			ends
				numpy.ndarray{long} (End positions of intervals)
			index
				numpy.ndarray{long} (Index of intervals)

		Returns
		---------
			indice
				np.ndarray{int} (Overlapping interval indices)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		if self.is_constructed == False:
			self.construct()

		ref_index, query_index = self._intersect_from_array(starts, ends, index)
		
		return ref_index, query_index
		

	cdef np.ndarray _coverage(AIList self):
		# Initialize coverage
		cdef double[::1] coverage = np.zeros(self.range, dtype=np.double)

		ailist_coverage(self.interval_list, &coverage[0])

		return np.asarray(coverage)

	def coverage(self):
		"""
		Find number of intervals overlapping every
		position in the AList range

		Returns
		---------
			pandas.Series{double} (Position on index and coverage as values)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize coverage
		cdef np.ndarray coverage
		# Calculate coverage
		coverage = self._coverage()
		
		return pd.Series(coverage, index=np.arange(self.first, self.last))


	cdef np.ndarray _bin_coverage(AIList self, int bin_size):
		# Initialize coverage
		cdef int n_bins = math.ceil(self.last / bin_size) - (self.first // bin_size)
		cdef double[::1] bins = np.zeros(n_bins, dtype=np.double)

		ailist_bin_coverage(self.interval_list, &bins[0], bin_size)

		return np.asarray(bins)

	cdef np.ndarray _bin_coverage_length(AIList self, int bin_size, int min_length, int max_length):
		# Initialize coverage
		cdef int n_bins = math.ceil(self.last / bin_size) - (self.first // bin_size)
		cdef double[::1] bins = np.zeros(n_bins, dtype=np.double)

		ailist_bin_coverage_length(self.interval_list, &bins[0], bin_size, min_length, max_length)

		return np.asarray(bins)

	def bin_coverage(self, int bin_size=100000, min_length=None, max_length=None):
		"""
		Find sum of coverage within binned
		positions
		
		Params
		---------
			bin_size
				int (Size of the bin to use)
			min_length
				int (Minimum length of intervals to include [default = None])
			max_length
				int (Maximum length of intervals to include [default = None])

		Returns
		---------
			pandas.Series{double} (Position on index and coverage as values)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize coverage
		cdef np.ndarray bins
		# Calculate coverage
		if min_length is None or max_length is None:
			bins = self._bin_coverage(bin_size)
		else:
			bins = self._bin_coverage_length(bin_size, min_length, max_length)
		
		return pd.Series(bins, index=(np.arange(len(bins)) + int(self.first / bin_size)) * bin_size)


	cdef np.ndarray _bin_nhits(AIList self, int bin_size):
		# Initialize coverage
		cdef int n_bins = math.ceil(self.last / bin_size) - (self.first // bin_size)
		cdef double[::1] bins = np.zeros(n_bins, dtype=np.double)
		
		ailist_bin_nhits(self.interval_list, &bins[0], bin_size)

		return np.asarray(bins)

	cdef np.ndarray _bin_nhits_length(AIList self, int bin_size, int min_length, int max_length):
		# Initialize coverage
		cdef int n_bins = math.ceil(self.last / bin_size) - (self.first // bin_size)
		cdef double[::1] bins = np.zeros(n_bins, dtype=np.double)

		ailist_bin_nhits_length(self.interval_list, &bins[0], bin_size, min_length, max_length)

		return np.asarray(bins)

	def bin_nhits(self, int bin_size=100000, min_length=None, max_length=None):
		"""
		Find number of intervals overlapping binned
		positions
		
		Params
		---------
			bin_size
				int (Size of the bin to use)
			min_length
				int (Minimum length of intervals to include [default = None])
			max_length
				int (Maximum length of intervals to include [default = None])

		Returns
		---------
			pandas.Series{double} (Position on index and coverage as values)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize coverage
		cdef np.ndarray bins
		# Calculate coverage
		if min_length is None or max_length is None:
			bins = self._bin_nhits(bin_size)
		else:
			bins = self._bin_nhits_length(bin_size, min_length, max_length)
		
		return pd.Series(bins, index=(np.arange(len(bins)) + int(self.first / bin_size)) * bin_size)


	def display(self):
		"""
		Print all intervals
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		display_list(self.interval_list)


	def merge(self, int gap=0):
		"""
		Merge intervals within a gap
		
		Params
		---------
			gap
				int (Gap between intervals to merge)

		Returns
		---------
			merged_list
				AIList (Merged intervals)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Make sure list is sorted
		if self.is_sorted == False:
			self.sort()

		cdef AIList merged_list = AIList()
		cdef ailist_t *merged_clist = ailist_merge(self.interval_list, gap)

		merged_list.set_list(merged_clist)

		return merged_list


	def subtract(self, AIList query_ail):
		"""
		Subtract intervals within another AIList
		
		Params
		---------
			query_ail
				AIList (AIList of intervals to subtract)

		Returns
		---------
			subtracted_list
				AIList (Subtracted intervals)
		"""

		# Check if object is still open
		if self.is_closed or query_ail.is_closed:
			raise NameError("AIList object has been closed.")

		# Make sure list is sorted
		if self.is_sorted == False:
			self.sort()
		if query_ail.is_sorted == False:
			query_ail.sort()

		cdef AIList subtracted_list = AIList()
		cdef ailist_t *subtracted_clist = ailist_subtract(query_ail.interval_list,
														  self.interval_list)

		subtracted_list.set_list(subtracted_clist)

		return subtracted_list


	def common(self, AIList query_ail):
		"""
		Common intervals within another AIList
		
		Params
		---------
			query_ail
				AIList (AIList of intervals to find commons)

		Returns
		---------
			common_list
				AIList (Common intervals)
		"""

		# Check if object is still open
		if self.is_closed or query_ail.is_closed:
			raise NameError("AIList object has been closed.")

		# Make sure list is sorted
		if self.is_sorted == False:
			self.sort()
		if query_ail.is_sorted == False:
			query_ail.sort()

		cdef AIList common_list = AIList()
		cdef ailist_t *common_clist = ailist_common(query_ail.interval_list,
													self.interval_list)

		common_list.set_list(common_clist)

		return common_list


	def append(self, AIList query_ail):
		"""
		Union of intervals within two AIList
		
		Params
		---------
			query_ail
				AIList (AIList of intervals to append)

		Returns
		---------
			union_list
				AIList (Union of intervals)
		"""

		# Check if object is still open
		if self.is_closed or query_ail.is_closed:
			raise NameError("AIList object has been closed.")

		cdef AIList union_list = AIList()
		cdef ailist_t *union_clist = ailist_append(query_ail.interval_list,
												   self.interval_list)

		union_list.set_list(union_clist)

		return union_list


	cdef np.ndarray _wps(AIList self, int protection):
		# Initialize wps
		cdef double[::1] wps = np.zeros(self.range, dtype=np.double)

		ailist_wps(self.interval_list, &wps[0], protection)

		return np.asarray(wps)

	cdef np.ndarray _wps_length(AIList self, int protection, int min_length, int max_length):
		# Initialize wps
		cdef double[::1] wps = np.zeros(self.range, dtype=np.double)

		ailist_wps_length(self.interval_list, &wps[0], protection, min_length, max_length)

		return np.asarray(wps)

	def wps(self, int protection=60, min_length=None, max_length=None):
		"""
		Calculate Window Protection Score
		for each position in AIList range
		
		Params
		---------
			protection
				int (Protection window to use)
			min_length
				int (Minimum length of intervals to include [default = None])
			max_length
				int (Maximum length of intervals to include [default = None])

		Returns
		---------
			pandas.Series{double} (Position on index and WPS as values)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")
		
		# Initialize wps
		cdef np.ndarray wps
		# Calculate wps
		if min_length is None or max_length is None:
			wps = self._wps(protection)
		else:
			wps = self._wps_length(protection, min_length, max_length)
		
		return pd.Series(wps, index=np.arange(self.first, self.last))

	
	def filter(self, int min_length=1, int max_length=400):
		"""
		Filter out intervals outside of a length range
		
		Params
		---------
			min_length
				int (Minimum length to keep)
			max_length
				int (Maximum langth to keep)

		Returns
		---------
			filtered_ail
				AIList (Filtered intervals)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize filtered list
		cdef AIList filtered_ail = AIList()

		cdef ailist_t *cfiltered_ail = ailist_length_filter(self.interval_list, min_length, max_length)
		filtered_ail.set_list(cfiltered_ail)

		return filtered_ail


	cdef np.ndarray _length_dist(AIList self):
		# Initialize distribution
		cdef int max_length = ailist_max_length(self.interval_list)
		cdef int[::1] distribution = np.zeros(max_length + 1, dtype=np.intc)

		# Calculate distribution
		ailist_length_distribution(self.interval_list, &distribution[0])

		return np.asarray(distribution, dtype=np.intc)

	def length_dist(self):
		"""
		Calculate length distribution of intervals
		
		Returns
		---------
			distribution
				numpy.ndarray{int} (Interval length distribution)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize distribution
		cdef np.ndarray distribution
		# Calculate distribution
		distribution = self._length_dist()

		return distribution


	cdef np.ndarray _nhits_from_array(AIList self, const long[::1] starts, const long[::1] ends):
		# Initialize hits
		cdef int length = starts.size
		cdef int[::1] nhits = np.zeros(length, dtype=np.intc)

		# Calculate distribution
		ailist_nhits_from_array(self.interval_list, &starts[0], &ends[0], length, &nhits[0])

		return np.asarray(nhits, dtype=np.intc)

	cdef np.ndarray _nhits_from_array_length(AIList self, const long[::1] starts, const long[::1] ends, int min_length, int max_length):
		# Initialize hits
		cdef int length = starts.size
		cdef int[::1] nhits = np.zeros(length, dtype=np.intc)

		# Calculate distribution
		ailist_nhits_from_array_length(self.interval_list, &starts[0], &ends[0], length, &nhits[0], min_length, max_length)

		return np.asarray(nhits, dtype=np.intc)

	def nhits_from_array(self, const long[::1] starts, const long[::1] ends, min_length=None, max_length=None):
		"""
		Find number of intervals overlapping given
		positions
		
		Params
		---------
			starts
				numpy.ndarray{long} (Start positions to intersect)
			ends
				numpy.ndarray{long} (End positions to intersect)
			min_length
				int (Minimum length of intervals to include [default = None])
			max_length
				int (Maximum length of intervals to include [default = None])

		Returns
		---------
			nhits
				numpy.ndarray{int} (Number of hits per position)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Make sure list is constructed
		if self.is_constructed == False:
			self.construct()

		# Initialize distribution
		cdef np.ndarray nhits
		# Calculate distribution
		if min_length is None or max_length is None:
			nhits = self._nhits_from_array(starts, ends)
		else:
			nhits = self._nhits_from_array_length(starts, ends, min_length, max_length)

		return nhits

	
	def close(self):
		"""
		Close object and clear memory
		"""

		# Free interval_list memory
		if self.interval_list:
			ailist_destroy(self.interval_list)
		self.interval_list = NULL
		
		self.is_closed = True