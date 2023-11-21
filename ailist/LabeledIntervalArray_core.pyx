#cython: embedsignature=True
#cython: profile=False

import pandas as pd
import os
import sys
import numpy as np
cimport numpy as np
import math
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


cdef class LabeledInterval(object):
	"""
	Wrapper of C interval_t and label

	:class:`~ailist.LabeledInterval` stores an interval

	"""

	def __init__(self,
				 start = None,
				 end = None,
				 id_value = None,
				 label = None):
		"""
		Initialize LabeledInterval

		Parameters
		----------
			start : int
				Starting position [default = None]
			end : int
				Ending position [default = None]
			id_value : int
				ID [defualt = None]
			label : str
				Label

		Returns
		-------
			None

		"""

		if start is not None:
			if id_value is None:
				id_value = 0

			# Create interval
			self.i = interval_init(start, end, id_value)
			self._label = label

	# Set the interval
	cdef void set_i(LabeledInterval self,
					interval_t *i,
					str label):
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
		self._label = label


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
	def id_value(self):
		"""
		ID of interval
		"""
		return self.i.id_value

	@property
	def label(self):
		"""
		Label of interval
		"""
		return self._label


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
			if self.label == other.label:
				if other.start < self.i.end and other.end > self.i.start:
					is_equal = True
				else:
					is_equal = False
			else:
				is_equal = False

		return is_equal


	def __str__(self):
		format_string = "Interval(%d-%d, %s)" % (self.start, self.end, self.label)
		return format_string


	def __repr__(self):
		format_string = "Interval(%d-%d, %s)" % (self.start, self.end, self.label)
		return format_string


	def to_array(self):
		"""
		"""

		laia = LabeledIntervalArray()
		laia.add(self.start, self.end, self.label)

		return laia


#@cython.auto_pickle(True)
cdef class LabeledIntervalArray(object):
	"""
	Wrapper for C labeled_aiarray_t

	:class:`~ailist.LabeledIntervalArray` stores a list of intervals
	"""

	def __cinit__(self):
		"""
		C Initialize LabeledIntervalArray object
		(Runs after __init__)
		"""

		# Initialize C level attributes
		self.laia = labeled_aiarray_init()
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
		Free LabeledIntervalArray.laia
		"""

		labeled_aiarray_destroy(self.laia)


	@property
	def size(self):
		"""
		Number of intervals in LabeledIntervalArray
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		return self.laia.total_nr

	@property
	def unique_labels(self):
		"""
		Array of unique labels
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Iterate over keys
		cdef const char *label_name

		labels = []
		cdef int i
		for i in range(self.laia.n_labels):
			label_name = self.laia.labels[i].name
			labels.append(label_name.decode())

		# Convert to numpy array
		labels = np.array(labels)

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
		cdef const char *label_name
		cdef int i
		for i in range(self.laia.n_labels):
			label_name = self.laia.labels[i].name
			counts[label_name.decode()] = self.laia.labels[i].ail.nr

		return counts


	@property
	def label_ranges(self):
		"""
		Ranges(start,  end) for each label
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Iterate over first and last
		cdef dict ranges = {}
		cdef const char *label_name
		cdef int i
		for i in range(self.laia.n_labels):
			label_name = self.laia.labels[i].name
			ranges[label_name.decode()] = (self.laia.labels[i].ail.first, self.laia.labels[i].ail.last)

		return ranges


	@property
	def is_constructed(self):
		"""
		Whether LabeledIntervalArray is constructed or not
		"""

		if self.laia.is_constructed == 0:
			return False
		else:
			return True


	@property
	def starts(self):
		"""
		Start values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Extract start values
		cdef long[::1] starts = np.zeros(self.size, dtype=np.int_)
		labeled_aiarray_extract_starts(self.laia, &starts[0])

		return np.asarray(starts, dtype=np.int_)


	@property
	def ends(self):
		"""
		End values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Extract end values
		cdef long[::1] ends = np.zeros(self.size, dtype=np.int_)
		labeled_aiarray_extract_ends(self.laia, &ends[0])

		return np.asarray(ends, dtype=np.int_)


	@property
	def labels(self):
		"""
		Label values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Extract end values
		cdef np.ndarray labels = np.zeros(self.size, dtype=object)
		cdef int i
		cdef LabeledInterval interval
		for i, interval in enumerate(self):
			labels[i] = interval.label

		return labels


	cdef ailist_t *_get_ail(LabeledIntervalArray self, char *label_name):
		# Get label
		cdef int32_t t = get_label(self.laia, label_name)

		# Check if label present
		cdef ailist_t *ail
		if (t != -1):
			ail = ailist_copy(self.laia.labels[t].ail)
		else:
			ail = ailist_init()

		return ail

	def get_ail(self, label):
		cdef bytes b_label = label.encode()
		cdef AIList ail = AIList()
		c_ail = self._get_ail(b_label)
		ail.set_list(c_ail)

		return ail


	def set_ail(self, AIList ail, str label):
		cdef bytes b_label = label.encode()
		#cdef ailist_t *copied_ail = ailist_copy(ail.c_ailist)
		labeled_aiarray_append_ail(self.laia, ail.c_ailist, b_label)

		return


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

		# Check if is constructed
		if self.is_constructed is False:
			self.construct()

		# Iterate over labels in ail
		cdef const char *label_name
		cdef labeled_aiarray_iter_t *laia_iter
		cdef labeled_interval_t *cintv
		cdef LabeledInterval output_interval
		cdef bytes label_bytes

		# Create iterator
		laia_iter = labeled_aiarray_iter_init(self.laia)
		while labeled_aiarray_iter_next(laia_iter) != 0:
			cintv = laia_iter.intv
			# Create LabeledInterval wrapper
			label_name = cintv.name
			label_bytes = label_name
			output_interval = LabeledInterval()
			output_interval.set_i(cintv.i, label_bytes.decode())
			yield output_interval

		labeled_aiarray_iter_destroy(laia_iter)


	def __hash__(self):
		"""
		Get hash value
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		return hash(self)


	cdef labeled_aiarray_t *_array_index(LabeledIntervalArray self,
										 const long[::1] ids):
		cdef int length = len(ids)
		cdef labeled_aiarray_t *cindexed_aiarray

		cindexed_aiarray = labeled_aiarray_slice_index(self.laia, &ids[0], length)

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
		cdef int slice_start
		cdef int slice_end
		cdef int slice_step
		cdef bytes label_name
		cdef uint8[::1] bool_index

		try:
			# Test is present
			iter(key)
			# Iterate over key
			indexed_aiarray = LabeledIntervalArray()

			# Check if keys are booleans
			if isinstance(key[0], np.bool_):
				# Check array is the same size
				if len(key) != self.size:
					raise IndexError("Index and LabeledIntervalArray of different sizes.")

				bool_index = key
				cindexed_aiarray = labeled_aiarray_slice_bool(self.laia, &bool_index[0])

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
				cindexed_aiarray = labeled_aiarray_slice_range(self.laia, slice_start,
																slice_end, slice_step)
				# Wrap
				indexed_aiarray.set_list(cindexed_aiarray)

				return indexed_aiarray

			# Check if key is greater than length
			if key >= self.laia.total_nr:
				raise IndexError("Value larger than LabeledIntervalArray length")

			# Check if negative
			if key < 0:
				key = self.laia.total_nr + key

			# Create LabeledInterval wrapper
			output_interval = LabeledInterval()
			coutput_interval = labeled_aiarray_get_index(self.laia, key)
			label_name = coutput_interval.name
			output_interval.set_i(coutput_interval.i, label_name.decode())

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
		if self.laia.total_nr > 10:
			for i in range(5):
				repr_string += "   (%d-%d, %s)\n" % (self[i].start, self[i].end, self[i].label)
			repr_string += "   ...\n"
			for i in range(-5, 0, 1):
				repr_string += "   (%d-%d, %s)\n" % (self[i].start, self[i].end, self[i].label)
		else:
			for i in range(self.laia.total_nr):
				repr_string += "   (%d-%d, %s)\n" % (self[i].start, self[i].end, self[i].label)

		return repr_string

	
	def __getstate__(self):
		"""
		Get state of LabeledIntervalArray object
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Get state
		state = self.to_dict()

		return state


	def __setstate__(self, state):
		"""
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Set state
		self.from_dict(state)

		return None


	def __sub__(self, LabeledIntervalArray query_laia):
		"""
		Subtract values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		return self.subtract(query_laia)

	
	def __add__(self, LabeledIntervalArray query_laia):
		"""
		Common values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		return self.common(query_laia)


	def __or__(self, LabeledIntervalArray query_laia):
		"""
		Common values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		return self.append(query_laia)


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

		labeled_aiarray_destroy(self.laia)

		# Replace new lebeled_aiarray
		self.laia = input_list
		self.is_closed = False

	#===========================================
	#             FUNCTION: get
	#===========================================

	#-------------------------------------------
	#              get: CYTHON
	#-------------------------------------------

	cdef labeled_aiarray_t *get_labels(LabeledIntervalArray self, const char *label_names,
										int str_label_len, int length):
		cdef labeled_aiarray_t *cintervals = labeled_aiarray_get_label_array(self.laia,
																			&label_names[0],
																			length, str_label_len)

		return cintervals

	cdef overlap_label_index_t *get_labels_with_index(LabeledIntervalArray self,
														const char *label_names,
														int str_label_len, int length):
		cdef overlap_label_index_t *cintervals = labeled_aiarray_get_label_array_with_index(self.laia,
																							&label_names[0],
																							length,
																							str_label_len)

		return cintervals

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

		# Determine where labels are
		cdef bytes label_name = label.encode()
		cdef uint32_t t = get_label(self.laia, label_name)
		cdef label_t *p = &self.laia.labels[t]
		cdef int i
		for i in range(p.ail.nr):
			index[i] = p.ail.interval_list[i].id_value

		return np.asarray(index)


	cdef np.ndarray _get_index_multi(LabeledIntervalArray self, np.ndarray labels):
		"""
		"""

		# Find intervals with label
		cdef int n = 0
		#cdef str label
		for label in labels:
			n += self.label_counts[label]

		cdef long[::] index = np.zeros(n, dtype=np.int_)
		cdef int i
		cdef int j = 0
		cdef bytes label_name
		cdef uint32_t t
		cdef label_t *p

		# Iterate over labels
		for label in labels:
			# Determine where labels are
			label_name = label.encode()
			t = get_label(self.laia, label_name)
			p = &self.laia.labels[t]

			# Iterate over intervals
			for i in range(p.ail.nr):
				index[j] = p.ail.interval_list[i].id_value
				j += 1

		return np.asarray(index)

	#-------------------------------------------
	#              get: PYTHON
	#-------------------------------------------

	def get(self,
			label,
			return_intervals = True,
			return_index = False):
		"""
		Get :class:`~aiarray.LabeledIntervalArray` for given label

		Parameters
		----------
			label : str
				Label to get
			return_intervals : bool
				Flag to return intervals
			return_index : bool
				Flag to return index array

		Returns
		-------
			intervals : LabeledIntervalArray
				Intervals with given label
			indices : numpy.ndarray
				Array of indices

		See Also
		--------
		LabeledIntervalArray.from_array: Add intervals from arrays
		LabeledIntervalArray.construct: Construct LabeledIntervalArray
		LabeledIntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from ailist import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.add(1, 2, 'a')
		>>> ail.add(3, 4, 'a')
		>>> ail.add(3, 6, 'a')
		>>> ail.add(3, 6, 'b')
		>>> ail.get("b")
		LabeledIntervalArray
   			(3-6, b)
		>>> ail.get(["b","a"])
		LabeledIntervalArray
			(3-6, b)
			(1-2, a)
			(3-4, a)
			(3-6, a)
		>>> ail.get(["b","a"], return_index=True)
		(LabeledIntervalArray
			(3-6, b)
			(1-2, a)
			(3-4, a)
			(3-6, a),
		array([3, 0, 1, 2]))
		>>> ail.get(["b","a"], return_index=True, return_intervals=False)
		array([3, 0, 1, 2])

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Find intervals with label
		cdef LabeledIntervalArray intervals = LabeledIntervalArray()
		cdef labeled_aiarray_t *cintervals
		cdef overlap_label_index_t *cintervals_index
		cdef int n_labels
		cdef np.ndarray labels
		cdef np.ndarray byte_labels
		cdef np.ndarray indices
		cdef bytes label_name
		if isinstance(label, str):
			label_name = label.encode()
			if return_intervals:
				if return_index:
					cintervals_index = labeled_aiarray_get_label_with_index(self.laia, label_name)
					# Wrap intervals
					intervals.set_list(cintervals_index.laia)

					# Create numpy array from C pointer
					indices = pointer_to_numpy_array(cintervals_index.indices, cintervals_index.size)

					return intervals, indices

				cintervals = labeled_aiarray_get_label(self.laia, label_name)
				# Wrap intervals
				intervals.set_list(cintervals)

				return intervals

			elif return_index:
				indices = self._get_index(str(label))

				return indices

		else:
			try:
				iter(label)
				#label_array = np.array([l for l in label]).astype(str)
				# Add array intervals
				labels = np.array(label)
				n_labels = len(labels)
				byte_labels = labels.astype(bytes)

				if return_intervals:
					if return_index:
						cintervals_index = self.get_labels_with_index(np.PyArray_BYTES(byte_labels),
																		byte_labels.itemsize, n_labels)
						# Wrap intervals
						intervals.set_list(cintervals_index.laia)

						# Create numpy array from C pointer
						indices = pointer_to_numpy_array(cintervals_index.indices, cintervals_index.size)

						return intervals, indices

					cintervals = self.get_labels(np.PyArray_BYTES(byte_labels), byte_labels.itemsize,
												 n_labels)
					# Wrap intervals
					intervals.set_list(cintervals)

					return intervals

				elif return_index:
					indices = self._get_index_multi(labels)

					return indices

			except TypeError:
				raise TypeError(" Could not determine label type.")


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
		LabeledIntervalArray.construct: Construct LabeledIntervalArray

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
		if self.is_constructed is False:
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
		LabeledIntervalArray.construct: Construct LabeledIntervalArray

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
		labeled_aiarray_add(self.laia, start, end, label_name)

	cdef void _from_array(LabeledIntervalArray self, const long[::1] starts, const long[::1] ends,
							const char *label_names, int array_length, int label_str_len):

		# Run C function
		labeled_aiarray_from_array(self.laia, &starts[0], &ends[0], &label_names[0],
									array_length, label_str_len)

		return

	def add(self, start, end, label):
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
		LabeledIntervalArray.construct: Construct LabeledIntervalArray
		LabeledIntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from ailist import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.add(1, 2, 'a')
		>>> ail.add(3, 4, 'a')
		>>> ail.add(3, 6, 'a')
		>>> ail
		LabeledIntervalArray
		   (1-2, 'a')
		   (3-4, 'a')
		   (3-6, 'a')

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check that object is not frozen
		if self.is_frozen:
			raise TypeError("LabeledIntervalArray is frozen and currently immutatable. "
							"Try '.unfreeze()' to reverse.")

		# Static type variables
		cdef int array_length
		cdef np.ndarray byte_labels

		if isinstance(start, int):
			# Check interval
			if start > end:
				raise IndexError("Start is larger than end.")

			# Insert interval
			self._insert(start, end, label.encode())

		elif isinstance(start, np.ndarray):
			# Add array intervals
			array_length = len(start)
			if array_length == 0:
				return
			byte_labels = label.astype(bytes)

			self._from_array(start, end, np.PyArray_BYTES(byte_labels), array_length,
								byte_labels.itemsize)

		elif isinstance(start, np.integer):
			# Check interval
			if start > end:
				raise IndexError("Start is larger than end.")

			# Insert interval
			self._insert(int(start), int(end), label.encode())

		else:
			raise TypeError("Start must be int or np.ndarray.")

		return


	cdef void _append(LabeledIntervalArray self, LabeledIntervalArray other_laia):

		# Run C function
		labeled_aiarray_append(self.laia, other_laia.laia)

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
		LabeledIntervalArray.construct: Construct LabeledIntervalArray
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
			raise TypeError("LabeledIntervalArray is frozen and currently immutatable. "
							"Try '.unfreeze()' to reverse.")

		self._append(other_ail)


	cdef void _construct(LabeledIntervalArray self, int min_length):
		# Contruct
		labeled_aiarray_construct(self.laia, min_length)
		labeled_aiarray_cache_id(self.laia)

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
		if self.is_constructed is False:
			self._construct(min_length)
		else:
			pass


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

		See Also
		--------
		LabeledIntervalArray.sort: Sort intervals inplace
		LabeledIntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from ailist import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.add(1, 2, 'a')
		>>> ail.add(3, 4, 'a')
		>>> ail.add(2, 6, 'a')
		>>> ail
		LabledIntervalArray
		   (1-2, 'a')
		   (3-4, 'a')
		   (2-6, 'a')
		>>> s_iter = ail.iter_sorted()
		>>> for i in s_iter:
		>>>		print(i)
		Interval(1-2, a)
		Interval(2-6, a)
		Interval(3-4, a)

		"""

		# Check if is constructed
		if self.is_constructed is False:
			self.construct()

		# Iterate over labels in ail
		cdef const char *label_name
		cdef label_sorted_iter_t *laia_iter
		cdef interval_t *cintv
		cdef LabeledInterval output_interval
		cdef bytes label_bytes

		for i in range(self.laia.n_labels):
			# Create sorted iterators
			label_name = self.laia.labels[i].name
			laia_iter = label_sorted_iter_init(self.laia, label_name)
			while label_sorted_iter_next(laia_iter) != 0:
				cintv = laia_iter.intv
				# Create LabeledInterval wrapper
				label_bytes = label_name
				output_interval = LabeledInterval()
				output_interval.set_i(cintv, label_bytes.decode())
				yield output_interval

			label_sorted_iter_destroy(laia_iter)


	def from_dict(self, 
				  dict interval_dict):
		"""
		Construct LabeledIntervalArray from dictionary

		Parameters
		----------
			interval_dict : dict
				Dictionary of intervals

		Returns
		-------
			None

		See Also
		--------
		LabeledIntervalArray.sort: Sort intervals inplace
		LabeledIntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from ailist import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.from_dict({'a': [(1, 2), (3, 4), (2, 6)]})
		>>> ail
		LabeledIntervalArray
		   (1-2, a)
		   (3-4, a)
		   (2-6, a)

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if already constructed
		if self.is_constructed is False:
			self.construct()
		else:
			pass

		# Iterate over labels in dict
		for label_name in interval_dict:
			self.set_ail(interval_dict[label_name], str(label_name))

		return None


	def to_dict(self):
		"""
		Convert LabeledIntervalArray to dictionary

		Parameters
		----------
			None

		Returns
		-------
			interval_dict : dict
				Dictionary of intervals

		See Also
		--------
		LabeledIntervalArray.sort: Sort intervals inplace
		LabeledIntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from ailist import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.add(1, 2, 'a')
		>>> ail.add(3, 4, 'a')
		>>> ail.add(2, 6, 'a')
		>>> ail
		LabeledIntervalArray
		   (1-2, a)
		   (3-4, a)
		   (2-6, a)
		>>> ail.to_dict()
		{'a': [(1, 2), (2, 6), (3, 4)]}

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Get ail
		interval_dict = {}
		for label in self.unique_labels:
			interval_dict[label] = self.get_ail(label)

		return interval_dict


	def iter_intersect(self,
					   LabeledIntervalArray query_laia,
					   return_intervals = True,
					   return_index = False):
		"""
		"""

		# Check if is constructed
		if self.is_constructed is False:
			self.construct()

		cdef LabeledIntervalArray overlaps
		cdef LabeledInterval i
		for i in query_laia:
			if return_intervals:
				if return_index:
					overlaps, index = self.intersect(i.start, i.end, i.label,
													return_intervals=True, return_index=True)
					yield overlaps, index
				else:
					overlaps = self.intersect(i.start, i.end, i.label,
											return_intervals=True, return_index=False)
					yield overlaps

			elif return_index:
				index = self.intersect(i.start, i.end, i.label,
										return_intervals=False, return_index=True)
				yield index


	cdef labeled_aiarray_t *_intersect(LabeledIntervalArray self, int start, int end,
										const char *label_name):
		# Call C function
		cdef labeled_aiarray_t *overlaps = labeled_aiarray_init()
		labeled_aiarray_query(self.laia, overlaps, label_name, start, end)

		return overlaps

	cdef labeled_aiarray_t *_intersect_from_array(LabeledIntervalArray self, const long[::1] starts,
													const long[::1] ends, const char *labels, int label_str_len):
		cdef int length = len(starts)
		cdef labeled_aiarray_t *overlaps = labeled_aiarray_init()
		labeled_aiarray_query_from_array(self.laia, overlaps, &labels[0], &starts[0], &ends[0],
										length, label_str_len)

		return overlaps

	cpdef _intersect_from_array_only_index(LabeledIntervalArray self, const long[::1] starts,
											const long[::1] ends, const char *labels, int label_str_len):

		cdef int length = len(starts)
		cdef array_query_t *total_overlaps = labeled_aiarray_query_index_from_array(self.laia, &labels[0],
																					&starts[0], &ends[0],
																					length, label_str_len)

		cdef np.ndarray ref_index = pointer_to_numpy_array(total_overlaps.ref_index,
															total_overlaps.size)
		cdef np.ndarray query_index = pointer_to_numpy_array(total_overlaps.query_index,
															total_overlaps.size)

		return ref_index, query_index

	cpdef _intersect_from_array_with_index(LabeledIntervalArray self, const long[::1] starts,
											const long[::1] ends, const char *labels, int label_str_len):

		cdef int length = len(starts)
		cdef overlap_label_index_t *total_overlaps = overlap_label_index_init()
		labeled_aiarray_query_with_index_from_array(self.laia, total_overlaps, &labels[0],
													&starts[0], &ends[0], length, label_str_len)

		# Create numpy array from C pointer
		cdef np.ndarray indices = pointer_to_numpy_array(total_overlaps.indices, total_overlaps.size)
		cdef LabeledIntervalArray overlaps = LabeledIntervalArray()
		overlaps.set_list(total_overlaps.laia)

		return overlaps, indices

	cpdef _intersect_with_index(LabeledIntervalArray self, int start, int end, const char *label_name):
		# Intersect with interval
		cdef overlap_label_index_t *total_overlaps = overlap_label_index_init()
		labeled_aiarray_query_with_index(self.laia, label_name, total_overlaps, start, end)

		# Create numpy array from C pointer
		cdef np.ndarray indices = pointer_to_numpy_array(total_overlaps.indices, total_overlaps.size)
		cdef LabeledIntervalArray overlaps = LabeledIntervalArray()
		overlaps.set_list(total_overlaps.laia)

		return overlaps, indices

	def intersect(self,
				  start,
				  end,
				  label,
				  return_intervals = True,
				  return_index = False):
		"""
		Find intervals overlapping given range

		Parameters
		----------
			start : int | np.ndarray
				Start position of query range
			end : int | np.ndarray
				End position of query range
			label : str | np.ndarray
				Label of quert range

		Returns
		-------
			overlaps : LabeledIntervalArray
				Overlapping intervals

		.. warning::
			This requires :func:`~aiarray.LabeledIntervalArray.construct` and will run it if not already run.
			This will re-sort intervals inplace is ail.track_index = False.

		See Also
		--------
		LabeledIntervalArray.construct: Construct LabeledIntervalArray
		LabeledIntervalArray.add: Add interval to LabeledIntervalArray
		LabeledIntervalArray.intersect_index: Find interval indices overlapping given range
		LabeledIntervalArray.intersect_from_array: Find interval indices overlapping given ranges

		Examples
		--------
		>>> from ailist import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.add(1, 2, 'a')
		>>> ail.add(3, 4, 'a')
		>>> ail.add(3, 6, 'a')
		>>> ail.add(3, 6, 'b')
		>>> ail
		LabeledIntervalArray
		   (1-2, a)
		   (3-4, a)
		   (3-6, a)
		   (3-6, b)
		>>> q = ail.intersect(2, 10, 'a')
		>>> q
		LabeledIntervalArray
		   (3-4, a)
		   (3-6, a)

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if is constructed
		if self.is_constructed is False:
			self.construct()

		# Intersect
		cdef np.ndarray indices
		cdef labeled_aiarray_t *i_list
		cdef LabeledIntervalArray overlaps

		if isinstance(start, np.ndarray):

			# Check that labels are bytes
			if isinstance(label, str):
				byte_labels = np.repeat(label, len(start), dtype=bytes)
			else:
				byte_labels = label.astype(bytes)

			if return_intervals:
				if return_index:
					# Intersect from array
					overlaps, indices = self._intersect_from_array_with_index(start, end,
																			  np.PyArray_BYTES(byte_labels),
																			  byte_labels.itemsize)
					return overlaps, indices

				else:
					i_list = self._intersect_from_array(start, end,
														np.PyArray_BYTES(byte_labels),
														byte_labels.itemsize)
					overlaps = LabeledIntervalArray()
					overlaps.set_list(i_list)
					return overlaps

			elif return_index:
				# Intersect from array
				ref_index, query_index = self._intersect_from_array_only_index(start, end,
																			   np.PyArray_BYTES(byte_labels),
																			   byte_labels.itemsize)
				return ref_index, query_index

		if isinstance(start, int):

			if return_intervals:
				if return_index:
					overlaps, indices = self._intersect_with_index(start, end, label.encode())
					return overlaps, indices

				else:
					i_list = self._intersect(start, end, label.encode())
					overlaps = LabeledIntervalArray()
					overlaps.set_list(i_list)
					return overlaps

			elif return_index:
				overlaps, indices = self._intersect_with_index(start, end, label.encode())
				return indices


	cdef void _has_hit_from_array(LabeledIntervalArray self,
								  const long[::1] starts,
								  const long[::1] ends,
								  uint8[::1] has_hit,
								  const char *labels,
								  int label_str_len):

		# Call C function
		cdef int length = len(starts)
		labeled_aiarray_query_has_hit_from_array(self.laia,
												 &labels[0],
												 &starts[0],
												 &ends[0],
												 length,
												 label_str_len,
												 &has_hit[0])

		return

	def has_hit(self, start, end, label):
		"""
		Find interval indices overlapping given ranges

		Parameters
		----------
			starts : int | numpy.ndarray {long}
				Start positions of intervals
			ends : int | numpy.ndarray {long}
				End positions of intervals
			labels : int | numpy.ndarray {str}
				Labels of intervals

		Returns
		-------
			has_hit : np.ndarray {bool}
				Bool array indicated overlap detected

		.. warning::
			This requires :func:`~aiarray.LabeledIntervalArray.construct` and will run it if not already run.

		See Also
		--------
		LabeledIntervalArray.construct: Construct LabeledIntervalArray
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
		if self.is_constructed is False:
			self.construct()

		# Initialize variables
		cdef uint8_t has_hit_single_c = 0
		cdef np.ndarray has_hit
		cdef uint8[::1] has_hit_mem
		cdef bytes byte_label

		# Intersect
		if isinstance(start, np.ndarray):
			# Check that labels are bytes
			has_hit = np.zeros(len(start), dtype=bool)
			has_hit_mem = has_hit
			byte_labels = label.astype(bytes)
			self._has_hit_from_array(start, end, has_hit_mem, np.PyArray_BYTES(byte_labels),
									byte_labels.itemsize)

			return has_hit

		elif isinstance(start, int):
			# Check that labels are bytes
			byte_label = str(label).encode()
			labeled_aiarray_query_has_hit(self.laia, byte_label, &has_hit_single_c, start, end)
			if has_hit_single_c == 1:
				return True
			else:
				return False


	cdef labeled_aiarray_t *_intersect_from_labeled_aiarray(LabeledIntervalArray self,
															LabeledIntervalArray laia):
		# Intersect with other LabeledIntervalArray
		cdef labeled_aiarray_t *overlaps = labeled_aiarray_init()
		labeled_aiarray_query_from_labeled_aiarray(self.laia, laia.laia, overlaps)

		return overlaps

	cpdef _intersect_index_from_labeled_aiarray(LabeledIntervalArray self, LabeledIntervalArray laia):
		# Intersect with other LabeledIntervalArray
		cdef array_query_t *total_overlaps = array_query_init()
		labeled_aiarray_query_index_from_labeled_aiarray(self.laia, laia.laia, total_overlaps)

		# Create numpy array from C pointer
		cdef np.ndarray ref_index = pointer_to_numpy_array(total_overlaps.ref_index,
															total_overlaps.size)
		cdef np.ndarray query_index = pointer_to_numpy_array(total_overlaps.query_index,
																total_overlaps.size)

		return ref_index, query_index

	cpdef _intersect_with_index_from_labeled_aiarray(LabeledIntervalArray self,
														LabeledIntervalArray laia2):
		# Intersect with interval
		cdef overlap_label_index_t *total_overlaps = overlap_label_index_init()
		labeled_aiarray_query_with_index_from_labeled_aiarray(self.laia, laia2.laia, total_overlaps)

		# Create numpy array from C pointer
		print("total_overlaps.size", total_overlaps.size, flush=True)
		cdef np.ndarray indices = pointer_to_numpy_array(total_overlaps.indices, total_overlaps.size)
		cdef LabeledIntervalArray overlaps = LabeledIntervalArray()
		overlaps.set_list(total_overlaps.laia)

		return overlaps, indices

	def intersect_from_LabeledIntervalArray(self,
											LabeledIntervalArray ail_query,
											return_intervals = True,
											return_index = False):
		"""
		Find interval indices overlapping given ranges

		Parameters
		----------
			ail_query : LabeledIntervalArray
				Intervals to query

		Returns
		-------
			ref_index : np.ndarray{int}
				Overlapping interval indices from IntervalArray
			query_index : np.ndarray{int}
				Overlapping interval indices from query IntervalArray

		See Also
		--------
		LabeledIntervalArray.construct: Construct IntervalArray
		LabeledIntervalArray.add: Add interval to IntervalArray
		LabeledIntervalArray.intersect: Find intervals overlapping given range
		LabeledIntervalArray.intersect_from_array: Find interval indices overlapping given range

		Examples
		--------
		>>> from ailist import LabeledIntervalArray
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
		>>> ail2 = LabeledIntervalArray()
		>>> ail2.add(1, 2, "a")
		>>> ail2.add(3, 6, "b")
		>>> ail2.add(3, 6, "a")
		>>> ail2
		IntervalArray
		  range: (1-6)
		    (1-2, 0)
		    (3-6, 1)
		>>> q = ail1.intersect_from_LabeledIntervalArray(ail2)
		>>> q
		(array([0, 1, 1]), array([0, 2, 1]))

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if object is constructed
		if self.is_constructed is False:
			self.construct()

		# Type variables
		cdef labeled_aiarray_t *i_list
		cdef LabeledIntervalArray overlaps
		cdef np.ndarray indices
		cdef np.ndarray query_index
		cdef np.ndarray ref_index

		# Intersect
		if return_intervals:
			if return_index:
				overlaps, indices = self._intersect_with_index_from_labeled_aiarray(ail_query)
				return overlaps, indices
			else:
				i_list = self._intersect_from_labeled_aiarray(ail_query)
				overlaps = LabeledIntervalArray()
				overlaps.set_list(i_list)
				return overlaps

		elif return_index:
			query_index, ref_index = self._intersect_index_from_labeled_aiarray(ail_query)
			return query_index, ref_index


	cdef void _nhits_from_array(LabeledIntervalArray self,
								const long[::1] starts,
								const long[::1] ends,
								long[::1] nhits,
								const char *labels,
								int label_str_len):

		# Call C function
		cdef int length = len(starts)
		labeled_aiarray_nhits_from_array(self.laia, &labels[0], &starts[0], &ends[0], length,
										label_str_len, &nhits[0])

		return

	cdef void _nhits_from_array_length(LabeledIntervalArray self, const long[::1] starts,
										const long[::1] ends, long[::1] nhits,
										const char *labels, int label_str_len,
										int min_length, int max_length):
		# Initialize hits
		cdef int length = starts.size

		# Calculate distribution
		labeled_aiarray_nhits_from_array_length(self.laia, &labels[0], &starts[0], &ends[0],
												length, label_str_len, &nhits[0],
												min_length, max_length)

		return

	def nhits(self, start, end, label, min_length=None, max_length=None):
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

		.. warning::
			This requires :func:`~aiarray.LabeledIntervalArray.construct` and will run it if not already run.

		See Also
		--------
		LabeledIntervalArray.construct: Construct LabeledIntervalArray
		LabeledIntervalArray.add: Add interval to LabeledIntervalArray
		LabeledIntervalArray.intersect: Find intervals overlapping given range

		Examples
		--------
		>>> from aiarray import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.add(1, 2, 'a')
		>>> ail.add(3, 4, 'a')
		>>> ail.add(2, 6, 'a')
		>>> ail
		LabeledIntervalArray
		   (1-2, 'a')
		   (3-4, 'a')
		   (2-6, 'a')
		>>> q = ail.nhits(2, 10, 'a')
		>>> q
		2

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("aiarray object has been closed.")

		# Make sure list is constructed
		if self.is_constructed is False:
			self.construct()

		# Static type variables
		cdef np.ndarray nhits
		cdef long[::1] nhits_mem
		cdef long single_nhits = 0
		cdef bytes label_name

		# Calculate nhits
		if isinstance(start, int):
			label_name = label.encode()
			if min_length is None or max_length is None:
				labeled_aiarray_nhits(self.laia, &single_nhits, label_name, start, end)
			else:
				labeled_aiarray_nhits_length(self.laia, &single_nhits, label_name,
											 start, end, min_length, max_length)

			return single_nhits

		# Calculate nhits
		elif isinstance(start, np.ndarray):
			nhits = np.zeros(len(start), dtype=np.int_)
			nhits_mem = nhits
			byte_labels = label.astype(bytes)
			if min_length is None or max_length is None:
				self._nhits_from_array(start, end, nhits_mem, np.PyArray_BYTES(byte_labels),
										byte_labels.itemsize)
			else:
				self._nhits_from_array_length(start, end, nhits_mem, np.PyArray_BYTES(byte_labels),
												byte_labels.itemsize, min_length, max_length)

			return nhits

		else:
			raise TypeError("Could not determine given type for start.")


	cdef labeled_aiarray_t *_determine_bins(LabeledIntervalArray self, int bin_size):
		"""
		Create LabeledIntervalArray for bins
		"""

		# Initialize variables
		cdef labeled_aiarray_t *bins = labeled_aiarray_init()
		cdef int first
		cdef int first_bin_start
		cdef int last
		cdef int start
		#cdef uint16_t label
		cdef int i
		cdef int j
		cdef const char *label_name

		# Iterate over labels
		for i in range(self.laia.n_labels):
			#label = self.laia.interval_list[self._get_label_index(i)].label
			first = self.laia.labels[i].ail.first
			first_bin_start = (first // bin_size) * bin_size
			last = self.laia.labels[i].ail.last
			n_bins = math.ceil(last / bin_size) - (first // bin_size)
			label_name = self.laia.labels[i].name

			# Iterate over label bins
			for j in range(n_bins):
				start = first_bin_start + (j * bin_size)
				labeled_aiarray_add(bins, start, start + bin_size, label_name)

		return bins


	cdef void _bin_nhits(LabeledIntervalArray self, long[::1] nhits, int bin_size):
		# Determine bin hits
		labeled_aiarray_bin_nhits(self.laia, &nhits[0], bin_size)

		return

	cdef void _bin_nhits_length(LabeledIntervalArray self, long[::1] nhits, int bin_size,
								int min_length, int max_length):
		# Determine bin hits
		labeled_aiarray_bin_nhits_length(self.laia,  &nhits[0], bin_size, min_length, max_length)

		return

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

		# Initialize nhits
		cdef np.ndarray nhits = np.zeros(bins.size, dtype=np.int_)
		cdef long[::1] nhits_mem = nhits

		# Calculate nhits
		if min_length is None or max_length is None:
			self._bin_nhits(nhits_mem, bin_size)
		else:
			self._bin_nhits_length(nhits_mem, bin_size, min_length, max_length)


		return bins, nhits


	def nhits_from_LabeledIntervalArray(self, LabeledIntervalArray query_laia, min_length=None,
										max_length=None):
		"""
		Find number of intervals overlapping

		Parameters
		----------
			query_laia : LabeledIntervalArray
				Intervals to query
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
		if query_laia.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Initialize nhits
		cdef np.ndarray nhits = np.zeros(query_laia.size, dtype=np.int_)
		cdef long[::1] nhits_mem = nhits

		# Calculate nhits
		if min_length is None or max_length is None:
			labeled_aiarray_nhits_from_labeled_aiarray(self.laia, query_laia.laia, &nhits_mem[0])
		else:
			labeled_aiarray_nhits_from_labeled_aiarray_length(self.laia, query_laia.laia,
																&nhits_mem[0], min_length,
																max_length)

		return nhits


	cdef np.ndarray _wps(LabeledIntervalArray self, const char *label_name, int protection):
		# Initialize wps
		cdef uint32_t t = get_label(self.laia, label_name)
		cdef long n = self.laia.labels[t].ail.last - self.laia.labels[t].ail.first
		cdef double[::1] wps = np.zeros(n, dtype=np.double)

		# Calculate wps
		labeled_aiarray_label_wps(self.laia, &wps[0], protection, label_name)

		return np.asarray(wps)

	cdef np.ndarray _wps_length(LabeledIntervalArray self, const char *label_name, int protection,
								int min_length, int max_length):
		# Initialize wps
		cdef uint32_t t = get_label(self.laia, label_name)
		cdef long n = self.laia.labels[t].ail.last - self.laia.labels[t].ail.first
		cdef double[::1] wps = np.zeros(n, dtype=np.double)

		# Calculate wps
		labeled_aiarray_label_wps_length(self.laia, &wps[0], protection, min_length, max_length,
											label_name)

		return np.asarray(wps)

	def wps(self, int protection=60, labels=None, min_length=None, max_length=None):
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

		# Check if empty
		if self.laia.total_nr == 0:
			return None

		# Determine which labels to calculate
		if labels is None:
			labels = self.unique_labels
		elif isinstance(labels, str):
			labels = np.array([labels])
		else:
			labels = np.array(labels)

		# Check all labels present
		missing_labels = set(labels) - set(self.unique_labels)
		if len(missing_labels) > 0:
			raise KeyError("Provided label not in LabeledIntervalArray. " + str(missing_labels))

		# Get label ranges
		label_ranges = self.label_ranges

		# Convert to bytes
		labels = labels.astype(bytes)

		# Iterate over labels
		wps_results = {}
		cdef const char *label_name
		cdef np.ndarray wps
		#cdef np.bytes_ label
		for label in labels:
			label_name = label

			# Calculate wps
			if min_length is None or max_length is None:
				wps = self._wps(label_name, protection)
			else:
				wps = self._wps_length(label_name, protection, min_length, max_length)

			wps_results[label.decode()] = pd.Series(wps,
													index = range(label_ranges[label.decode()][0],
																  label_ranges[label.decode()][1]))

		return wps_results


	cdef np.ndarray _coverage(LabeledIntervalArray self, const char *label_name):
		# Initialize cov
		cdef uint32_t t = get_label(self.laia, label_name)
		cdef long n = self.laia.labels[t].ail.last - self.laia.labels[t].ail.first
		cdef double[::1] cov = np.zeros(n, dtype=np.double)

		# Calculate cov
		labeled_aiarray_label_coverage(self.laia, &cov[0], label_name)

		return np.asarray(cov)

	cdef np.ndarray _coverage_length(LabeledIntervalArray self, const char *label_name,
									int min_length, int max_length):
		# Initialize cov
		cdef uint32_t t = get_label(self.laia, label_name)
		cdef long n = self.laia.labels[t].ail.last - self.laia.labels[t].ail.first
		cdef double[::1] cov = np.zeros(n, dtype=np.double)

		# Calculate cov
		labeled_aiarray_label_coverage_length(self.laia, &cov[0], label_name,
												min_length, max_length)

		return np.asarray(cov)

	def coverage(self, labels=None, min_length=None, max_length=None):
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
			cov_results : dict {str:numpy.ndarray}
				Coverage as values

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("aiarray object has been closed.")

		# Check if empty
		if self.laia.total_nr == 0:
			return None

		# Determine which labels to calculate
		if labels is None:
			labels = self.unique_labels
		elif isinstance(labels, str):
			labels = np.array([labels])
		else:
			labels = np.array(labels)

		# Check all labels present
		missing_labels = set(labels) - set(self.unique_labels)
		if len(missing_labels) > 0:
			raise KeyError("Provided label not in LabeledIntervalArray. " + str(missing_labels))

		# Get label ranges
		label_ranges = self.label_ranges

		# Convert to bytes
		labels = labels.astype(bytes)

		# Iterate over labels
		cov_results = {}
		cdef const char *label_name
		cdef np.ndarray cov
		for label in labels:
			label_name = label

			# Calculate wps
			if min_length is None or max_length is None:
				cov = self._coverage(label_name)
			else:
				cov = self._coverage_length(label_name, min_length, max_length)

			cov_results[label.decode()] = pd.Series(cov,
													index = range(label_ranges[label.decode()][0],
																  label_ranges[label.decode()][1]))

		return cov_results


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
		if self.is_constructed is False:
			self.construct()

		# Create merged
		cdef LabeledIntervalArray merged_list = LabeledIntervalArray()
		cdef labeled_aiarray_t *merged_clist = labeled_aiarray_merge(self.laia, gap)
		merged_list.set_list(merged_clist)

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

		cdef labeled_aiarray_t *cfiltered_ail = labeled_aiarray_length_filter(self.laia, min_length,
																				max_length)
		filtered_ail.set_list(cfiltered_ail)

		return filtered_ail


	cpdef _downsample_with_index(LabeledIntervalArray self, double proportion):
		# Randomly downsample LabeledIntervalArray
		cdef overlap_label_index_t *new_intervals = labeled_aiarray_downsample_with_index(self.laia,
																							proportion)

		# Create numpy array from C pointer
		cdef np.ndarray indices = pointer_to_numpy_array(new_intervals.indices, new_intervals.size)
		cdef LabeledIntervalArray intervals = LabeledIntervalArray()
		intervals.set_list(new_intervals.laia)

		return intervals, indices

	def downsample(self,
				   double proportion,
				   return_intervals = True,
				   return_index = True):
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
		cdef LabeledIntervalArray filtered_ail
		cdef labeled_aiarray_t *cfiltered_ail
		cdef np.ndarray indices
		if return_intervals:
			if return_index:
				filtered_ail, indices = self._downsample_with_index(proportion)

				return filtered_ail, indices
			else:
				filtered_ail = LabeledIntervalArray()
				cfiltered_ail = labeled_aiarray_downsample(self.laia, proportion)
				filtered_ail.set_list(cfiltered_ail)

				return filtered_ail

		elif return_index:
			# Intersect
			filtered_ail, indices = self._downsample_with_index(proportion)

			return indices


	cdef np.ndarray _length_dist(LabeledIntervalArray self):
		# Initialize distribution
		cdef int max_length = labeled_aiarray_max_length(self.laia)
		cdef int[::1] distribution = np.zeros(max_length + 1, dtype=np.intc)

		# Calculate distribution
		labeled_aiarray_length_distribution(self.laia, &distribution[0])

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

		cdef overlap_label_index_t *matched_ail = labeled_aiarray_exact_match(self.laia,
																				other_aiarray.laia)

		# Create numpy array from C pointer
		cdef np.ndarray indices = pointer_to_numpy_array(matched_ail.indices, matched_ail.size)
		cdef LabeledIntervalArray matched = LabeledIntervalArray()
		matched.set_list(matched_ail.laia)

		return matched, indices

	def filter_exact_match(self, LabeledIntervalArray other_aiarray):
		"""
		Determine which intervals are present

		Parameters
		----------

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("AIList object has been closed.")

		# Check construction
		if self.is_constructed is False:
			self.construct()
		if other_aiarray.is_constructed is False:
			other_aiarray.construct()

		matched_ail, indices = self._filter_exact_match(other_aiarray)

		return matched_ail, indices


	cdef void _has_exact_match(LabeledIntervalArray self, LabeledIntervalArray other_aiarray,
								uint8_t[::1] has_match):
		"""
		"""

		# Call C function
		labeled_aiarray_has_exact_match(self.laia, other_aiarray.laia, &has_match[0])

		return

	def has_exact_match(self, LabeledIntervalArray other_aiarray):
		"""
		Determine which intervals are present
		"""

		# Check if object is still open
		if self.is_closed or other_aiarray.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if objects are constructed
		if self.is_constructed is False:
			self.construct()
		if other_aiarray.is_constructed is False:
			other_aiarray.construct()

		# Find matches
		cdef np.ndarray has_match = np.zeros(self.laia.total_nr, dtype=bool)
		cdef uint8_t[::1] has_match_mem = has_match
		self._has_exact_match(other_aiarray, has_match_mem)

		return has_match


	cdef void _is_exact_match(LabeledIntervalArray self, LabeledIntervalArray other_aiarray,
								uint8_t[::1] has_match1, uint8_t[::1] has_match2):
		"""
		"""

		# Call C function
		labeled_aiarray_is_exact_match(self.laia, other_aiarray.laia, &has_match1[0], &has_match2[0])

		return

	def is_exact_match(self, LabeledIntervalArray other_aiarray):
		"""
		Determine which intervals are present

		Parameters
		----------
			other_aiarray: LabeledIntervalArray
				Other LabeledIntervalArray object to compare to

		Returns
		-------
			ref_index : numpy.ndarray{int}
				Indices of intervals in self that are present in other_aiarray
			query_index : numpy.ndarray{int}
				Indices of intervals in other_aiarray that are present in self

		See Also
		--------
			:func:`has_exact_match`

		Examples
		--------
		>>> from ailist import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.add(0, 10, "a")
		>>> ail.add(20, 30, "a")
		>>> ail.add(40, 50, "b")
		>>> ail.add(60, 70, "b")
		>>> ail2 = LabeledIntervalArray()
		>>> ail2.add(0, 10, "a")
		>>> ail2.add(20, 30, "b")
		>>> ail2.add(40, 50, "c")
		>>> ref_index, query_index = ail.is_exact_match(ail2)
		"""

		# Check if object is still open
		if self.is_closed or other_aiarray.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if objects are constructed
		if self.is_constructed is False:
			self.construct()
		if other_aiarray.is_constructed is False:
			other_aiarray.construct()

		# Find matches
		cdef np.ndarray has_match1 = np.zeros(self.laia.total_nr, dtype=bool)
		cdef uint8_t[::1] has_match_mem1 = has_match1
		cdef np.ndarray has_match2 = np.zeros(other_aiarray.laia.total_nr, dtype=bool)
		cdef uint8_t[::1] has_match_mem2 = has_match2
		# Call C function
		self._is_exact_match(other_aiarray, has_match_mem1, has_match_mem2)

		return has_match1, has_match2


	cpdef _which_exact_match(LabeledIntervalArray self, LabeledIntervalArray other_aiarray):

		cdef array_query_t *total_overlaps = array_query_init()
		labeled_aiarray_which_exact_match(self.laia, other_aiarray.laia, total_overlaps)

		cdef np.ndarray ref_index = pointer_to_numpy_array(total_overlaps.ref_index,
															total_overlaps.size)
		cdef np.ndarray query_index = pointer_to_numpy_array(total_overlaps.query_index,
																total_overlaps.size)

		return ref_index, query_index


	def which_exact_match(self, LabeledIntervalArray other_aiarray):
		"""
		Determine which intervals are present

		Parameters
		----------
			other_aiarray: LabeledIntervalArray
				Other LabeledIntervalArray object to compare to

		Returns
		-------
			ref_index : numpy.ndarray{int}
				Indices of intervals in self that are present in other_aiarray
			query_index : numpy.ndarray{int}
				Indices of intervals in other_aiarray that are present in self

		See Also
		--------
			:func:`has_exact_match`

		Examples
		--------
		>>> from ailist import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.add(0, 10, "a")
		>>> ail.add(20, 30, "a")
		>>> ail.add(40, 50, "b")
		>>> ail.add(60, 70, "b")
		>>> ail2 = LabeledIntervalArray()
		>>> ail2.add(0, 10, "a")
		>>> ail2.add(20, 30, "b")
		>>> ail2.add(40, 50, "c")
		>>> ref_index, query_index = ail.is_exact_match(ail2)
		"""

		# Check if object is still open
		if self.is_closed or other_aiarray.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if objects are constructed
		if self.is_constructed is False:
			self.construct()
		if other_aiarray.is_constructed is False:
			other_aiarray.construct()

		# Call C function
		ref_index, query_index = self._which_exact_match(other_aiarray)

		return ref_index, query_index


	cdef int _where_interval(LabeledIntervalArray self, int start, int end, const char *label_name):

		cdef index = labeled_aiarray_where_interval(self.laia, label_name, start, end)

		return index


	def where_interval(self, start, end, label):
		"""
		Determine which intervals are present

		Parameters
		----------
			other_aiarray: LabeledIntervalArray
				Other LabeledIntervalArray object to compare to

		Returns
		-------
			ref_index : numpy.ndarray{int}
				Indices of intervals in self that are present in other_aiarray
			query_index : numpy.ndarray{int}
				Indices of intervals in other_aiarray that are present in self

		See Also
		--------
			:func:`has_exact_match`

		Examples
		--------
		>>> from ailist import LabeledIntervalArray
		>>> ail = LabeledIntervalArray()
		>>> ail.add(0, 10, "a")
		>>> ail.add(20, 30, "a")
		>>> ail.add(40, 50, "b")
		>>> ail.add(60, 70, "b")
		>>> ail2 = LabeledIntervalArray()
		>>> ail2.add(0, 10, "a")
		>>> ail2.add(20, 30, "b")
		>>> ail2.add(40, 50, "c")
		>>> ref_index, query_index = ail.is_exact_match(ail2)
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if objects are constructed
		if self.is_constructed is False:
			self.construct()

		# Call C function
		cdef bytes label_name = label.encode()
		cdef int index = self._where_interval(start, end, label_name)

		return index


	cdef int _index_with_aiarray(LabeledIntervalArray self, LabeledIntervalArray other_aiarray):

		# Call C function
		cdef int result = labeled_aiarray_index_with_aiarray(self.laia, other_aiarray.laia)

		return result


	def index_with_aiarray(self, LabeledIntervalArray other_aiarray):
		"""
		"""

		# Check if object is still open
		if self.is_closed or other_aiarray.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		return_code = self._index_with_aiarray(other_aiarray)

		if return_code == 1:
			raise NameError("Failed to run properly. Values are likely currupted now.")


	cdef void _get_locs(LabeledIntervalArray self, uint8[::1] locs_view, char *label_names,
						int label_str_len, int n_labels):
		"""
		"""

		labeled_aiarray_get_label_array_presence(self.laia, &label_names[0], n_labels, &locs_view[0],
												label_str_len)

		return

	def get_locs(self, labels):
		"""
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		cdef np.ndarray locs = np.zeros(self.size, dtype=bool)
		cdef uint8[::1] locs_view = np.frombuffer(locs, dtype=np.uint8)

		# Check that labels are bytes
		if isinstance(labels, np.ndarray) is False:
			labels = np.array(labels)
		byte_labels = labels.astype(bytes)

		# Intersect from array
		self._get_locs(locs_view, np.PyArray_BYTES(byte_labels), byte_labels.itemsize, len(labels))

		return locs


	cdef void _create_bin(LabeledIntervalArray self, int bin_size, int bin_range,
							const char* label_name):
		"""
		Create LabeledIntervalArray for bins
		"""

		# Initialize variables
		cdef int first
		cdef int first_bin_start
		cdef int last
		cdef int start
		cdef int j

		# Find bounds
		first = 0
		first_bin_start = (first // bin_size) * bin_size
		last = bin_range
		n_bins = math.ceil(last / bin_size) - (first // bin_size)

		# Iterate over label bins
		for j in range(n_bins):
			start = first_bin_start + (j * bin_size)
			labeled_aiarray_add(self.laia, start, start + bin_size, label_name)

		return

	@staticmethod
	def create_bin(dict_range, bin_size=100000):
		"""
		"""

		cdef LabeledIntervalArray laia = LabeledIntervalArray()
		cdef int bin_range
		cdef bytes label_bytes
		cdef const char* label_name

		for label in dict_range:
			label_bytes = label.encode()
			label_name = label_bytes
			bin_range = dict_range[label]
			laia._create_bin(bin_size, bin_range, label_name)

		return laia


	def simulate(self):
		"""
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		cdef LabeledIntervalArray simulation = LabeledIntervalArray()
		labeled_aiarray_simulate(self.laia, simulation.laia)

		return simulation


	def sorted_index(self):
		"""
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if objects are constructed
		if self.is_constructed is False:
			self.construct()

		cdef np.ndarray sorted_index = np.zeros(self.size, dtype=np.int_)
		cdef long[::1] sorted_index_mem = sorted_index
		labeled_aiarray_sort_index(self.laia, &sorted_index_mem[0])

		return sorted_index


	def sort(self):
		"""
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if objects are constructed
		if self.is_constructed is False:
			self.construct()

		labeled_aiarray_sort(self.laia)

		return


	cdef np.ndarray _midpoint_coverage(LabeledIntervalArray self, const char *label_name):
		# Initialize cov
		cdef uint32_t t = get_label(self.laia, label_name)
		cdef long n = self.laia.labels[t].ail.last - self.laia.labels[t].ail.first
		cdef double[::1] cov = np.zeros(n, dtype=np.double)

		# Calculate cov
		labeled_aiarray_label_midpoint_coverage(self.laia, &cov[0], label_name)

		return np.asarray(cov)

	def midpoint_coverage(self, labels=None, min_length=None, max_length=None):
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
			cov_results : dict {str:numpy.ndarray}
				Coverage as values
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if empty
		if self.laia.total_nr == 0:
			return None

		# Determine which labels to calculate
		if labels is None:
			labels = self.unique_labels
		elif isinstance(labels, str):
			labels = np.array([labels])
		else:
			labels = np.array(labels)

		# Check all labels present
		missing_labels = set(labels) - set(self.unique_labels)
		if len(missing_labels) > 0:
			raise KeyError("Provided label not in LabeledIntervalArray. " + str(missing_labels))

		# Get label ranges
		label_ranges = self.label_ranges

		# Convert to bytes
		labels = labels.astype(bytes)

		# Iterate over labels
		cov_results = {}
		cdef const char *label_name
		cdef np.ndarray cov
		for label in labels:
			label_name = label

			# Calculate wps
			if min_length is None or max_length is None:
				cov = self._midpoint_coverage(label_name)
			else:
				cov = self._midpoint_coverage_length(label_name, min_length, max_length)

			cov_results[label.decode()] = pd.Series(cov,
													index = range(label_ranges[label.decode()][0],
																  label_ranges[label.decode()][1]))

		return cov_results


	def common(LabeledIntervalArray self, LabeledIntervalArray other_laia):
		"""
		Finds the common intervals between two LabeledIntervalArrays

		Parameters
		----------
			other_laia : LabeledIntervalArray
				LabeledIntervalArray to find common intervals with

		Returns
		-------
			common_laia : LabeledIntervalArray
				LabeledIntervalArray with common intervals

		See Also
		--------
			LabeledIntervalArray.union
			LabeledIntervalArray.subtract
			LabeledIntervalArray.intersect

		Notes
		-----
			- The common intervals are returned as a new LabeledIntervalArray
			- The common intervals are not sorted

		Examples
		>>> laia1 = LabeledIntervalArray()
		>>> laia1.add_interval(0, 10, 'A')
		>>> laia1.add_interval(10, 20, 'B')
		>>> laia1.add_interval(20, 30, 'C')
		>>> laia1.add_interval(30, 40, 'D')
		>>> laia1.add_interval(40, 50, 'E')

		>>> laia2 = LabeledIntervalArray()
		>>> laia2.add_interval(0, 10, 'A')
		>>> laia2.add_interval(10, 20, 'B')

		>>> laia1.common(laia2)
		>>> LabeledIntervalArray
		>>> 0-10: A
		>>> 10-20: B

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if other object is still open
		if other_laia.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if objects are constructed
		if self.is_constructed is False:
			self.construct()

		# Check if other objects are constructed
		if other_laia.is_constructed is False:
			other_laia.construct()

		cdef LabeledIntervalArray common_laia = LabeledIntervalArray()
		cdef labeled_aiarray_t *claia = labeled_aiarray_common(self.laia, other_laia.laia)
		common_laia.set_list(claia)

		return common_laia


	def union(LabeledIntervalArray self, LabeledIntervalArray other_laia):
		"""
		Finds the union of two LabeledIntervalArrays

		Parameters
		----------
			other_laia : LabeledIntervalArray
				LabeledIntervalArray to find union with

		Returns
		-------
			union_laia : LabeledIntervalArray
				LabeledIntervalArray with union

		See Also
		--------
			LabeledIntervalArray.common
			LabeledIntervalArray.subtract
			LabeledIntervalArray.intersect

		Notes
		-----
			- The union is returned as a new LabeledIntervalArray
			- The union is not sorted

		Examples
		>>> laia1 = LabeledIntervalArray()
		>>> laia1.add_interval(0, 10, 'A')
		>>> laia1.add_interval(10, 20, 'B')
		>>> laia1.add_interval(20, 30, 'C')
		>>> laia1.add_interval(30, 40, 'D')
		>>> laia1.add_interval(40, 50, 'E')

		>>> laia2 = LabeledIntervalArray()
		>>> laia2.add_interval(0, 10, 'A')
		>>> laia2.add_interval(10, 20, 'B')

		>>> laia1.union(laia2)
		>>> LabeledIntervalArray
		>>> 0-10: A
		>>> 10-20: B
		>>> 20-30: C
		>>> 30-40: D
		>>> 40-50: E

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if other object is still open
		if other_laia.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if objects are constructed
		if self.is_constructed is False:
			self.construct()

		# Check if other objects are constructed
		if other_laia.is_constructed is False:
			other_laia.construct()

		cdef LabeledIntervalArray union_laia = LabeledIntervalArray()
		cdef labeled_aiarray_t *claia = labeled_aiarray_union(self.laia, other_laia.laia)
		union_laia.set_list(claia)

		return union_laia


	def subtract(LabeledIntervalArray self, LabeledIntervalArray other_laia):
		"""
		Finds the subtraction of two LabeledIntervalArrays

		Parameters
		----------
			other_laia : LabeledIntervalArray
				LabeledIntervalArray to find subtraction with

		Returns
		-------
			subtract_laia : LabeledIntervalArray
				LabeledIntervalArray with subtraction

		See Also
		--------
			LabeledIntervalArray.common
			LabeledIntervalArray.union
			LabeledIntervalArray.intersect

		Notes
		-----
			- The subtraction is returned as a new LabeledIntervalArray
			- The subtraction is not sorted

		Examples
		>>> laia1 = LabeledIntervalArray()
		>>> laia1.add_interval(0, 10, 'A')
		>>> laia1.add_interval(10, 20, 'B')
		>>> laia1.add_interval(20, 30, 'C')

		>>> laia2 = LabeledIntervalArray()
		>>> laia2.add_interval(0, 10, 'A')
		>>> laia2.add_interval(10, 20, 'B')

		>>> laia1.subtract(laia2)
		>>> LabeledIntervalArray
		>>> 20-30: C

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if other object is still open
		if other_laia.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if objects are constructed
		if self.is_constructed is False:
			self.construct()

		# Check if other objects are constructed
		if other_laia.is_constructed is False:
			other_laia.construct()

		cdef LabeledIntervalArray subtract_laia = LabeledIntervalArray()
		cdef labeled_aiarray_t *claia = labeled_aiarray_subtract(self.laia, other_laia.laia)
		subtract_laia.set_list(claia)

		return subtract_laia


	cdef np.ndarray _percent_coverage(LabeledIntervalArray self, LabeledIntervalArray other_laia):
		# Initialize coverage
		cdef double[::1] cov = np.zeros(self.size, dtype=np.double)

		# Calculate percent coverage
		labeled_aiarray_percent_coverage(self.laia, other_laia.laia, &cov[0])

		return np.asarray(cov)

	def percent_coverage(LabeledIntervalArray self, LabeledIntervalArray other_laia):
		"""
		Finds the percent coverage of two LabeledIntervalArrays

		Parameters
		----------
			other_laia : LabeledIntervalArray
				LabeledIntervalArray to find percent coverage with

		Returns
		-------
			percent_coverage : float
				Percent coverage of two LabeledIntervalArrays

		See Also
		--------
			LabeledIntervalArray.common
			LabeledIntervalArray.union
			LabeledIntervalArray.intersect

		Notes
		-----
			- The percent coverage is returned as a float
			- The percent coverage is not sorted

		Examples
		>>> laia1 = LabeledIntervalArray()
		>>> laia1.add_interval(0, 10, 'A')
		>>> laia1.add_interval(10, 20, 'B')
		>>> laia1.add_interval(20, 30, 'C')

		>>> laia2 = LabeledIntervalArray()
		>>> laia2.add_interval(0, 10, 'A')
		>>> laia2.add_interval(10, 20, 'B')

		>>> laia1.percent_coverage(laia2)
		>>> [0.6666666666666666, 0.3333333333333333]

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if other object is still open
		if other_laia.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		# Check if objects are constructed
		if self.is_constructed is False:
			self.construct()

		# Check if other objects are constructed
		if other_laia.is_constructed is False:
			other_laia.construct()

		cdef np.ndarray percent_coverage = self._percent_coverage(other_laia)

		return percent_coverage


	def validate_construction(self):
		"""
		Validates the construction of the LabeledIntervalArray

		Returns
		-------
			is_valid : bool
				True if the LabeledIntervalArray is valid, False otherwise
		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		cdef int res = labeled_aiarray_validate_construction(self.laia)

		if res == 0:
			return False
		else:
			return True
			

	def copy(self):
		"""
		Copy LabeledIntervalArray

		Returns
		-------
			laia_copied : LabeledIntervalArray
				Copied LabeledIntervalArray

		Notes
		-----
			- The copy is not sorted

		Examples
		>>> laia1 = LabeledIntervalArray()
		>>> laia1.add_interval(0, 10, 'A')
		>>> laia1.add_interval(10, 20, 'B')

		>>> laia2 = laia1.copy()
		>>> laia2
		>>> LabeledIntervalArray
		>>> 0-10: A
		>>> 10-20: B

		"""

		# Check if object is still open
		if self.is_closed:
			raise NameError("LabeledIntervalArray object has been closed.")

		cdef LabeledIntervalArray laia_copied = LabeledIntervalArray()
		cdef labeled_aiarray_t * c_laia_copied = labeled_aiarray_copy(self.laia)
		laia_copied.set_list(c_laia_copied)

		return laia_copied


	def close(self):
		"""
		Close object and clear memory
		"""

		# Free labeled_interval_list memory
		if self.laia:
			labeled_aiarray_destroy(self.laia)
		self.laia = NULL

		self.is_closed = True
