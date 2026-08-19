"""
Comprehensive test suite for ailist.LabeledIntervalArray.

Run with:  pytest -v test_LabeledIntervalArray.py

Notes
-----
* These tests target the *built* ``ailist`` extension (the Cython/C package).
  They were authored against the public API as documented in
  ``LabeledIntervalArray_core.pyx`` and could not be executed in the authoring
  environment (no compiled extension available there), so run them once against
  your build to confirm.
* Assertions avoid depending on interval *ordering*, because ``construct()``
  re-decomposes/sorts intervals in place. Set- and length-based invariants are
  used instead.
* ``filter`` length bounds are treated as *exclusive* on both ends
  (``min_length < length < max_length``), matching the C implementation.
"""

import pickle

import numpy as np
import pytest

from ailist import LabeledIntervalArray, __version__


# ---------------------------------------------------------------------------
# Helpers / fixtures
# ---------------------------------------------------------------------------

def interval_set(laia):
    """Return the set of (start, end, label) triples in a LabeledIntervalArray."""
    return {(iv.start, iv.end, iv.label) for iv in laia}


def build(intervals):
    """Build a LabeledIntervalArray from a list of (start, end, label)."""
    laia = LabeledIntervalArray()
    for start, end, label in intervals:
        laia.add(start, end, label)
    return laia


@pytest.fixture
def simple():
    """Small two-label array used across many tests."""
    return build([
        (1, 12, "a"),
        (10, 12, "a"),
        (5, 12, "a"),
        (10, 22, "a"),
        (1, 13, "b"),
        (1, 13, "c"),
    ])


@pytest.fixture
def two_label():
    return build([
        (0, 10, "a"),
        (20, 30, "a"),
        (40, 50, "b"),
        (60, 70, "b"),
    ])


# ---------------------------------------------------------------------------
# Package
# ---------------------------------------------------------------------------

class TestPackage:
    def test_version_is_string(self):
        # Loosened from a hard-coded "2.0.0" so the suite is not brittle to bumps.
        assert isinstance(__version__, str)
        assert __version__ != ""


# ---------------------------------------------------------------------------
# Construction & basic introspection
# ---------------------------------------------------------------------------

class TestConstructionBasics:
    def test_empty(self):
        laia = LabeledIntervalArray()
        assert laia.size == 0
        assert len(laia) == 0
        assert list(laia) == []

    def test_add_and_size(self):
        laia = LabeledIntervalArray()
        laia.add(1, 2, "a")
        laia.add(3, 4, "a")
        laia.add(3, 6, "b")
        assert laia.size == 3
        assert len(laia) == 3

    def test_interval_contents(self, simple):
        expected = {
            (1, 12, "a"), (10, 12, "a"), (5, 12, "a"), (10, 22, "a"),
            (1, 13, "b"), (1, 13, "c"),
        }
        assert interval_set(simple) == expected

    def test_starts_ends_arrays(self, simple):
        starts = simple.starts
        ends = simple.ends
        assert isinstance(starts, np.ndarray)
        assert isinstance(ends, np.ndarray)
        assert len(starts) == simple.size
        assert len(ends) == simple.size
        # Order-independent: the multiset of starts/ends must match the input.
        assert sorted(starts.tolist()) == sorted([1, 10, 5, 10, 1, 1])
        assert sorted(ends.tolist()) == sorted([12, 12, 12, 22, 13, 13])

    def test_unique_labels(self, simple):
        assert set(simple.unique_labels) == {"a", "b", "c"}

    def test_label_counts(self, simple):
        counts = dict(simple.label_counts)
        assert counts["a"] == 4
        assert counts["b"] == 1
        assert counts["c"] == 1

    def test_label_ranges(self, two_label):
        ranges = dict(two_label.label_ranges)
        # label "a": intervals [0,10) and [20,30) -> first=0, last=30
        assert ranges["a"][0] == 0
        assert ranges["a"][1] == 30
        # label "b": [40,50) and [60,70) -> first=40, last=70
        assert ranges["b"][0] == 40
        assert ranges["b"][1] == 70

    def test_labels_property_length(self, simple):
        # `labels` yields per-interval objects; only its length is contractually clear.
        assert len(simple.labels) == simple.size


class TestConstructFlag:
    def test_is_constructed_toggles(self, simple):
        # add() deconstructs; construct() sets the flag.
        assert simple.is_constructed in (True, False)
        simple.construct()
        assert simple.is_constructed is True

    def test_validate_construction(self, simple):
        simple.construct()
        # Should report a successfully-constructed structure (truthy / 1).
        assert simple.validate_construction()

    def test_add_after_construct_redeconstructs(self, simple):
        simple.construct()
        assert simple.is_constructed is True
        simple.add(100, 200, "a")
        # adding invalidates construction
        assert simple.is_constructed is False
        assert simple.size == 7


# ---------------------------------------------------------------------------
# add() guards
# ---------------------------------------------------------------------------

class TestAddGuards:
    def test_start_gt_end_raises(self):
        laia = LabeledIntervalArray()
        with pytest.raises(IndexError):
            laia.add(10, 5, "a")

    def test_add_when_frozen_raises(self):
        laia = build([(1, 5, "a")])
        laia.freeze()
        with pytest.raises(TypeError):
            laia.add(6, 7, "a")

    def test_unfreeze_allows_add(self):
        laia = build([(1, 5, "a")])
        laia.freeze()
        laia.unfreeze()
        laia.add(6, 7, "a")
        assert laia.size == 2

    def test_add_when_closed_raises(self):
        laia = build([(1, 5, "a")])
        laia.close()
        with pytest.raises(NameError):
            laia.add(6, 7, "a")


# ---------------------------------------------------------------------------
# Indexing & iteration
# ---------------------------------------------------------------------------

class TestIndexing:
    def test_int_index_returns_interval(self, two_label):
        two_label.construct()
        iv = two_label[0]
        assert iv.start is not None
        assert iv.end is not None
        # the indexed interval must be one of the originals
        assert (iv.start, iv.end, iv.label) in interval_set(two_label)

    def test_negative_index(self, two_label):
        two_label.construct()
        last = two_label[-1]
        also_last = two_label[two_label.size - 1]
        assert (last.start, last.end, last.label) == (also_last.start, also_last.end, also_last.label)

    def test_out_of_range_positive_raises(self, two_label):
        with pytest.raises(IndexError):
            _ = two_label[two_label.size]

    def test_out_of_range_negative_raises(self, two_label):
        # Very-negative index must raise, not segfault / wrap past 0.
        with pytest.raises(IndexError):
            _ = two_label[-(two_label.size + 1)]

    def test_slice_returns_array(self, two_label):
        sub = two_label[0:2]
        assert isinstance(sub, LabeledIntervalArray)
        assert sub.size == 2

    def test_integer_array_index(self, two_label):
        two_label.construct()
        sub = two_label[np.array([0, 2])]
        assert isinstance(sub, LabeledIntervalArray)
        assert sub.size == 2

    def test_boolean_array_index(self, two_label):
        two_label.construct()
        mask = np.array([True, False, True, False])
        sub = two_label[mask]
        assert isinstance(sub, LabeledIntervalArray)
        assert sub.size == 2


class TestIteration:
    def test_iter_yields_all(self, simple):
        items = list(simple)
        assert len(items) == simple.size

    def test_iter_is_repeatable(self, simple):
        first = interval_set(simple)
        second = interval_set(simple)
        assert first == second

    def test_iter_sorted_count(self, two_label):
        two_label.construct()
        # iter_sorted should visit every interval exactly once
        count = sum(1 for _ in two_label.iter_sorted())
        assert count == two_label.size


# ---------------------------------------------------------------------------
# Intersect / nhits / has_hit
# ---------------------------------------------------------------------------

class TestIntersect:
    def test_intersect_basic(self):
        laia = build([(1, 2, "a"), (3, 4, "a"), (3, 6, "a"), (3, 6, "b")])
        hits = laia.intersect(3, 5, "a")
        assert isinstance(hits, LabeledIntervalArray)
        # [3,4) and [3,6) overlap [3,5); [1,2) does not
        got = {(iv.start, iv.end) for iv in hits}
        assert got == {(3, 4), (3, 6)}

    def test_intersect_respects_label(self):
        laia = build([(3, 6, "a"), (3, 6, "b")])
        hits = laia.intersect(3, 6, "a")
        assert all(iv.label == "a" for iv in hits)
        assert hits.size == 1

    def test_intersect_absent_label_empty(self):
        laia = build([(3, 6, "a")])
        hits = laia.intersect(3, 6, "zzz")
        assert hits.size == 0

    def test_intersect_no_overlap_empty(self):
        laia = build([(3, 6, "a")])
        hits = laia.intersect(100, 200, "a")
        assert hits.size == 0

    def test_nhits(self):
        laia = build([(1, 2, "a"), (3, 4, "a"), (2, 6, "a")])
        # query [3,5): overlaps [3,4) and [2,6) -> 2
        assert laia.nhits(3, 5, "a") == 2

    def test_has_hit_true_false(self):
        laia = build([(3, 6, "a")])
        assert laia.has_hit(4, 5, "a")
        assert not laia.has_hit(100, 200, "a")


# ---------------------------------------------------------------------------
# Set-like operations
# ---------------------------------------------------------------------------

class TestSetOps:
    def test_merge_overlapping(self):
        laia = build([(0, 10, "a"), (5, 15, "a"), (20, 30, "a")])
        merged = laia.merge(gap=0)
        # [0,10) & [5,15) merge -> [0,15); [20,30) stays
        got = {(iv.start, iv.end) for iv in merged}
        assert got == {(0, 15), (20, 30)}

    def test_merge_keeps_labels_separate(self):
        laia = build([(0, 10, "a"), (5, 15, "b")])
        merged = laia.merge(gap=0)
        # different labels do not merge
        assert merged.size == 2

    def test_filter_length(self):
        laia = build([(0, 5, "a"), (0, 50, "a"), (0, 500, "a")])  # lengths 5, 50, 500
        filtered = laia.filter(min_length=1, max_length=400)
        lengths = sorted(iv.end - iv.start for iv in filtered)
        assert lengths == [5, 50]  # 500 excluded (not < 400)

    def test_subtract(self):
        a = build([(0, 100, "a")])
        b = build([(40, 60, "a")])
        result = a.subtract(b)
        got = {(iv.start, iv.end) for iv in result}
        assert got == {(0, 40), (60, 100)}

    def test_subtract_operator(self):
        a = build([(0, 100, "a")])
        b = build([(40, 60, "a")])
        result = a - b
        assert isinstance(result, LabeledIntervalArray)
        assert {(iv.start, iv.end) for iv in result} == {(0, 40), (60, 100)}

    def test_subtract_label_absent_passthrough(self):
        a = build([(0, 100, "a")])
        b = build([(40, 60, "zzz")])
        result = a.subtract(b)
        # label "a" not in b -> interval passes through unchanged
        assert {(iv.start, iv.end, iv.label) for iv in result} == {(0, 100, "a")}

    def test_common(self):
        a = build([(0, 50, "a")])
        b = build([(20, 100, "a")])
        result = a.common(b)
        # common region is [20, 50)
        got = {(iv.start, iv.end) for iv in result}
        assert got == {(20, 50)}

    def test_union_combines_counts(self):
        a = build([(0, 10, "a"), (20, 30, "a")])
        b = build([(40, 50, "b")])
        result = a.union(b)
        assert result.size == 3
        assert set(result.unique_labels) == {"a", "b"}


# ---------------------------------------------------------------------------
# Exact-match family
# ---------------------------------------------------------------------------

class TestExactMatch:
    @pytest.fixture
    def pair(self):
        a = build([(0, 10, "a"), (20, 30, "a"), (40, 50, "b"), (60, 70, "b")])
        b = build([(0, 10, "a"), (20, 30, "b"), (40, 50, "b")])
        # exact (start,end,label) matches: only (0,10,"a") and (40,50,"b")
        return a, b

    def test_where_interval_hit(self):
        laia = build([(0, 10, "a"), (20, 30, "a")])
        idx = laia.where_interval(0, 10, "a")
        assert idx != -1

    def test_where_interval_miss(self):
        laia = build([(0, 10, "a")])
        assert laia.where_interval(1, 2, "a") == -1
        assert laia.where_interval(0, 10, "zzz") == -1

    def test_has_exact_match_shape(self, pair):
        a, b = pair
        mask = a.has_exact_match(b)
        assert isinstance(mask, np.ndarray)
        assert len(mask) == a.size
        assert mask.dtype == bool
        # exactly two of a's intervals match b: (0,10,a) and (40,50,b)
        assert int(mask.sum()) == 2

    def test_is_exact_match_two_masks(self, pair):
        a, b = pair
        mask_a, mask_b = a.is_exact_match(b)
        assert len(mask_a) == a.size
        assert len(mask_b) == b.size
        assert int(mask_a.sum()) == 2
        assert int(mask_b.sum()) == 2

    def test_which_exact_match_pairs(self, pair):
        a, b = pair
        ref_index, query_index = a.which_exact_match(b)
        assert isinstance(ref_index, np.ndarray)
        assert isinstance(query_index, np.ndarray)
        assert len(ref_index) == len(query_index)
        assert len(ref_index) == 2

    def test_filter_exact_match(self, pair):
        a, b = pair
        matched, indices = a.filter_exact_match(b)
        assert isinstance(matched, LabeledIntervalArray)
        # the two exact matches survive the filter
        assert matched.size == 2
        assert {(iv.start, iv.end, iv.label) for iv in matched} == {(0, 10, "a"), (40, 50, "b")}


# ---------------------------------------------------------------------------
# Copy / close lifecycle
# ---------------------------------------------------------------------------

class TestLifecycle:
    def test_copy_is_independent(self):
        a = build([(0, 10, "a"), (10, 20, "b")])
        c = a.copy()
        assert c.size == a.size
        assert interval_set(c) == interval_set(a)
        # mutate the copy; original is unaffected
        c.add(100, 200, "a")
        assert c.size == a.size + 1
        assert (100, 200, "a") not in interval_set(a)

    def test_close_blocks_access(self):
        a = build([(0, 10, "a")])
        a.close()
        assert a.is_closed is True
        with pytest.raises(NameError):
            _ = a.size

    def test_freeze_sets_flag(self):
        a = build([(0, 10, "a")])
        a.freeze()
        assert a.is_frozen is True
        a.unfreeze()
        assert a.is_frozen is False


# ---------------------------------------------------------------------------
# Per-label numeric outputs
# ---------------------------------------------------------------------------

class TestNumeric:
    def test_length_dist_array(self):
        laia = build([(0, 10, "a"), (0, 10, "a"), (0, 20, "a")])
        dist = laia.length_dist()
        assert isinstance(dist, np.ndarray)
        # two intervals of "length bucket" 10 should register
        assert dist.sum() >= 2

    def test_bin_nhits_returns_pair(self):
        laia = build([(0, 100, "a"), (50, 150, "a")])
        laia.construct()
        bins, nhits = laia.bin_nhits(bin_size=50)
        assert isinstance(nhits, np.ndarray)
        assert len(nhits) == len(bins) if hasattr(bins, "__len__") else True
        assert nhits.sum() >= 1

    def test_nhits_from_labeled_array(self):
        ref = build([(0, 100, "a")])
        query = build([(10, 20, "a"), (30, 40, "a")])
        nhits = ref.nhits_from_LabeledIntervalArray(query)
        assert isinstance(nhits, np.ndarray)
        assert nhits.sum() >= 1


# ---------------------------------------------------------------------------
# LabeledInterval object
# ---------------------------------------------------------------------------

class TestLabeledInterval:
    def test_fields(self):
        laia = build([(5, 17, "chr1")])
        laia.construct()
        iv = laia[0]
        assert iv.start == 5
        assert iv.end == 17
        assert iv.label == "chr1"
        assert iv.id_value is not None

    def test_to_array(self):
        laia = build([(5, 17, "chr1")])
        laia.construct()
        iv = laia[0]
        arr = iv.to_array()
        assert arr is not None

    def test_equality_and_hash(self):
        laia = build([(5, 17, "chr1"), (5, 17, "chr1")])
        laia.construct()
        a = laia[0]
        b = laia[1]
        # same coordinates+label compare equal and hash equal
        assert a == b
        assert hash(a) == hash(b)

    def test_pickle_roundtrip(self):
        laia = build([(5, 17, "chr1")])
        laia.construct()
        iv = laia[0]
        restored = pickle.loads(pickle.dumps(iv))
        assert restored.start == iv.start
        assert restored.end == iv.end
        assert restored.label == iv.label


# ---------------------------------------------------------------------------
# Larger / stress-ish (exercises the component decomposition, not just lengths)
# ---------------------------------------------------------------------------

class TestLarger:
    def test_many_intervals_construct_and_count(self):
        laia = LabeledIntervalArray()
        n = 5000
        for i in range(n):
            laia.add(i, i + 10, "a" if i % 2 == 0 else "b")
        laia.construct()
        assert laia.size == n
        counts = dict(laia.label_counts)
        assert counts["a"] + counts["b"] == n

    def test_many_intervals_intersect(self):
        laia = LabeledIntervalArray()
        for i in range(0, 1000, 10):
            laia.add(i, i + 10, "a")
        laia.construct()
        # query [0,25) overlaps [0,10),[10,20),[20,30) -> 3
        assert laia.nhits(0, 25, "a") == 3


if __name__ == "__main__":
    import sys
    sys.exit(pytest.main([__file__, "-v"]))
