source "http://rubygems.org"

gem "rake", "~> 10.3.2"
gem "rubyzip" 
gem "git", :require => false 

# uncomment if you need to update the bcl measures
gem "bcl", "~> 0.5.4"
#gem "bcl", :github => "NREL/bcl-gem"
#gem "bcl", :path => "../bcl-gem"

#gem "openstudio-aws", "~> 0.1.25"
gem "openstudio-aws", :github => "NREL/OpenStudio-aws-gem", :branch => 'aws_rc15_fix'
#gem "openstudio-aws", :path => "../OpenStudio-aws-gem"

gem "aws-sdk-core", "<2.0.0.rc15"

gem "openstudio-analysis", "~> 0.3.4"
#gem "openstudio-analysis", :github => "NREL/OpenStudio-analysis-gem", :branch=> 'develop'
#gem "openstudio-analysis", :path => "../OpenStudio-analysis-gem"

gem "colored", "~> 1.2"

if RUBY_PLATFORM =~ /win32/
  gem "win32console", "~> 1.3.2", :platform => [:mswin, :mingw]
end

group :test do
  gem "rspec", "~> 2.12"
  gem "ci_reporter", "~> 1.9.0"
end

