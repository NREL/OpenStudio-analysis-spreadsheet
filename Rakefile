require "bundler"
Bundler.setup

require 'rake'
require 'rake/clean'

require 'openstudio-aws'
require 'openstudio-analysis'
require 'colored'
require 'pp'

CLEAN.include("*.pem", "./projects/*.json", "*.json")

def get_project
  # determine the project file to run.  This will list out all the xlsx files and give you a 
  # choice from which to choose
  puts
  puts "Select which project to run from the list below:".cyan.underline
  puts "Note: if this list is too long, simply remove xlsx files from the ./projects directory".cyan
  projects = Dir.glob("./projects/*.xlsx").reject { |i| i =~ /~\$.*/ }
  projects.each_index do |i|
    puts "  #{i+1}) #{File.basename(projects[i])}".green
  end
  puts
  print "Selection (1-#{projects.size}): ".cyan
  n = $stdin.gets.chomp
  n_i = n.to_i
  if n_i == 0 || n_i > projects.size
    puts "Could not process your selection. You entered '#{n}'".red
    exit
  end

  excel = nil
  excel_file = projects[n_i-1]
  if excel_file && File.exists?(excel_file)
    excel = OpenStudio::Analysis::Translator::Excel.new(excel_file)
    excel.process
  else
    puts "Could not find input excel file: #{excel_file}".red
    exit 1
  end

  excel
end

def create_cluster(excel)
  if File.exists?("#{excel.cluster_name}.json")
    puts
    puts "It appears that a cluster for #{excel.cluster_name} is already running. \
If this is not the case then delete ./#{excel.cluster_name}.json file. \
Or run `rake clean`".red
    puts "Will try to continue".cyan
  else
    puts "Creating cluster for #{excel.cluster_name}".cyan
    puts "Validating cluster options".cyan

    if excel.settings['worker_nodes'].to_i == 0
      puts 'Number of workers set to zero'.red
      exit 1
    end

    puts "Number of worker nodes set to #{excel.settings['worker_nodes'].to_i}".cyan
    puts "Starting cluster...".cyan
    
    # Don't use the old API (Version 1)
    aws_options = {
        ami_lookup_version: 2,
        openstudio_server_version: excel.settings['openstudio_server_version']
    }
    aws = OpenStudio::Aws::Aws.new(aws_options)
    
    server_options = {
        instance_type: excel.settings["server_instance_type"],
        user_id: excel.settings["user_id"]
        # aws_key_pair_name: 'custom_key',
        # private_key_file_name: File.expand_path('~/.ssh/private_key')
        # optional -- will default later
        # ebs_volume_id: nil,
    }

    worker_options = {
        instance_type: excel.settings["worker_instance_type"],
        user_id: excel.settings["user_id"]
        # aws_key_pair_name: 'custom_key',
        # private_key_file_name: File.expand_path('~/.ssh/private_key')
    }

    # Create the server & worker
    aws.create_server(server_options, "#{excel.cluster_name}.json")
    aws.create_workers(excel.settings["worker_nodes"].to_i, worker_options)

    # This saves off a file called named #{excelfile}.json that can be used to read in to run the
    server_dns = "http://#{aws.os_aws.server.data.dns}"

    puts "Cluster setup and awaiting analyses. IP address #{server_dns}".cyan
  end
end

def run_analysis(excel, run_vagrant = false, run_NREL24 = false, run_NREL12 = false)
  puts "Running the analysis"
  if File.exists?("#{excel.cluster_name}.json") || run_vagrant || run_NREL12 || run_NREL24
    # for each model in the excel file submit the analysis
    server_dns = nil
    if run_vagrant
      server_dns = "http://localhost:8080"
    elsif run_NREL24
      server_dns ="http://bball-130449.nrel.gov:8080"
    elsif run_NREL12
      server_dns ="http://bball-129913.nrel.gov:8080"
    else
      json = JSON.parse(File.read("#{excel.cluster_name}.json"), :symbolize_names => true)
      server_dns = "http://#{json[:server][:dns]}"
    end

    excel.models.each do |model|
      # parse the file and check if the instance appears to be up

      formulation_file = "./analysis/#{model[:name]}.json"
      analysis_zip_file = "./analysis/#{model[:name]}.zip"

      # Project data 
      options = {hostname: server_dns}
      api = OpenStudio::Analysis::ServerApi.new(options)

      project_options = {}
      project_id = api.new_project(project_options)

      analysis_options = {
          formulation_file: formulation_file,
          upload_file: analysis_zip_file,
          reset_uuids: true
      }
      analysis_id = api.new_analysis(project_id, analysis_options)

     if (excel.problem['analysis_type'] == 'optim') || (excel.problem['analysis_type'] == 'rgenoud')
      run_options = {
          analysis_action: "start",
          without_delay: false, # run in background
          analysis_type: excel.problem['analysis_type'],
          allow_multiple_jobs: excel.run_setup['allow_multiple_jobs'],
          use_server_as_worker: true,
          simulate_data_point_filename: excel.run_setup['simulate_data_point_filename'],
          run_data_point_filename: excel.run_setup['run_data_point_filename']
      }
     else
      run_options = {
          analysis_action: "start",
          without_delay: false, # run in background
          analysis_type: excel.problem['analysis_type'],
          allow_multiple_jobs: excel.run_setup['allow_multiple_jobs'],
          use_server_as_worker: excel.run_setup['use_server_as_worker'],
          simulate_data_point_filename: excel.run_setup['simulate_data_point_filename'],
          run_data_point_filename: excel.run_setup['run_data_point_filename']
      }
     end
      api.run_analysis(analysis_id, run_options)

      # If the analysis is LHS, then go ahead and run batch run because there is 
      # no explicit way to tell the system to do it
      if excel.problem['analysis_type'] == 'lhs' || excel.problem['analysis_type'] == 'preflight' || excel.problem['analysis_type'] == 'single_run'
        run_options = {
            analysis_action: "start",
            without_delay: false, # run in background
            analysis_type: 'batch_run',
            allow_multiple_jobs: excel.run_setup['allow_multiple_jobs'],
            use_server_as_worker: excel.run_setup['use_server_as_worker'],
            simulate_data_point_filename: excel.run_setup['simulate_data_point_filename'],
            run_data_point_filename: excel.run_setup['run_data_point_filename']
        }
        api.run_analysis(analysis_id, run_options)
      end
    end

    puts
    puts "Server URL is: #{server_dns}".bold.cyan
    puts "Make sure to check the AWS console and terminate any jobs when you are finished!".bold.red
  else
    puts "There doesn't appear to be a cluster running for this project #{excel.cluster_name}"
  end
end

desc "create the analysis files with more output"
task :setup do
  excel = get_project

  puts "Seed models are:".cyan
  excel.models.each do |model|
    puts "  #{model}".green
  end

  puts "Weather files to bundle are are:".cyan
  excel.weather_files.each do |wf|
    puts "  #{wf}".green
  end

  puts "Saving the analysis JSONS and zips".cyan
  excel.save_analysis # directory is define in the setup

  puts "Finished saving analysis into the analysis directory".cyan
end

desc "test the creation of the cluster"
task :create_cluster do
  excel = get_project

  create_cluster(excel)
end

desc "setup problem, start cluster, and run analysis (will submit another job if cluster is already running)"
task :run do
  excel = get_project
  excel.save_analysis
  create_cluster(excel)
  run_analysis(excel)
end

desc "run vagrant"
task :run_vagrant do
  excel = get_project
  excel.save_analysis
  run_analysis(excel, true)
end

desc "run NREL12"
task :run_NREL12 do
  excel = get_project
  excel.save_analysis
  run_analysis(excel, false, false, true)
end
desc "run NREL24"
task :run_NREL24 do
  excel = get_project
  excel.save_analysis
  run_analysis(excel, false, true, false)
end

#desc "kill all running on cloud"
#task :kill_all do
#  excel = get_project
#
#  if File.exists?("server_data.json")
#    # parse the file and check if the instance appears to be up
#    json = JSON.parse(File.read("server_data.json"), :symbolize_names => true)
#    server_dns = "http://#{json[:server][:dns]}"
#
#    # Project data
#    options = {hostname: server_dns}
#    api = OpenStudio::Analysis::ServerApi.new(options)
#    api.kill_all_analyses
#  else
#    puts "There doesn't appear to be a cluster running"
#  end
#end
#
#desc "kill all running vagrant"
#task :kill_all_vagrant do
#  server_dns = "http://localhost:8080"
#
#  # Project data
#  options = {hostname: server_dns}
#  api = OpenStudio::Analysis::ServerApi.new(options)
#  api.kill_all_analyses
#end
#

desc "delete all projects on site"
task :delete_all do
  if File.exists?("server_data.json")
    # parse the file and check if the instance appears to be up
    json = JSON.parse(File.read("server_data.json"), :symbolize_names => true)
    server_dns = "http://#{json[:server][:dns]}"

    # Project data 
    options = {hostname: server_dns}
    api = OpenStudio::Analysis::ServerApi.new(options)
    api.delete_all
  else
    puts "There doesn't appear to be a cluster running"
  end
end

desc "delete all projects on site"
task :delete_all_vagrant do
  # parse the file and check if the instance appears to be up
  server_dns = "http://localhost:8080"

  # Project data 
  options = {hostname: server_dns}
  api = OpenStudio::Analysis::ServerApi.new(options)
  api.delete_all
end

task :default do
  system("rake -sT") # s for silent
end

desc "make csv file of measures"
task :create_measure_csv do
  require 'CSV'
  require 'bcl'

  b = BCL::ComponentMethods.new
  new_csv_file = "./doc/local_measures.csv"
  FileUtils.rm_f(new_csv_file) if File.exists?(new_csv_file)
  csv = CSV.open(new_csv_file, "w")
  Dir.glob("./**/measure.json").each do |file|
    puts "Parsing Measure JSON for CSV #{file}"
    json = JSON.parse(File.read(file), :symbolize_names => true)
    b.translate_measure_hash_to_csv(json).each {|r| csv << r}
  end

  csv.close
end

desc "update measure.json files"
task :update_measure_jsons do
  require 'bcl'
  bcl = BCL::ComponentMethods.new

  Dir['./**/measure.rb'].each do |m|
    puts "Parsing #{m}"
    j = bcl.parse_measure_file("useless", m)
    m_j = "#{File.join(File.dirname(m), File.basename(m, '.*'))}.json"
    puts "Writing #{m_j}"
    File.open(m_j, 'w') {|f| f << JSON.pretty_generate(j)}
  end
end

desc "update measure.xml files"
task :update_measure_xmls do

  begin 
    require 'openstudio'
    require 'git'

    #g = Git.open(File.dirname(__FILE__), :log => Logger.new("update_measure_xmls.log"))
    #g = Git.init
    #g.status.untracked.each do |u|
    #  puts u
    #end
        
    os_version = OpenStudio::VersionString.new(OpenStudio::openStudioVersion)
    min_os_version = OpenStudio::VersionString.new("1.4.0")
    if os_version >= min_os_version
      Dir['./**/measure.rb'].each do |m|
        
        # DLM: todo, check for untracked files in this directory and do not compute checksums if they exist
        
        measure = OpenStudio::BCLMeasure::load(OpenStudio::Path.new("#{File.dirname(m)}"))
        if measure.empty?
          puts "Directory #{m} is not a measure"
        else
          measure = measure.get
          measure.checkForUpdates
          #measure.save
        end
      end
    end
    
  rescue LoadError
    puts 'Cannot require openstudio or git'
  end

end

desc "update measures from BCL"
task :update_measures do
  require 'bcl'

  FileUtils.mkdir_p("./measures")

  bcl = BCL::ComponentMethods.new
  bcl.parsed_measures_path = "./measures"
  bcl.login # have to do this even if you don't set your username to get a session

  query = 'NREL%20PNNL%2BBCL%2BGroup'
  success = bcl.measure_metadata(query, nil, true)


  # delete the test files
  Dir.glob("#{bcl.parsed_measures_path}/**/tests").each do |file|
    puts "Deleting test file #{file}"
    FileUtils.rm_rf(file)
  end
end
