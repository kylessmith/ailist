#cython: embedsignature=True
#cython: profile=False

import os
import sys
import numpy as np
cimport numpy as np
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
		location : str
			Directory to header files
	"""

	# Grab file location
	location = os.path.split(os.path.realpath(__file__))[0]

	return location


cdef np.ndarray pointer_to_numpy_array(void *ptr, np.npy_intp size):
	"""
	Convert c pointer to numpy array.
	The memory will be freed as soon as the ndarray is deallocated.

	Parameters
	----------
		ptr : void
			Pointer to be given to numpy
		size : np.npy_intp
			Size of the array

	Returns
	-------
		arr : numpy.ndarray
			Numpy array from given pointer

	"""

	# Import functions for numpy C header
	cdef extern from "numpy/arrayobject.h":
		void PyArray_ENABLEFLAGS(np.ndarray arr, int flags)

	# Create shape of ndarray
	cdef np.npy_intp dims[1]
	dims[0] = size

	# Create ndarray from C pointer
	cdef np.ndarray arr = np.PyArray_SimpleNewFromData(1, &dims[0], np.NPY_LONG, ptr)

	# Hand control of data freeing to numpy
	PyArray_ENABLEFLAGS(arr, np.NPY_ARRAY_OWNDATA)
	#np.PyArray_UpdateFlags(arr, arr.flags.num | np.NPY_OWNDATA)

	return arr
