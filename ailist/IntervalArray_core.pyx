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
		location : str
			Directory to header files
	"""

	# Grab file location
	location = os.path.split(os.path.realpath(__file__))[0]

	return location


cpdef IntervalArray rebuild_IntervalArray(bytes data, bytes b_length):
	"""
	Rebuild function for __reduce__()

	Parameters
	----------
		data : bytes 
			Bytes representation of aiarray_t
		b_length : bytes 
			Length of aiarray_t

	Returns
	-------
		aia : aiarray_t* 
			Translated aiarray_t from data

	"""

	# Initialize new IntervalArray
	aia = IntervalArray()

	# Build IntervalArray from serialized data
	cdef aiarray_t *interval_list = aia._set_data(data, b_length)
	aia.set_list(interval_list)

	return aia


@cython.auto_pickle(True)
cdef class IntervalArray(object):
	"""
	Wrapper for C aiarray_t

	:class:`~IntervalArray.IntervalArray` stores a list of intervals
	"""

	def __cinit__(self):
		"""
		Initialize IntervalArray object
		"""

		self.c_aiarray = aiarray_init()
		self.is_constructed = False
		self.is_closed = False
		self.is_frozen = False


	def __init__(self):
		"""
		Initialize IntervalArray object

		Parameters
		----------
			None

		Returns
		-------
			None

		"""

		pass


	def __dealloc__(self):
		"""
		Free IntervalArray.c_aiarray
		"""
		
		#if hasattr(self, "interval_list"):
			#aiarray_destroy(self.c_aiarray)

		aiarray_destroy(self.c_aiarray)


	cdef bytes _get_data(self):
		"""
		Function to convert aiarray_t to bytes
		for serialization by __reduce__()
		"""

		return <bytes>(<char*>self.c_aiarray.interval_list)[:(sizeof(interval_t)*self.c_aiarray.nr)]


	cdef aiarray_t *_set_data(self, bytes data, bytes b_length):
		"""
		Function to build aiarray_t object from
		serialized bytes using __reduce__()

		Parameters
		----------
			data : bytes 
				Bytes representation of aiarray_t
			b_length : bytes
				Length of aiarray_t

		Returns
		---------
			interval_list : aiarray_t*
				Translated aiarray_t for bytes
		"""
		
		# Convert bytes to ints
		cdef int length = int.from_bytes(b_length, byteorder)
		
		# Create new aiarray_t
		cdef aiarray_t *aia = aiarray_init()
		cdef interval_t *interval_list = <interval_t*>malloc(length * sizeof(interval_t))
		memcpy(interval_list, <char*>data, sizeof(interval_t) * length)

		# Iteratively add intervals to interval_list		
		cdef int i
		for i in range(length):
			aiarray_add(aia, interval_list[i].start, interval_list[i].end)

		return aia


	def __reduce__(self):
		"""
		Used for pickling. Convert IntervalArray to bytes and back.
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")
		
		# Convert ints to bytes
		b_length = int(self.c_aiarray.nr).to_bytes(4, byteorder)

		# Convert aiarray_t to bytes
		data = self._get_data()

		return (rebuild_IntervalArray, (data, b_length))

	
	@property
	def nc(self):
		"""
		Number of components in constructed IntervalArray
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check if object is constructed
		if self.is_constructed:
			return self.c_aiarray.nc
		else:
			return None


	@property
	def lenC(self):
		"""
		Length of components in constructed IntervalArray
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check if object is constructed
		if self.is_constructed:
			return self.c_aiarray.lenC[self.c_aiarray.nc]
		else:
			return None

	
	@property
	def idxC(self):
		"""
		Index of components in constructed IntervalArray
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check
		if self.is_constructed:
			return self.c_aiarray.idxC[self.c_aiarray.nc]
		else:
			return None


	@property	
	def size(self):
		"""
		Number of intervals in IntervalArray
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		return self.c_aiarray.nr
	
	@property
	def first(self):
		"""
		Start of first interval in IntervalArray
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")
		
		# Check if ther are any intervals
		if self.size == 0:
			return None
		else:
			return self.c_aiarray.first

	@property
	def last(self):
		"""
		End of last intervals in IntervalArray
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check if there are any intervals
		if self.size == 0:
			return None
		else:
			return self.c_aiarray.last

	@property
	def range(self):
		"""
		IntervalArray.last - IntervalArray.first
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check if ther are any intervals
		if self.size == 0:
			return 0
		else:
			return self.last - self.first

	@property
	def id_index(self):
		"""
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")
		# Check if object is constructed
		if self.is_constructed == False:
			raise NameError("IntervalArray object must be constructed.")		
		
		ids = np.zeros(len(self), dtype=np.intc)
		cdef int i
		for i in range(len(self)):
			ids[i] = self.c_aiarray.id_index[i]

		return ids

	def __len__(self):
		"""
		Return size of interval_list
		"""
		
		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		return self.size

	
	def __iter__(self):
		"""
		Iterate over IntervalArray object
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Iterate over interval list
		cdef Interval interval
		cdef interval_t *cinterval
		cdef int i
		for i in range(self.size):
			interval = Interval()
			cinterval = aiarray_get_index(self.c_aiarray, i)
			interval.set_i(cinterval)
			
			yield interval


	def __sub__(self, IntervalArray query_ail):
		"""
		Subtract values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		return self.subtract(query_ail)


	def __add__(self, IntervalArray query_ail):
		"""
		Common values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		return self.common(query_ail)


	def __or__(self, IntervalArray query_ail):
		"""
		Common values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		return self.append(query_ail)

	
	def __hash__(self):
		"""
		Get hash value
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		return hash(self)
		
		
	cdef aiarray_t *_array_index(IntervalArray self, const long[::1] ids):
		"""
		Index and array looking for index value

		Parameters
		----------
			self : IntervalArray
				self object
			ids : const long[::1]
				Indices

		Returns
		-------
			cindexed_IntervalArray : aiarray_t
				Subseted array

		"""
		
		# Define variables
		cdef int length = len(ids)
		cdef aiarray_t *cindexed_IntervalArray
		
		# Call C indexing to subset aiarray_t
		cindexed_IntervalArray = aiarray_array_index(self.c_aiarray, &ids[0], length)
		
		return cindexed_IntervalArray

	def __getitem__(self, key):
		"""
		Index Intervals by value
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Define variables
		cdef IntervalArray indexed_IntervalArray
		cdef aiarray_t *cindexed_IntervalArray
		cdef int k
		cdef interval_t *i
		cdef int slice_start
		cdef int slice_end
		cdef int slice_step

		# Check if key is iterable
		try:
			iter(key) # Test is present
			# Iterate over key
			indexed_IntervalArray = IntervalArray()

			# Check if keys are booleans
			if isinstance(key[0], np.bool_):
				for k in range(len(key)):
					# if True
					if key[k]:
						# Add interval
						#i = self.c_aiarray.interval_list[k]
						i = aiarray_get_index(self.c_aiarray, k)
						indexed_IntervalArray.add(i.start, i.end)

			# Must be integers
			else:
				cindexed_IntervalArray = self._array_index(key)
				indexed_IntervalArray.set_list(cindexed_IntervalArray)
			
			return indexed_IntervalArray
		
		# key is not iterable, treat as int
		except TypeError:
			# Check if key is slice
			if isinstance(key, slice):
				# Determine indices
				slice_start, slice_end, slice_step = key.indices(self.size)
				# Iterate over key
				indexed_IntervalArray = IntervalArray()
				for k in range(slice_start, slice_end, slice_step):
					# Add interval
					#i = self.c_aiarray.interval_list[k]
					i = aiarray_get_index(self.c_aiarray, k)
					indexed_IntervalArray.add(i.start, i.end)
					
				return indexed_IntervalArray

			# Check if key is greater than length
			if key >= self.c_aiarray.nr:
				raise IndexError("Value larger than IntervalArray length")

			# Check if negative
			if key < 0:
				key = self.c_aiarray.nr + key

			# Create Interval wrapper
			output_interval = Interval()
			i = aiarray_get_index(self.c_aiarray, key)
			output_interval.set_i(i)
		
		return output_interval


	def __repr__(self):
		"""
		Representation of IntervalArray object
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Initialize string
		repr_string = "IntervalArray\n"
		if self.size == 0:
			repr_string += " range: (None-None)\n"
		else:
			repr_string += " range: (%d-%d)\n" % (self.first, self.last)

		# Iterate over interval_list
		if self.c_aiarray.nr > 10:
			for i in range(5):
				repr_string += "   (%d-%d)\n" % (self[i].start, self[i].end)
			repr_string += "   ...\n"
			for i in range(-5, 0, 1):
				repr_string += "   (%d-%d)\n" % (self[i].start, self[i].end)
		else:
			for i in range(self.c_aiarray.nr):
				repr_string += "   (%d-%d)\n" % (self[i].start, self[i].end)

		return repr_string		


	cdef void set_list(IntervalArray self, aiarray_t *input_list):
		"""
		Set wrapper of C IntervalArray

		Parameters
		----------
			input_list : aiarray_t*
				aiarray_t to replace existing one

		Returns
		-------
			None
		"""

		# Free old skiplist
		#if self.c_aiarray:
			#aiarray_destroy(self.c_aiarray)
		aiarray_destroy(self.c_aiarray)
		
		# Replace new skiplist
		self.c_aiarray = input_list
		self.is_closed = False


	def freeze(self):
		"""
		Make :class:`~IntervalArray.IntervalArray` immutable

		Parameters
		----------
			None

		Returns
		-------
			None

		See Also
		--------
		IntervalArray.unfreeze: Make mutable
		IntervalArray.sort: Sort intervals inplace
		IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect

		Examples
		--------
		>>> from IntervalArray import IntervalArray
		>>> ail = IntervalArray()
		>>> ail.add(1, 2)
		>>> ail.add(3, 4)
		>>> ail.add(3, 6)
		>>> ail
		IntervalArray
		  range: (1-6)
		   (1-2)
		   (3-4)
		   (3-6)
		>>> ail.freeze()
		>>> ail.add(9, 10)
		TypeError: IntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Make sure it is constructed
		if self.is_constructed == False:
			self.construct()

		# Change to frozen
		self.is_frozen = True


	def unfreeze(self):
		"""
		Make :class:`~IntervalArray.IntervalArray` mutable

		Parameters
		----------
			None

		Returns
		-------
			None

		See Also
		--------
		IntervalArray.freeze: Make immutable
		IntervalArray.sort: Sort intervals inplace
		IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect

		Examples
		--------
		>>> from IntervalArray import IntervalArray
		>>> ail = IntervalArray()
		>>> ail.add(1, 2)
		>>> ail.add(3, 4)
		>>> ail.add(3, 6)
		>>> ail
		IntervalArray
		  range: (1-6)
		   (1-2)
		   (3-4)
		   (3-6)
		>>> ail.freeze()
		>>> ail.add(9, 10)
		TypeError: IntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.
		>>> ail.unfreeze()
		>>> ail.add(9, 10)

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Change to not frozen
		self.is_frozen = False


	cdef void _insert(IntervalArray self, int start, int end):
		aiarray_add(self.c_aiarray, start, end)

	def add(self, int start, int end):
		"""
		Add an interval to IntervalArray inplace
		
		Parameters
		----------
			start : int
				Start position of interval
			end : int
				End position of interval

		Returns
		-------
			None

		See Also
		--------
		IntervalArray.from_array: Add intervals from arrays
		IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect
		IntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from IntervalArray import IntervalArray
		>>> ail = IntervalArray()
		>>> ail.add(1, 2)
		>>> ail.add(3, 4)
		>>> ail.add(3, 6)
		>>> ail
		IntervalArray
		  range: (1-6)
		   (1-2)
		   (3-4)
		   (3-6)

		"""
		
		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check that object is not frozen
		if self.is_frozen:
			raise TypeError("IntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.")

		# Insert interval
		self._insert(start, end)
		self.is_constructed = False


	cdef np.ndarray _get_comp_bounds(IntervalArray self):
		"""
		Get component index for label
		"""

		# Initialize label specific variables
		cdef int *idxC = self.c_aiarray.idxC
		cdef int n_comps = self.c_aiarray.nc
		cdef np.ndarray comps_bounds = np.zeros(n_comps + 1, dtype=int)

		# Iterate over components
		cdef int i
		for i in range(n_comps):
			comps_bounds[i] = idxC[i]
		comps_bounds[n_comps] = self.c_aiarray.nr

		return comps_bounds
	
	def iter_sorted(self):
		"""
		Iterate over an IntervalArray in sort by starts

		Parameters
		----------
			None

		Returns
		-------
			intervals : generator of Interval objects
				Generates Interval objects sorted by starts

		"""

		#raise NotImplementedError("This feature is not implemented yet")

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check if object is constructed
		if not self.is_constructed:
			raise TypeError("IntervalArray object must be constructed first. Try '.construct()' first.")

		# Define variables
		#cdef np.ndarray self.ail.idxC[]
		cdef np.ndarray comp_bounds
		cdef np.ndarray label_comp_used
		cdef int n
		cdef int position
		cdef int selected_comp
		#cdef int label_start
		#cdef int label_end
		cdef interval_t *cintv
		cdef Interval output_interval

		#label_code = self.label_map[label]
		comp_bounds = self._get_comp_bounds()
		comp_used = comp_bounds[:len(comp_bounds) - 1].copy()

		#label_start = self.ail.label_index[label_code]
		#label_end = self.ail.label_index[label_code + 1]

		# Iterate over component intervals
		cintv = &self.c_aiarray.interval_list[0]
		for n in range(self.size):
			selected_comp = 0
			# Iterate over other components
			for j in range(len(comp_bounds) - 1):
				# Check component has intervals left to investigate
				if comp_used[j] == comp_bounds[j + 1]:
					continue
				# Determine position
				position = comp_used[j]
				# Check for lower start
				if self.c_aiarray.interval_list[position].start < cintv.start:
					cintv = &self.c_aiarray.interval_list[position]
					selected_comp = j

			# Create Interval wrapper
			output_interval = Interval()
			output_interval.set_i(cintv)
			yield output_interval
			
			# Increment comp_counter for selected comp
			comp_used[selected_comp] += 1
			# Iterate over components
			for j in range(len(comp_bounds) - 1):
				# If position is available, assign next interval
				if comp_used[j] != comp_bounds[j + 1]:
					position = comp_used[j]
					cintv = &self.c_aiarray.interval_list[position]
					break


	def from_array(self, const long[::1] starts, const long[::1] ends):
		"""
		Add intervals from arrays to IntervalArray inplace
		
		Parameters
		----------
			starts : ~numpy.ndarray{long}
				Start positions of intervals
			ends : numpy.ndarray{long}
				End positions of intervals

		Returns
		-------
			None

		See Also
		--------
		IntervalArray.add: Add interval to IntervalArray
		IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect
		IntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from IntervalArray import IntervalArray
		>>> import numpy as np
		>>> starts = np.arange(100)
		>>> ends = starts + 10
		>>> ail = IntervalArray()
		>>> ail.from_array(starts, ends)
		>>> ail.
		IntervalArray
		  range: (0-109)
		   (0-10)
		   (1-11)
		   (2-12)
		   (3-13)
		   (4-14)
		   ...
		   (95-105)
		   (96-106)
		   (97-107)
		   (98-108)

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check that object is not frozen
		if self.is_frozen:
			raise TypeError("IntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.")

		# Call C function to create
		cdef int array_length = len(starts)
		aiarray_from_array(self.c_aiarray, &starts[0], &ends[0], array_length)
		self.is_constructed = False


	cdef void _construct(IntervalArray self, int min_length):
		# Contruct
		aiarray_construct(self.c_aiarray, min_length)
		# Remember input order
		aiarray_cache_id(self.c_aiarray)

	def construct(self, int min_length=20):
		"""
		Construct aiarray_t *Required to call intersect

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
		IntervalArray.sort: Sort intervals inplace
		IntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from IntervalArray import IntervalArray
		>>> ail = IntervalArray()
		>>> ail.add(1, 2)
		>>> ail.add(3, 4)
		>>> ail.add(2, 6)
		>>> ail
		IntervalArray
		  range: (1-6)
		   (1-2)
		   (3-4)
		   (2-6)
		>>> ail.construct()
		>>> ail
		IntervalArray
		  range: (1-6)
		   (1-2)
		   (2-6)
		   (3-4)

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check if already constructed
		if self.is_constructed == False:
			self._construct(min_length)
			self.is_constructed = True
		else:
			pass


	cdef aiarray_t *_intersect(IntervalArray self, int start, int end):
		cdef aiarray_t *overlaps = aiarray_query(self.c_aiarray, start, end)

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
			overlaps : IntervalArray
				Overlapping intervals

		.. warning::
			This requires :func:`~IntervalArray.IntervalArray.construct` and will run it if not already run. This will re-sort intervals inplace.

		See Also
		--------
		IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect
		IntervalArray.add: Add interval to IntervalArray
		IntervalArray.intersect_from_array: Find interval indices overlapping given ranges

		Examples
		--------
		>>> from IntervalArray import IntervalArray
		>>> ail = IntervalArray()
		>>> ail.add(1, 2)
		>>> ail.add(3, 4)
		>>> ail.add(2, 6)
		>>> ail
		IntervalArray
		  range: (1-6)
		   (1-2)
		   (3-4)
		   (2-6)
		>>> q = ail.intersect(2, 10)
		>>> q
		IntervalArray
		  range: (2-6)
		   (2-6)
		   (3-4)

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check if is constructed
		if self.is_constructed == False:
			self.construct()

		# Intersect
		cdef aiarray_t *i_list = self._intersect(start, end)
		cdef IntervalArray overlaps = IntervalArray()
		overlaps.set_list(i_list)

		return overlaps


	@cython.boundscheck(False)
	@cython.wraparound(False)
	@cython.initializedcheck(False)
	cpdef _intersect_from_array(IntervalArray self, const long[::1] starts, const long[::1] ends):
		cdef int length = len(starts)
		cdef array_query_t *total_overlaps
		total_overlaps = aiarray_query_from_array(self.c_aiarray, &starts[0], &ends[0], length)

		cdef np.ndarray ref_index = pointer_to_numpy_array(total_overlaps.ref_index, total_overlaps.size)
		cdef np.ndarray query_index = pointer_to_numpy_array(total_overlaps.query_index, total_overlaps.size)

		return ref_index, query_index

	def intersect_from_array(self, const long[::1] starts, const long[::1] ends):
		"""
		Find interval indices overlapping given ranges
		
		Parameters
		----------
			starts : numpy.ndarray{long}
				Start positions of intervals
			ends : numpy.ndarray{long}
				End positions of intervals

		Returns
		-------
			ref_index : np.ndarray{int}
				Overlapping interval indices from IntervalArray
			query_index : np.ndarray{int}
				Overlapping interval indices from query IntervalArray

		.. warning::
			This requires :func:`~IntervalArray.IntervalArray.construct` and will run it if not already run. This will re-sort intervals inplace.

		See Also
		--------
		IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect
		IntervalArray.add: Add interval to IntervalArray
		IntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from IntervalArray import IntervalArray
		>>> ail1 = IntervalArray()
		>>> ail1.add(1, 2)
		>>> ail1.add(3, 4)
		>>> ail1.add(2, 6)
		>>> ail1
		IntervalArray
		  range: (1-6)
		   (1-2)
		   (3-4)
		   (2-6)
		>>> ail2 = IntervalArray()
		>>> ail2.add(1, 2)
		>>> ail2.add(3, 6)
		>>> ail2
		IntervalArray
		  range: (1-6)
		    (1-2)
		    (3-6)
		>>> q = ail1.intersect_from_array(ail2)
		>>> q
		(array([2, 1]), array([]))

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check if object is constructed
		if self.is_constructed == False:
			self.construct()

		# Call C function
		ref_index, query_index = self._intersect_from_array(starts, ends)
		
		return ref_index, query_index


	cpdef _intersect_from_aiarray(IntervalArray self, IntervalArray ail):
		# Intersect with other IntervalArray
		cdef array_query_t *total_overlaps = aiarray_query_from_aiarray(self.c_aiarray, ail.c_aiarray)

		# Create numpy array from C pointer
		cdef np.ndarray ref_index = pointer_to_numpy_array(total_overlaps.ref_index, total_overlaps.size)
		cdef np.ndarray query_index = pointer_to_numpy_array(total_overlaps.query_index, total_overlaps.size)

		return ref_index, query_index

	def intersect_from_IntervalArray(self, IntervalArray ail_query):
		"""
		Find interval indices overlapping given ranges
		
		Parameters
		----------
			ail_query : IntervalArray
				Intervals to query

		Returns
		-------
			ref_index : np.ndarray{int}
				Overlapping interval indices from IntervalArray
			query_index : np.ndarray{int}
				Overlapping interval indices from query IntervalArray

		See Also
		--------
		IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect
		IntervalArray.add: Add interval to IntervalArray
		IntervalArray.intersect: Find intervals overlapping given range
		IntervalArray.intersect_from_array: Find interval indices overlapping given range

		Examples
		--------
		>>> from IntervalArray import IntervalArray
		>>> ail1 = IntervalArray()
		>>> ail1.add(1, 2)
		>>> ail1.add(3, 4)
		>>> ail1.add(2, 6)
		>>> ail1
		IntervalArray
		  range: (1-6)
		   (1-2, 0)
		   (3-4, 1)
		   (2-6, 2)
		>>> ail2 = IntervalArray()
		>>> ail2.add(1, 2)
		>>> ail2.add(3, 6)
		>>> ail2
		IntervalArray
		  range: (1-6)
		    (1-2, 0)
		    (3-6, 1)
		>>> q = ail1.intersect_from_IntervalArray(ail2)
		>>> q
		(array([0, 1, 1]), array([0, 2, 1]))

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check if object is constructed
		if self.is_constructed == False:
			self.construct()

		# Intersect
		ref_index, query_index = self._intersect_from_aiarray(ail_query)
		
		return ref_index, query_index


	cpdef _intersect_with_index(IntervalArray self, int start, int end):
		# Intersect with other IntervalArray
		cdef overlap_index_t *total_overlaps = aiarray_query_with_index(self.c_aiarray, start, end)

		# Create numpy array from C pointer
		cdef np.ndarray indices = pointer_to_numpy_array(total_overlaps.indices, total_overlaps.size)
		cdef IntervalArray overlaps = IntervalArray()
		overlaps.set_list(total_overlaps.ail)

		return overlaps, indices
	
	def intersect_with_index(self, int start, int end):
		"""
		Find interval indices overlapping given ranges
		
		Parameters
		----------
			ail_query : IntervalArray
				Intervals to query

		Returns
		-------
			ref_index : np.ndarray{int}
				Overlapping interval indices from IntervalArray
			query_index : np.ndarray{int}
				Overlapping interval indices from query IntervalArray

		See Also
		--------
		IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect
		IntervalArray.add: Add interval to IntervalArray
		IntervalArray.intersect: Find intervals overlapping given range
		IntervalArray.intersect_from_array: Find interval indices overlapping given range

		Examples
		--------
		>>> from IntervalArray import IntervalArray
		>>> ail1 = IntervalArray()
		>>> ail1.add(1, 2)
		>>> ail1.add(3, 4)
		>>> ail1.add(2, 6)
		>>> ail1
		IntervalArray
		  range: (1-6)
		   (1-2)
		   (3-4)
		   (2-6)
		>>> ail2 = IntervalArray()
		>>> ail2.add(1, 2)
		>>> ail2.add(3, 6)
		>>> ail2
		IntervalArray
		  range: (1-6)
		    (1-2)
		    (3-6)
		>>> q = ail1.intersect_from_IntervalArray(ail2)
		>>> q
		(array([0, 1, 1]), array([0, 2, 1]))

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check if object is constructed
		if self.is_constructed == False:
			self.construct()

		# Intersect
		cdef IntervalArray overlaps
		cdef np.ndarray indices
		overlaps, indices = self._intersect_with_index(start, end)
		
		return overlaps, indices
		

	cdef np.ndarray _coverage(IntervalArray self):
		# Initialize coverage
		cdef double[::1] coverage = np.zeros(self.range, dtype=np.double)

		# Call C function
		aiarray_coverage(self.c_aiarray, &coverage[0])

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
			coverage : pandas.Series{double}
				Position on index and coverage as values

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Initialize coverage
		cdef np.ndarray coverage
		# Calculate coverage
		coverage = self._coverage()
		
		return pd.Series(coverage, index=np.arange(self.first, self.last))


	cdef np.ndarray _bin_coverage(IntervalArray self, int bin_size):
		# Initialize coverage
		cdef int n_bins = math.ceil(self.last / bin_size) - (self.first // bin_size)
		cdef double[::1] bins = np.zeros(n_bins, dtype=np.double)

		# Call C function
		aiarray_bin_coverage(self.c_aiarray, &bins[0], bin_size)

		return np.asarray(bins)

	cdef np.ndarray _bin_coverage_length(IntervalArray self, int bin_size, int min_length, int max_length):
		# Initialize coverage
		cdef int n_bins = math.ceil(self.last / bin_size) - (self.first // bin_size)
		cdef double[::1] bins = np.zeros(n_bins, dtype=np.double)

		# Call C function
		aiarray_bin_coverage_length(self.c_aiarray, &bins[0], bin_size, min_length, max_length)

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
			bins : pandas.Series{double}
				Position on index and coverage as values

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Initialize coverage
		cdef np.ndarray bins
		# Calculate coverage
		if min_length is None or max_length is None:
			bins = self._bin_coverage(bin_size)
		else:
			bins = self._bin_coverage_length(bin_size, min_length, max_length)
		
		return pd.Series(bins, index=(np.arange(len(bins)) + int(self.first / bin_size)) * bin_size)


	cdef np.ndarray _bin_nhits(IntervalArray self, int bin_size):
		# Initialize coverage
		cdef int n_bins = math.ceil(self.last / bin_size) - (self.first // bin_size)
		cdef double[::1] bins = np.zeros(n_bins, dtype=np.double)
		
		# Call C function
		aiarray_bin_nhits(self.c_aiarray, &bins[0], bin_size)

		return np.asarray(bins)

	cdef np.ndarray _bin_nhits_length(IntervalArray self, int bin_size, int min_length, int max_length):
		# Initialize coverage
		cdef int n_bins = math.ceil(self.last / bin_size) - (self.first // bin_size)
		cdef double[::1] bins = np.zeros(n_bins, dtype=np.double)

		# Call C function
		aiarray_bin_nhits_length(self.c_aiarray, &bins[0], bin_size, min_length, max_length)

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
			bins : pandas.Series{double}
				Position on index and coverage as values

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

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
			raise NameError("IntervalArray object has been closed.")

		# Call C function
		display_array(self.c_aiarray)


	def merge(self, int gap=0):
		"""
		Merge intervals within a gap
		
		Parameters
		----------
			gap : int
				Gap between intervals to merge

		Returns
		-------
			merged_list : IntervalArray
				Merged intervals

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Make sure list is constructed
		if self.is_constructed == False:
			self.construct()

		# Create merged
		cdef IntervalArray merged_list = IntervalArray()
		# Call C function
		cdef aiarray_t *merged_clist = aiarray_merge(self.c_aiarray, gap)
		merged_list.set_list(merged_clist)

		return merged_list


	def subtract(self, IntervalArray query_ail):
		"""
		Subtract intervals within another IntervalArray
		
		Parameters
		----------
			query_ail : IntervalArray
				IntervalArray of intervals to subtract

		Returns
		-------
			subtracted_list : IntervalArray
				Subtracted intervals
		"""

		# Check if object is still open
		if self.is_closed or query_ail.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Make sure list is constructed
		if self.is_constructed == False:
			self.construct()
		if query_ail.is_constructed == False:
			query_ail.construct()

		# Create subracted
		cdef IntervalArray subtracted_list = IntervalArray()
		cdef aiarray_t *subtracted_clist = aiarray_subtract(query_ail.c_aiarray,
														  self.c_aiarray)
		subtracted_list.set_list(subtracted_clist)

		return subtracted_list


	def common(self, IntervalArray query_ail):
		"""
		Common intervals within another IntervalArray
		
		Parameters
		----------
			query_ail : IntervalArray
				IntervalArray of intervals to find commons

		Returns
		-------
			common_list : IntervalArray
				Common intervals

		"""

		# Check if object is still open
		if self.is_closed or query_ail.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Make sure list is constructed
		if self.is_constructed == False:
			self.construct()
		if query_ail.is_constructed == False:
			query_ail.construct()

		# Create common
		cdef IntervalArray common_list = IntervalArray()
		cdef aiarray_t *common_clist = aiarray_common(query_ail.c_aiarray,
													self.c_aiarray)
		common_list.set_list(common_clist)

		return common_list


	def append(self, IntervalArray query_ail):
		"""
		Union of intervals within two IntervalArray
		
		Parameters
		----------
			query_ail : IntervalArray
				IntervalArray of intervals to append

		Returns
		-------
			union_list: IntervalArray
				Union of intervals

		"""

		# Check if object is still open
		if self.is_closed or query_ail.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Create union
		cdef IntervalArray union_list = IntervalArray()
		cdef aiarray_t *union_clist = aiarray_append(query_ail.c_aiarray,
												   self.c_aiarray)
		union_list.set_list(union_clist)

		return union_list


	cdef np.ndarray _wps(IntervalArray self, int protection):
		# Initialize wps
		cdef double[::1] wps = np.zeros(self.range, dtype=np.double)

		aiarray_wps(self.c_aiarray, &wps[0], protection)

		return np.asarray(wps)

	cdef np.ndarray _wps_length(IntervalArray self, int protection, int min_length, int max_length):
		# Initialize wps
		cdef double[::1] wps = np.zeros(self.range, dtype=np.double)

		aiarray_wps_length(self.c_aiarray, &wps[0], protection, min_length, max_length)

		return np.asarray(wps)

	def wps(self, int protection=60, min_length=None, max_length=None):
		"""
		Calculate Window Protection Score
		for each position in IntervalArray range
		
		Parameters
		----------
			protection : int
				Protection window to use
			min_length : int
				Minimum length of intervals to include [default = None]
			max_length : int
				Maximum length of intervals to include [default = None]

		Returns
		-------
			wps : pandas.Series{double}
				Position on index and WPS as values

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")
		
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
		
		Parameters
		----------
			min_length : int
				Minimum length to keep
			max_length : int
				Maximum langth to keep

		Returns
		-------
			filtered_ail : IntervalArray
				Filtered intervals

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Initialize filtered list
		cdef IntervalArray filtered_ail = IntervalArray()

		cdef aiarray_t *cfiltered_ail = aiarray_length_filter(self.c_aiarray, min_length, max_length)
		filtered_ail.set_list(cfiltered_ail)

		return filtered_ail


	cdef np.ndarray _length_dist(IntervalArray self):
		# Initialize distribution
		cdef int max_length = aiarray_max_length(self.c_aiarray)
		cdef int[::1] distribution = np.zeros(max_length + 1, dtype=np.intc)

		# Calculate distribution
		aiarray_length_distribution(self.c_aiarray, &distribution[0])

		return np.asarray(distribution, dtype=np.intc)

	def length_dist(self):
		"""
		Calculate length distribution of intervals

		Parameters
		----------
			None
		
		Returns
		-------
			distribution : numpy.ndarray{int}
				Interval length distribution

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Initialize distribution
		cdef np.ndarray distribution
		# Calculate distribution
		distribution = self._length_dist()

		return distribution


	cdef np.ndarray _nhits_from_array(IntervalArray self, const long[::1] starts, const long[::1] ends):
		# Initialize hits
		cdef int length = starts.size
		cdef int[::1] nhits = np.zeros(length, dtype=np.intc)

		# Calculate distribution
		aiarray_nhits_from_array(self.c_aiarray, &starts[0], &ends[0], length, &nhits[0])

		return np.asarray(nhits, dtype=np.intc)

	cdef np.ndarray _nhits_from_array_length(IntervalArray self, const long[::1] starts, const long[::1] ends, int min_length, int max_length):
		# Initialize hits
		cdef int length = starts.size
		cdef int[::1] nhits = np.zeros(length, dtype=np.intc)

		# Calculate distribution
		aiarray_nhits_from_array_length(self.c_aiarray, &starts[0], &ends[0], length, &nhits[0], min_length, max_length)

		return np.asarray(nhits, dtype=np.intc)

	def nhits_from_array(self, const long[::1] starts, const long[::1] ends, min_length=None, max_length=None):
		"""
		Find number of intervals overlapping given
		positions
		
		Parameters
		----------
			starts : numpy.ndarray{long}
				Start positions to intersect
			ends : numpy.ndarray{long}
				End positions to intersect
			min_length : int
				Minimum length of intervals to include [default = None]
			max_length : int
				Maximum length of intervals to include [default = None]

		Returns
		-------
			nhits : numpy.ndarray{int}
				Number of hits per position

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

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


	cdef np.ndarray _interval_coverage(IntervalArray self, int start, int end):
		# Initialize hits
		cdef int[::1] coverage = np.zeros(end - start, dtype=np.intc)

		# Calculate distribution
		aiarray_interval_coverage(self.c_aiarray, start, end, &coverage[0])

		return np.asarray(coverage, dtype=np.intc)
	
	def interval_coverage(self, int start, int end):
		"""
		Find number of intervals overlapping each
		position in given interval
		
		Parameters
		----------
			start : int
				Start position to intersect
			end : int
				End position to intersect

		Returns
		-------
			coverage : pandas.Series{int}
				Number of hits per position

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

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
		Randomly downsample IntervalArray
		
		Parameters
		----------
			proportion : double
				Proportion of intervals to keep

		Returns
		-------
			filtered_ail : IntervalArray
				Downsampled IntervalArray

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Initialize filtered list
		cdef IntervalArray filtered_ail = IntervalArray()

		cdef aiarray_t *cfiltered_ail = aiarray_downsample(self.c_aiarray, proportion)
		filtered_ail.set_list(cfiltered_ail)

		return filtered_ail

	
	cpdef _downsample_with_index(IntervalArray self, double proportion):
		# Randomly downsample IntervalArray
		cdef overlap_index_t *new_intervals = aiarray_downsample_with_index(self.c_aiarray, proportion)

		# Create numpy array from C pointer
		cdef np.ndarray indices = pointer_to_numpy_array(new_intervals.indices, new_intervals.size)
		cdef IntervalArray intervals = IntervalArray()
		intervals.set_list(new_intervals.ail)

		return intervals, indices
	
	def downsample_with_index(self, double proportion):
		"""
		Find interval indices overlapping given ranges
		
		Parameters
		----------
			ail_query : IntervalArray
				Intervals to query

		Returns
		-------
			ref_index : np.ndarray{int}
				Overlapping interval indices from IntervalArray
			query_index : np.ndarray{int}
				Overlapping interval indices from query IntervalArray

		See Also
		--------
		IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect
		IntervalArray.add: Add interval to IntervalArray
		IntervalArray.intersect: Find intervals overlapping given range
		IntervalArray.intersect_from_array: Find interval indices overlapping given range

		Examples
		--------
		>>> from IntervalArray import IntervalArray
		>>> ail1 = IntervalArray()
		>>> ail1.add(1, 2)
		>>> ail1.add(3, 4)
		>>> ail1.add(2, 6)
		>>> ail1
		IntervalArray
		  range: (1-6)
		   (1-2)
		   (3-4)
		   (2-6)
		>>> ail2 = IntervalArray()
		>>> ail2.add(1, 2)
		>>> ail2.add(3, 6)
		>>> ail2
		IntervalArray
		  range: (1-6)
		    (1-2)
		    (3-6)
		>>> q = ail1.intersect_from_IntervalArray(ail2)
		>>> q
		(array([0, 1, 1]), array([0, 2, 1]))

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check if object is constructed
		if self.is_constructed == False:
			self.construct()

		# Intersect
		cdef IntervalArray intervals
		cdef np.ndarray indices
		intervals, indices = self._downsamples_with_index(proportion)
		
		return intervals, indices


	def index_by_IntervalArray(self, IntervalArray ail, inplace=False):
		"""
		Use IntervalArray as an index to adjust values given other IntervalArray

		Parameters
		----------
			ail : IntervalArray
				Intervals to index
			inplace : bool
				Whether to due inplace (If done wrong, can lead to corrupted data!)
		
		Returns
		-------
			indexed_ail : IntervalArray
				Re-indexed intervals

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("IntervalArray object has been closed.")

		# Check if frozen
		if inplace and self.is_frozen:
			raise TypeError("IntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.")

		# Index
		cdef IntervalArray indexed_ail = IntervalArray()
		cdef aiarray_t *cindexed_ail
		cdef exit_code
		if inplace:
			exit_code = aiarray_index_by_aiarray_inplace(self.c_aiarray, ail.c_aiarray)
			# Check if it ran correctly
			if exit_code == 1:
				raise LookupError("Index out of bounds. DATA IS LIKELY CURRUPTED NOW!")
		else:
			cindexed_ail = aiarray_index_by_aiarray(self.c_aiarray, ail.c_aiarray)
			indexed_ail.set_list(cindexed_ail)
			# Check if it ran correctly
			if indexed_ail.size != self.size:
				raise LookupError("Index out of bounds.")

			return indexed_ail


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
			raise NameError("IntervalArray object has been closed.")

		# Extract start values
		cdef long[::1] starts = np.zeros(self.size, dtype=np.int_)
		aiarray_extract_starts(self.c_aiarray, &starts[0])

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
			raise NameError("IntervalArray object has been closed.")

		# Extract end values
		cdef long[::1] ends = np.zeros(self.size, dtype=np.int_)
		aiarray_extract_ends(self.c_aiarray, &ends[0])

		return np.asarray(ends, dtype=np.intc)

	
	def close(self):
		"""
		Close object and clear memory
		"""

		# Free interval_list memory
		if self.c_aiarray:
			aiarray_destroy(self.c_aiarray)
		self.c_aiarray = NULL
		
		self.is_closed = True