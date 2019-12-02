Tutorial
=========

.. code-block:: python

	from ailist import AIList
	import numpy as np

	i = AIList()
	i.add(15, 20)
	i.add(10, 30)
	i.add(17, 19)
	i.add(5, 20)
	i.add(12, 15)
	i.add(30, 40)

	# Print intervals
	i.display()
	# (15-20) (10-30) (17-19) (5-20) (12-15) (30-40)

	# Find overlapping intervals
	o = i.intersect(6, 15)
	o.display()
	# (5-20) (10-30) (12-15)

	# Find index of overlaps
	i.intersect_index(6, 15)
	# array([3, 1, 4])

	# Now i has been constructed/sorted
	i.display()
	# (5-20) (10-30) (12-15) (15-20) (17-19) (30-40)

	# Can be done manually as well at any time
	i.construct()

	# Iterate over intervals
	for x in i:
	   print(x)
	# Interval(5-20, 3, 0.0)
	# Interval(10-30, 1, 0.0)
	# Interval(12-15, 4, 0.0)
	# Interval(15-20, 0, 0.0)
	# Interval(17-19, 2, 0.0)
	# Interval(30-40, 5, 0.0)

	# Interval comparisons
	j = AIList()
	j.add(5, 15)
	j.add(50, 60)

	# Subtract regions
	s = i - j #also: i.subtract(j)
	s.display()
	# (15-20) (15-30) (15-20) (17-19) (30-40) 

	# Common regions
	i + j #also: i.common(j)
	# AIList
	#  range: (5-15)
	#    (5-15, 3, 0.0)
	#    (10-15, 1, 0.0)
	#    (12-15, 4, 0.0)

	# AIList can also add to from arrays
	starts = np.arange(10,1000,100)
	ends = starts + 50
	ids = starts
	values = np.ones(10)
	i.from_array(starts, ends, ids, values)
	i.display()
	# (5-20) (10-30) (12-15) (15-20) (17-19) (30-40) 
	# (10-60) (110-160) (210-260) (310-360) (410-460) 
	# (510-560) (610-660) (710-760) (810-860) (910-960)

	# Merge overlapping intervals
	m = i.merge(gap=10)
	m.display()
	# (5-60) (110-160) (210-260) (310-360) (410-460) 
	# (510-560) (610-660) (710-760) (810-860) (910-960)

	# Find array of coverage
	c = i.coverage()
	c.head()
	# 5    1.0
	# 6    1.0
	# 7    1.0
	# 8    1.0
	# 9    1.0
	# dtype: float64

	# Calculate window protection score
	w = i.wps(5)
	w.head()
	# 5   -1.0
	# 6   -1.0
	# 7    1.0
	# 8   -1.0
	# 9   -1.0
	# dtype: float64

	# Filter to interval lengths between 3 and 20
	fi = i.filter(3,20)
	fi.display()
	# (5-20) (10-30) (15-20) (30-40)

	# Query by array
	i.intersect_from_array(starts, ends, ids)
	# (array([ 10,  10,  10,  10,  10,  10,  10, 110, 210, 310, 410, 510, 610,
	#         710, 810, 910]),
	# array([  5,   2,   0,   4,  10,   1,   3, 110, 210, 310, 410, 510, 610,
	#        710, 810, 910]))

