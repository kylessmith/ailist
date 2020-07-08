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

# Test AIList
i = AIList()

i.from_array(starts1, ends1, ids1, values1)
i.construct()

ai_res = i.intersect_from_array(starts2, ends2, ids2)

i.intersect(starts2[50], ends2[50])

# Test NCLS
n = NCLS(starts1, ends1, ids1)

n_res = n.all_overlaps_both(starts2, ends2, ids2)

list(n.find_overlap(starts2[50], ends2[50]))

# Test pandas
p = pd.IntervalIndex.from_tuples(list(zip(starts1, ends1)))

p.overlaps(pd.Interval(starts2[50], ends2[50]))

# Test quicksect
b = quicksect.IntervalTree()
for i in range(len(starts1)):
    b.add(starts1[i], ends1[i])

b.search(starts2[50], ends2[50])
    
KIFYH5=milo