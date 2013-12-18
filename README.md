Analysis Example
================

This example uses OpenStudio's Analysis & AWS gem to setup and run simulations on an Amazon OpenStudio Cluster.

Loyout
------
* Doc - Contains the spreadsheet (input_data.json).  This is what you will change
* Analysis - These are the exported files that are uploaded to the cloud server to run.
* Seeds - Example seed OSM models
* Weather - Where to dump other weather files of interest
* Measures- Local cache of BCL measures

Instructions
------------

Currently the execution of this requires command line (terminal) access.  

* Make sure to have ruby 2.0 installed and the bundler gem.  Check your version of ruby by running `ruby --version`.  To install bundler run `gem install bundler` at the command line. Note Mac 10.9 users using system Ruby 2.0 will need to run `sudo gem install bundler`.

* Install the dependencies by running

```
bundle
```
Note Mac 10.9 users using system Ruby 2.0 may need to run `sudo bundle`

* Run example (will setup the cluster and run the project)

```
bundle exec rake run
```

* Note the first time you run this you will need to add in your AWS creditials, then run again

* Kill running simulations

```
bundle exec rake kill_all
```

* Delete projects

```
bundle exec rake delete_all
```

* Reset analysis (removes the server files) NOTE: this does not kill AWS instances. You must do that manually via the AWS console

```
bundle exec rake clean
```

* To run an analysis on a preconfigured AWS instance

```
bundle exec rake run_analysis
```

Running Example
---------------

Make sure that you have Ruby 2.0 and the Bundler gem

```
ruby --version
gem install bundler
```

In terminal do the following:
```
git clone https://github.com/nllong/os-analysis-example.git
cd os-analysis-example
sudo bundle install
bundle exec rake run
```

Updating Example
----------------

In terminal
```
git pull
bundle update
```
Note: Mac 10.9 users may need to run `sudo bundle update`
