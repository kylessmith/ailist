Tutorial
=========

.. code-block:: python

	from ailist import LabeledIntervalArray
	
	ail = LabeledIntervalArray()
	ail.add(1, 2, 'a')
	ail.add(3, 4, 'a')
	ail.add(3, 6, 'a')
	ail.add(3, 6, 'b')
	ail.intersect(3,6,"a")
	#LabeledIntervalArray
	#  (3-4, a)
	#  (3-6, a)