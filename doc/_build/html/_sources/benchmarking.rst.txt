Benchmarking
============

All benchmarks were done on a 2.9 GHz Intel Core i7 processor with 16GB of RAM on macOS Mojave (version 10.14.6).

.. code-block:: python

	# ailist version: 1.0.0
	from ailist import AIList
	# ncls version: 0.0.53
	from ncls import NCLS
	# numpy version: 1.19.1
	import numpy as np
	# pandas version: 1.1.0
	import pandas as pd
	# quicksect version: 0.2.2
	import quicksect
	
	# Set seed
	np.random.seed(100)

	# First values
	starts1 = np.random.randint(0, 100000, 100000)
	ends1 = starts1 + np.random.randint(1, 10000, 100000)
	ids1 = np.arange(len(starts1))

	# Second values
	starts2 = np.random.randint(0, 100000, 100000)
	ends2 = starts2 + np.random.randint(1, 10000, 100000)
	ids2 = np.arange(len(starts2))

	###### Test AIList ######
	i = AIList()
	
	%time i.from_array(starts1, ends1, ids1, values1)
	# CPU times: user 1.1 ms, sys: 649 µs, total: 1.75 ms
	# Wall time: 1.78 ms
	
	%time i.construct()
	# CPU times: user 11.5 ms, sys: 1.13 ms, total: 12.6 ms
	# Wall time: 12.7 ms
	
	%time ai_res = i.intersect_from_array(starts2, ends2, ids2)
	# CPU times: user 12 s, sys: 5.79 s, total: 17.7 s
	# Wall time: 17.8 s
	### Resulting memory usage: ~5GB
	### Max memory usage: ~9GB
	
	%timeit i.intersect(starts2[50], ends2[50])
	# 73.5 µs ± 831 ns per loop (mean ± std. dev. of 7 runs, 10000 loops each)
	
	###### Test AIList(track_sort=True) ######
	i = AIList(track_sort=True)
	
	%time i.from_array(starts1, ends1, ids1, values1)
	# CPU times: user 1.58 ms, sys: 569 µs, total: 2.15 ms
	# Wall time: 2.15 ms
	
	%time i.construct()
	# CPU times: user 11.5 ms, sys: 1.18 ms, total: 12.6 ms
	# Wall time: 12.6 ms
	
	%time ai_res = i.intersect_from_array(starts2, ends2, ids2)
	# CPU times: user 12.6 s, sys: 5.98 s, total: 18.6 s
	# Wall time: 18.7 s
	### Resulting memory usage: ~5GB
	### Max memory usage: ~9GB
	
	%timeit i.intersect(starts2[50], ends2[50])
	# 76.2 µs ± 1.42 µs per loop (mean ± std. dev. of 7 runs, 10000 loops each)
	
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
	# CPU times: user 232 ms, sys: 9.01 ms, total: 241 ms
	# Wall time: 241 ms
	
	%timeit p[p.overlaps(pd.Interval(starts2[50], ends2[50]))]
	# 924 µs ± 24.4 µs per loop (mean ± std. dev. of 7 runs, 1000 loops each)
	
	###### Test quicksect ######
	b = quicksect.IntervalTree()
	%time for i in range(len(starts1)): b.add(starts1[i], ends1[i])
	# CPU times: user 345 ms, sys: 8.02 ms, total: 353 ms
	# Wall time: 359 ms
	
	%timeit b.search(starts2[50], ends2[50])
	# 550 µs ± 24.7 µs per loop (mean ± std. dev. of 7 runs, 1000 loops each)