Release Notes
=============

.. role:: small
.. role:: smaller


Version 2.0.3
-------------

Large breaking changes to simplify maintance.


Version 0.1.8
-------------

Method additions
	- :func:`~ailist.AIList.index_by_ailist`


Version 0.1.7
-------------

Fixed memory leak
	- Fixed memory leak in :func:`~ailist.AIList.intersect_from_array`
	- Fixed memory leak in :func:`~ailist.AIList.intersect`

Frozen status
	- Ability to make :class:`~ailist.AIList` immutable with :func:`~ailist.AIList.freeze`

Method additions
	- Added ability to index with iterables
	- :func:`~ailist.AIList.downsample` 
	- :func:`~ailist.AIList.bin_sums`
	- :func:`~ailist.AIList.bin_means`

Documentation overhaul
	- Creation of documentation for :class:`~ailist.AIList`
	- Creation of documentation for :class:`~ailist.Interval`