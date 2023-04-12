from .LabeledIntervalArray_core import LabeledIntervalArray, LabeledInterval
from .Interval_core import Interval
import numpy as np


class IntervalArray(object):
    """
    :class:`~IntervalArray.IntervalArray` stores a list of intervals
    """

    def __init__(self):
        """
        Initialize IntervalArray object

        Parameters
        ----------
            None

        Returns
        -------
            None

        """

        self._laia = LabeledIntervalArray()

    
    @property
    def is_closed(self):
        """
        Whether object is still in memory
        """

        self._laia.is_closed

    @property
    def is_frozen(self):
        """
        Whether object is immutable
        """

        return self._laia.is_frozen

    
    @property	
    def size(self):
        """
        Number of intervals in IntervalArray
        """

        return self._laia.size


    @property
    def range(self):
        """
        Ranges(start,  end) for each label
        """

        label_ranges = self._laia.label_ranges()
        if len(label_ranges) == 0:
            return None            
        
        return label_ranges["_IntervalArray"]

	
    @property
    def is_constructed(self):
        """
        Whether IntervalArray is constructed or not
        """

        return self._laia.is_constructed
	
    @property
    def starts(self):
        """
        Start values
        """

        starts = self._laia.starts

        return starts

	
    @property
    def ends(self):
        """
        End values
        """

        ends = self._laia.ends

        return ends

    def __len__(self):
        """
        Return size of IntervalArray
        """
        
        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        return self.size

	
    def __iter__(self):
        """
        Iterate over IntervalArray object
        """

        # Check if is constructed
        if self.is_constructed == False:
            self.construct()

        # Iterate through intervals
        for interval in self._laia:
            yield Interval(interval.start, interval.end)

	
    def __hash__(self):
        """
        Get hash value
        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        return hash(self)


    def _wrap_laia(self, laia):
        """
        """

        self._laia.close()
        if isinstance(laia, LabeledInterval):
            laia = laia.to_array()
        self._laia = laia
    

    def __getitem__(self, key):
        """
        Index Intervals by value
        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Check that key given id 1D
        if isinstance(key, tuple) and len(key) == 2:
            raise IndexError("Incorrect number of dimensions given.")

        # Index
        if isinstance(key, int):
            new_labeled_intervals = self._laia.__getitem__(key)
            new_interval = Interval(new_labeled_intervals.start, new_labeled_intervals.end)

            return new_interval
        else:
            new_intervals = IntervalArray()
            new_labeled_intervals = self._laia.__getitem__(key)
            new_intervals._wrap_laia(new_labeled_intervals)

            return new_intervals


    def __repr__(self):
        """
        Representation of IntervalArray object
        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Initialize string
        repr_string = "IntervalArray\n"

        # Iterate over labeled_interval_list
        if self.size > 10:
            for i in range(5):
                repr_string += "   (%d-%d)\n" % (self[i].start, self[i].end)
            repr_string += "   ...\n"
            for i in range(-5, 0, 1):
                repr_string += "   (%d-%d)\n" % (self[i].start, self[i].end)
        else:
            for i in range(self.size):
                repr_string += "   (%d-%d)\n" % (self[i].start, self[i].end)

        return repr_string


    def freeze(self):
        """
        Make :class:`~ailist.IntervalArray` immutable

        Parameters
        ----------
            None

        Returns
        -------
            None

        See Also
        --------
        IntervalArray.unfreeze: Make mutable
        IntervalArray.sort: Sort intervals inplace
        IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect

        Examples
        --------
        >>> from ailist import IntervalArray
        >>> ail = IntervalArray()
        >>> ail.add(1, 2)
        >>> ail.add(3, 4)
        >>> ail.add(3, 6)
        >>> ail
        IntervalArray
            (1-2)
            (3-4)
            (3-6)
        >>> ail.freeze()
        >>> ail.add(9, 10)
        TypeError: IntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Make sure it is constructed
        if self.is_constructed == False:
            self.construct()

        # Change to frozen
        self.is_frozen = True


    def unfreeze(self):
        """
        Make :class:`~ailist.IntervalArray` mutable

        Parameters
        ----------
            None

        Returns
        -------
            None

        See Also
        --------
        IntervalArray.freeze: Make immutable
        IntervalArray.sort: Sort intervals inplace
        IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect

        Examples
        --------
        >>> from aiarray import IntervalArray
        >>> ail = IntervalArray()
        >>> ail.add(1, 2)
        >>> ail.add(3, 4)
        >>> ail.add(3, 6)
        >>> ail
        IntervalArray
            (1-2)
            (3-4)
            (3-6)
        >>> ail.freeze()
        >>> ail.add(9, 10)
        TypeError: IntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.
        >>> ail.unfreeze()
        >>> ail.add(9, 10)

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Change to not frozen
        self.is_frozen = False


    def add(self, start, end):
        """
        Add an interval to IntervalArray inplace
        
        Parameters
        ----------
            start : int
                Start position of interval
            end : int
                End position of interval

        Returns
        -------
            None

        See Also
        --------
        IntervalArray.from_array: Add intervals from arrays
        IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect
        IntervalArray.intersect: Find intervals overlapping given range

        Examples
        --------
        >>> from ailist import IntervalArray
        >>> ail = IntervalArray()
        >>> ail.add(1, 2)
        >>> ail.add(3, 4)
        >>> ail.add(3, 6)
        >>> ail
        IntervalArray
            (1-2)
            (3-4)
            (3-6)

        """
        
        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Check that object is not frozen
        if self.is_frozen:
            raise TypeError("IntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.")

        # Add
        if isinstance(start, int):
            self._laia.add(start, end, "_IntervalArray")
        elif isinstance(start, np.ndarray):
            labels = np.repeat("_IntervalArray", len(start))
            self._laia.add(start, end, labels)

	
    def append(self, other_ail):
        """
        Add intervals from arrays to IntervalArray inplace
        
        Parameters
        ----------
            other_ail : IntervalArray
                Intervals to add to current IntervalArray

        Returns
        -------
            None

        See Also
        --------
        IntervalArray.add: Add interval to IntervalArray
        IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect
        IntervalArray.intersect: Find intervals overlapping given range

        Examples
        --------
        >>> from ailist import IntervalArray
        >>> import numpy as np
        >>> starts = np.arange(100)
        >>> ends = starts + 10
        >>> labels = np.repeat('a', len(starts))
        >>> ail = IntervalArray()
        >>> ail.from_array(starts, ends, labels)
        >>> ail
        IntervalArray
            (0-10, a)
            (1-11, a)
            (2-12, a)
            (3-13, a)
            (4-14, a)
            ...
            (95-105, a)
            (96-106, a)
            (97-107, a)
            (98-108, a)
            (99-109, a)
        
        >>> len(ail)
        100

        >>> ail2 = IntervalArray()
        >>> ail2.from_array(starts, ends, labels)
        >>> ail.append(ail2)
        >>> ail
        IntervalArray
            (0-10, a)
            (1-11, a)
            (2-12, a)
            (3-13, a)
            (4-14, a)
            ...
            (95-105, a)
            (96-106, a)
            (97-107, a)
            (98-108, a)
            (99-109, a)
        
        >>> len(ail)
        200

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Check that object is not frozen
        if self.is_frozen:
            raise TypeError("IntervalArray is frozen and currently immutatable. Try '.unfreeze()' to reverse.")
        
        self._laia.append(other_ail._laia)


    def construct(self, min_length = 20):
        """
        Construct labeled_aiarray_t *Required to call intersect

        Parameters
        ----------
            min_length : int
                Minimum length

        Returns
        -------
            None


        See Also
        --------
        IntervalArray.sort: Sort intervals inplace
        IntervalArray.intersect: Find intervals overlapping given range

        Examples
        --------
        >>> from ailist import IntervalArray
        >>> ail = IntervalArray()
        >>> ail.add(1, 2)
        >>> ail.add(3, 4)
        >>> ail.add(2, 6)
        >>> ail
        IntervalArray
            (1-2)
            (3-4)
            (2-6)
        >>> ail.construct()
        >>> ail
        IntervalArray
            (1-2)
            (2-6)
            (3-4)

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("Labledaiarray object has been closed.")

        # Check if already constructed
        if self.is_constructed == False:
            self._laia.construct()
        else:
            pass


    def iter_sorted(self):
        """
        Iterate over an IntervalArray in sorted way
        
        Parameters
        ----------
            None
        
        Returns
        -------
            sorted_iter : Generator
                Generator of LabeledIntervals

        See Also
        --------
        IntervalArray.sort: Sort intervals inplace
        IntervalArray.intersect: Find intervals overlapping given range

        Examples
        --------
        >>> from ailist import IntervalArray
        >>> ail = IntervalArray()
        >>> ail.add(1, 2)
        >>> ail.add(3, 4)
        >>> ail.add(2, 6)
        >>> ail
        LabledIntervalArray
            (1-2)
            (3-4)
            (2-6)
        >>> s_iter = ail.iter_sorted()
        >>> for i in s_iter:
        >>>		print(i)
        Interval(1-2)
        Interval(2-6)
        Interval(3-4)

        """

        # Check if is constructed
        if self.is_constructed == False:
            self.construct()

        # Iterate over labels in ail
        for i in self._laia.iter_sorted():
            interval = Interval(i.start, i.end)
            yield interval


    def iter_intersect(self,
                        query_laia,
                        return_intervals = True,
                        return_index = False):
        """
        """

        # Check if is constructed
        if self.is_constructed == False:
            self.construct()

        if return_intervals:
            if return_index:
                for overlaps, index in self._laia.iter_intersect(query_laia._laia,
                                                           return_intervals = True,
                                                           return_index = True):
                    i_overlaps = IntervalArray()
                    i_overlaps._wrap_laia(overlaps)
                    yield i_overlaps, index
            else:
                for overlaps in self.laia.iter_intersect(query_laia._laia,
                                                        return_intervals = True,
                                                        return_index = False):
                    i_overlaps = IntervalArray()
                    i_overlaps._wrap_laia(overlaps)
                    yield i_overlaps

        elif return_index:
            for index in self.iter_intersect(query_laia._laia,
                                             return_intervals = False,
                                             return_index = True):
                yield index


    def intersect(self, 
                    start, 
                    end, 
                    return_intervals = True,
                    return_index = False):
        """
        Find intervals overlapping given range
        
        Parameters
        ----------
            start : int | np.ndarray
                Start position of query range
            end : int | np.ndarray
                End position of query range

        Returns
        -------
            overlaps : IntervalArray
                Overlapping intervals

        .. warning::
            This requires :func:`~aiarray.IntervalArray.construct` and will run it if not already run. This will re-sort intervals inplace is ail.track_index = False.

        See Also
        --------
        IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect
        IntervalArray.add: Add interval to IntervalArray
        IntervalArray.intersect_index: Find interval indices overlapping given range
        IntervalArray.intersect_from_array: Find interval indices overlapping given ranges

        Examples
        --------
        >>> from ailist import IntervalArray
        >>> ail = IntervalArray()
        >>> ail.add(1, 2)
        >>> ail.add(3, 4)
        >>> ail.add(3, 6)
        >>> ail.add(3, 6)
        >>> ail
        IntervalArray
            (1-2)
            (3-4)
            (3-6)
            (3-6)
        >>> q = ail.intersect(2, 10)
        >>> q
        IntervalArray
            (3-4)
            (3-6)

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Check if is constructed
        if self.is_constructed == False:
            self.construct()

        # Intersect
        if return_intervals:
            if return_index:
                label_overlaps, indices = self._laia.intersect(start, end, "_IntervalArray",
                                                               return_intervals=True,
                                                               return_index=True)
                overlaps = IntervalArray()
                overlaps._wrap_laia(label_overlaps)
                return overlaps, indices

            else:
                label_overlaps = self._laia.intersect(start, end, "_IntervalArray",
                                                      return_intervals=True,
                                                      return_index=False)
                overlaps = IntervalArray()
                overlaps._wrap_laia(label_overlaps)
                return overlaps

        elif return_index:
            indices = self._laia.intersect(start, end, "_IntervalArray",
                                            return_intervals=False,
                                            return_index=True)
            return indices

	
    def has_hit(self, start, end):
        """
        Find interval indices overlapping given ranges
        
        Parameters
        ----------
            starts : int | numpy.ndarray {long}
                Start positions of intervals
            ends : int | numpy.ndarray {long}
                End positions of intervals

        Returns
        -------
            has_hit : np.ndarray {bool}
                Bool array indicated overlap detected

        .. warning::
            This requires :func:`~aiarray.IntervalArray.construct` and will run it if not already run. This will re-sort intervals inplace if ail.track_index = False.

        See Also
        --------
        IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect
        IntervalArray.add: Add interval to IntervalArray
        IntervalArray.intersect: Find intervals overlapping given range
        IntervalArray.intersect_index: Find interval indices overlapping given range

        Examples
        --------
        >>> from aiarray import IntervalArray
        >>> ail1 = IntervalArray()
        >>> ail1.add(1, 2)
        >>> ail1.add(3, 4)
        >>> ail1.add(2, 6)
        >>> ail1
        IntervalArray
            (1-2)
            (3-4)
            (2-6)
        >>> ail2 = IntervalArray()
        >>> ail2.add(1, 2)
        >>> ail2.add(3, 6)
        >>> ail2
        IntervalArray
            (1-2)
            (3-6)
        >>> q = ail1.intersect_from_array(ail2)
        >>> q
        (array([2, 1]), array([]))

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Check if object is constructed
        if self.is_constructed == False:
            self.construct()

        # Initialize variables
        if isinstance(start, int):
            has_hit = self._laia.has_hit(start, end, "_IntervalArray")
        elif isinstance(start, np.ndarray):
            labels = np.repeat("_IntervalArray", len(start))
            has_hit = self._laia.has_hit(start, end, labels)
        
        return has_hit


    def intersect_from_IntervalArray(self,
                                     ail_query,
                                     return_intervals = True,
                                     return_index = False):
        """
        Find interval indices overlapping given ranges
        
        Parameters
        ----------
            ail_query : IntervalArray
                Intervals to query

        Returns
        -------
            ref_index : np.ndarray{int}
                Overlapping interval indices from IntervalArray
            query_index : np.ndarray{int}
                Overlapping interval indices from query IntervalArray

        See Also
        --------
        IntervalArray.construct: Construct IntervalArray, required to call IntervalArray.intersect
        IntervalArray.add: Add interval to IntervalArray
        IntervalArray.intersect: Find intervals overlapping given range
        IntervalArray.intersect_from_array: Find interval indices overlapping given range

        Examples
        --------
        >>> from ailist import IntervalArray
        >>> ail1 = IntervalArray()
        >>> ail1.add(1, 2)
        >>> ail1.add(3, 4)
        >>> ail1.add(2, 6)
        >>> ail1
        IntervalArray
            range: (1-6)
            (1-2)
            (3-4)
            (2-6)
        >>> ail2 = IntervalArray()
        >>> ail2.add(1, 2)
        >>> ail2.add(3, 6)
        >>> ail2.add(3, 6)
        >>> ail2
        IntervalArray
            (1-2)
            (3-6)
        >>> q = ail1.intersect_from_IntervalArray(ail2)
        >>> q
        (array([0, 1, 1]), array([0, 2, 1]))

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Check if object is constructed
        if self.is_constructed == False:
            self.construct()

        if return_intervals:
            if return_index:
                label_overlaps, indices = self._laia.intersect_from_LabeledIntervalArray(ail_query._laia,
                                                                                    return_intervals=True,
                                                                                    return_index=True)
                overlaps = IntervalArray()
                overlaps._wrap_laia(label_overlaps)
                return overlaps, indices
            else:
                label_overlaps = self._laia.intersect_from_LabeledIntervalArray(ail_query._laia,
                                                                                    return_intervals=True,
                                                                                    return_index=False)
                overlaps = IntervalArray()
                overlaps._wrap_laia(label_overlaps)
                return overlaps

        elif return_index:
            query_index, ref_index = self._laia.intersect_from_LabeledIntervalArray(ail_query._laia,
                                                                                    return_intervals=False,
                                                                                    return_index=True)
            return query_index, ref_index


    def nhits(self, start, end, min_length=None, max_length=None):
        """
        Find number of intervals overlapping given
        positions
        
        Parameters
        ----------
            starts : numpy.ndarray {long}
                Start positions to intersect
            ends : numpy.ndarray {long}
                End positions to intersect
            min_length : int
                Minimum length of intervals to include [default = None]
            max_length : int
                Maximum length of intervals to include [default = None]

        Returns
        -------
            nhits : numpy.ndarray{int}
                Number of hits per position

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("aiarray object has been closed.")

        # Make sure list is constructed
        if self.is_constructed == False:
            self.construct()

        if isinstance(start, int):
            nhits = self._laia.nhits(start, end, "_IntervalArray", max_length, min_length)
        elif isinstance(start, np.ndarray):
            labels = np.repeat("_IntervalArray", len(start))
            nhits = self._laia.nhits(start, end, labels, max_length, min_length)

        return nhits


    def bin_nhits(self, bin_size=100000, min_length=None, max_length=None):
        """
        Find number of intervals overlapping binned
        positions
        
        Parameters
        ----------
            bin_size : int
                Size of the bin to use
            min_length : int
                Minimum length of intervals to include [default = None]
            max_length : int
                Maximum length of intervals to include [default = None]

        Returns
        -------
            bins : pandas.Series {double}
                Position on index and coverage as values

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Determine bins
        label_bins = self._laia.bin_nhits(bin_size, min_length, max_length)
        bins = IntervalArray()
        bins._wrap_laia(label_bins)

        return bins

	
    def nhits_from_IntervalArray(self, query_laia, min_length=None, max_length=None):
        """
        Find number of intervals overlapping 
        
        Parameters
        ----------
            query_laia : IntervalArray
                Intervals to query
            min_length : int
                Minimum length of intervals to include [default = None]
            max_length : int
                Maximum length of intervals to include [default = None]

        Returns
        -------
            bins : pandas.Series {double}
                Position on index and coverage as values

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")
        if query_laia.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Initialize nhits
        nhits = self._laia.nhits_from_LabeledIntervalArray(query_laia, min_length, max_length)
        
        return nhits


    def wps(self, protection=60, min_length=None, max_length=None):
        """
        Calculate Window Protection Score
        for each position in IntervalArray range
        
        Parameters
        ----------
            protection : int
                Protection window to use
            min_length : int
                Minimum length of intervals to include [default = None]
            max_length : int
                Maximum length of intervals to include [default = None]

        Returns
        -------
            wps : pandas.Series {double}
                Position on index and WPS as values

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("aiarray object has been closed.")

        # Check if empty
        if self.laia.total_nr == 0:
                return None

        # Determine which labels to calculate
        wps_results = self._laia.wps(protection, "_IntervalArray", min_length, max_length)
        wps = wps_results["_IntervalArray"]
        
        return wps


    def coverage(self, min_length=None, max_length=None):
        """
        Calculate coverage
        for each position in IntervalArray range
        
        Parameters
        ----------
            min_length : int
                Minimum length of intervals to include [default = None]
            max_length : int
                Maximum length of intervals to include [default = None]

        Returns
        -------
            cov_results : dict {str:numpy.ndarray}
                Coverage as values

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("aiarray object has been closed.")

        # Check if empty
        if self.laia.total_nr == 0:
                return None

        # Determine which labels to calculate
        cov_results = self._laia.coverage("_IntervalArray", min_length, max_length)
        cov = cov_results["_IntervalArry"]
        
        return cov


    def merge(self, gap=0):
        """
        Merge intervals within a gap
        
        Parameters
        ----------
            gap : int
                Gap between intervals to merge

        Returns
        -------
            merged_list : IntervalArray
                Merged intervals

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("aiarray object has been closed.")

        # Make sure list is constructed
        if self.is_constructed == False:
            self.construct()

        # Create merged
        label_merged_list = self._laia.merge(gap)
        merged_list = IntervalArray()
        merged_list._wrap_laia(label_merged_list)

        return merged_list


    def filter(self, min_length=1, max_length=400):
        """
        Filter out intervals outside of a length range
        
        Parameters
        ----------
            min_length : int
                Minimum length to keep
            max_length : int
                Maximum langth to keep

        Returns
        -------
            filtered_ail : IntervalArray
                Filtered intervals

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Initialize filtered list
        label_filtered = self._laia.filter(min_length, max_length)
        filtered = IntervalArray()
        filtered._wrap_laia(label_filtered)

        return filtered


    def downsample(self,
                    proportion,
                    return_intervals = True,
                    return_index = True):
        """
        Randomly downsample IntervalArray
        
        Parameters
        ----------
            proportion : double
                Proportion of intervals to keep

        Returns
        -------
            filtered_ail : IntervalArray
                Downsampled IntervalArray

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        if return_intervals:
            if return_index:
                label_filtered, indices = self._laia.downsample(proportion,
                                                                return_intervals=True,
                                                                return_index=False)
                filtered = IntervalArray()
                filtered._wrap_laia(label_filtered)
                return filtered, indices
            else:
                label_filtered = self._laia.downsample(proportion,
                                                        return_intervals=True,
                                                        return_index=False)
                filtered = IntervalArray()
                filtered._wrap_laia(label_filtered)
                return filtered

        elif return_index:
            indices = self._laia.downsample(proportion, return_intervals=False, return_index=True)
            return indices


    def length_dist(self):
        """
        Calculate length distribution of intervals

        Parameters
        ----------
            None
        
        Returns
        -------
            distribution : numpy.ndarray{int}
                Interval length distribution

        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("AIList object has been closed.")


        # Calculate distribution
        distribution = self._laia.length_dist()

        return distribution


    def filter_exact_match(self, other_aiarray):
        """
        Determine which intervals are present
        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("AIList object has been closed.")

        # Check construction
        if self.is_constructed == False:
            self.construct()
        if other_aiarray.is_constructed == False:
            other_aiarray.construct()

        label_matched_ail, indices = self._laia.filter_exact_match(other_aiarray._laia)
        matched_ail = IntervalArray()
        matched_ail._wrap_laia(label_matched_ail)

        return matched_ail, indices


    def has_exact_match(self, other_aiarray):
        """
        Determine which intervals are present
        """

        # Check if object is still open
        if self.is_closed or other_aiarray.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Check if objects are constructed
        if self.is_constructed == False:
            self.construct()
        if other_aiarray.is_constructed == False:
            other_aiarray.construct()

        # Find matches
        has_match = self._laia.has_exact_match(other_aiarray._laia)

        return has_match


    def index_with_aiarray(self, other_aiarray):
        """
        """

        # Check if object is still open
        if self.is_closed or other_aiarray.is_closed:
            raise NameError("IntervalArray object has been closed.")

        return_code = self._laia.index_with_aiarray(other_aiarray._laia)

        if return_code == 1:
            raise NameError("Failed to run properly. Values are likely currupted now.")


    @staticmethod
    def create_bin(bin_range, bin_size=100000):
        """
        """

        label_range = {"_IntervalArray": bin_range}
        laia = LabeledIntervalArray.create_bin(label_range, bin_size)
        aia = IntervalArray()
        aia._wrap_laia(laia)

        return aia


    def simulate(self):
        """
        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        label_simulation = self._laia.simulate()
        simulation = IntervalArray()
        simulation._wrap_laia(label_simulation)

        return simulation


    def sorted_index(self):
        """
        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Check if objects are constructed
        if self.is_constructed == False:
            self.construct()

        sorted_index = self._laia.sorted_index()

        return sorted_index


    def sort(self):
        """
        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        # Check if objects are constructed
        if self.is_constructed == False:
            self.construct()

        self._laia.sort()

        return


    def validate_construction(self):
        """
        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")
        
        res = self._laia.validate_construction()

        return res


    def copy(self):
        """
        Copy IntervalArray
        """

        # Check if object is still open
        if self.is_closed:
            raise NameError("IntervalArray object has been closed.")

        laia_copied = self._laia.copy()
        aia_copied = IntervalArray()
        aia_copied._wrap_laia(laia_copied)

        return aia_copied


    def close(self):
        """
        Close object and clear memory
        """

        # Free IntervalArray memory
        self._laia.close()