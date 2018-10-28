AutoTouchPlus
=============

.. image:: https://img.shields.io/travis/sentrip/AutoTouchPlus.svg
    :target: https://travis-ci.com/sentrip/AutoTouchPlus


.. image:: https://coveralls.io/repos/github/sentrip/AutoTouchPlus/badge.svg
    :target: https://coveralls.io/github/sentrip/AutoTouchPlus

.. image:: https://img.shields.io/github/release/sentrip/AutoTouchPlus/all.svg
    :alt: GitHub release 
    :target: https://github.com/sentrip/AutoTouchPlus/releases/latest


A framework for creating better, faster and shorter AutoTouch scripts

* Free software: `MIT License <https://github.com/sentrip/AutoTouchPlus/blob/master/LICENSE>`_
* Documentation: https://sentrip.github.io/AutoTouchPlus/


Features
--------

* Screen watching and advanced interaction
* Web requests and JSON parsing
* Unit-testing framework based on Python's `pytest`
* Functions for system and file operations
* Logging utilities for selective logging
* Object orientation (classes and inheritance)
* Python's `list`, `dict` and `set` objects
* Many of Python's builtins (such as `map`, `filter`, `sorted`, `reversed`, ...)
* Context managers, `with` statement, exceptions and exception-handling similar to Python


Installation
------------
To install AutoTouchPlus, there are 3 methods. 
For ease of installation and usage, all of the modules in AutoTouchPlus are compiled into a single file - "AutoTouchPlus.lua" - that can be imported. 
When installed just run "tests.lua" to ensure everything works and you're ready to go! 


Install from device:
~~~~~~~~~~~~~~~~~~~~
1. Copy the raw text from `install.lua <https://raw.githubusercontent.com/sentrip/AutoTouchPlus/master/install.lua>`_ and paste it into a new script in AutoTouch. 
2. Save and run the script, and you're ready to go!


Install from computer (using developer install script):
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Run the following commands on your computer (requires scp installed on your device)

.. code-block:: shell

  PHONE_IP=<YOUR.PHONES.IP.ADDRESS>
  git clone https://github.com/sentrip/AutoTouchPlus.git
  cd AutoTouchPlus
  ./dev.py install -ip $PHONE_IP


Install with manual file copy:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
1. Download AutoTouchPlus.lua and tests.lua from the `latest release <https://github.com/sentrip/AutoTouchPlus/releases/latest>`_
2. Copy AutoTouchPlus.lua and tests.lua to /var/mobile/Library/AutoTouch/Scripts/


Usage
-----
To use AutoTouchPlus, simply import it at the beginning of your script:

.. code-block:: text

  require("AutoTouchPlus")
  
  -- lets print some nested objects!
  print(str(list{1, 2, (','):join{'a', 'b'}, sorted(list{5, 4, 3})}))


.. include:: HISTORY.rst
