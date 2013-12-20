Analysis Example
================

This example uses OpenStudio's Analysis & AWS gem to setup and run simulations on an Amazon OpenStudio Cluster.

Layout
------
* Doc - Contains the spreadsheet (input_data.json).  This is what you will change
* Analysis - These are the exported files that are uploaded to the cloud server to run.
* Seeds - Example seed OSM models
* Weather - Where to dump other weather files of interest
* Measures- Local cache of BCL measures

Instructions
------------

Currently the execution of this requires command line (terminal) access.  

* Make sure to have ruby 2.0 installed and the bundler gem.  Check your version of ruby by running `ruby --version`.

* Install RubyGem's Bundler.  In a command line call the method below.  

```
`gem install bundler`
```
Note Mac 10.9 users using system Ruby 2.0 will need to run `sudo gem install bundler`.

* Install the dependencies by running

```
bundle
```

Note Mac 10.9 users using system Ruby 2.0 may need to run `sudo bundle`

* Run example (will setup the cluster and run the project)

```
bundle exec rake run
```

* Note the first time you run this you will need to add in your AWS creditials in your <home-dir>/config_aws.yml file then run the `bundle exec rake run` command again.  Note that this file should only be readable by you as it contains your secret key for AWS access. The YML file will look something like:

```
access_key_id: YOUR_ACCESS_KEY_ID
secret_access_key: YOUR_SECRET_ACCESS_KEY
```

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

Running Example from Git
---------------

Make sure that you have Ruby 2.0 and the Bundler gem

```
ruby --version
gem install bundler
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


Windows Specific Installation Steps
-----------------------------------

If you have any issues getting gem dependencies installed, it may be helpful to remove all your gems and start over.  to do this run the command below (note that you will need to reinstall bundler after removing all gems).

```
ruby -e "`gem list`.split(/$/).each { |line| puts `gem uninstall -Iax #{line.split(' ')[0]}` unless line.empty? }"
```


If you are using XML (via the BCL gem) then by default the path to the libxml dlls is not included.  You will need to add the path by hand.  To do this find where the DLLs are by going to your Ruby installation directory and making sure they exist. Typically the installation will be something like:

```
C:\Ruby<RUBY_VERSION>\lib\ruby\gems\<RUBY_VERSION>\gems\libxml-ruby-<GEM_VERSION>\lib\libs
```

Add this path to your environment variables.
