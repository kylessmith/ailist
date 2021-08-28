import numpy as np
import pickle


test_first_wps = np.array([-2., -2., -2., -2., -2., -1., -1., -2., -3., -3.])
test_last_wps = np.array([ 2.,  2.,  2.,  0.,  0.,  0.,  0.,  1., -1., -1.])

test_ld = np.array([1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
                    0, 0, 0, 1])

test_nhits = np.array([1, 4, 4, 2, 2, 2, 2, 2, 2, 2])

test_bin_nhits = np.array([2,2,2,0,2,2,2,2,2,2,2,2,2,2,2,2,2,1], dtype=np.double)
test_bin_nhits_length = np.array([1,2,2,0,2,2,2,2,2,2,2,2,2,2,2,2,2,1], dtype=np.double)

test_bin_sums = np.array([0.2,0.2,0.2,0,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.1], dtype=np.double)

test_bin_coverage = np.array([3,5,7,0,10,10,10,10,10,10,10,10,10,10,10,10,10,5], dtype=np.double)
test_bin_coverage_length = np.array([2,5,7,0,10,10,10,10,10,10,10,10,10,10,10,10,10,5], dtype=np.double)

test_intersect_index = (np.array([200, 200, 123, 123], dtype=np.intc), np.array([0, 2, 5, 6], dtype=np.long))

test_subtract_starts = np.array([0, 13, 25, 100, 0, 25, 110], dtype=np.intc)
test_subtract_ends = np.array([10, 15, 30, 105, 5, 27, 120], dtype=np.intc)

test_common_starts = np.array([10, 11, 15, 19, 30, 20], dtype=np.intc)
test_common_ends = np.array([11, 13, 19, 25, 100, 25], dtype=np.intc)


def test_AIList():
    from ailist import AIList, Interval

    # Test AIList construction
    i = AIList()
    i.add(10, 11, 1)
    i.add(15, 19, 2)
    i.add(11, 13, 3)
    i.add(19, 22, 4)
    i.add(20, 25, 5)
    i.add(30, 100, 6)
    i.add(30, 95, 7)
    i.construct()
    assert len(i) == 7

    # Test iteration
    is_Interval = 0
    for x in i:
        is_Interval += isinstance(x, Interval)
    assert (is_Interval == 7)

    # Test bin nhits
    bh = i.bin_nhits(5)
    assert (bh.values == test_bin_nhits).all()

    # Test bin nhits length
    bhl = i.bin_nhits(5, 2, 100)
    assert (bhl.values == test_bin_nhits_length).all()

    # Test bin coverage
    bc = i.bin_coverage(5)
    assert (bc.values == test_bin_coverage).all()

    # Test bin coverage length
    bcl = i.bin_coverage(5, 2, 100)
    assert (bcl.values == test_bin_coverage_length).all()

    # Test bin sums
    #bs = i.bin_sums(5)
    #assert (i.bin_sums(5) == test_bin_sums).all()

    # Test intersection
    o = i.intersect(3, 15)
    assert o.size == 2 and o.first == 10 and o.last == 13

    # Test intersect from array
    oi = i.intersect_from_array(np.array([1,30]), np.array([15,35]), np.array([200,123]))
    print(oi)
    assert (oi[0] == test_intersect_index[0]).all()
    assert (oi[1] == test_intersect_index[1]).all()

    # Test index intersection
    oi = i.intersect_index(3, 15)
    assert (oi == np.array([0,2], dtype=np.long)).all()

    # Test WPS calculation
    w = i.wps(4)
    assert (w.values[:10] == test_first_wps).all() and (w.values[-10:] == test_last_wps).all()

    # Test merging
    m = i.merge()
    assert m.size == 5 and m.first == 10 and m.last == 100

    # Test subtract
    j = AIList()
    j.add(20,27)
    j.add(0,105)
    j.add(0,5)
    j.add(110,120)
    s = j - i
    for k, x in enumerate(s):
        assert x.start == test_subtract_starts[k]
        assert x.end == test_subtract_ends[k]

    # Test common
    c = j + i
    for k, x in enumerate(c):
        assert x.start == test_common_starts[k]
        assert x.end == test_common_ends[k]

    # Test append

    # Test indexing
    assert i[-2].start == 30

    # Test filtering
    f = i.filter(3, 10)
    assert f.size == 2 and f.first == 15 and f.last == 25

    # Test length distribution
    ld = i.length_dist()
    assert (ld == test_ld).all()

    # Test nhits from arrray
    starts = np.arange(1,100,10)
    ends = starts + 10
    nhits = i.nhits_from_array(starts, ends)
    assert (nhits == test_nhits).all()

    # Test ailist indexing
    index_ail = AIList()
    index_ail.add(1, 2, 0)
    index_ail.add(0, 1, 0)
    index_ail.add(2, 4, 0)
    ind = index_ail.index_by_ailist(i)
    assert ind[0].start == 11 and ind[0].end == 13
    assert ind[2].start == 15 and ind[2].end == 22

    # Test pickling
    d = pickle.dumps(i)
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

    # Test close
    i.close()
    try:
        i.add(10,20)
        assert False
    except NameError:
        assert True

if __name__ == "__main__":
    test_AIList()