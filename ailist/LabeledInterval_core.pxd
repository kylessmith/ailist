import numpy as np
cimport numpy as np
cimport cython
from libc.stdint cimport uint32_t, int32_t, int64_t, uint16_t
from libc.stdlib cimport malloc, free


cdef extern from "src/labeled_interval.c":
	# C is include here so that it doesn't need to be compiled externally
	pass

cdef extern from "src/labeled_interval.h":
	# C is include here so that it doesn't need to be compiled externally
	ctypedef struct labeled_interval_t:
		uint32_t start      				# Region start: 0-based
		uint32_t end    					# Region end: not inclusive
		int32_t id_value					# Region ID
		uint16_t label						# Region label

	# Initialize interval_t
	labeled_interval_t *labeled_interval_init(uint32_t start, uint32_t end, int32_t id_value, uint16_t label) nogil


cdef class LabeledInterval(object):
	"""
	Wrapper for C labeled interval
	"""

	# Define attributes
	cdef str _label

	# C instance of struct
	cdef labeled_interval_t *i

	# Methods for serialization
	cdef void set_i(self, labeled_interval_t *i, str label)
