AutoTouchPlus
=============
A framework for creating better, faster and shorter AutoTouch scripts

* Free software: Apache License, Version 2.0
* Documentation: https://sentrip.github.io/AutoTouchPlus/


Features
--------

* Screen watching and interaction
* Web requests and JSON parsing
* Unit-testing framework based on Python's pytest
* Functions for system and file operations
* Object orientation (classes and inheritance)
* Python's "list", "dict" and "set" objects
* Many of Python's builtins (such as "sorted", "reversed", ...)
* Context managers, exceptions and exception-handling similar to Python


Installation
------------
To install this file, there are 3 methods. 
For ease of installation, all of the modules in AutoTouchPlus are compiled into a single file - "AutoTouchPlus.lua" - that can be imported. When installed just run "tests.lua" to ensure everything works and you're ready to go! 

|

Fastest and simplest method:

* Copy the raw text from "install.lua" and paste it into a new script in AutoTouch. Then just save and run the script!


Second, more complicated method:

* Run the following commands on your computer (requires git and scp)

.. code-block:: shell

  PHONE_IP=<YOUR.PHONES.IP.ADDRESS>
  git clone https://github.com/sentrip/AutoTouchPlus.git
  cd AutoTouchPlus
  scp AutoTouchPlus.lua tests.lua root@$PHONE_IP:/var/mobile/Library/AutoTouch/Scripts/


Third, most tedious method (manual file copy):

* Copy "AutoTouchPlus.lua" and "tests.lua" to "/var/mobile/Library/AutoTouch/Scripts"


Usage
-----
To use AutoTouchPlus, simply import it at the beginning of your script:

.. code-block:: text

  require("AutoTouchPlus")
  
  -- lets print some nested objects!
  print(str(list{1, 2, (','):join{'a', 'b'}, sorted(list{5, 4, 3})}))

