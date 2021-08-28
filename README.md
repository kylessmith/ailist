# Augmented Interval List

[![Build Status](https://travis-ci.org/kylessmith/ailist.svg?branch=master)](https://travis-ci.org/kylessmith/ailist) [![PyPI version](https://badge.fury.io/py/ailist.svg)](https://badge.fury.io/py/ailist)
[![Coffee](https://img.shields.io/badge/-buy_me_a%C2%A0coffee-gray?logo=buy-me-a-coffee&color=ff69b4)](https://www.buymeacoffee.com/kylessmith)

Augmented interval list (AIList) is a data structure for enumerating intersections 
between a query interval and an interval set. AILists have previously been shown 
to be faster than interval tree, NCList, and BEDTools.

This implementation is a Python wrapper of the one used in the original [AIList library][AIList_github].


Additonal wrapper functions have been created which allow easy user interface.

All citations should reference to [original paper][paper].

For full usage and installation [documentation][AIList_docs]

## Install

If you dont already have numpy and scipy installed, it is best to download
`Anaconda`, a python distribution that has them included.  
```
    https://continuum.io/downloads
```

Dependencies can be installed by:

```
    pip install -r requirements.txt
```

PyPI install, presuming you have all its requirements installed:
```
    pip install ailist
```

## Benchmark

Test numpy random integers:

```python
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

```

| Library | Function | Time (µs) |
| --- | --- | --- |
| ncls | single overlap | 1170 |
| pandas | single overlap | 924 |
| quicksect | single overlap |  550 |
| ailist | single overlap | 73 |

| Library | Function | Time (s) | Max Memory (GB) |
| --- | --- | --- | --- |
| ncls | bulk overlap | 151 s | >50 |
| ailist | bulk overlap | 17.8 s | ~9 |

## Usage

```python
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
# Interval(5-20, 3)
# Interval(10-30, 1)
# Interval(12-15, 4)
# Interval(15-20, 0)
# Interval(17-19, 2)
# Interval(30-40, 5)

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
#    (5-15, 3)
#    (10-15, 1)
#    (12-15, 4)

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

```


## Original paper

> Jianglin Feng,  Aakrosh Ratan,  Nathan C Sheffield; Augmented Interval List: a novel data structure for efficient genomic interval search, Bioinformatics, btz407, https://doi.org/10.1093/bioinformatics/btz407


[AIList_github]: https://github.com/databio/AIList
[paper]: https://academic.oup.com/bioinformatics/advance-article/doi/10.1093/bioinformatics/btz407/5509521
[AIList_docs]: https://www.biosciencestack.com/static/ailist/docs/index.html