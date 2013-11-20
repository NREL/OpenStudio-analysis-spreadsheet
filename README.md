Analysis Example
================

This example uses OpenStudio's Analysis & AWS gem to setup and run simulations on an Amazon OpenStudio Cluster.

Instructions
------------

Currently the execution of this requires command line (terminal) access.  

* Make sure to have ruby 2.0 installed and the bundler gem.  Check your version of ruby by running `ruby --version`.  To install bundler run `gem install bundler` at the command line.

* Install the dependencies by running

```
bundle
```

* Run example (will setup the cluster and run the project)

```
rake run
```

* Note the first time you run this you will need to add in your AWS creditials, then run again

* Kill running simulations

```
rake kill_all
```

* Delete projects

```
rake delete_all
```

* Reset analysis (removes the server files) NOTE: this does not kill AWS instances. You must do that manually via the AWS console

```
rake clean
```

* To run an analysis on a preconfigured AWS instance

```
rake run_analysis
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
sudo bundle update
```
