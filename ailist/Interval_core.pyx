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


cdef class Interval(object):
	"""
	Wrapper of C interval_t

	:class:`~Interval_core.Interval` stores an interval
	
	"""

	def __init__(self, start=None, end=None, id_value=None):
		"""
		Initialize Interval

		Parameters
		----------
			start : int
				Starting position [default = None]
			end : int
				Ending position [default = None]
			id_value : int
				ID [defualt = None]

		Returns
		-------
			None

		"""

		if start is not None:
			if id_value is None:
				id_value = 0
			# Create interval
			self.i = interval_init(start, end, id_value)

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
	def id_value(self):
		"""
		ID of interval
		"""

		return self.i.id_value
	

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
		format_string = "Interval(%d-%d, %s)" % (self.start, self.end, self.id_value)
		return format_string


	def __repr__(self):
		format_string = "Interval(%d-%d, %s)" % (self.start, self.end, self.id_value)
		return format_string

