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

	Parameters
	----------
		None

	Returns
	-------
		str (Directory to header files)
	"""

	return os.path.split(os.path.realpath(__file__))[0]


cpdef AIList rebuild(bytes data, bytes b_length):
	"""
	Rebuild function for __reduce__()

	Parameters
	----------
		data : bytes 
			Bytes representation of ailist_t
		b_length : bytes 
			Length of ailist_t

	Returns
	-------
		c : ailist_t* 
			Translated ailist_t from data
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
	
	PyArray_ENABLEFLAGS(arr, np.NPY_OWNDATA)
	#np.PyArray_UpdateFlags(arr, arr.flags.num | np.NPY_OWNDATA)

	return arr


cdef class Interval(object):
	"""
	Wrapper of C interval_t

	:class:`~ailist.Interval` stores an interval
	
	"""

	def __init__(self, start=None, end=None, index=None, value=None):
		"""
		Initialize Interval

		Parameters
		----------
			start : int
				Starting position [default = None]
			end : int
				Ending position [default = None]
			index : int
				Index position [defualt = None]
			value : float
				Value [default = None]

		Returns
		-------
			None

		"""

		if start is not None:
			if index is None:
				index = 0
			if value is None:
				value = 0.0
			# Create interval
			self.i = interval_init(start, end, index, value)

	# Set the interval
	cdef void set_i(Interval self, interval_t *i):
		"""
		Initialize wrapper of C interval

		Parameters
		----------
			i : interval_t
				C interval_t to be wrapped

		Returns
		-------
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
	

	def __hash__(self):
		"""
		Get hash value
		"""

		return hash(repr(self))

	
	def __eq__(self, other):
		"""
		Check if there is overlap
		"""

		# Check that the classes match
		is_equal = self.__class__ == other.__class__

		# Check for overlap
		if is_equal:
			if other.start < self.i.end and other.end > self.i.start:
				is_equal = True
			else:
				is_equal = False
		
		return is_equal


	def __str__(self):
		format_string = "Interval(%d-%d, %s, %s)" % (self.start, self.end, self.index, self.value)
		return format_string


	def __repr__(self):
		format_string = "Interval(%d-%d, %s, %s)" % (self.start, self.end, self.index, self.value)
		return format_string


	def to_list(self):
		"""
		Create an :class:`~ailist.AIList` with one element

		Parameters
		----------
			None

		Results
		-------
			ail : :class:`~ailist.AIList`
				Created list

		"""

		# Initialize AIList
		ail = AIList()

		# Add Interval
		ail.add(self.start, self.end, self.value)

		return ail


@cython.auto_pickle(True)
cdef class AIList(object):
	"""
	Wrapper for C ailist_t

	:class:`~ailist.AIList` stores a list of intervals
	"""

	def __cinit__(self):
		"""
		Initialize AIList object
		"""

		self.interval_list = ailist_init()
		self.is_constructed = False
		self.is_sorted = False
		self.is_closed = False
		self.is_frozen = False


	def __init__(self):
		"""
		Initialize AIList object
		"""

		pass


	def __dealloc__(self):
		"""
		Free AIList.interval_list
		"""
		
		#if hasattr(self, "interval_list"):
			#ailist_destroy(self.interval_list)

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

		Parameters
		----------
			data : bytes 
				Bytes representation of ailist_t
			b_length : bytes
				Length of ailist_t

		Returns
		---------
			interval_list : ailist_t*
				Translated ailist_t for bytes
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
			interval.set_i(&self.interval_list.interval_list[i])
			
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

	
	def __hash__(self):
		"""
		Get hash value
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		return hash(self)


	def __getitem__(self, key):
		"""
		Index Intervals by value
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if key is iterable
		cdef AIList indexed_ailist
		cdef int k
		cdef interval_t i
		cdef int slice_start
		cdef int slice_end
		cdef int slice_step
		try:
			iter(key) # Test is present
			# Iterate over key
			indexed_ailist = AIList()

			# Check if keys are booleans
			if isinstance(key[0], np.bool_):
				for k in range(len(key)):
					# if True
					if key[k]:
						# Add interval
						i = self.interval_list.interval_list[k]
						indexed_ailist.add(i.start, i.end, i.value)

			# Must be integers
			else:
				for k in key:
					# Add interval
					i = self.interval_list.interval_list[k]
					indexed_ailist.add(i.start, i.end, i.value)
			
			return indexed_ailist
		
		# key is not iterable, treat as int
		except TypeError:
			# Check if key is slice
			if isinstance(key, slice):
				# Determine indices
				slice_start, slice_end, slice_step = key.indices(self.size)
				# Iterate over key
				indexed_ailist = AIList()
				for k in range(slice_start, slice_end, slice_step):
					# Add interval
					i = self.interval_list.interval_list[k]
					indexed_ailist.add(i.start, i.end, i.value)
					
				return indexed_ailist

			# Check if key is greater than length
			if key >= self.interval_list.nr:
				raise IndexError("Value larger than ailist length")

			# Check if negative
			if key < 0:
				key = self.interval_list.nr + key

			# Create Interval wrapper
			output_interval = Interval()
			output_interval.set_i(&self.interval_list.interval_list[key])
		
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

		Parameters
		----------
			input_list : ailist_t*
				ailist_t to replace existing one

		Returns
		-------
			None
		"""

		# Free old skiplist
		if self.interval_list:
			ailist_destroy(self.interval_list)
		
		# Replace new skiplist
		self.interval_list = input_list
		self.is_closed = False


	def freeze(self):
		"""
		Make :class:`~ailist.AIList` immutable

		Parameters
		----------
			None

		Returns
		-------
			None

		See Also
		--------
		AIList.unfreeze: Make mutable
		AIList.sort: Sort intervals inplace
		AIList.construct: Construct AIList, required to call AIList.intersect

		Examples
		--------
		>>> from ailist import AIList
		>>> ail = AIList()
		>>> ail.add(1, 2)
		>>> ail.add(3, 4)
		>>> ail.add(3, 6)
		>>> ail
		AIList
		  range: (1-6)
		   (1-2, 0, 0.0)
		   (3-4, 1, 0.0)
		   (3-6, 2, 0.0)
		>>> ail.freeze()
		>>> ail.add(9, 10)
		TypeError: AIList is frozen and currently immutatable. Try '.unfreeze()' to reverse.

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Make sure it is constructed
		if self.is_constructed == False:
			self.construct()

		# Change to frozen
		self.is_frozen = True


	def unfreeze(self):
		"""
		Make :class:`~ailist.AIList` mutable

		Parameters
		----------
			None

		Returns
		-------
			None

		See Also
		--------
		AIList.freeze: Make immutable
		AIList.sort: Sort intervals inplace
		AIList.construct: Construct AIList, required to call AIList.intersect

		Examples
		--------
		>>> from ailist import AIList
		>>> ail = AIList()
		>>> ail.add(1, 2)
		>>> ail.add(3, 4)
		>>> ail.add(3, 6)
		>>> ail
		AIList
		  range: (1-6)
		   (1-2, 0, 0.0)
		   (3-4, 1, 0.0)
		   (3-6, 2, 0.0)
		>>> ail.freeze()
		>>> ail.add(9, 10)
		TypeError: AIList is frozen and currently immutatable. Try '.unfreeze()' to reverse.
		>>> ail.unfreeze()
		>>> ail.add(9, 10)

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Change to not frozen
		self.is_frozen = False


	cdef void _insert(AIList self, int start, int end, double value):
		ailist_add(self.interval_list, start, end, self.interval_list.nr, value)

	def add(self, int start, int end, double value=0.0):
		"""
		Add an interval to AIList inplace
		
		Parameters
		----------
			start : int
				Start position of interval
			end : int
				End position of interval
			value : double
				Value of interval [default = 0.0]

		Returns
		-------
			None

		See Also
		--------
		AIList.from_array: Add intervals from arrays
		AIList.construct: Construct AIList, required to call AIList.intersect
		AIList.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from ailist import AIList
		>>> ail = AIList()
		>>> ail.add(1, 2)
		>>> ail.add(3, 4)
		>>> ail.add(3, 6)
		>>> ail
		AIList
		  range: (1-6)
		   (1-2, 0, 0.0)
		   (3-4, 1, 0.0)
		   (3-6, 2, 0.0)

		"""
		
		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check that object is not frozen
		if self.is_frozen:
			raise TypeError("AIList is frozen and currently immutatable. Try '.unfreeze()' to reverse.")

		self._insert(start, end, value)
		self.is_constructed = False
		self.is_sorted = False


	def from_array(self, const long[::1] starts, const long[::1] ends, const long[::1] index, const double[::1] values):
		"""
		Add intervals from arrays to AIList inplace
		
		Parameters
		----------
			starts : ~numpy.ndarray{long}
				Start positions of intervals
			ends : numpy.ndarray{long}
				End positions of intervals
			index : numpy.ndarray{long}
				Index of intervals
			values : numpy.ndarray{double}
				Values of intervals

		Returns
		-------
			None

		See Also
		--------
		AIList.add: Add interval to AIList
		AIList.construct: Construct AIList, required to call AIList.intersect
		AIList.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from ailist import AIList
		>>> import numpy as np
		>>> starts = np.arange(100)
		>>> ends = starts + 10
		>>> index = np.arange(len(starts))
		>>> values = np.ones(len(starts))
		>>> ail = AIList()
		>>> ail.from_array(starts, ends, index, values)
		>>> ail.
		AIList
		  range: (0-109)
		   (0-10, 0, 1.0)
		   (1-11, 1, 1.0)
		   (2-12, 2, 1.0)
		   (3-13, 3, 1.0)
		   (4-14, 4, 1.0)
		   ...
		   (95-105, 95, 1.0)
		   (96-106, 96, 1.0)
		   (97-107, 97, 1.0)
		   (98-108, 98, 1.0)

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check that object is not frozen
		if self.is_frozen:
			raise TypeError("AIList is frozen and currently immutatable. Try '.unfreeze()' to reverse.")

		cdef int array_length = len(starts)
		ailist_from_array(self.interval_list, &starts[0], &ends[0], &index[0], &values[0], array_length)
		self.is_constructed = False
		self.is_sorted = False


	cdef void _construct(AIList self, int min_length):
		ailist_construct(self.interval_list, min_length)

	def construct(self, int min_length=20):
		"""
		Construct ailist_t *Required to call intersect

		Parameters
		----------
			min_length : int
				Minimum length

		Returns
		-------
			None

		.. warning::
			This will re-sort intervals inplace

		See Also
		--------
		AIList.sort: Sort intervals inplace
		AIList.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from ailist import AIList
		>>> ail = AIList()
		>>> ail.add(1, 2)
		>>> ail.add(3, 4)
		>>> ail.add(2, 6)
		>>> ail
		AIList
		  range: (1-6)
		   (1-2, 0, 0.0)
		   (3-4, 1, 0.0)
		   (2-6, 2, 0.0)
		>>> ail.construct()
		>>> ail
		AIList
		  range: (1-6)
		   (1-2, 0, 0.0)
		   (2-6, 2, 0.0)
		   (3-4, 1, 0.0)

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

		Parameters
		----------
			None

		Returns
		-------
			None
		
		See Also
		--------
		AIList.construct: Construct AIList, required to call AIList.intersect

		Examples
		--------
		>>> from ailist import AIList
		>>> ail = AIList()
		>>> ail.add(1, 2)
		>>> ail.add(3, 4)
		>>> ail.add(2, 6)
		>>> ail
		AIList
		  range: (1-6)
		   (1-2, 0, 0.0)
		   (3-4, 1, 0.0)
		   (2-6, 2, 0.0)
		>>> ail.sort()
		>>> ail
		AIList
		  range: (1-6)
		   (1-2, 0, 0.0)
		   (2-6, 2, 0.0)
		   (3-4, 1, 0.0)

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if sorted
		if self.is_sorted == False:
			self._sort()
			self.is_sorted = True


	cdef ailist_t *_intersect(AIList self, int start, int end):
		cdef ailist_t *overlaps = ailist_query(self.interval_list, start, end)

		return overlaps

	def intersect(self, int start, int end):
		"""
		Find intervals overlapping given range
		
		Parameters
		----------
			start : int
				Start position of query range
			end : int
				End position of query range

		Returns
		-------
			overlaps : AIList
				Overlapping intervals

		.. warning::
			This requires :func:`~ailist.AIList.construct` and will run it if not already run. This will re-sort intervals inplace.

		See Also
		--------
		AIList.construct: Construct AIList, required to call AIList.intersect
		AIList.add: Add interval to AIList
		AIList.intersect_index: Find interval indices overlapping given range
		AIList.intersect_from_array: Find interval indices overlapping given ranges

		Examples
		--------
		>>> from ailist import AIList
		>>> ail = AIList()
		>>> ail.add(1, 2)
		>>> ail.add(3, 4)
		>>> ail.add(2, 6)
		>>> ail
		AIList
		  range: (1-6)
		   (1-2, 0, 0.0)
		   (3-4, 1, 0.0)
		   (2-6, 2, 0.0)
		>>> q = ail.intersect(2, 10)
		>>> q
		AIList
		  range: (2-6)
		   (2-6, 2, 0.0)
		   (3-4, 1, 0.0)

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if is constructed
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
		
		Parameters
		----------
			start : int
				Start position of query range
			end : int
				End position of query range

		Returns
		-------
			indice numpy.ndarray{int}
				Overlapping interval indices

		.. warning::
			This requires :func:`~ailist.AIList.construct` and will run it if not already run. This will re-sort intervals inplace.

		See Also
		--------
		AIList.construct: Construct AIList, required to call AIList.intersect
		AIList.add: Add interval to AIList
		AIList.intersect: Find intervals overlapping given range
		AIList.intersect_from_array: Find interval indices overlapping given ranges

		Examples
		--------
		>>> from ailist import AIList
		>>> ail = AIList()
		>>> ail.add(1, 2)
		>>> ail.add(3, 4)
		>>> ail.add(2, 6)
		>>> ail
		AIList
		  range: (1-6)
		   (1-2, 0, 0.0)
		   (3-4, 1, 0.0)
		   (2-6, 2, 0.0)
		>>> q = ail.intersect_index(2, 10)
		>>> q
		array([2, 1])

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
		
		Parameters
		----------
			starts : numpy.ndarray{long}
				Start positions of intervals
			ends : numpy.ndarray{long}
				End positions of intervals
			index : numpy.ndarray{long}
				Index of intervals

		Returns
		-------
			ref_index : np.ndarray{int}
				Overlapping interval indices from AIList
			query_index : np.ndarray{int}
				Overlapping interval indices from query AIList

		.. warning::
			This requires :func:`~ailist.AIList.construct` and will run it if not already run. This will re-sort intervals inplace.

		See Also
		--------
		AIList.construct: Construct AIList, required to call AIList.intersect
		AIList.add: Add interval to AIList
		AIList.intersect: Find intervals overlapping given range
		AIList.intersect_index: Find interval indices overlapping given range

		Examples
		--------
		>>> from ailist import AIList
		>>> ail1 = AIList()
		>>> ail1.add(1, 2)
		>>> ail1.add(3, 4)
		>>> ail1.add(2, 6)
		>>> ail1
		AIList
		  range: (1-6)
		   (1-2, 0, 0.0)
		   (3-4, 1, 0.0)
		   (2-6, 2, 0.0)
		>>> ail2 = AIList()
		>>> ail2.add(1, 2)
		>>> ail2.add(3, 6)
		>>> ail2
		AIList
		  range: (1-6)
		    (1-2, 0, 0.0)
		    (3-6, 1, 0.0)
		>>> q = ail1.intersect_from_array(ail2)
		>>> q
		(array([2, 1]), array([]))

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if object is constructed
		if self.is_constructed == False:
			self.construct()

		ref_index, query_index = self._intersect_from_array(starts, ends, index)
		
		return ref_index, query_index


	cpdef _intersect_from_ailist(AIList self, AIList ail):
		# Intersect with other AIList
		cdef array_query_t *total_overlaps = ailist_query_from_ailist(self.interval_list, ail.interval_list)

		cdef np.ndarray ref_index = pointer_to_numpy_array(total_overlaps.ref_index, total_overlaps.size)
		cdef np.ndarray query_index = pointer_to_numpy_array(total_overlaps.query_index, total_overlaps.size)

		return ref_index, query_index

	def intersect_from_ailist(self, AIList ail_query):
		"""
		Find interval indices overlapping given ranges
		
		Parameters
		----------
			ail_query : AIList
				Intervals to query

		Returns
		-------
			ref_index : np.ndarray{int}
				Overlapping interval indices from AIList
			query_index : np.ndarray{int}
				Overlapping interval indices from query AIList

		.. warning::
			This requires :func:`~ailist.AIList.construct` and will run it if not already run. This will re-sort intervals inplace.

		See Also
		--------
		AIList.construct: Construct AIList, required to call AIList.intersect
		AIList.add: Add interval to AIList
		AIList.intersect: Find intervals overlapping given range
		AIList.intersect_index: Find interval indices overlapping given range
		AIList.intersect_from_array: Find interval indices overlapping given range

		Examples
		--------
		>>> from ailist import AIList
		>>> ail1 = AIList()
		>>> ail1.add(1, 2)
		>>> ail1.add(3, 4)
		>>> ail1.add(2, 6)
		>>> ail1
		AIList
		  range: (1-6)
		   (1-2, 0, 0.0)
		   (3-4, 1, 0.0)
		   (2-6, 2, 0.0)
		>>> ail2 = AIList()
		>>> ail2.add(1, 2)
		>>> ail2.add(3, 6)
		>>> ail2
		AIList
		  range: (1-6)
		    (1-2, 0, 0.0)
		    (3-6, 1, 0.0)
		>>> q = ail1.intersect_from_array(ail2)
		>>> q
		(array([2, 1]), array([]))

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if object is constructed
		if self.is_constructed == False:
			self.construct()

		ref_index, query_index = self._intersect_from_ailist(ail_query)
		
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

		Parameters
		----------
			None

		Returns
		-------
			pandas.Series{double}
				Position on index and coverage as values
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
		
		Parameters
		----------
			bin_size : int
				Size of the bin to use
			min_length : int
				Minimum length of intervals to include [default = None]
			max_length : int
				Maximum length of intervals to include [default = None]

		Returns
		-------
			pandas.Series{double}
				Position on index and coverage as values

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
		
		Parameters
		----------
			bin_size : int
				Size of the bin to use
			min_length : int
				Minimum length of intervals to include [default = None]
			max_length : int
				Maximum length of intervals to include [default = None]

		Returns
		-------
			pandas.Series{double}
				Position on index and coverage as values

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


	cdef np.ndarray _bin_sums(AIList self, int bin_size):
		# Initialize coverage
		cdef int n_bins = math.ceil(self.last / bin_size) - (self.first // bin_size)
		cdef double[::1] bins = np.zeros(n_bins, dtype=np.double)
		
		ailist_bin_sums(self.interval_list, &bins[0], bin_size)

		return np.asarray(bins)

	def bin_sums(self, int bin_size=100000):
		"""
		Find sum of values for intervals overlapping binned
		positions
		
		Params
		---------
			bin_size
				int (Size of the bin to use)

		Returns
		---------
			pandas.Series{double} (Position on index and sum as values)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize coverage
		cdef np.ndarray bins
		# Calculate sums
		bins = self._bin_sums(bin_size)
		
		return pd.Series(bins, index=(np.arange(len(bins)) + int(self.first / bin_size)) * bin_size)


	def bin_means(self, int bin_size=100000):
		"""
		Find mean of values for intervals overlapping binned
		positions
		
		Params
		---------
			bin_size
				int (Size of the bin to use)

		Returns
		---------
			pandas.Series{double} (Position on index and mean as values)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize coverage
		cdef np.ndarray sums
		cdef np.ndarray nhits
		cdef np.ndarray means
		
		# Calculate sums
		sums = self._bin_sums(bin_size)
		nhits = self._bin_nhits(bin_size)
		means = sums / nhits
		
		return pd.Series(means, index=(np.arange(len(means)) + int(self.first / bin_size)) * bin_size)


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
		if self.range == 0:
			return None
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


	cdef np.ndarray _interval_coverage(AIList self, int start, int end):
		# Initialize hits
		cdef int[::1] coverage = np.zeros(end - start, dtype=np.intc)

		# Calculate distribution
		ailist_interval_coverage(self.interval_list, start, end, &coverage[0])

		return np.asarray(coverage, dtype=np.intc)
	
	def interval_coverage(self, int start, int end):
		"""
		Find number of intervals overlapping each
		position in given interval
		
		Params
		---------
			start
				int (Start position to intersect)
			end
				int (End position to intersect)

		Returns
		---------
			coverage
				numpy.ndarray{int} (Number of hits per position)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Make sure list is constructed
		if self.is_constructed == False:
			self.construct()

		# Initialize distribution
		cdef np.ndarray coverage
		# Calculate distribution
		coverage = self._interval_coverage(start, end)

		return pd.Series(coverage, index=np.arange(start, end))

	
	def downsample(self, double proportion):
		"""
		Randomly downsample AIList
		
		Params
		---------
			proportion
				double (Proportion of intervals to keep)

		Returns
		---------
			filtered_AIList
				AIList (Downsampled AIList)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize filtered list
		cdef AIList filtered_ail = AIList()

		cdef ailist_t *cfiltered_ail = ailist_downsample(self.interval_list, proportion)
		filtered_ail.set_list(cfiltered_ail)

		return filtered_ail


	def reset_index(self):
		"""
		Reset index value

		Parameters
		----------
			None
		
		Returns
		-------
			None

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Reset index
		ailist_reset_index(self.interval_list)


	def extract_index(self):
		"""
		Return the index values

		Parameters
		----------
			None

		Returns
		-------
			numpy.ndarray
				Index values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Extract index values
		cdef long[::1] indices = np.zeros(self.size, dtype=np.int_)
		ailist_extract_index(self.interval_list, &indices[0])

		return np.asarray(indices, dtype=np.intc)


	def extract_starts(self):
		"""
		Return the start values

		Parameters
		----------
			None

		Returns
		-------
			numpy.ndarray
				Start values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Extract start values
		cdef long[::1] starts = np.zeros(self.size, dtype=np.int_)
		ailist_extract_starts(self.interval_list, &starts[0])

		return np.asarray(starts, dtype=np.intc)

	
	def extract_ends(self):
		"""
		Return the end values

		Parameters
		----------
			None

		Returns
		-------
			numpy.ndarray
				End values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Extract end values
		cdef long[::1] ends = np.zeros(self.size, dtype=np.int_)
		ailist_extract_ends(self.interval_list, &ends[0])

		return np.asarray(ends, dtype=np.intc)


	def extract_values(self):
		"""
		Return the values

		Parameters
		----------
			None

		Returns
		-------
			numpy.ndarray
				Values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Extract end values
		cdef double[::1] values = np.zeros(self.size, dtype=np.double)
		ailist_extract_values(self.interval_list, &values[0])

		return np.asarray(values, dtype=np.intc)

	
	def close(self):
		"""
		Close object and clear memory
		"""

		# Free interval_list memory
		if self.interval_list:
			ailist_destroy(self.interval_list)
		self.interval_list = NULL
		
		self.is_closed = True