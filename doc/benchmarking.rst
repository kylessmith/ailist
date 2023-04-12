Benchmarking
============

.. code-block:: python

	# ailist version: 0.1.7
	from ailist import AIList
	# ncls version: 0.0.53
	from ncls import NCLS
	# numpy version: 1.18.4
	import numpy as np
	# pandas version: 1.0.3
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
	
	%time i.from_array(starts1, ends1, ids1, values1)
	# CPU times: user 2.12 ms, sys: 1.55 ms, total: 3.67 ms
	# Wall time: 9.6 ms
	
	%time i.construct()
	# CPU times: user 11.9 ms, sys: 1.35 ms, total: 13.3 ms
	# Wall time: 18.7 ms
	
	%time ai_res = i.intersect_from_array(starts2, ends2, ids2)
	# CPU times: user 11.9 s, sys: 5.96 s, total: 17.9 s
	# Wall time: 17.9 s
	### Resulting memory usage: ~5GB
	### Max memory usage: ~9GB
	
	%timeit i.intersect(starts2[50], ends2[50])
	# 102 µs ± 1.05 µs per loop (mean ± std. dev. of 7 runs, 10000 loops each)
	
	###### Test NCLS ######
	%time n = NCLS(starts1, ends1, ids1)
	# CPU times: user 36.5 ms, sys: 1.65 ms, total: 38.1 ms
	# Wall time: 38.2 ms
	
	%time n_res = n.all_overlaps_both(starts2, ends2, ids2)
	# CPU times: user 53.6 s, sys: 1min 18s, total: 2min 12s
	# Wall time: 2min 31s
	### Resulting memory usage: >30GB
	### Max memory usage: >50GB
	
	%timeit list(n.find_overlap(starts2[50], ends2[50]))
	# 1.17 ms ± 22.2 µs per loop (mean ± std. dev. of 7 runs, 1000 loops each)
	
	###### Test pandas IntervalIndex ######
	%time p = pd.IntervalIndex.from_tuples(list(zip(starts1, ends1)))
	# CPU times: user 873 ms, sys: 10.2 ms, total: 883 ms
	# Wall time: 884 ms
	
	%timeit p.overlaps(pd.Interval(starts2[50], ends2[50]))
	# 241 µs ± 6.05 µs per loop (mean ± std. dev. of 7 runs, 1000 loops each)
	
	###### Test quicksect ######
	b = quicksect.IntervalTree()
	for i in range(len(starts1)):
	    b.add(starts1[i], ends1[i])
	
	%timeit b.search(starts2[50], ends2[50])
	# 1.05 ms ± 79.8 µs per loop (mean ± std. dev. of 7 runs, 1000 loops each)