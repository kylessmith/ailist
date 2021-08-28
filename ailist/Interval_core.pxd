import numpy as np
cimport numpy as np
cimport cython
from libc.stdint cimport uint32_t, int32_t, int64_t
from libc.stdlib cimport malloc, free


cdef extern from "src/interval.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/interval.h":
	# C is include here so that it doesn't need to be compiled externally
	ctypedef struct interval_t:
		uint32_t start      				# Region start: 0-based
		uint32_t end    					# Region end: not inclusive
		int32_t id_value					# Region ID

	# Initialize interval_t
	interval_t *interval_init(uint32_t start, uint32_t end, int32_t id_value) nogil


cdef class Interval(object):
	"""
	Wrapper for C interval
	"""

	# C instance of struct
	cdef interval_t *i

	# Methods for serialization
	cdef void set_i(self, interval_t *i)
