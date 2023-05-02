|Stars| |PyPIDownloads| |PyPI| |Build Status| |Coffee|

.. |Stars| image:: https://img.shields.io/github/stars/kylessmith/ailist?logo=GitHub&color=yellow
   :target: https://github.com/kylessmith/ailist/stargazers
.. |PyPIDownloads| image:: https://pepy.tech/badge/ailist
   :target: https://pepy.tech/project/ailist
.. |PyPI| image:: https://img.shields.io/pypi/v/ailist.svg
   :target: https://pypi.org/project/ailist
.. |Build Status| image:: https://travis-ci.org/kylessmith/ailist.svg?branch=master
   :target: https://travis-ci.org/kylessmith/ailist
.. |Coffee| image:: https://img.shields.io/badge/-buy_me_a%C2%A0coffee-gray?logo=buy-me-a-coffee&color=ff69b4
   :target: https://www.buymeacoffee.com/kylessmith

ailist – Augmented Interval List implemented in Cython/C
========================================================

The Python-based implementation efficiently deals with many intervals.

Benchmark
~~~~~~~~~

Test numpy random integers, see `benchmarking <benchmarking.html>`__

+-----------+----------------+-----------+
| Library   | Function       | Time (µs) |
+===========+================+===========+
| ncls      | single overlap |      916  |
+-----------+----------------+-----------+
| quicksect | single overlap |      1050 |
+-----------+----------------+-----------+
| pandas    | single overlap |       94  |
+-----------+----------------+-----------+
| ailist    | single overlap |       30  |
+-----------+----------------+-----------+

As of conducting these benchmarks, only ncls and ailist have bulk query functions.

+-----------+--------------+----------+-----------------+
| Library   | Function     | Time (s) | Max Memory (GB) |
+===========+==============+==========+=================+
| ncls      | bulk overlap | ~79      | >50             |
+-----------+--------------+----------+-----------------+
| ailist    | bulk overlap | ~5.4     | ~9              |
+-----------+--------------+----------+-----------------+

Querying intervals is much faster and more efficient with ailist