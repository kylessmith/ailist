|Stars| |PyPIDownloads| |PyPI| |Build Status|

.. |Stars| image:: https://img.shields.io/github/stars/kylessmith/ailist?logo=GitHub&color=yellow
   :target: https://github.com/kylessmith/ailist/stargazers
.. |PyPIDownloads| image:: https://pepy.tech/badge/ailist
   :target: https://pepy.tech/project/ailist
.. |PyPI| image:: https://img.shields.io/pypi/v/ailist.svg
   :target: https://pypi.org/project/ailist
.. |Build Status| image:: https://travis-ci.org/kylessmith/ailist.svg?branch=master
   :target: https://travis-ci.org/kylessmith/ailist

ailist – Augmented Interval List implemented in Cython/C
========================================================

The Python-based implementation efficiently deals with many intervals.

Benchmark
~~~~~~~~~

Test numpy random integers, see `benchmarking <benchmarking.html>`__

+-----------+----------------+-----------+
| Library   | Function       | Time (µs) |
+===========+================+===========+
| ncls      | single overlap |      1170 |
+-----------+----------------+-----------+
| quicksect | single overlap |      1050 |
+-----------+----------------+-----------+
| pandas    | single overlap |       241 |
+-----------+----------------+-----------+
| ailist    | single overlap |       102 |
+-----------+----------------+-----------+

As of conducting these benchmarks, only ncls and ailist have bulk query functions.

+-----------+--------------+----------+-----------------+
| Library   | Function     | Time (s) | Max Memory (GB) |
+===========+==============+==========+=================+
| ncls      | bulk overlap | ~151     | >50             |
+-----------+--------------+----------+-----------------+
| ailist    | bulk overlap | ~17.9    | ~9              |
+-----------+--------------+----------+-----------------+

Querying intervals is much faster and more efficient with ailist