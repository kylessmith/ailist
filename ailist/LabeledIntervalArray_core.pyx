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
from libc.stdio cimport printf

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


cpdef LabeledIntervalArray rebuild_LabeledIntervalArray(bytes data, bytes b_length, bytes b_label_list):
	"""
	Rebuild function for __reduce__()

	Parameters
	----------
		data : bytes 
			Bytes representation of labeled_aiarray_t
		b_length : bytes 
			Length of labeled_aiarray_t

	Returns
	-------
		c : labeled_aiarray_t* 
			Translated labeled_aiarray_t from data
	"""

	# Initialize new LabeledIntervalArray
	c = LabeledIntervalArray()

	# Build aiarray from serialized data
	cdef labeled_aiarray_t *interval_list = c._set_data(data, b_length, b_label_list)
	c.set_list(interval_list)

	return c


@cython.auto_pickle(True)
cdef class LabeledIntervalArray(object):
	"""
	Wrapper for C labeled_aiarray_t

	:class:`~aiarray.LabeledIntervalArray` stores a list of intervals
	"""

	def __cinit__(self):
		"""
		C Initialize LabeledIntervalArray object
		(Runs after __init__)
		"""

		# Initialize C level attributes
		self.ail = labeled_aiarray_init()
		self.is_constructed = False
		self.is_closed = False
		self.is_frozen = False


	def __init__(self):
		"""
		Initialize LabeledIntervalArray object

		Parameters
		----------
			None

		Returns
		-------
			None

		"""

		# Initialize Python level attributes
		pass


	def __dealloc__(self):
		"""
		Free LabeledIntervalArray.ail
		"""
		
		# Free C labeled_aiarray_t
		#if self.ail:
			#labeled_aiarray_destroy(self.ail)
		labeled_aiarray_destroy(self.ail)


	cdef bytes _get_data(self):
		"""
		Function to convert labeled_aiarray_t to bytes
		for serialization by __reduce__()
		"""

		return <bytes>(<char*>self.ail.interval_list)[:(sizeof(labeled_interval_t) * self.ail.nr)]

	cdef labeled_aiarray_t *_set_data(self, bytes data, bytes b_length, bytes b_label_list):
		"""
		Function to build labeled_aiarray_t object from
		serialized bytes using __reduce__()

		Parameters
		----------
			data : bytes 
				Bytes representation of labeled_aiarray_t
			b_length : bytes
				Length of labeled_aiarray_t

		Returns
		---------
			interval_list : labeled_aiarray_t*
				Translated labeled_aiarray_t for bytes
		"""
		
		# Convert bytes to ints
		cdef int length = int.from_bytes(b_length, byteorder)
		
		# Create new labeled_aiarray_t
		cdef labeled_aiarray_t *aia = labeled_aiarray_init()
		cdef labeled_interval_t *interval_list = <labeled_interval_t*>malloc(length * sizeof(labeled_interval_t))
		memcpy(interval_list, <char*>data, sizeof(labeled_interval_t)*length)

		# Iteratively add intervals to labeled_interval_list
		cdef list label_list = b_label_list.split(b";;")
		#cdef bytes label_name	
		cdef int i
		for i in range(length):
			labeled_aiarray_add(aia, interval_list[i].start, interval_list[i].end, label_list[interval_list[i].label])
			#pass

		return aia


	def __reduce__(self):
		"""
		Used for pickling. Convert labeled_aiarray to bytes and back.
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")
		
		# Convert ints to bytes
		b_length = int(self.ail.nr).to_bytes(4, byteorder)

		# Convert labeled_aiarray_t to bytes
		data = self._get_data()

		# Record label_map
		label_list = ";;".join(list(self.label_map.keys()))
		b_label_list = label_list.encode()

		return (rebuild_LabeledIntervalArray, (data, b_length, b_label_list))


	def print_label_map(self):
		display_label_map(self.ail)

	
	@property
	def label_map(self):
		"""
		Dictionary of label names toe integer representation
		"""

		# Initialize label map
		lmap = {}

		# Iterate over keys
		cdef const char *label_name
		cdef int i
		for i in range(self.ail.nl):
			label_name = query_rev_label_map(self.ail, i)
			lmap[label_name.decode()] = i

		return lmap

	@property
	def rev_label_map(self):
		"""
		Dictionary of label names to integer representation
		"""

		# Initialize label map
		lmap = {}

		# Iterate over keys
		cdef const char *label_name
		cdef int i
		for i in range(self.ail.nl):
			label_name = query_rev_label_map(self.ail, i)
			lmap[i] = label_name.decode()

		return lmap
	
	@property	
	def size(self):
		"""
		Number of intervals in LabeledIntervalArray
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		return self.ail.nr

	@property
	def unique_labels(self):
		"""
		Array of unique labels
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Find labels
		labels = np.array(list(self.label_map.keys()))
		
		return labels

	@property
	def label_counts(self):
		"""
		Count number of intervals per label
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Iterate over labels
		counts = {}
		for label in self.label_map:
			start = self._get_label_index(self.label_map[label])
			end = self._get_label_index(self.label_map[label]+1)
			counts[label] = end - start

		return counts

	@property
	def label_index(self):
		"""
		Index of labels in sorted LabeledIntervalArray
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Iterate over label_index
		cdef int i
		cdef np.ndarray index = np.zeros(self.ail.nl, dtype=int)
		for i in range(self.ail.nl):
			index[i] = self._get_label_index(i)
		
		return index

	@property
	def label_ranges(self):
		"""
		Ranges(start,  end) for each label
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Iterate over first and last
		cdef int i
		cdef dict ranges = {}
		for i in range(self.ail.nl):
			ranges[self.rev_label_map[i]] = (self.ail.first[i], self.ail.last[i])
		
		return ranges

	@property
	def _nl(self):
		return self.ail.nl
		

	def __len__(self):
		"""
		Return size of labeled_interval_list
		"""
		
		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		return self.size

	
	def __iter__(self):
		"""
		Iterate over LabeledIntervalArray object
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Iterate over interval list
		cdef LabeledInterval interval
		cdef labeled_interval_t *cinterval
		cdef int i
		for i in range(self.size):
			interval = LabeledInterval()
			cinterval = labeled_aiarray_get_id(self.ail, i)
			interval.set_i(cinterval, self.rev_label_map[cinterval.label])
			
			yield interval

	
	def __hash__(self):
		"""
		Get hash value
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		return hash(self)
		
		
	cdef labeled_aiarray_t *_array_index(LabeledIntervalArray self, const long[::1] ids):
		cdef int length = len(ids)
		cdef labeled_aiarray_t *cindexed_aiarray

		cindexed_aiarray = labeled_aiarray_slice_index(self.ail, &ids[0], length)

		if cindexed_aiarray == NULL:
			cindexed_aiarray = labeled_aiarray_init()
		
		return cindexed_aiarray

	def __getitem__(self, key):
		"""
		Index LabeledIntervals by value
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check that key given id 1D
		if isinstance(key, tuple) and len(key) == 2:
			raise IndexError("Incorrect number of dimensions given.")

		# Check if key is iterable
		cdef LabeledIntervalArray indexed_aiarray
		cdef labeled_aiarray_t *cindexed_aiarray
		cdef LabeledInterval output_interval
		cdef labeled_interval_t *coutput_interval
		cdef int k
		cdef labeled_interval_t i
		cdef labeled_interval_t *id_i
		cdef labeled_aiarray_t *label_i
		cdef int slice_start
		cdef int slice_end
		cdef int slice_step
		cdef int label_code
		cdef int j
		cdef const char *label_name
		cdef uint8[::1] bool_index
		
		try:
			iter(key) # Test is present
			# Iterate over key
			indexed_aiarray = LabeledIntervalArray()

			# Check if keys are booleans
			if isinstance(key[0], np.bool_):
				# Check array is the same size
				if len(key) != self.size:
					raise IndexError("Index and LabeledIntervalArray of different sizes.")

				bool_index = key
				cindexed_aiarray = labeled_aiarray_slice_bool(self.ail, &bool_index[0])

			# Must be integers
			else:
				cindexed_aiarray = self._array_index(key)

			# Wrap
			indexed_aiarray.set_list(cindexed_aiarray)
			
			return indexed_aiarray
		
		# key is not iterable, treat as int
		except TypeError:
			# Check if key is slice
			if isinstance(key, slice):
				# Determine indices
				slice_start, slice_end, slice_step = key.indices(self.size)
				# Iterate over key
				indexed_aiarray = LabeledIntervalArray()
				cindexed_aiarray = labeled_aiarray_slice_range(self.ail, slice_start, slice_end, slice_step)
				# Wrap
				indexed_aiarray.set_list(cindexed_aiarray)
					
				return indexed_aiarray

			# Check if key is greater than length
			if key >= self.ail.nr:
				raise IndexError("Value larger than LabeledIntervalArray length")

			# Check if negative
			if key < 0:
				key = self.ail.nr + key

			# Create LabeledInterval wrapper
			output_interval = LabeledInterval()
			coutput_interval = labeled_aiarray_get_id(self.ail, key)
			output_interval.set_i(coutput_interval, self.rev_label_map[coutput_interval.label])
		
		return output_interval


	def __repr__(self):
		"""
		Representation of LabeledIntervalArray object
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Initialize string
		repr_string = "LabeledIntervalArray\n"

		# Iterate over labeled_interval_list
		if self.ail.nr > 10:
			for i in range(5):
				repr_string += "   (%d-%d, %s)\n" % (self[i].start, self[i].end, self[i].label)
			repr_string += "   ...\n"
			for i in range(-5, 0, 1):
				repr_string += "   (%d-%d, %s)\n" % (self[i].start, self[i].end, self[i].label)
		else:
			for i in range(self.ail.nr):
				repr_string += "   (%d-%d, %s)\n" % (self[i].start, self[i].end, self[i].label)

		return repr_string


	cdef void set_list(LabeledIntervalArray self, labeled_aiarray_t *input_list):
		"""
		Set wrapper of C aiarray

		Parameters
		----------
			input_list : labeled_aiarray_t*
				labeled_aiarray_t to replace existing one

		Returns
		-------
			None
		"""

		# Free old labeled_aiarray
		#if self.ail:
			#labeled_aiarray_destroy(self.ail)
		labeled_aiarray_destroy(self.ail)
		
		# Replace new lebeled_aiarray
		self.ail = input_list
		self.is_closed = False


	cdef labeled_aiarray_t *get_labels(LabeledIntervalArray self, const char[:,::1] labels, int length):
		#cdef const char[::1] *label_names = label_array
		cdef const char *first_char = &labels[0,0]
		cdef labeled_aiarray_t *cintervals = get_label_array(self.ail, &first_char, length)

		return cintervals

	def get(self, label):
		"""
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")
		
		# Find intervals with label
		cdef LabeledIntervalArray intervals = LabeledIntervalArray()
		cdef labeled_aiarray_t *cintervals
		cdef np.ndarray label_array
		if isinstance(label, str) or isinstance(label, int):
			cintervals = get_label(self.ail, label.encode())
		else:
			try:
				iter(label)
				label_array = np.array([l for l in label]).astype(str)
				cintervals = self.get_labels(label_array, label_array.size)
			except TypeError:
				raise TypeError(" Could not determine label type.")
		
		# Wrap intervals
		intervals.set_list(cintervals)

		return intervals


	cdef overlap_label_index_t *get_labels_with_index(LabeledIntervalArray self, const char *label_names, int str_label_len, int length):
		#cdef const char[::1] *label_names = label_array
		cdef overlap_label_index_t *cintervals = get_label_array_with_index(self.ail, &label_names[0], length, str_label_len)

		return cintervals

	def get_with_index(self, label):
		"""
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")
		
		# Find intervals with label
		cdef LabeledIntervalArray intervals = LabeledIntervalArray()
		#cdef labeled_aiarray_t *cintervals
		cdef overlap_label_index_t *cintervals_index
		cdef int n_labels
		cdef np.ndarray labels
		cdef np.ndarray byte_labels
		if isinstance(label, str) or isinstance(label, int):
			cintervals_index = get_label_with_index(self.ail, label.encode())
		else:
			try:
				iter(label)
				# Add array intervals
				labels = np.array(label)
				n_labels = len(labels)
				byte_labels = labels.astype(bytes)
				
				cintervals_index = self.get_labels_with_index(np.PyArray_BYTES(byte_labels), byte_labels.itemsize, n_labels)
			except TypeError:
				raise TypeError(" Could not determine label type.")
		
		# Wrap intervals
		intervals.set_list(cintervals_index.ail)

		# Create numpy array from C pointer
		cdef np.ndarray indices = pointer_to_numpy_array(cintervals_index.indices, cintervals_index.size)

		return intervals, indices

	
	cdef np.ndarray _get_index(LabeledIntervalArray self, str label):
		"""
		"""

		# Check if any with label
		try:
			if self.label_counts[label] == 0:
				return np.array([], dtype=np.double)
		except KeyError:
			return np.array([], dtype=np.double)
		
		# Find intervals with label
		cdef long[::] index = np.zeros(self.label_counts[label], dtype=np.int_)
		cdef int start_i
		cdef int end_i
		
		# Determine where labels are
		start_i = self.label_index[self.label_map[label]]
		if self.label_map[label] + 1 == self.ail.nl:
			end_i = self.ail.nr
		else:
			end_i = self.label_index[self.label_map[label] + 1] 
		
		# Iterate over intervals
		cdef labeled_interval_t found_interval
		cdef int i
		cdef int index_i = 0
		for i in range(start_i, end_i):
			found_interval = self.ail.interval_list[i]
			index[index_i] = found_interval.id_value
			index_i += 1

		return np.asarray(index)

	
	cdef np.ndarray _get_index_multi(LabeledIntervalArray self, np.ndarray labels):
		"""
		"""
		
		# Find intervals with label
		cdef n = 0
		cdef int label
		for label in range(len(labels)):
			n += self.label_counts[labels[label]]
		cdef long[::] index = np.zeros(n, dtype=np.int_)
		cdef int start_i
		cdef int end_i
		cdef int i
		cdef int index_i = 0
		cdef labeled_interval_t found_interval
		
		for label in range(len(labels)):
			# Determine where labels are
			start_i = self.label_index[self.label_map[labels[label]]]
			if self.label_map[labels[label]] + 1 == self.ail.nl:
				end_i = self.ail.nr
			else:
				end_i = self.label_index[self.label_map[labels[label]] + 1] 
			
			# Iterate over intervals
			for i in range(start_i, end_i):
				found_interval = self.ail.interval_list[i]
				index[index_i] = found_interval.id_value
				index_i += 1

		return np.asarray(index)

	def get_index(self, label):
		"""
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Make sure it is constructed
		if self.is_constructed == False:
			self.construct()

		if isinstance(label, str):
			index = self._get_index(str(label))
		else:
			index = self._get_index_multi(label)

		return index


	def freeze(self):
		"""
		Make :class:`~aiarray.LabeledIntervalArray` immutable

		Parameters
		----------
			None

		Returns
		-------
			None

		See Also
		--------
		LabeledIntervalArray.unfreeze: Make mutable
		LabeledIntervalArray.sort: Sort intervals inplace
		LabeledIntervalArray.construct: Construct LabeledIntervalArray, required to call LabeledIntervalArray.intersect

		Examples
		--------
		>>> from aiarray import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.add(1, 2, 'a')
		>>> ail.add(3, 4, 'a')
		>>> ail.add(3, 6, 'a')
		>>> ail
		aiarray
		  range: (1-6)
		   (1-2, 'a')
		   (3-4, 'a')
		   (3-6, 'a')
		>>> ail.freeze()
		>>> ail.add(9, 10, 'a')
		TypeError: LabeledIntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Make sure it is constructed
		if self.is_constructed == False:
			self.construct()

		# Change to frozen
		self.is_frozen = True


	def unfreeze(self):
		"""
		Make :class:`~aiarray.LabeledIntervalArray` mutable

		Parameters
		----------
			None

		Returns
		-------
			None

		See Also
		--------
		LabeledIntervalArray.freeze: Make immutable
		LabeledIntervalArray.sort: Sort intervals inplace
		LabeledIntervalArray.construct: Construct LabeledIntervalArray, required to call LabeledIntervalArray.intersect

		Examples
		--------
		>>> from aiarray import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.add(1, 2, 'a')
		>>> ail.add(3, 4, 'a')
		>>> ail.add(3, 6, 'a')
		>>> ail
		LabeledIntervalArray
		  range: (1-6)
		   (1-2, 'a')
		   (3-4, 'a')
		   (3-6, 'a')
		>>> ail.freeze()
		>>> ail.add(9, 10, 'a')
		TypeError: LabeledIntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.
		>>> ail.unfreeze()
		>>> ail.add(9, 10, 'a')

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Change to not frozen
		self.is_frozen = False


	cdef void _insert(LabeledIntervalArray self, int start, int end, const char *label_name):
		labeled_aiarray_add(self.ail, start, end, label_name)

	def add(self, int start, int end, str label):
		"""
		Add an interval to LabeledIntervalArray inplace
		
		Parameters
		----------
			start : int
				Start position of interval
			end : int
				End position of interval
			label : str
				Label of interval

		Returns
		-------
			None

		See Also
		--------
		LabeledIntervalArray.from_array: Add intervals from arrays
		LabeledIntervalArray.construct: Construct LabeledIntervalArray, required to call LabeledIntervalArray.intersect
		LabeledIntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from aiarray import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.add(1, 2, 'a')
		>>> ail.add(3, 4, 'a')
		>>> ail.add(3, 6, 'a')
		>>> ail
		aiarray
		  range: (1-6)
		   (1-2, 'a')
		   (3-4, 'a')
		   (3-6, 'a')

		"""
		
		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check that object is not frozen
		if self.is_frozen:
			raise TypeError("LabeledIntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.")

		# Insert interval
		self._insert(start, end, label.encode())
		self.is_constructed = False


	cdef void _from_array(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, const char *label_names, int array_length, int label_str_len):
		#cdef const char *label_name
		labeled_aiarray_from_array(self.ail, &starts[0], &ends[0], &label_names[0], array_length, label_str_len)
		#cdef int i
		#for i in range(array_length):
			#label_name = &label_names[i,:][0]
			#labeled_aiarray_add(self.ail, starts[i], ends[i], label_name)
		return
	
	def from_array(self, const long[::1] starts, const long[::1] ends, np.ndarray labels):
		"""
		Add intervals from arrays to LabeledIntervalArray inplace
		
		Parameters
		----------
			starts : numpy.ndarray {long}
				Start positions of intervals
			ends : numpy.ndarray {long}
				End positions of intervals
			labels : numpy.ndarray {object/str}
				ID of intervals

		Returns
		-------
			None

		See Also
		--------
		LabeledIntervalArray.add: Add interval to LabeledIntervalArray
		LabeledIntervalArray.construct: Construct LabeledIntervalArray, required to call LabeledIntervalArray.intersect
		LabeledIntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from aiarray import LabeledIntervalArray
		>>> import numpy as np
		>>> starts = np.arange(100)
		>>> ends = starts + 10
		>>> labeld = np.repeat('a', len(starts))
		>>> ail = LabeledIntervalArray()
		>>> ail.from_array(starts, ends, labels)
		>>> ail
		LabeledIntervalArray
		  range: (0-109)
		   (0-10, 'a')
		   (1-11, 'a')
		   (2-12, 'a')
		   (3-13, 'a')
		   (4-14, 'a')
		   ...
		   (95-105, 'a')
		   (96-106, 'a')
		   (97-107, 'a')
		   (98-108, 'a')

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check that object is not frozen
		if self.is_frozen:
			raise TypeError("LabeledIntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.")

		# Add array intervals
		cdef int array_length = len(starts)
		cdef np.ndarray byte_labels = labels.astype(bytes)
		
		self._from_array(starts, ends, np.PyArray_BYTES(byte_labels), array_length, byte_labels.itemsize)
		self.is_constructed = False

	
	cdef void _append(LabeledIntervalArray self, LabeledIntervalArray other_ail):
		#cdef const char *label_name
		labeled_aiarray_append(self.ail, other_ail.ail)
		#cdef int i
		#for i in range(array_length):
			#label_name = &label_names[i,:][0]
			#labeled_aiarray_add(self.ail, starts[i], ends[i], label_name)
		return
	
	def append(self, LabeledIntervalArray other_ail):
		"""
		Add intervals from arrays to LabeledIntervalArray inplace
		
		Parameters
		----------
			other_ail : LabeledIntervalArray
				Intervals to add to current LabeledIntervalArray

		Returns
		-------
			None

		See Also
		--------
		LabeledIntervalArray.add: Add interval to LabeledIntervalArray
		LabeledIntervalArray.construct: Construct LabeledIntervalArray, required to call LabeledIntervalArray.intersect
		LabeledIntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from ailist import LabeledIntervalArray
		>>> import numpy as np
		>>> starts = np.arange(100)
		>>> ends = starts + 10
		>>> labels = np.repeat('a', len(starts))
		>>> ail = LabeledIntervalArray()
		>>> ail.from_array(starts, ends, labels)
		>>> ail
		LabeledIntervalArray
		  	(0-10, a)
			(1-11, a)
			(2-12, a)
			(3-13, a)
			(4-14, a)
			...
			(95-105, a)
			(96-106, a)
			(97-107, a)
			(98-108, a)
			(99-109, a)
		
		>>> len(ail)
		100

		>>> ail2 = LabeledIntervalArray()
		>>> ail2.from_array(starts, ends, labels)
		>>> ail.append(ail2)
		>>> ail
		LabeledIntervalArray
		  	(0-10, a)
			(1-11, a)
			(2-12, a)
			(3-13, a)
			(4-14, a)
			...
			(95-105, a)
			(96-106, a)
			(97-107, a)
			(98-108, a)
			(99-109, a)
		
		>>> len(ail)
		200

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check that object is not frozen
		if self.is_frozen:
			raise TypeError("LabeledIntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.")
		
		self._append(other_ail)
		self.is_constructed = False


	cdef void _construct(LabeledIntervalArray self, int min_length):
		# Contruct
		labeled_aiarray_radix_label_sort(self.ail)
		labeled_aiarray_sort(self.ail)
		labeled_aiarray_construct(self.ail, min_length)
		labeled_aiarray_cache_id(self.ail)

	def construct(self, int min_length=20):
		"""
		Construct labeled_aiarray_t *Required to call intersect

		Parameters
		----------
			min_length : int
				Minimum length

		Returns
		-------
			None

		.. warning::
			This will re-sort intervals inplace if ail.track_index = False

		See Also
		--------
		LabeledIntervalArray.sort: Sort intervals inplace
		LabeledIntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from aiarray import Labledaiarray
		>>> ail = Labledaiarray()
		>>> ail.add(1, 2, 'a')
		>>> ail.add(3, 4, 'a')
		>>> ail.add(2, 6, 'a')
		>>> ail
		Labledaiarray
		  range: (1-6)
		   (1-2, 'a')
		   (3-4, 'a')
		   (2-6, 'a')
		>>> ail.construct()
		>>> ail
		Labledaiarray
		  range: (1-6)
		   (1-2, 'a')
		   (2-6, 'a')
		   (3-4, 'a')

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("Labledaiarray object has been closed.")

		# Check if already constructed
		if self.is_constructed == False:
			self._construct(min_length)
			self.is_constructed = True
		else:
			pass


	cdef int _get_label_index(LabeledIntervalArray self, int label):
		"""
		"""

		cdef int count = 0
		cdef int i
		for i in range(label):
			count += self.ail.label_count[i]

		return count

	cdef np.ndarray _get_label_comp_bounds(LabeledIntervalArray self, int label):
		"""
		Get component index for label
		"""

		# Initialize label specific variables
		cdef int label_start = self._get_label_index(label)
		cdef int *idxC = &self.ail.idxC[label * 10]
		cdef int n_comps = self.ail.nc[label]
		cdef np.ndarray comps_bounds = np.zeros(n_comps + 1, dtype=int)

		# Iterate over components
		cdef int i
		for i in range(n_comps):
			comps_bounds[i] = label_start + idxC[i]
		comps_bounds[n_comps] = self._get_label_index(label + 1)

		return comps_bounds

	cdef np.ndarray _get_label_comp_length(LabeledIntervalArray self, int label):
		"""
		Get component lengths for label
		"""

		# Initialize label specifc variables
		cdef int *lenC = &self.ail.idxC[label * 10]
		cdef int n_comps = self.ail.nc[label]
		cdef np.ndarray comps_length = np.zeros(n_comps, dtype=int)

		# Iterate over components
		cdef int i
		for i in range(n_comps):
			comps_length[i] = lenC[i]

		return comps_length

	def iter_sorted(self):
		"""
		Iterate over an LabeledIntervalArray in sorted way
		
		Parameters
		----------
			None
		
		Returns
		-------
			sorted_iter : Generator
				Generator of LabeledIntervals
		"""

		# Check if is constructed
		if self.is_constructed == False:
			self.construct()

		# Iterate over labels in ail
		cdef const char *label_name
		cdef label_sorted_iter_t *ail_iter
		cdef labeled_interval_t *cintv
		cdef LabeledInterval output_interval
		cdef bytes label_bytes
		cdef int label
		for label in range(self.ail.nl):
			label_name = query_rev_label_map(self.ail, label)
			# Create sorted iterators
			ail_iter = iter_init(self.ail, label_name)
			while iter_next(ail_iter) != 0:
				cintv = ail_iter.intv
				# Create LabeledInterval wrapper
				label_bytes = label_name
				output_interval = LabeledInterval()
				output_interval.set_i(cintv, label_bytes.decode())
				yield output_interval

			iter_destroy(ail_iter)


	cdef labeled_aiarray_t *_intersect(LabeledIntervalArray self, int start, int end, const char *label_name):
		cdef labeled_aiarray_t *overlaps = labeled_aiarray_query_single(self.ail, start, end, label_name)

		return overlaps

	def intersect(self, int start, int end, str label):
		"""
		Find intervals overlapping given range
		
		Parameters
		----------
			start : int
				Start position of query range
			end : int
				End position of query range
			label : str
				Label of quert range

		Returns
		-------
			overlaps : LabeledIntervalArray
				Overlapping intervals

		.. warning::
			This requires :func:`~aiarray.LabeledIntervalArray.construct` and will run it if not already run. This will re-sort intervals inplace is ail.track_index = False.

		See Also
		--------
		LabeledIntervalArray.construct: Construct LabeledIntervalArray, required to call LabeledIntervalArray.intersect
		LabeledIntervalArray.add: Add interval to LabeledIntervalArray
		LabeledIntervalArray.intersect_index: Find interval indices overlapping given range
		LabeledIntervalArray.intersect_from_array: Find interval indices overlapping given ranges

		Examples
		--------
		>>> from aiarray import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.add(1, 2, 'a')
		>>> ail.add(3, 4, 'a')
		>>> ail.add(2, 6, 'a')
		>>> ail
		aiarray
		  range: (1-6)
		   (1-2, 'a')
		   (3-4, 'a')
		   (2-6, 'a')
		>>> q = ail.intersect(2, 10, 'a')
		>>> q
		aiarray
		  range: (2-6)
		   (2-6, 'a')
		   (3-4, 'a')

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if is constructed
		if self.is_constructed == False:
			self.construct()

		# Check if label is present
		try:
			self.label_map[label]
		except KeyError:
			raise KeyError("Label given is not in LabeledIntervalArray.")

		# Intersect
		cdef labeled_aiarray_t *i_list = self._intersect(start, end, label.encode())
		cdef LabeledIntervalArray overlaps = LabeledIntervalArray()
		overlaps.set_list(i_list)

		return overlaps

	
	def has_hit(self, int start, int end, str label):
		"""
		Find interval indices overlapping given ranges
		
		Parameters
		----------
			starts : numpy.ndarray {long}
				Start positions of intervals
			ends : numpy.ndarray {long}
				End positions of intervals
			labels : numpy.ndarray {str}
				Labels of intervals

		Returns
		-------
			ref_index : np.ndarray {int}
				Overlapping interval indices from LabeledIntervalArray
			query_index : np.ndarray {int}
				Overlapping interval indices from query LabeledIntervalArray

		.. warning::
			This requires :func:`~aiarray.LabeledIntervalArray.construct` and will run it if not already run. This will re-sort intervals inplace if ail.track_index = False.

		See Also
		--------
		LabeledIntervalArray.construct: Construct LabeledIntervalArray, required to call LabeledIntervalArray.intersect
		LabeledIntervalArray.add: Add interval to LabeledIntervalArray
		LabeledIntervalArray.intersect: Find intervals overlapping given range
		LabeledIntervalArray.intersect_index: Find interval indices overlapping given range

		Examples
		--------
		>>> from aiarray import LabeledIntervalArray
		>>> ail1 = LabeledIntervalArray()
		>>> ail1.add(1, 2, 'a')
		>>> ail1.add(3, 4, 'a')
		>>> ail1.add(2, 6, 'a')
		>>> ail1
		LabeledIntervalArray
		  range: (1-6)
		   (1-2, 'a')
		   (3-4, 'a')
		   (2-6, 'a')
		>>> ail2 = LabeledIntervalArray()
		>>> ail2.add(1, 2, 'a')
		>>> ail2.add(3, 6, 'a')
		>>> ail2
		LabeledIntervalArray
		  range: (1-6)
		    (1-2, 'a')
		    (3-6, 'a')
		>>> q = ail1.intersect_from_array(ail2)
		>>> q
		(array([2, 1]), array([]))

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if object is constructed
		if self.is_constructed == False:
			self.construct()

		# Check that labels are bytes
		cdef bytes byte_label = str(label).encode()

		cdef np.ndarray has_hit = np.zeros(self.size, dtype=bool)
		cdef uint8[::1] has_hit_mem = has_hit

		# Intersect
		labeled_aiarray_query_has_hit(self.ail, &has_hit_mem[0], start, end, byte_label)
		
		return has_hit


	@cython.boundscheck(False)
	@cython.wraparound(False)
	@cython.initializedcheck(False)
	cpdef _intersect_from_array(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, const char *labels, int label_str_len):
		cdef int length = len(starts)
		cdef array_query_t *total_overlaps
		#cdef const char *first_char = &labels[0,0]
		#cdef const char *first_char = np.PyArray_BYTES(labels)
		total_overlaps = labeled_aiarray_query_from_array(self.ail, &starts[0], &ends[0], &labels[0], length, label_str_len)

		cdef np.ndarray ref_index = pointer_to_numpy_array(total_overlaps.ref_index, total_overlaps.size)
		cdef np.ndarray query_index = pointer_to_numpy_array(total_overlaps.query_index, total_overlaps.size)

		return ref_index, query_index

	def intersect_from_array(self, const long[::1] starts, const long[::1] ends, np.ndarray labels):
		"""
		Find interval indices overlapping given ranges
		
		Parameters
		----------
			starts : numpy.ndarray {long}
				Start positions of intervals
			ends : numpy.ndarray {long}
				End positions of intervals
			labels : numpy.ndarray {str}
				Labels of intervals

		Returns
		-------
			ref_index : np.ndarray {int}
				Overlapping interval indices from LabeledIntervalArray
			query_index : np.ndarray {int}
				Overlapping interval indices from query LabeledIntervalArray

		.. warning::
			This requires :func:`~aiarray.LabeledIntervalArray.construct` and will run it if not already run. This will re-sort intervals inplace if ail.track_index = False.

		See Also
		--------
		LabeledIntervalArray.construct: Construct LabeledIntervalArray, required to call LabeledIntervalArray.intersect
		LabeledIntervalArray.add: Add interval to LabeledIntervalArray
		LabeledIntervalArray.intersect: Find intervals overlapping given range
		LabeledIntervalArray.intersect_index: Find interval indices overlapping given range

		Examples
		--------
		>>> from aiarray import LabeledIntervalArray
		>>> ail1 = LabeledIntervalArray()
		>>> ail1.add(1, 2, 'a')
		>>> ail1.add(3, 4, 'a')
		>>> ail1.add(2, 6, 'a')
		>>> ail1
		LabeledIntervalArray
		  range: (1-6)
		   (1-2, 'a')
		   (3-4, 'a')
		   (2-6, 'a')
		>>> ail2 = LabeledIntervalArray()
		>>> ail2.add(1, 2, 'a')
		>>> ail2.add(3, 6, 'a')
		>>> ail2
		LabeledIntervalArray
		  range: (1-6)
		    (1-2, 'a')
		    (3-6, 'a')
		>>> q = ail1.intersect_from_array(ail2)
		>>> q
		(array([2, 1]), array([]))

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if object is constructed
		if self.is_constructed == False:
			self.construct()

		# Check that labels are bytes
		byte_labels = labels.astype(bytes)

		# Intersect from array
		ref_index, query_index = self._intersect_from_array(starts, ends, np.PyArray_BYTES(byte_labels), byte_labels.itemsize)
		
		return ref_index, query_index


	@cython.boundscheck(False)
	@cython.wraparound(False)
	@cython.initializedcheck(False)
	cpdef _has_hit_from_array(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, uint8[::1] has_hit, const char *labels, int label_str_len):
		cdef int length = len(starts)
		labeled_aiarray_has_hit_from_array(self.ail, &starts[0], &ends[0], &labels[0], length, label_str_len, &has_hit[0])

		return
	
	def has_hit_from_array(self, const long[::1] starts, const long[::1] ends, np.ndarray labels):
		"""
		Find interval indices overlapping given ranges
		
		Parameters
		----------
			starts : numpy.ndarray {long}
				Start positions of intervals
			ends : numpy.ndarray {long}
				End positions of intervals
			labels : numpy.ndarray {str}
				Labels of intervals

		Returns
		-------
			ref_index : np.ndarray {int}
				Overlapping interval indices from LabeledIntervalArray
			query_index : np.ndarray {int}
				Overlapping interval indices from query LabeledIntervalArray

		.. warning::
			This requires :func:`~aiarray.LabeledIntervalArray.construct` and will run it if not already run. This will re-sort intervals inplace if ail.track_index = False.

		See Also
		--------
		LabeledIntervalArray.construct: Construct LabeledIntervalArray, required to call LabeledIntervalArray.intersect
		LabeledIntervalArray.add: Add interval to LabeledIntervalArray
		LabeledIntervalArray.intersect: Find intervals overlapping given range
		LabeledIntervalArray.intersect_index: Find interval indices overlapping given range

		Examples
		--------
		>>> from aiarray import LabeledIntervalArray
		>>> ail1 = LabeledIntervalArray()
		>>> ail1.add(1, 2, 'a')
		>>> ail1.add(3, 4, 'a')
		>>> ail1.add(2, 6, 'a')
		>>> ail1
		LabeledIntervalArray
		  range: (1-6)
		   (1-2, 'a')
		   (3-4, 'a')
		   (2-6, 'a')
		>>> ail2 = LabeledIntervalArray()
		>>> ail2.add(1, 2, 'a')
		>>> ail2.add(3, 6, 'a')
		>>> ail2
		LabeledIntervalArray
		  range: (1-6)
		    (1-2, 'a')
		    (3-6, 'a')
		>>> q = ail1.intersect_from_array(ail2)
		>>> q
		(array([2, 1]), array([]))

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if object is constructed
		if self.is_constructed == False:
			self.construct()

		# Check that labels are bytes
		byte_labels = labels.astype(bytes)

		cdef np.ndarray has_hit = np.zeros(self.size, dtype=bool)
		cdef uint8[::1] has_hit_mem = has_hit

		# Intersect from array
		self._has_hit_from_array(starts, ends, has_hit_mem, np.PyArray_BYTES(byte_labels), byte_labels.itemsize)
		
		return has_hit

	
	cpdef _intersect_from_labeled_aiarray(LabeledIntervalArray self, LabeledIntervalArray ail):
		# Intersect with other LabeledIntervalArray
		cdef array_query_t *total_overlaps = labeled_aiarray_query_from_labeled_aiarray(self.ail, ail.ail)

		# Create numpy array from C pointer
		cdef np.ndarray ref_index = pointer_to_numpy_array(total_overlaps.ref_index, total_overlaps.size)
		cdef np.ndarray query_index = pointer_to_numpy_array(total_overlaps.query_index, total_overlaps.size)

		return ref_index, query_index

	def intersect_from_LabeledIntervalArray(self, LabeledIntervalArray ail_query):
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
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if object is constructed
		if self.is_constructed == False:
			self.construct()

		# Intersect
		query_index, ref_index = self._intersect_from_labeled_aiarray(ail_query)
		
		return query_index, ref_index


	cpdef _intersect_with_index(LabeledIntervalArray self, int start, int end, const char *label_name):
		# Intersect with interval
		cdef overlap_label_index_t *total_overlaps = labeled_aiarray_query_single_with_index(self.ail, start, end, label_name)

		# Create numpy array from C pointer
		cdef np.ndarray indices = pointer_to_numpy_array(total_overlaps.indices, total_overlaps.size)
		cdef LabeledIntervalArray overlaps = LabeledIntervalArray()
		overlaps.set_list(total_overlaps.ail)

		return overlaps, indices
	
	def intersect_with_index(self, int start, int end, str label):
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

		# Check if label is present
		try:
			self.label_map[label]
		except KeyError:
			raise KeyError("Label given is not in LabeledIntervalArray.")

		# Intersect
		cdef LabeledIntervalArray overlaps
		cdef np.ndarray indices
		overlaps, indices = self._intersect_with_index(start, end, label.encode())
		
		return overlaps, indices


	cpdef _intersect_with_index_from_LabeledIntervalArray(LabeledIntervalArray self, LabeledIntervalArray ail2):
		# Intersect with interval
		cdef overlap_label_index_t *total_overlaps = labeled_aiarray_query_with_index_from_labeled_aiarray(self.ail, ail2.ail)

		# Create numpy array from C pointer
		cdef np.ndarray indices = pointer_to_numpy_array(total_overlaps.indices, total_overlaps.size)
		cdef LabeledIntervalArray overlaps = LabeledIntervalArray()
		overlaps.set_list(total_overlaps.ail)

		return overlaps, indices
	
	def intersect_with_index_from_LabeledIntervalArray(self, LabeledIntervalArray ail):
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
		cdef LabeledIntervalArray overlaps
		cdef np.ndarray indices
		overlaps, indices = self._intersect_with_index_from_LabeledIntervalArray(ail)
		# Set label_map
		overlaps.copy_maps(self)
		
		return overlaps, indices

	
	cdef np.ndarray _nhits_from_array(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, const char[:,::1] labels):
		# Initialize hits
		cdef int length = starts.size
		cdef int[::1] nhits = np.zeros(length, dtype=np.intc)
		cdef const char *first_char = &labels[0,0]

		# Calculate distribution
		labeled_aiarray_nhits_from_array(self.ail, &starts[0], &ends[0], &first_char, length, &nhits[0])

		return np.asarray(nhits, dtype=np.intc)

	cdef np.ndarray _nhits_from_array_length(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends, const char[:,::1] labels, int min_length, int max_length):
		# Initialize hits
		cdef int length = starts.size
		cdef int[::1] nhits = np.zeros(length, dtype=np.intc)
		cdef const char *first_char = &labels[0,0]

		# Calculate distribution
		labeled_aiarray_nhits_from_array_length(self.ail, &starts[0], &ends[0], &first_char, length, &nhits[0], min_length, max_length)

		return np.asarray(nhits, dtype=np.intc)

	def nhits_from_array(self, const long[::1] starts, const long[::1] ends, np.ndarray labels, min_length=None, max_length=None):
		"""
		Find number of intervals overlapping given
		positions
		
		Parameters
		----------
			starts : numpy.ndarray {long}
				Start positions to intersect
			ends : numpy.ndarray {long}
				End positions to intersect
			labels : numpy.ndarray {long}
				Labels to intersect
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
			raise NameError("aiarray object has been closed.")

		# Make sure list is constructed
		if self.is_constructed == False:
			self.construct()

		# Initialize distribution
		cdef np.ndarray nhits

		# Calculate distribution
		if min_length is None or max_length is None:
			nhits = self._nhits_from_array(starts, ends, labels)
		else:
			nhits = self._nhits_from_array_length(starts, ends, labels, min_length, max_length)

		return nhits

	cdef labeled_aiarray_t *_determine_bins(LabeledIntervalArray self, int bin_size):
		"""
		Create LabeledIntervalArray for bins
		"""

		# Initialize variables
		cdef labeled_aiarray_t *bins = labeled_aiarray_init()
		cdef int nbins
		cdef int first
		cdef int first_bin_start
		cdef int last
		cdef int start
		#cdef uint16_t label
		cdef int i
		cdef int j
		cdef const char *label_name

		# Iterate over labels
		for i in range(self.ail.nl):
			if self.ail.label_count[i] > 0:
				#label = self.ail.interval_list[self._get_label_index(i)].label
				first = self.ail.first[i]
				first_bin_start = (first // bin_size) * bin_size
				last = self.ail.last[i]
				n_bins = math.ceil(last / bin_size) - (first // bin_size)

				# Iterate over label bins
				for j in range(n_bins):
					start = first_bin_start + (j * bin_size)
					label_name = query_rev_label_map(self.ail, i)
					labeled_aiarray_add(bins, start, start + bin_size, label_name)

		return bins

	cdef np.ndarray _bin_nhits(LabeledIntervalArray self, labeled_aiarray_t *bins, int bin_size):
		# Initialize nhits
		cdef double[::1] nhits = np.zeros(bins.nr, dtype=np.double)
		# Determine bin hits
		labeled_aiarray_bin_nhits(self.ail, bins, &nhits[0], bin_size)

		return np.asarray(nhits)

	cdef np.ndarray _bin_nhits_length(LabeledIntervalArray self, labeled_aiarray_t *bins, int bin_size, int min_length, int max_length):
		# Initialize coverage
		cdef double[::1] nhits = np.zeros(bins.nr, dtype=np.double)
		# Determine bin hits
		labeled_aiarray_bin_nhits_length(self.ail, bins, &nhits[0], bin_size, min_length, max_length)

		return np.asarray(nhits)

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
			bins : pandas.Series {double}
				Position on index and coverage as values

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Determine bins
		cdef labeled_aiarray_t *cbins = self._determine_bins(bin_size)
		cdef LabeledIntervalArray bins = LabeledIntervalArray()
		bins.set_list(cbins)
		bins.construct()

		# Set bins label_map
		cdef int label
		cdef int i
		for i in range(self.ail.nl):
			bins.label_map[self.rev_label_map[i]] = i
			bins.rev_label_map[i] = self.rev_label_map[i]

		# Initialize nhits
		cdef np.ndarray nhits
		# Calculate nhits
		if min_length is None or max_length is None:
			nhits = self._bin_nhits(bins.ail, bin_size)
		else:
			nhits = self._bin_nhits_length(bins.ail, bin_size, min_length, max_length)
		
		return bins, nhits


	def nhits(self, int start, int end, str label, min_length=None, max_length=None):
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
			bins : pandas.Series {double}
				Position on index and coverage as values

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Calculate nhits
		cdef int nhits
		cdef bytes label_name = label.encode()
		if min_length is None or max_length is None:
			nhits = labeled_aiarray_nhits(self.ail, start, end, label_name)
		else:
			nhits = labeled_aiarray_nhits_length(self.ail, start, end, label_name, min_length, max_length)
		
		return nhits

	
	cdef np.ndarray _wps(LabeledIntervalArray self, int protection):
		# Initialize wps
		cdef long n = 0
		cdef int i
		for i in range(self.ail.nl):
			n += self.ail.last[i] - self.ail.first[i]
		cdef double[::1] wps = np.zeros(n, dtype=np.double)

		# Calculate wps
		labeled_aiarray_wps(self.ail, &wps[0], protection)

		return np.asarray(wps)

	cdef np.ndarray _wps_length(LabeledIntervalArray self, int protection, int min_length, int max_length):
		# Initialize wps
		cdef long n = 0
		cdef int i
		for i in range(self.ail.nl):
			n += self.ail.last[i] - self.ail.first[i]
		cdef double[::1] wps = np.zeros(n, dtype=np.double)

		# Calculate wps
		labeled_aiarray_wps_length(self.ail, &wps[0], protection, min_length, max_length)

		return np.asarray(wps)

	def wps(self, int protection=60, min_length=None, max_length=None):
		"""
		Calculate Window Protection Score
		for each position in LabeledIntervalArray range
		
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
			wps : pandas.Series {double}
				Position on index and WPS as values

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("aiarray object has been closed.")
		
		# Initialize wps
		cdef np.ndarray wps
		# Calculate wps
		if self.ail.nr == 0:
			return None
		if min_length is None or max_length is None:
			wps = self._wps(protection)
		else:
			wps = self._wps_length(protection, min_length, max_length)
		
		return wps

	
	cdef np.ndarray _coverage(LabeledIntervalArray self):
		# Initialize wps
		cdef long n = 0
		cdef int i
		for i in range(self.ail.nl):
			n += self.ail.last[i] - self.ail.first[i]

		cdef double[::1] coverage = np.zeros(n, dtype=np.double)

		# Calculate coverage
		labeled_aiarray_coverage(self.ail, &coverage[0])

		return np.asarray(coverage)


	def coverage(self):
		"""
		Calculate coverage
		for each position in LabeledIntervalArray range
		
		Parameters
		----------
			min_length : int
				Minimum length of intervals to include [default = None]
			max_length : int
				Maximum length of intervals to include [default = None]

		Returns
		-------
			coverage : numpy.ndarray
				Coverage as values

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("labeled_aiarray object has been closed.")
		
		# Initialize coverage
		cdef np.ndarray coverage
		# Calculate coverage
		if self.ail.nr == 0:
			return None
		
		coverage = self._coverage()
		
		return coverage

	
	def merge(self, int gap=0):
		"""
		Merge intervals within a gap
		
		Parameters
		----------
			gap : int
				Gap between intervals to merge

		Returns
		-------
			merged_list : LabeledIntervalArray
				Merged intervals

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("aiarray object has been closed.")

		# Make sure list is constructed
		if self.is_constructed == False:
			self.construct()

		# Create merged
		cdef LabeledIntervalArray merged_list = LabeledIntervalArray()
		cdef labeled_aiarray_t *merged_clist = labeled_aiarray_merge(self.ail, gap)
		merged_list.set_list(merged_clist)
		# Set bins label_map
		cdef int label
		cdef int i
		for i in range(self.ail.nl):
			if self.ail.label_count[i] > 0:
				label = self.ail.interval_list[self._get_label_index(i)].label
				merged_list.label_map[self.rev_label_map[label]] = label
				merged_list.rev_label_map[label] = self.rev_label_map[label]

		return merged_list

	
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
			filtered_ail : LabeledIntervalArray
				Filtered intervals

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Initialize filtered list
		cdef LabeledIntervalArray filtered_ail = LabeledIntervalArray()

		cdef labeled_aiarray_t *cfiltered_ail = labeled_aiarray_length_filter(self.ail, min_length, max_length)
		filtered_ail.set_list(cfiltered_ail)
		# Set bins label_map
		cdef int label
		cdef int i
		for i in range(self.ail.nl):
			if self.ail.label_count[i] > 0:
				label = self.ail.interval_list[self._get_label_index(i)].label
				filtered_ail.label_map[self.rev_label_map[label]] = label
				filtered_ail.rev_label_map[label] = self.rev_label_map[label]

		return filtered_ail
	

	def downsample(self, double proportion):
		"""
		Randomly downsample LabeledIntervalArray
		
		Parameters
		----------
			proportion : double
				Proportion of intervals to keep

		Returns
		-------
			filtered_ail : LabeledIntervalArray
				Downsampled LabeledIntervalArray

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Initialize filtered list
		cdef LabeledIntervalArray filtered_ail = LabeledIntervalArray()

		cdef labeled_aiarray_t *cfiltered_ail = labeled_aiarray_downsample(self.ail, proportion)
		filtered_ail.set_list(cfiltered_ail)
		# Set bins label_map
		cdef int label
		cdef int i
		for i in range(self.ail.nl):
			if self.ail.label_count[i] > 0:
				label = self.ail.interval_list[self._get_label_index(i)].label
				filtered_ail.label_map[self.rev_label_map[label]] = label
				filtered_ail.rev_label_map[label] = self.rev_label_map[label]

		return filtered_ail

	
	cpdef _downsample_with_index(LabeledIntervalArray self, double proportion):
		# Randomly downsample LabeledIntervalArray
		cdef overlap_label_index_t *new_intervals = labeled_aiarray_downsample_with_index(self.ail, proportion)

		# Create numpy array from C pointer
		cdef np.ndarray indices = pointer_to_numpy_array(new_intervals.indices, new_intervals.size)
		cdef LabeledIntervalArray intervals = LabeledIntervalArray()
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
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if object is constructed
		if self.is_constructed == False:
			self.construct()

		# Intersect
		cdef LabeledIntervalArray filtered_ail
		cdef np.ndarray indices
		filtered_ail, indices = self._downsample_with_index(proportion)
		# Set bins label_map
		cdef int label
		cdef int i
		for i in range(self.ail.nl):
			if self.ail.label_count[i] > 0:
				label = self.ail.interval_list[self._get_label_index(i)].label
				filtered_ail.label_map[self.rev_label_map[label]] = label
				filtered_ail.rev_label_map[label] = self.rev_label_map[label]
		
		return filtered_ail, indices
	

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
			raise NameError("LabeledIntervalArray object has been closed.")

		# Extract start values
		cdef long[::1] starts = np.zeros(self.size, dtype=np.int_)
		labeled_aiarray_extract_starts(self.ail, &starts[0])

		return np.asarray(starts, dtype=np.int_)

	
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
			raise NameError("LabeledIntervalArray object has been closed.")

		# Extract end values
		cdef long[::1] ends = np.zeros(self.size, dtype=np.int_)
		labeled_aiarray_extract_ends(self.ail, &ends[0])

		return np.asarray(ends, dtype=np.int_)

	
	def extract_labels(self):
		"""
		Return the label values

		Parameters
		----------
			None

		Returns
		-------
			labels : numpy.ndarray
				label values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Extract end values
		cdef np.ndarray labels = np.zeros(self.size, dtype=np.object)
		cdef int i
		cdef LabeledInterval interval
		for i, interval in enumerate(self):
			labels[i] = interval.label

		return labels

	
	cdef np.ndarray _length_dist(LabeledIntervalArray self):
		# Initialize distribution
		cdef int max_length = labeled_aiarray_max_length(self.ail)
		cdef int[::1] distribution = np.zeros(max_length + 1, dtype=np.intc)

		# Calculate distribution
		labeled_aiarray_length_distribution(self.ail, &distribution[0])

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


	cpdef _filter_exact_match(LabeledIntervalArray self, LabeledIntervalArray other_aiarray):
		"""
		"""

		cdef overlap_label_index_t *matched_ail = has_exact_match(self.ail, other_aiarray.ail)

		# Create numpy array from C pointer
		cdef np.ndarray indices = pointer_to_numpy_array(matched_ail.indices, matched_ail.size)
		cdef LabeledIntervalArray matched = LabeledIntervalArray()
		matched.set_list(matched_ail.ail)

		return matched, indices

	def filter_exact_match(self, LabeledIntervalArray other_aiarray):
		"""
		Determine which intervals are present
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check construction
		if self.is_constructed == False:
			self.construct()
		if other_aiarray.is_constructed == False:
			other_aiarray.construct()

		matched_ail, indices = self._filter_exact_match(other_aiarray)

		return matched_ail, indices

	
	cdef np.ndarray _has_exact_match(LabeledIntervalArray self, LabeledIntervalArray other_aiarray):
		"""
		"""

		cdef LabeledIntervalArray matched_ail = LabeledIntervalArray()
		cdef LabeledInterval query_interval
		cdef LabeledInterval interval
		cdef bint present = False
		cdef int i
		cdef int start_i
		cdef int end_i
		cdef np.ndarray has_match = np.zeros(len(self), dtype=bool)
		cdef dict label_counts = self.label_counts
		cdef np.ndarray label_index = self.label_index

		for query_interval in other_aiarray:
			try:
				if label_counts[query_interval.label] > 0:
					start_i = label_index[self.label_map[query_interval.label]]
					if self.label_map[query_interval.label] + 1 == self.ail.nl:
						end_i = self.ail.nr
					else:
						end_i = label_index[self.label_map[query_interval.label] + 1]

					for i in range(start_i, end_i):
						interval = self[i]
						if interval.label == query_interval.label and interval.start == query_interval.start and interval.end == query_interval.end:
							has_match[i] = True
							break
			except KeyError:
				continue

		return has_match

	def has_exact_match(self, LabeledIntervalArray other_aiarray):
		"""
		Determine which intervals are present
		"""

		# Check if object is still open
		if self.is_closed or other_aiarray.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if objects are constructed
		if self.is_constructed == False:
			self.construct()
		#if other_aiarray.is_constructed == False:
			#other_aiarray.construct()

		# Find matches
		cdef np.ndarray has_match = self._has_exact_match(other_aiarray)

		return has_match


	cdef int _index_with_aiarray(LabeledIntervalArray self, LabeledIntervalArray other_aiarray):
		"""
		"""

		# Iterate over ail
		cdef int label_start
		cdef int position_start
		cdef int position_end

		# Determine label indices
		cdef int *label_index = <int *>malloc(other_aiarray.ail.nl * sizeof(int))
		get_label_index_array(other_aiarray.ail, label_index)

		cdef uint16_t label_code
		cdef uint16_t other_label_code

		cdef int i
		for i in range(self.ail.nr):
			# Set label codes
			label_code = self.ail.interval_list[i].label
			other_label_code = other_aiarray.label_map[self.rev_label_map[label_code]]

			# Set ail1 start to start position in ail2
			position_start = self.ail.interval_list[i].start
			# Check position
			if position_start < 0 or position_start >= other_aiarray.ail.nr:
				return 1

			label_start = label_index[other_label_code]
			self.ail.interval_list[i].start = other_aiarray.ail.interval_list[label_start + position_start].start

			# Set ail1 end to start position in ail2
			position_end = self.ail.interval_list[i].end - 1
			# Check position
			if position_end < 0 or position_end >= other_aiarray.ail.nr:
				return 1

			self.ail.interval_list[i].end = other_aiarray.ail.interval_list[label_start + position_end].end


			#print("i: %d, start: %d, end: %d, label: %d, label2: %d, label_start: %d\n", i, position_start, position_end, label_code, other_label_code, label_start)

		# Change range
		for i in range(self.ail.nl):
			position_start = self.ail.first[i]
			position_end = self.ail.last[i] - 1
			label_start = label_index[i]
			self.ail.first[i] = other_aiarray.ail.interval_list[label_start + position_start].start
			self.ail.last[i] = other_aiarray.ail.interval_list[label_start + position_end].end - 1

		free(label_index)

		return 0


	def index_with_aiarray(self, LabeledIntervalArray other_aiarray):
		"""
		"""

		return_code = self._index_with_aiarray(other_aiarray)

		if return_code == 1:
			raise NameError("Failed to run properly. Values are likely currupted now.")


	cdef void _get_locs(LabeledIntervalArray self, uint8[::1] locs_view, char *label_names, int label_str_len, int n_labels):
		"""
		"""

		get_label_array_presence(self.ail, &label_names[0], n_labels, &locs_view[0], label_str_len)
	
	def get_locs(self, labels):
		"""
		"""

		cdef np.ndarray locs = np.zeros(self.size, dtype=bool)
		cdef uint8[::1] locs_view = np.frombuffer(locs, dtype=np.uint8)

		# Check that labels are bytes
		if isinstance(labels, np.ndarray) == False:
			labels = np.array(labels)
		byte_labels = labels.astype(bytes)

		# Intersect from array
		self._get_locs(locs_view, np.PyArray_BYTES(byte_labels), byte_labels.itemsize, len(labels))

		return locs

	
	def copy(self):
		"""
		Copy LabeledIntervalArray
		"""

		cdef LabeledIntervalArray ail_copied = LabeledIntervalArray()
		cdef labeled_aiarray_t * c_ail_copied = labeled_aiarray_copy(self.ail)
		ail_copied.set_list(c_ail_copied)

		return ail_copied

	
	def close(self):
		"""
		Close object and clear memory
		"""

		# Free labeled_interval_list memory
		if self.ail:
			labeled_aiarray_destroy(self.ail)
		self.ail = NULL
		
		self.is_closed = True