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


cdef class Interval(object):
	"""
	Wrapper of C interval_t

	:class:`~Interval_core.Interval` stores an interval

	"""

	def __init__(self, start=None, end=None):
		"""
		Initialize Interval

		Parameters
		----------
			start : int
				Starting position [default = None]
			end : int
				Ending position [default = None]

		Returns
		-------
			None

		"""

		self.start = start
		self.end = end


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
			if other.start < self.end and other.end > self.start:
				is_equal = True
			else:
				is_equal = False

		return is_equal


	def __str__(self):
		format_string = "Interval(%d-%d)" % (self.start, self.end)
		return format_string


	def __repr__(self):
		format_string = "Interval(%d-%d)" % (self.start, self.end)
		return format_string
