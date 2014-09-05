Analysis Example Change Log
==================================

There is no formal versioning of this project; however, below is a list of known changes.

Version 0.3.0
-------------
* Removed `rake new` method and template.xlsx. Simply copy and paste one of the template files in the projects folder.
* Update dependencies

Version 0.2.0
------------------------
* Remove the sampling column
* More columns for defining the outputs

Version 0.1.3
------------
* New Spreadsheet Setup sheet format to select instances and number of worker nodes.

Version 0.1.1
-----------
* AMIs in the future will not need the simulate_data_point field, rather the run_data_point_filename. Updated Rakefile to support both

Version 0.1
-------------
* Change XLSX translator to read from a "Variables" spreadsheet instead of "Sensitivity"
* [BUG FIX] Added check for when weather file is a zip or an epw
* [BUG FIX] Convert argument values to the right variable types
* [BUG FIX] Add measure type parsing by reading the inherited class
