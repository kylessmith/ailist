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
from .Interval_core import Interval
np.import_array()

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


cpdef AIList rebuild_AIList(bytes data, bytes b_length):
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

		self.c_ailist = ailist_init()
		self.is_constructed = False
		self.is_closed = False
		self.is_frozen = False


	def __init__(self):
		"""
		Initialize AIList object

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
		Free AIList.c_ailist
		"""

		ailist_destroy(self.c_ailist)


	cdef bytes _get_data(self):
		"""
		Function to convert ailist_t to bytes
		for serialization by __reduce__()
		"""

		return <bytes>(<char*>self.c_ailist.interval_list)[:(sizeof(interval_t)*self.c_ailist.nr)]


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
		-------
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
			ailist_add(ail, interval_list[i].start, interval_list[i].end,
						interval_list[i].id_value)

		return ail


	def __reduce__(self):
		"""
		Used for pickling. Convert ailist to bytes and back.
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Convert ints to bytes
		b_length = int(self.c_ailist.nr).to_bytes(4, byteorder)

		# Convert ailist_t to bytes
		data = self._get_data()

		return (rebuild_AIList, (data, b_length))


	@property
	def nc(self):
		"""
		Number of components in constructed AIList
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if object is constructed
		if self.is_constructed:
			return self.c_ailist.nc
		else:
			return None


	@property
	def lenC(self):
		"""
		Length of components in constructed AIList
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if object is constructed
		if self.is_constructed:
			lenC = np.zeros(self.c_ailist.nc, dtype=np.intc)
			for i in range(self.c_ailist.nc):
				lenC[i] = self.c_ailist.lenC[i]
			return lenC
		else:
			return None


	@property
	def idxC(self):
		"""
		Index of components in constructed AIList
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if object is constructed
		if self.is_constructed:
			idxC = np.zeros(self.c_ailist.nc, dtype=np.intc)
			for i in range(self.c_ailist.nc):
				idxC[i] = self.c_ailist.idxC[i]
			return idxC
		else:
			return None


	@property
	def size(self):
		"""
		Number of intervals in AIList
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		return self.c_ailist.nr

	@property
	def first(self):
		"""
		Start of first interval in AIList
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if there are any intervals
		if self.size == 0:
			return None
		else:
			return self.c_ailist.first

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
			return self.c_ailist.last

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
		cdef int i
		for i in range(self.size):
			interval = Interval(self.c_ailist.interval_list[i].start,
								self.c_ailist.interval_list[i].end)

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


	cdef ailist_t *_array_id(AIList self, const long[::1] ids):
		cdef int length = len(ids)
		cdef ailist_t *cindexed_ailist

		# Call C function
		cindexed_ailist = ailist_get_id_array(self.c_ailist, &ids[0], length)

		return cindexed_ailist

	cdef ailist_t *_interval_id(AIList self, int id_value):
		cdef ailist_t *cindexed_ailist

		# Call C function
		cindexed_ailist = ailist_get_id(self.c_ailist, id_value)

		return cindexed_ailist

	def __getitem__(self, key):
		"""
		Index Intervals by id_value
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize variables
		cdef AIList indexed_ailist
		cdef ailist_t *cindexed_ailist
		cdef interval_t cinterval

		# Initialize results
		indexed_ailist = AIList()

		# Check if key is iterable
		try:
			# Test if iterable
			iter(key)

			# Check if keys are booleans
			if isinstance(key[0], np.bool_):
				raise IndexError("Cannot use boolean array as key")

			# Must be integers
			else:
				cindexed_ailist = self._array_id(key)

		# key is not iterable, treat as int
		except TypeError:
			# Check if key is slice
			if isinstance(key, slice):
				raise IndexError("Cannot use slice as key")

			# Must be integer
			# Check if key is greater than length
			if key >= self.c_ailist.nr:
				raise IndexError("Value larger than AIList length")

			# Check if negative
			if key < 0:
				key = self.c_ailist.nr + key

			cinterval = self.c_ailist.interval_list[key]
			interval = Interval(cinterval.start, cinterval.end)

			return interval

		# Wrap c object
		indexed_ailist.set_list(cindexed_ailist)

		return indexed_ailist


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
		if self.c_ailist.nr > 10:
			for i in range(5):
				repr_string += "   (%d-%d)\n" % (self[i].start, self[i].end)
			repr_string += "   ...\n"
			for i in range(-5, 0, 1):
				repr_string += "   (%d-%d)\n" % (self[i].start, self[i].end)
		else:
			for i in range(self.c_ailist.nr):
				repr_string += "   (%d-%d)\n" % (self[i].start, self[i].end)

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

		ailist_destroy(self.c_ailist)

		# Replace new skiplist
		self.c_ailist = input_list
		self.is_closed = False


	@property
	def ids(self):
		"""
		Return the ID values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Extract id_values
		cdef long[::1] ids = np.zeros(self.size, dtype=np.int_)
		ailist_extract_ids(self.c_ailist, &ids[0])

		return np.asarray(ids, dtype=np.intc)


	@property
	def starts(self):
		"""
		Return the start values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Extract start values
		cdef long[::1] starts = np.zeros(self.size, dtype=np.int_)
		ailist_extract_starts(self.c_ailist, &starts[0])

		return np.asarray(starts, dtype=np.intc)


	@property
	def ends(self):
		"""
		Return the end values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Extract end values
		cdef long[::1] ends = np.zeros(self.size, dtype=np.int_)
		ailist_extract_ends(self.c_ailist, &ends[0])

		return np.asarray(ends, dtype=np.intc)


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
		   (1-2, 0)
		   (3-4, 1)
		   (3-6, 2)
		>>> ail.freeze()
		>>> ail.add(9, 10)
		TypeError: AIList is frozen and currently immutatable. Try '.unfreeze()' to reverse.

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Make sure it is constructed
		if self.is_constructed is False:
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
		   (1-2, 0)
		   (3-4, 1)
		   (3-6, 2)
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


	cdef void _insert(AIList self, int start, int end, int id_value):
		ailist_add(self.c_ailist, start, end, id_value)

	def add(self, start, end, id_value=None):
		"""
		Add an interval to AIList inplace

		Parameters
		----------
			start : int
				Start position of interval
			end : int
				End position of interval
			id_value : double
				ID of interval [default = None]

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
		   (1-2)
		   (3-4)
		   (3-6)
		>>> import numpy as np
		>>> starts = np.arange(100)
		>>> ends = starts + 10
		>>> index = np.arange(len(starts))
		>>> ail = AIList()
		>>> ail.add(starts, ends, index)
		>>> ail
		AIList
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
			(99-109)


		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check that object is not frozen
		if self.is_frozen:
			raise TypeError("AIList is frozen and currently immutatable. Try '.unfreeze()' to reverse.")

		# Check if start is int
		cdef int array_length
		cdef const long[::1] starts
		cdef const long[::1] ends
		cdef const long[::1] ids
		if isinstance(start, int):
			# Check interval
			if start > end:
				raise IndexError("Start is greater than end.")

			# Insert interval
			if id_value is None:
				self._insert(start, end, self.c_ailist.nr)
			else:
				self._insert(start, end, id_value)

		elif isinstance(start, np.ndarray):
			array_length = len(start)
			starts = start
			ends = end
			ids = id_value
			ailist_from_array(self.c_ailist, &starts[0], &ends[0], &ids[0], array_length)

		else:
			raise TypeError("Start must be int or np.ndarray.")

		# Object is no longer constructed
		self.is_constructed = False

	@staticmethod
	def from_array(const long[::1] starts, const long[::1] ends, const long[::1] ids):
		"""
		Add intervals from arrays to AIList inplace

		Parameters
		----------
			starts : ~numpy.ndarray{long}
				Start positions of intervals
			ends : numpy.ndarray{long}
				End positions of intervals
			ids : numpy.ndarray{long}
				ID of intervals

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
		>>> ail = AIList.from_array(starts, ends, index)
		>>> ail
		AIList
		  range: (0-109)
		   (0-10, 0)
		   (1-11, 1)
		   (2-12, 2)
		   (3-13, 3)
		   (4-14, 4)
		   ...
		   (95-105, 95)
		   (96-106, 96)
		   (97-107, 97)
		   (98-108, 98)

		"""

		ail = AIList()
		cdef int array_length = len(starts)
		ailist_from_array(ail.c_ailist, &starts[0], &ends[0], &ids[0], array_length)

		return ail


	cdef void _construct(AIList self, int min_length):
		# Contruct
		ailist_construct(self.c_ailist, min_length)
		#ailist_construct_v0(self.c_ailist, min_length)

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
		   (1-2, 0)
		   (3-4, 1)
		   (2-6, 2)
		>>> ail.construct()
		>>> ail
		AIList
		  range: (1-6)
		   (1-2, 0)
		   (2-6, 2)
		   (3-4, 1)

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if already constructed
		if self.is_constructed is False:
			self._construct(min_length)
			self.is_constructed = True
		else:
			pass


	def iter_sorted(self):
		"""
		Iterate over an AIList in sorted way

		Parameters
		----------
			None

		Returns
		-------
			sorted_iter : Generator
				Generator of Intervals
		"""

		# Check if is constructed
		if self.is_constructed is False:
			self.construct()

		# Iterate over  ail
		cdef interval_t *cintv
		#cdef Interval output_interval

		# Create sorted iterators
		cdef ailist_sorted_iter_t *ail_iter = ailist_sorted_iter_init(self.c_ailist)
		while ailist_sorted_iter_next(ail_iter) != 0:
			cintv = ail_iter.intv
			# Create Interval wrapper
			output_interval = Interval(cintv.start, cintv.end)
			#output_interval.set_i(cintv)
			yield output_interval

		ailist_sorted_iter_destroy(ail_iter)


	cdef ailist_t *_intersect(AIList self, int start, int end):
		cdef ailist_t *overlaps = ailist_init()
		ailist_query(self.c_ailist, overlaps, start, end)

		return overlaps

	cdef ailist_t *_intersect_from_array(AIList self,
										 const long[::1] starts,
										 const long[::1] ends):
		cdef int length = starts.size
		cdef ailist_t *overlaps = ailist_init()
		ailist_query_from_array(self.c_ailist, overlaps, &starts[0], &ends[0], length)

		return overlaps

	def intersect(self, start, end):
		"""
		Find intervals overlapping given range

		Parameters
		----------
			start : int | np.ndarray{int}
				Start position of query range
			end : int | np.ndarray{int}
				End position of query range

		Returns
		-------
			overlaps : AIList
				Overlapping intervals

		.. warning::
			This requires :func:`~ailist.AIList.construct` and will run it if not already run.
			This will re-sort intervals inplace.

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
		   (1-2, 0)
		   (3-4, 1)
		   (2-6, 2)
		>>> q = ail.intersect(2, 10)
		>>> q
		AIList
		  range: (2-6)
		   (2-6, 2)
		   (3-4, 1)

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if is constructed
		if self.is_constructed is False:
			self.construct()

		# Intersect
		cdef const long[::1] starts
		cdef const long[::1] ends
		cdef ailist_t *i_list
		cdef AIList overlaps = AIList()
		if isinstance(start, int):
			i_list = self._intersect(start, end)
			overlaps.set_list(i_list)
		elif isinstance(start, np.ndarray):
			starts = start
			ends = end
			i_list = self._intersect_from_array(starts, ends)
			overlaps.set_list(i_list)
		else:
			raise TypeError("Start must be int or np.ndarray.")

		return overlaps


	cdef np.ndarray _intersect_ids(AIList self, int start, int end):
		cdef ailist_t *overlaps = ailist_init()
		ailist_query(self.c_ailist, overlaps, start, end)
		cdef long[::1] ids = np.zeros(overlaps.nr, dtype=np.long)

		# Extract IDs
		ailist_extract_ids(overlaps, &ids[0])

		return np.asarray(ids)

	@cython.boundscheck(False)
	@cython.wraparound(False)
	@cython.initializedcheck(False)
	cpdef _intersect_ids_from_array(AIList self, const long[::1] starts, const long[::1] ends,
									const long[::1] ids):
		cdef int length = len(starts)
		cdef array_query_t *total_overlaps = array_query_init()
		ailist_query_id_from_array(self.c_ailist, total_overlaps, &starts[0],
									&ends[0], &ids[0], length)

		cdef np.ndarray ref_index = pointer_to_numpy_array(total_overlaps.ref_index,
														   total_overlaps.size)
		cdef np.ndarray query_index = pointer_to_numpy_array(total_overlaps.query_index,
															 total_overlaps.size)

		return ref_index, query_index

	def intersect_ids(self, start, end):
		"""
		Find interval indices overlapping given range

		Parameters
		----------
			start : int | np.ndarray{int}
				Start position of query range
			end : int | np.ndarray{int}
				End position of query range

		Returns
		-------
			ids : numpy.ndarray{int}
				Overlapping interval indices

		.. warning::
			This requires :func:`~ailist.AIList.construct` and will run it if not already run.
			This will re-sort intervals inplace.

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
		   (1-2, 0)
		   (3-4, 1)
		   (2-6, 2)
		>>> q = ail.intersect_index(2, 10)
		>>> q
		array([2, 1])

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if object has been constructed
		if self.is_constructed is False:
			self.construct()

		# Intersect
		cdef const long[::1] starts
		cdef const long[::1] ends
		cdef np.ndarray ref_ids
		cdef np.ndarray query_ids
		if isinstance(start, int):
			ref_ids = self._intersect_ids(start, end)
			return ref_ids

		elif isinstance(start, np.ndarray):
			starts = start
			ends = end
			ids = np.arange(len(starts), dtype=np.long)
			ref_ids, query_ids = self._intersect_ids_from_array(starts, ends, ids)
			return ref_ids, query_ids

		else:
			raise TypeError("Start must be int or np.ndarray.")


	cdef ailist_t *_intersect_from_ailist(AIList self, AIList ail):
		# Intersect with other AIList
		cdef ailist_t *overlaps = ailist_init()
		ailist_query_from_ailist(self.c_ailist, ail.c_ailist, overlaps)

		return overlaps

	def intersect_from_ailist(self, AIList ail_query):
		"""
		Find interval indices overlapping given ranges

		Parameters
		----------
			ail_query : AIList
				Intervals to query

		Returns
		-------
			ail : AIList
				Overlapping intervals

		.. warning::
			This requires :func:`~ailist.AIList.construct` and will run it if not already run.
			This will re-sort intervals inplace.

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
		   (1-2, 0)
		   (3-4, 1)
		   (2-6, 2)
		>>> ail2 = AIList()
		>>> ail2.add(1, 2)
		>>> ail2.add(3, 6)
		>>> ail2
		AIList
		  range: (1-6)
		    (1-2, 0)
		    (3-6, 1)
		>>> q = ail1.intersect_from_ailist(ail2)
		>>> q
		(array([0, 1, 1]), array([0, 2, 1]))

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check if object is constructed
		if self.is_constructed is False:
			self.construct()

		# Intersect
		cdef ailist_t *c_ailist = self._intersect_from_ailist(ail_query)
		cdef AIList ail = AIList()
		ail.set_list(c_ailist)

		return ail


	cdef np.ndarray _coverage(AIList self):
		# Initialize coverage
		cdef double[::1] coverage = np.zeros(self.range, dtype=np.double)

		# Call C function
		ailist_coverage(self.c_ailist, &coverage[0])

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

		# Call C function
		ailist_bin_coverage(self.c_ailist, &bins[0], bin_size)

		return np.asarray(bins)

	cdef np.ndarray _bin_coverage_length(AIList self, int bin_size, int min_length,
										 int max_length):
		# Initialize coverage
		cdef int n_bins = math.ceil(self.last / bin_size) - (self.first // bin_size)
		cdef double[::1] bins = np.zeros(n_bins, dtype=np.double)

		# Call C function
		ailist_bin_coverage_length(self.c_ailist, &bins[0], bin_size, min_length, max_length)

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
		cdef long[::1] bins = np.zeros(n_bins, dtype=np.double)

		# Call C function
		ailist_bin_nhits(self.c_ailist, &bins[0], bin_size)

		return np.asarray(bins)

	cdef np.ndarray _bin_nhits_length(AIList self, int bin_size, int min_length, int max_length):
		# Initialize coverage
		cdef int n_bins = math.ceil(self.last / bin_size) - (self.first // bin_size)
		cdef long[::1] bins = np.zeros(n_bins, dtype=np.double)

		# Call C function
		ailist_bin_nhits_length(self.c_ailist, &bins[0], bin_size, min_length, max_length)

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
			raise NameError("AIList object has been closed.")

		# Initialize coverage
		cdef np.ndarray bins

		# Calculate coverage
		if min_length is None or max_length is None:
			bins = self._bin_nhits(bin_size)
		else:
			bins = self._bin_nhits_length(bin_size, min_length, max_length)

		return pd.Series(bins, index=(np.arange(len(bins)) + int(self.first / bin_size)) * bin_size)


	cdef void _nhits(AIList self, long *nhits, int start, int end):

		# Call C function
		ailist_query_nhits(self.c_ailist, nhits, start, end)

		return

	cdef void _nhits_length(AIList self, long *nhits, int start, int end, int min_length,
							int max_length):

		# Call C function
		ailist_query_nhits_length(self.c_ailist, nhits, start, end, min_length, max_length)

		return

	def nhits(self, start, end, min_length=None, max_length=None):
		"""
		Find number of intervals overlapping binned
		positions

		Parameters
		----------
			min_length : int
				Minimum length of intervals to include [default = None]
			max_length : int
				Maximum length of intervals to include [default = None]

		Returns
		-------
			nhits : int
				Number of overlaps

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize nhits
		cdef long nhits = 0

		# Calculate coverage
		if min_length is None or max_length is None:
			bins = self._nhits(&nhits, start, end)
		else:
			bins = self._nhits_length(&nhits, start, end, min_length, max_length)

		return nhits


	def display(self):
		"""
		Print all intervals
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		display_list(self.c_ailist)


	def merge(self, int gap=0):
		"""
		Merge intervals within a gap

		Parameters
		----------
			gap : int
				Gap between intervals to merge

		Returns
		-------
			merged_list : AIList
				Merged intervals

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Make sure list is constructed
		if self.is_constructed is False:
			self.construct()

		# Create merged
		cdef AIList merged_list = AIList()

		# Call C function
		cdef ailist_t *merged_clist = ailist_merge(self.c_ailist, gap)
		merged_list.set_list(merged_clist)

		return merged_list


	def subtract(self, AIList query_ail):
		"""
		Subtract intervals within another AIList

		Parameters
		----------
			query_ail : AIList
				AIList of intervals to subtract

		Returns
		-------
			subtracted_list : AIList
				Subtracted intervals
		"""

		# Check if object is still open
		if self.is_closed or query_ail.is_closed:
			raise NameError("AIList object has been closed.")

		# Make sure list is constructed
		if self.is_constructed is False:
			self.construct()
		if query_ail.is_constructed is False:
			query_ail.construct()

		# Create subracted
		cdef AIList subtracted_list = AIList()

		# Call Cfunction
		cdef ailist_t *subtracted_clist = ailist_subtract(self.c_ailist,
														  query_ail.c_ailist)
		subtracted_list.set_list(subtracted_clist)

		return subtracted_list


	def common(self, AIList query_ail):
		"""
		Common intervals within another AIList

		Parameters
		----------
			query_ail : AIList
				AIList of intervals to find commons

		Returns
		-------
			common_list : AIList
				Common intervals

		"""

		# Check if object is still open
		if self.is_closed or query_ail.is_closed:
			raise NameError("AIList object has been closed.")

		# Make sure list is constructed
		if self.is_constructed is False:
			self.construct()
		if query_ail.is_constructed is False:
			query_ail.construct()

		# Create common
		cdef AIList common_list = AIList()
		cdef ailist_t *common_clist = ailist_common(self.c_ailist,
													query_ail.c_ailist)
		common_list.set_list(common_clist)

		return common_list


	def append(self, AIList query_ail):
		"""
		Union of intervals within two AIList

		Parameters
		----------
			query_ail : AIList
				AIList of intervals to append

		Returns
		-------
			union_list: AIList
				Union of intervals

		"""

		# Check if object is still open
		if self.is_closed or query_ail.is_closed:
			raise NameError("AIList object has been closed.")

		# Create union
		cdef AIList union_list = AIList()
		cdef ailist_t *union_clist = ailist_append(query_ail.c_ailist,
												   self.c_ailist)
		union_list.set_list(union_clist)

		return union_list


	cdef np.ndarray _wps(AIList self, int protection):
		# Initialize wps
		cdef double[::1] wps = np.zeros(self.range, dtype=np.double)

		ailist_wps(self.c_ailist, &wps[0], protection)

		return np.asarray(wps)

	cdef np.ndarray _wps_length(AIList self, int protection, int min_length, int max_length):
		# Initialize wps
		cdef double[::1] wps = np.zeros(self.range, dtype=np.double)

		ailist_wps_length(self.c_ailist, &wps[0], protection, min_length, max_length)

		return np.asarray(wps)

	def wps(self, int protection=60, min_length=None, max_length=None):
		"""
		Calculate Window Protection Score
		for each position in AIList range

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
			raise NameError("AIList object has been closed.")

		# Make sure list is constructed
		if self.is_constructed is False:
			self.construct()

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
			filtered_ail : AIList
				Filtered intervals

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize filtered list
		cdef AIList filtered_ail = AIList()

		# Call C function
		ailist_length_filter(self.c_ailist, filtered_ail.c_ailist, min_length, max_length)
		#filtered_ail.set_list(cfiltered_ail)

		return filtered_ail


	cdef np.ndarray _length_dist(AIList self):
		# Initialize distribution
		cdef int max_length = ailist_max_length(self.c_ailist)
		cdef int[::1] distribution = np.zeros(max_length + 1, dtype=np.intc)

		# Calculate distribution
		ailist_length_distribution(self.c_ailist, &distribution[0])

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
		ailist_nhits_from_array(self.c_ailist, &starts[0], &ends[0], length, &nhits[0])

		return np.asarray(nhits, dtype=np.intc)

	cdef np.ndarray _nhits_from_array_length(AIList self, const long[::1] starts,
											 const long[::1] ends, int min_length,
											 int max_length):
		# Initialize hits
		cdef int length = starts.size
		cdef int[::1] nhits = np.zeros(length, dtype=np.intc)

		# Calculate distribution
		ailist_nhits_from_array_length(self.c_ailist, &starts[0], &ends[0], length,
										&nhits[0], min_length, max_length)

		return np.asarray(nhits, dtype=np.intc)

	def nhits_from_array(self, const long[::1] starts, const long[::1] ends,
						 min_length=None, max_length=None):
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
			raise NameError("AIList object has been closed.")

		# Make sure list is constructed
		if self.is_constructed is False:
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
		ailist_interval_coverage(self.c_ailist, start, end, &coverage[0])

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
			raise NameError("AIList object has been closed.")

		# Make sure list is constructed
		if self.is_constructed is False:
			self.construct()

		# Initialize distribution
		cdef np.ndarray coverage

		# Calculate distribution
		coverage = self._interval_coverage(start, end)

		return pd.Series(coverage, index=np.arange(start, end))


	def downsample(self, double proportion):
		"""
		Randomly downsample AIList

		Parameters
		----------
			proportion : double
				Proportion of intervals to keep

		Returns
		-------
			filtered_ail : AIList
				Downsampled AIList

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize filtered list
		cdef AIList filtered_ail = AIList()

		# Call C function
		cdef ailist_t *cfiltered_ail = ailist_downsample(self.c_ailist, proportion)
		filtered_ail.set_list(cfiltered_ail)

		return filtered_ail


	def closest(self,
				start,
				end,
				k = 5):
		"""
		Find k closest intervals to given interval

		Parameters
		----------
			start : int
				Start position of interval
			end : int
				End position of interval
			k : int
				Number of closest intervals to find [default = 5]

		Returns
		-------
			closest_ail : AIList
				AIList of closest intervals
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Initialize closest list
		cdef AIList closest_ail = AIList()

		# Call C function
		cdef ailist_t *c_closest_ail = ailist_closest(start, end, self.c_ailist, k)
		closest_ail.set_list(c_closest_ail)

		return closest_ail


	def copy(self):
		"""
		Make a copy of the AIList
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		cdef AIList new_ail = AIList()
		cdef ailist_t *c_new_ail = ailist_copy(self.c_ailist)
		new_ail.set_list(c_new_ail)

		return new_ail


	def close(self):
		"""
		Close object and clear memory
		"""

		ailist_destroy(self.c_ailist)
		self.c_ailist = NULL

		self.is_closed = True
