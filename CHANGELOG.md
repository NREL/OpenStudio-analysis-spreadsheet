Analysis Example Change Log
==================================

There is no formal versioning of this project...

Unreleased Version 0.2.0
------------------------

* Remove the sampling column

* More columns for defining the outputs

Version 0.1.3
------------

### Major Changes

* New Spreadsheet Setup sheet format to select instances and number of worker nodes. 

Version 0.1.1
-----------

### Minor Changes

* AMIs in the future will not need the simulate_data_point field, rather the run_data_point_filename. Updated Rakefile to support both

Version 0.1
-------------

### Major Changes (may be backwards incompatible)

* Change XLSX translator to read from a "Variables" spreadsheet instead of "Sensitivity"

### New Features

### Resolved Issues

* Added check for when weather file is a zip or an epw

* Convert argument values to the right variable types

* Add measure type parsing by reading the inherited class
