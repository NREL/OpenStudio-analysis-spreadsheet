require "bundler"
Bundler.setup

require 'rake'
require 'rake/clean'

require 'openstudio-aws'
require 'openstudio-analysis'
require 'colored'

CLEAN.include("*.pem", "./projects/*.json")

def get_project()
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
    puts "It appears that a cluster for #{excel.cluster_name} is already running.  If this is not the case then delete ./#{excel.cluster_name}.json file".red
    puts "Will try to continue".cyan
  else
    puts "Creating cluster for #{excel.cluster_name}".cyan
    puts "Validating cluster options...".cyan

    raise "Number of workers not defined".red if excel.settings['worker_nodes'].to_i == 0
    
    puts "Number of worker nodes set to #{excel.settings['worker_nodes'].to_i}".cyan
    puts "Starting cluster...".cyan
    
    # TODO: move this over to version 2 once the amis are fixed
    #aws_options = {:ami_lookup_version => 2, :openstudio_server_version => excel.settings['openstudio_server_version']}
    aws_options = {:ami_lookup_version => 1, :openstudio_version => excel.settings['openstudio_server_version']}
    aws = OpenStudio::Aws::Aws.new(aws_options)
    server_options = {instance_type: excel.settings["server_instance_type"]}
    worker_options = {instance_type: excel.settings["worker_instance_type"]}
  
    # Create the server
    aws.create_server(server_options, "#{excel.cluster_name}.json", excel.settings["user_id"])
  
    # Create the worker
    aws.create_workers(excel.settings["worker_nodes"].to_i, worker_options, excel.settings["user_id"])
  
    # This saves off a file called named #{excelfile}.json that can be used to read in to run the 
    # next step
  
    puts "Cluster setup and awaiting analyses".cyan
  end
end

def run_analysis(excel, run_vagrant = false)
  puts "Running the analysis"
  if File.exists?("#{excel.cluster_name}.json") || run_vagrant
    # for each model in the excel file submit the analysis
    server_dns = nil
    if run_vagrant
      server_dns = "http://localhost:8080"
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

      run_options = {
          analysis_action: "start",
          without_delay: true,
          analysis_type: excel.problem['analysis_type'],
          allow_multiple_jobs: excel.run_setup['allow_multiple_jobs'],
          use_server_as_worker: excel.run_setup['use_server_as_worker'],
          simulate_data_point_filename: excel.run_setup['simulate_data_point_filename'],
          run_data_point_filename: excel.run_setup['run_data_point_filename']
      }
      api.run_analysis(analysis_id, run_options)
    end

    puts
    puts "Server URL is: #{server_dns}".bold.cyan
    puts "Make sure to check the AWS console and terminate any jobs when you are finished!".bold.red
  else
    puts "There doesn't appear to be a cluster running for this project #{excel.cluster_name}"
  end
end

desc "create a new analysis (and spreadsheet)"
task :new do
  print "Name of the new project without the file extension (this will make a new spreadsheet): ".cyan
  n = $stdin.gets.chomp

  new_projectfile = nil
  tmp_excel = "./doc/template_input.xlsx"
  if File.exists?(tmp_excel)
    new_projectfile = "./projects/#{n}.xlsx"
    if File.exists?(new_projectfile)
      puts "File already exists, rerun with a new name".red
      exit 1
    end
    FileUtils.copy(tmp_excel, new_projectfile)
  else
    puts "Template file has been deleted (#{tmp_excel}. Best to recheckout the project".red
  end
  puts
  puts "Open the excel file and add in your seed models, weather files, and measures #{new_projectfile}".cyan
  puts "When ready, from the command line run 'rake run' and select the project of interest".cyan
end

desc "create the analysis files with more output"
task :setup do
  excel = get_project()

  puts "Seed models are:".cyan
  excel.models.each do |model|
    puts "  #{model}".green
  end

  puts "Weather files to bundle are are:".cyan
  excel.weather_files.each do |wf|
    puts "  #{wf}".green
  end

  puts "Saving the analysis JSONS and zips".cyan
  excel.save_analysis() # directory is define in the setup

  puts "Finished saving analysis into the analysis directory".cyan
end

desc "test the creation of the cluster"
task :create_cluster do
  excel = get_project()

  create_cluster(excel)
end

desc "run on already configured AWS cluster"
task :run_analysis => :setup do

end

desc "setup problem, start cluster, and run analysis"
task :run do
  excel = get_project()
  excel.save_analysis()
  create_cluster(excel)
  run_analysis(excel)
end

desc "run vagrant"
task :run_vagrant do
  excel = get_project()
  excel.save_analysis()
  run_analysis(excel, true)
end

#desc "kill all running on cloud"
#task :kill_all do
#  excel = get_project()
#  
#  if File.exists?("server_data.json")
#    # parse the file and check if the instance appears to be up
#    json = JSON.parse(File.read("server_data.json"), :symbolize_names => true)
#    server_dns = "http://#{json[:server][:dns]}"
#
#    # Project data 
#    options = {hostname: server_dns}
#    api = OpenStudio::Analysis::ServerApi.new(options)
#    api.kill_all_analyses()
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
#  api.kill_all_analyses()
#end
#
#desc "delete all projects on site"
#task :delete_all do
#  if File.exists?("server_data.json")
#    # parse the file and check if the instance appears to be up
#    json = JSON.parse(File.read("server_data.json"), :symbolize_names => true)
#    server_dns = "http://#{json[:server][:dns]}"
#
#    # Project data 
#    options = {hostname: server_dns}
#    api = OpenStudio::Analysis::ServerApi.new(options)
#    api.delete_all()
#  else
#    puts "There doesn't appear to be a cluster running"
#  end
#end

task :default do
  system("rake -sT") # s for silent
end

desc "make csv file of measures"
task :create_measure_csv do
  require 'CSV'

  new_csv_file = "./doc/bcl_spreadsheet.csv"
  FileUtils.rm_f(new_csv_file) if File.exists?(new_csv_file)
  csv = CSV.open(new_csv_file, "w")
  Dir.glob("./measures/**/*.json").each do |file|
    puts "Parsing Measure JSON #{file}"
    json = JSON.parse(File.read(file), :symbolize_names => true)
    csv << [false, json[:name], json[:classname], json[:measure_type]]

    json[:arguments].each do |argument|
      values = []
      values << ''
      values << 'argument'
      values << argument[:display_name]
      values << argument[:name]
      values << 'static'
      values << argument[:variable_type]
      values << ''
      # units
      
      # watch out because :default_value can be a boolean 
      argument[:default_value].nil? ? values << '' : values << argument[:default_value]
      choices = ''
      if argument[:choices]
        choices << "|#{argument[:choices].join(",")}|" if not argument[:choices].empty?
      end
      values << choices 
      
      csv << values
    end
  end

  csv.close
end

desc "update measures from BCL"
task :update_measures do
  require 'bcl'
  
  FileUtils.mkdir_p("./measures")

  bcl = BCL::ComponentMethods.new
  bcl.parsed_measures_path = "./measures"
  bcl.login() # have to do this even if you don't set your username to get a session
  query = 'NREL'
  #filter = 'show_rows=5'
  
  success = bcl.measure_metadata(query, nil, false)
  if success
    # move the measures to the right place
  end

  # delete the test files
  Dir.glob("#{bcl.parsed_measures_path}/**/tests").each do |file|
    puts "Deleting test file #{file}"
    FileUtils.rm_rf(file)
  end
end

