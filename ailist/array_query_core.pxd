import numpy as np
cimport numpy as np
cimport cython
from libc.stdint cimport uint32_t, int32_t, int64_t
from libc.stdlib cimport malloc, free


cdef extern from "src/array_query/array_query_utilities.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/array_query/array_query_utilities.h":
	# C is include here so that it doesn't need to be compiled externally
	ctypedef struct array_query_t:
		long *ref_index
		long *query_index
		int size
		int max_size
	
	#-------------------------------------------------------------------------------------
	# array_query_utilities.c
	#=====================================================================================

	# Initialize array_query struct
	array_query_t *array_query_init() nogil

	# Free array_query struct memory
	void array_query_destroy(array_query_t *aq) nogil

	# Add query to array_query struct
	void array_query_add(array_query_t *aq, long ref, long query) nogil


# Convert c pointer to numpy array
cdef np.ndarray pointer_to_numpy_array(void *ptr, np.npy_intp size)