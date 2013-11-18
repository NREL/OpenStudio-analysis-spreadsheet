require "bundler"
Bundler.setup

require "rake"
require "rspec/core/rake_task"

require 'bcl'
require 'openstudio-aws'
require 'openstudio-analysis'


desc "create the analysis files"
task :setup do
  # Read, parse, and validate the excel file
  excel_file = "./doc/input_data.xlsx"
  if File.exists?(excel_file)
    excel = OpenStudio::Analysis::Translator::Excel.new("./doc/input_data.xlsx")

    # Print some messages
    puts "Seed models are:"
    excel.models.each do |model|
      puts "  #{model}"
    end

    puts "Weather files to bundle are are:"
    excel.weather_files.each do |wf|
      puts "  #{wf}"
    end

    puts "Saving the analysis JSONS and zips"
    excel.save_analysis() # directory is define in the setup
  else
    puts "ERROR: could not find input excel file: #{excel_file}"
  end
end

desc "test the creation of the cluster"
task :test_create_cluster do
  WORKER_INSTANCES=2

  #require 'openstudio-aws'
  aws = OpenStudio::Aws::Aws.new()
  server_options = {instance_type: "m1.small"}
  #server_options = {instance_type: "m2.xlarge" }

  worker_options = {instance_type: "m1.small"}
  #worker_options = {instance_type: "m2.xlarge" }
  #worker_options = {instance_type: "m2.2xlarge" }
  #worker_options = {instance_type: "m2.4xlarge" }
  #worker_options = {instance_type: "cc2.8xlarge" }

  # Create the server
  aws.create_server(server_options)

  # Create the worker
  aws.create_workers(WORKER_INSTANCES, worker_options)

  # This saves off a file called server_data.json that can be used to read in to run the 
  # next step
end

desc "manually run the model on the AWS cluster"
task :run_model do
  if File.exists?("server_data.json")
    # parse the file and check if the instance appears to be up
    json = JSON.parse(File.read("server_data.json"), :symbolize_names => true)
    server_dns = "http://#{json[:server_dns]}"

    project_name = "medium_office"
    formulation_file = "./analysis/#{project_name}.json"
    analysis_zip_file = "./analysis/#{project_name}.zip"

    # Project data 
    options = {hostname: server_dns}
    api = OpenStudio::Analysis::ServerApi.new(options)

    project_options = {}
    project_id = api.new_project(project_options)

    analysis_options = {formulation_file: formulation_file,
                        upload_file: analysis_zip_file,
                        reset_uuids: true}
    analysis_id = api.new_analysis(project_id, analysis_options)

    run_options = {analysis_action: "start",
                   without_delay: false,
                   analysis_type: "lhs",
                   allow_multiple_jobs: true}
    api.run_analysis(analysis_id, run_options)

    run_options = {analysis_action: "start",
                   without_delay: false,
                   analysis_type: "batch_run",
                   allow_multiple_jobs: true,
                   use_server_as_worker: false,
                   simulate_data_point_filename: "simulate_data_point_lhs.rb"}
    api.run_analysis(analysis_id, run_options)
  else
    puts "There doesn't appear to be a cluster running"
  end
end

desc "run analysis"
task :run => [:setup, :create_cluster, :run_model] do

end

desc "update measures from BCL"
task :update_measures do
  bcl = BCL::ComponentMethods.new
  bcl.login() # have to do this even if you don't set your username to get a session
  
  #json = JSON.parse(bcl.search(nil, "f[0]=bundle%3Anrel_measure&show_rows=100"), :symbolize_names => true)
  json = bcl.list_all_measures()
  if json[:result]
    json[:result].each do |measure|
      if measure[:measure][:name] && measure[:measure][:uuid]
        next if measure[:measure][:name] =~ /Change this to whatever you want/
        next if measure[:measure][:name] =~ /Add Non-Integrated Water Side Economizer/
        puts "Downloading #{measure[:measure][:name]} : #{measure[:measure][:uuid]}"
        file_data = bcl.download_component(measure[:measure][:uuid])
        
        if file_data
          save_file = File.expand_path("./measures/#{measure[:measure][:name].downcase.gsub(" ", "_")}.zip")
          File.open(save_file, 'wb') {|f| f << file_data}
          
          # now unzip the file and read in the arguments (MAC/LINUX Only)
          `cd #{File.dirname(save_file)} && unzip -f #{save_file}`
        end
        
      end
    end
  end

  File.open("junkout.json", 'w') { |f| f << JSON.pretty_generate(json) }
end

task :process_measures do
  Dir.glob("./measures/*.zip").each do |zipfile|
    
  end
  
end

desc "delete all projects on site"
task :delete_all do
  if File.exists?("server_data.json")
    # parse the file and check if the instance appears to be up
    json = JSON.parse(File.read("server_data.json"), :symbolize_names => true)
    server_dns = "http://#{json[:server_dns]}"

    # Project data 
    options = {hostname: server_dns}
    api = OpenStudio::Analysis::ServerApi.new(options)
    api.delete_all()
  else
    puts "There doesn't appear to be a cluster running"
  end


end

task :default do
  system("rake -sT") # s for silent
end
