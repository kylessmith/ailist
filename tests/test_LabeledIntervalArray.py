import pytest
from ailist import LabeledIntervalArray, LabeledInterval
import numpy as np
import pickle


@pytest.fixture
def interval_list():
# Test IntervalArray construction
i = LabeledIntervalArray()
i.add(10, 11, 'a')
i.add(1, 11, 'b')
i.add(15, 19, 'a')
i.add(11, 13, 'a')
i.add(19, 22, 'a')
i.add(15, 17, 'b')
i.add(20, 25, 'a')
i.add(30, 100, 'a')
i.add(1, 110, 'c')
i.add(30, 95, 'a')
i.add(20, 30, 'c')
i.add(25, 31, 'c')
i.construct()

    return i
    
    
def test_iteration(interval_list):
    # Expected results
    expected_starts = np.array([10, 1, 15, 11, 19, 15, 20, 30, 1, 30, 20, 25], dtype=int)
    
    # Test iteration
    is_Interval = 0
    for x in interval_list:
        is_Interval += isinstance(x, LabeledInterval)
    assert (is_Interval == 12)
    

def test_sorted_iteration(interval_list):
    # Expected results
    expected_sorted_starts = np.array([10, 11, 15, 19, 20, 30, 30, 1, 15, 1, 20, 25], dtype=int)
    
    # Test iteration
    is_Interval = 0
    for x in interval_list.iter_sorted:
        is_Interval += isinstance(x, LabeledInterval)
    assert (is_Interval == 12)
    

def test_nhits(interval_list):
    # Expected results
    expected_bin_nhits = np.array([2,2,2,0,2,2,2,2,2,2,2,2,2,2,2,2,2,1,
                                   1,1,1,1,
                                   1,1,1,1,2,3,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1], dtype=np.double)
    expected_bin_starts = np.array([10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,
                                    0,5,10,15,
                                    0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105])
    expected_bin_nhits_length = np.array([1,2,2,0,2,2,2,2,2,2,2,2,2,2,2,2,2,1], dtype=np.double)
    expected_nhits = np.array([1, 4, 4, 2, 2, 2, 2, 2, 2, 2])

    # Test nhits
    interval_list.nhits(3, 15, 'a')

    # Test bin nhits
    bh_bins, bh = interval_list.bin_nhits(5)
    assert (bh.values == expected_bin_nhits).all()

    # Test bin nhits length
    bhl = interval_list.bin_nhits(5, 2, 100)
    assert (bhl.values == expected_bin_nhits_length).all()

    # Test nhits from arrray
    starts = np.arange(1,100,10)
    ends = starts + 10
    nhits = interval_list.nhits_from_array(starts, ends)
    assert (nhits == expected_nhits).all()


def test_bin_coverage(interval_list):
    # Expected results
    expected_bin_coverage = np.array([3,5,7,0,10,10,10,10,10,10,10,10,10,10,10,10,10,5], dtype=np.double)
    expected_bin_coverage_length = np.array([2,5,7,0,10,10,10,10,10,10,10,10,10,10,10,10,10,5], dtype=np.double)

    # Test bin coverage
    bc = interval_list.bin_coverage(5)
    assert (bc.values == expected_bin_coverage).all()

    # Test bin coverage length
    bcl = interval_list.bin_coverage(5, 2, 100)
    assert (bcl.values == expected_bin_coverage_length).all()


def test_intersection(interval_list):
    # Expected results
    expected_intersect_index = (np.array([0, 1, 1, 2, 2], dtype=np.intc), np.array([5, 0, 3, 7, 9], dtype=np.long))

    # Test intersection
    o = interval_list.intersect(3, 15, 'a')
    assert o.size == 2 and o.label_ranges['a'][0] == 10 and o.label_ranges['a'][1] == 13

    # Test intersect from array
    oi = interval_list.intersect_from_array(np.array([16,1,30]), np.array([40,15,35]), np.array(['b','a','a']))
    assert (oi[0] == expected_intersect_index[0]).all()
    assert (oi[1] == expected_intersect_index[1]).all()

    # Test intersection with original index
    o, oi = interval_list.intersect_with_index(3, 15, 'a')
    assert o.size == 2 and o.label_ranges['a'][0] == 10 and o.label_ranges['a'][1] == 13
    assert (oi == np.array([0,3], dtype=int)).all()


def test_wps(interval_list):
    # Expected results
    expected_first_wps = np.array([-2., -2., -2., -2., -2., -1., -1., -2., -3., -3.])
    expected_last_wps = np.array([ 2.,  2.,  2.,  0.,  0.,  0.,  0.,  1., -1., -1.])

    # Test WPS calculation
    w = interval_list.wps(4)
    assert (w[:10] == expected_first_wps).all() and (w[-10:] == expected_last_wps).all()


def test_merge(interval_list):
    # Test merging
    m = interval_list.merge()
    assert m.size == 8 and m.label_ranges['a'][0] == 10 and m.label_ranges['a'][1] == 100


def test_ops(interval_list):
    # Expected results
    expected_subtract_starts = np.array([0, 13, 25, 100, 0, 25, 110], dtype=np.intc)
    expected_subtract_ends = np.array([10, 15, 30, 105, 5, 27, 120], dtype=np.intc)
    expected_common_starts = np.array([10, 11, 15, 19, 30, 20], dtype=np.intc)
    expected_common_ends = np.array([11, 13, 19, 25, 100, 25], dtype=np.intc)

    # Test subtract
    j = IntervalArray()
    j.add(20,27)
    j.add(0,105)
    j.add(0,5)
    j.add(110,120)
    s = j - interval_list
    for k, x in enumerate(s):
        assert x.start == expected_subtract_starts[k]
        assert x.end == expected_subtract_ends[k]

    # Test common
    c = j + interval_list
    for k, x in enumerate(c):
        assert x.start == expected_common_starts[k]
        assert x.end == expected_common_ends[k]


def test_filter(interval_list):
    # Test filtering
    f = interval_list.filter(3, 10)
    assert f.size == 2 and f.first == 15 and f.last == 25


def test_pickle(interval_list):
    # Test pickling
    d = pickle.dumps(interval_list)
    i2 = pickle.loads(d)
    assert i2.size == 7 and i2.first == 10 and i2.last == 100

    # Test pickle adding
    i2.add(40, 60)
    assert len(i2) == 8

    # Test pickle iteration
    is_Interval = 0
    for x in i2:
        is_Interval += isinstance(x, Interval)
    assert is_Interval == 8


def test_length_dist(interval_list):
    # Expected results
    expected_ld = np.array([1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
                    0, 0, 0, 1])

    # Test length distribution
    ld = interval_list.length_dist()
    assert (ld == expected_ld).all()


def test_index(interval_list):
    # Test indexing
    assert interval_list[-2].start == 30
    
