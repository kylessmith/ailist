Benchmarking
============

.. code-block:: python

	# ailist version: 2.0.3
	from ailist import AIList
	# ncls version: 0.0.66
	from ncls import NCLS
	# numpy version: 1.23.5
	import numpy as np
	# pandas version: 1.5.3
	import pandas as pd
	# quicksect version: 0.2.2
	import quicksect
	
	# Set seed
	np.random.seed(100)

	# First values
	starts1 = np.random.randint(0, 100000, 100000)
	ends1 = starts1 + np.random.randint(1, 10000, 100000)
	ids1 = np.arange(len(starts1))
	values1 = np.ones(len(starts1))

	# Second values
	starts2 = np.random.randint(0, 100000, 100000)
	ends2 = starts2 + np.random.randint(1, 10000, 100000)
	ids2 = np.arange(len(starts2))
	values2 = np.ones(len(starts2))

	###### Test AIList ######
	i = AIList()
	
	%time i.from_array(starts1, ends1, ids1)
	# CPU times: user 787 µs, sys: 924 µs, total: 1.71 ms
	# Wall time: 2.75 ms
	
	%time i.construct()
	# CPU times: user 12.9 ms, sys: 759 µs, total: 13.7 ms
	# Wall time: 13.6 ms
	
	%time ai_res = i.intersect_from_array(starts2, ends2, ids2)
	# CPU times: user 3.23 s, sys: 2.3 s, total: 5.54 s
	# Wall time: 5.71 s
	### Resulting memory usage: ~6.77GB
	### Max memory usage: ~9GB
	
	%timeit i.intersect(starts2[50], ends2[50])
	# 29.5 µs ± 2.38 µs per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
	
	###### Test NCLS ######
	%time n = NCLS(starts1, ends1, ids1)
	# CPU times: user 41.3 ms, sys: 4.65 ms, total: 46 ms
	# Wall time: 44.5 ms
	
	%time n_res = n.all_overlaps_both(starts2, ends2, ids2)
	# CPU times: user 24.9 s, sys: 29 s, total: 53.9 s
	# Wall time: 1min 19s
	### Resulting memory usage: >30GB
	### Max memory usage: >50GB
	
	%timeit list(n.find_overlap(starts2[50], ends2[50]))
	# 916 µs ± 6.75 µs per loop (mean ± std. dev. of 7 runs, 1,000 loops each)
	
	###### Test pandas IntervalIndex ######
	%time p = pd.IntervalIndex.from_tuples(list(zip(starts1, ends1)))
	# CPU times: user 167 ms, sys: 8.25 ms, total: 175 ms
	# Wall time: 176 ms
	
	%timeit p.overlaps(pd.Interval(starts2[50], ends2[50]))
	# 90.4 µs ± 716 ns per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
	
	###### Test quicksect ######
	b = quicksect.IntervalTree()
	for i in range(len(starts1)):
	    b.add(starts1[i], ends1[i])
	
	%timeit b.search(starts2[50], ends2[50])
	# 1.05 ms ± 79.8 µs per loop (mean ± std. dev. of 7 runs, 1000 loops each)