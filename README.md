# Analysis Example

This example uses OpenStudio's Analysis & AWS gem to setup and run simulations on an Amazon OpenStudio Cluster.

## Layout
* Analysis - These are the exported files that are uploaded to the cloud server to run.
* Projects - List of projects in the form of analysis spreadsheets. These are the file that you should edit and copy.
* Seeds - Example seed OSM models.
* Weather - Where to dump other weather files of interest.
* Measures- Local cache of BCL measures.

## Instructions

Currently the execution of this requires command line (terminal) access.  

* Make sure to have Ruby 2.0 installed and the bundler gem.  Check your version of Ruby by running `ruby --version`.
* Note that if you are a Windows user, install the 32-bit version of Ruby from here: http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.0.0-p353.exe?direct
* If you are behind a **proxy** then make sure to export the environment variables.  For windows you can add them to your environment or at the command line using. Similar for Mac/Linux except use export.

```
set HTTP_PROXY=proxy.a.com:port  ( e.g. 192.168.0.1:2782 or a.b.com:8080 )
set HTTP_PROXY_USER=user 
set HTTP_PROXY_PASS=password
```

## Running Examples

* Verify Ruby version and install RubyGem's Bundler.  In a command line call the method below. *Note Mac 10.9 users using system Ruby 2.0 will need to run `sudo <command>` if you are using system's Ruby.*

```
ruby --version
gem install bundler
```

### Using Git

```
git clone https://github.com/NREL/OpenStudio-analysis-spreadsheet.git
cd os-analysis-example
bundle 
bundle exec rake run
```
Note: Mac 10.9 users may need to call `sudo bundle`

To update simply go to the directory and call

```
git pull
bundle
```

### Without Git

* Download the latest release from https://github.com/NREL/OpenStudio-analysis-spreadsheet/releases
* Unzip into a directory and go to that directory in a command/terminal window
* Run

```
cd <path_to_downloaded_directory>
bundle
bundle exec rake run
```

* Run example (will setup the cluster and run the project)

```
bundle exec rake run
```

* This will now ask which project you want to run. Select the right spreadsheet.

* Note the first time you run this you will need to add in your AWS credentials in your <home-dir>/config_aws.yml file then run the `bundle exec rake run` command again.  Note that this file should only be readable by you as it contains your secret key for AWS access. The YML file will look something like:


```
access_key_id: YOUR_ACCESS_KEY_ID
secret_access_key: YOUR_SECRET_ACCESS_KEY
```

* To run an analysis on a pre-configured AWS instance. The program will look for the pre-defined cluster configuration information and submit to that cluster.

```
bundle exec rake run
```

* To add a new project (spreadsheet)

Copy and rename one of the templates in the `projects` directory.

* Delete projects
Note: this has been disabled.

```
bundle exec rake delete_all
```

* Reset analysis (removes the server files) NOTE: this does not kill AWS instances. You must do that manually via the AWS console
Note: this has been disabled.

```
bundle exec rake clean
```


## Windows Specific Installation Steps

If you have any issues getting gem dependencies installed, it may be helpful to remove all your gems and start over.  to do this run the command below (note that you will need to reinstall bundler after removing all gems).

```
ruby -e "`gem list`.split(/$/).each { |line| puts `gem uninstall -Iax #{line.split(' ')[0]}` unless line.empty? }"
```


If you are using XML (via the BCL gem) then by default the path to the libxml DLLs is not included.  You will need to add the path by hand.  To do this find where the DLLs are by going to your Ruby installation directory and making sure they exist. Typically the installation will be something like:

```
C:\Ruby<RUBY_VERSION>\lib\ruby\gems\<RUBY_VERSION>\gems\libxml-ruby-<GEM_VERSION>\lib\libs
```

Add this path to your environment variables.


## Todos

* Move the analysis files under need a project specific folder (under project)
* Re-enable the kill_all methods
