# Analysis Examples

[![Dependency Status](https://www.versioneye.com/user/projects/540a3047ccc023a17f0001d5/badge.svg?style=flat)](https://www.versioneye.com/user/projects/540a3047ccc023a17f0001d5)

The OpenStudio Analysis Spreadsheet uses OpenStudio's Analysis & AWS gem to setup and run simulations on an Amazon OpenStudio Cluster.  Example analysis are:

* Monthly Utility Data Calibration
![alt tag](https://cloud.githubusercontent.com/assets/2235296/10324111/7887be68-6c44-11e5-86de-9d004585ad8e.png)

* Timeseries Calibration
![alt tag](https://cloud.githubusercontent.com/assets/2235296/10324119/7d4919ce-6c44-11e5-982a-2216095b523d.png)
![alt tag](https://cloud.githubusercontent.com/assets/2235296/10324120/7ec41f60-6c44-11e5-941d-208286a63b32.png)
 
* Optimization
![alt tag](https://cloud.githubusercontent.com/assets/2235296/10324114/7a4e536a-6c44-11e5-9c64-57ef26658ed3.png)

* Design of Experiments
![alt tag](https://cloud.githubusercontent.com/assets/2235296/10324117/7bc4e34e-6c44-11e5-8bee-894b4412043d.png)

* Uncertainty Quantification
![alt tag](https://cloud.githubusercontent.com/assets/2235296/10324123/802cc5fa-6c44-11e5-86d8-c8db0302d514.png)

## Available Algorithms
* NSGA2 (Nondominated Sorting Genetic Algorithm 2) multi-objective optimization
* SPEA2 (Strength Pareto Evolutionary Algorithm 2) multi-objective optimization
* RGenoud (R version of GENetic Optimization Using Derivaties) single-objective optimization
* PSO (Particle Swarm Optimization) single-objective optimization
* Optim (Gradient based) single-objective optimization
* Latin Hypercube Sampling (LHS)
* Full Factorial Design of Experiments
* Parallel Batch Running
* Preflight [min/median/max] test
* Single Run
* Repeat Run

## OpenStudio Server
  The analysis spreadsheet submits jobs/problems to the OpenStudio Server https://github.com/NREL/OpenStudio-server.
  The architecture of the OS-Server:
  ![alt tag](https://cloud.githubusercontent.com/assets/2235296/10324109/764a00e8-6c44-11e5-8e96-828a06c8df63.png)
  
## User Documentation
  https://github.com/NREL/OpenStudio-analysis-spreadsheet/blob/develop/documentation/spreadsheet_userguide_prerelease.pdf

## Layout
* Analysis - These are the exported files that are uploaded to the cloud server to run.
* Projects - List of projects in the form of analysis spreadsheets. These are the file that you should edit and copy.
* Seeds - Example seed OSM models.
* Weather - Where to dump other weather files of interest.
* Measures- Local cache of BCL measures.

## Instructions

Currently the execution of this requires command line (terminal) access.  

* Make sure to have Ruby 2.0 installed and the bundler gem.  Check your version of Ruby by running `ruby --version`.
* Does not currently work with Ruby 2.2.
* Note that if you are a Windows user, install the 32-bit version of Ruby from here: http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.0.0-p353.exe?direct
* If you are behind a **proxy** then make sure to export the environment variables.  For windows you can add them to your environment or at the command line using. Similar for Mac/Linux except use export.

```
set HTTP_PROXY=proxy.a.com:port  ( e.g. 192.168.0.1:2782 or a.b.com:8080 )
set HTTP_PROXY_USER=user 
set HTTP_PROXY_PASS=password
```

## Running Examples

* Verify Ruby version and install RubyGem's Bundler.  In a command line call the method below.

```
ruby --version
gem install bundler
```
*Note Mac 10.9 users using system Ruby 2.0 will need to run `sudo bundle` if you are using system's Ruby.*

### Using Git

```
git clone https://github.com/NREL/OpenStudio-analysis-spreadsheet.git
cd <path to download>
bundle 
bundle exec rake run
```
*Note Mac 10.9 users using system Ruby 2.0 will need to run `sudo bundle` if you are using system's Ruby.*

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

* Note the first time you run this you will need to add in your AWS credentials in your `<home-dir>/aws_config.yml` file then run the `bundle exec rake run` command again.  Note that this file should only be readable by you as it contains your secret key for AWS access. The YML file will look something like:


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

## Troubleshooting

### AWS

If you just created your Amazon Web Service account and try to run the analysis, you may notice an error regarding verification of the account (see below).

```
Aws::EC2::Errors::PendingVerification: Your account is currently being verified. 
Verification normally takes less than 2 hours. Until your account is verified, 
you may not be able to launch additional instances or create additional volumes. 
If you are still receiving this message after more than 2 hours, please let us 
know by writing to aws-verification@amazon.com. We appreciate your patience.
```

If this happens, wait a couple hours and try again.  You can also contact Amazon to check if they have verified your account.

### Sudo Rights and Mac/Linux

Make sure that you do not run the `bundle exec rake run` command as sudo.  If you do then you will see a permission error on writing to either the .pem or .log files.  If this happens then do the following:
* Run `sudo rake clean`
* Remove the ~/.aws.log from your home directory. `sudo rm -f ~/.aws.log`

### Access Errors

If you experience issues accessing github.com, rubygems.org, or aws.amazon.com, make sure that the path to these sites are not blocked.  Some more information can be found in [this issue](https://github.com/NREL/OpenStudio-analysis-gem/issues/3).

## Todos

* Move the analysis files under need a project specific folder (under project)
* Re-enable the kill_all methods

