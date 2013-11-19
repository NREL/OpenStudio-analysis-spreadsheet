require "bundler"
Bundler.setup

require "rake"
require "rspec/core/rake_task"
require 'rake/clean'
require 'bcl'
require 'openstudio-aws'
require 'openstudio-analysis'

NUMBER_OF_WORKERS = 1
PROJECT_NAME = "medium_office"

CLEAN.include('./server_data.json', 'worker_data.json', 'ec2_server_key.pem')
CLOBBER.include('hello')

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
task :create_cluster do
  aws = OpenStudio::Aws::Aws.new()
  #server_options = {instance_type: "m1.small"}  # 1 core ($0.06/hour)
  server_options = {instance_type: "m2.xlarge" } # 2 cores ($0.410/hour)

  #worker_options = {instance_type: "m1.small"} # 1 core ($0.06/hour)
  #worker_options = {instance_type: "m2.xlarge" } # 2 cores ($0.410/hour)
  #worker_options = {instance_type: "m2.2xlarge" } # 4 cores ($0.820/hour)
  #worker_options = {instance_type: "m2.4xlarge" } # 8 cores ($1.64/hour) 
  worker_options = {instance_type: "cc2.8xlarge" } # 16 cores ($2.40/hour) | we turn off hyperthreading

  # Create the server
  aws.create_server(server_options)

  # Create the worker
  aws.create_workers(NUMBER_OF_WORKERS, worker_options)

  # This saves off a file called server_data.json that can be used to read in to run the 
  # next step
end

desc "manually run the model on the AWS cluster"
task :run_model do
  if File.exists?("server_data.json")
    # parse the file and check if the instance appears to be up
    json = JSON.parse(File.read("server_data.json"), :symbolize_names => true)
    server_dns = "http://#{json[:server_dns]}"

    formulation_file = "./analysis/#{PROJECT_NAME}.json"
    analysis_zip_file = "./analysis/#{PROJECT_NAME}.zip"

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
task :run => [:setup, :create_cluster, :run_model]

desc "run vagrant"
task :run_vagrant => [:setup] do
  formulation_file = "./analysis/#{PROJECT_NAME}.json"
  analysis_zip_file = "./analysis/#{PROJECT_NAME}.zip"

  # Project data 
  options = {hostname: 'http://localhost:8080'}
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

desc "make csv file of measures"
task :create_measure_csv do
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
      values << '' # units
      argument[:default_value] ? values << argument[:default_value] : values << ''

      csv << values
    end
  end

  csv.close
end

desc "update measures from BCL"
task :update_measures do
  FileUtils.mkdir_p("./measures")
  bcl = BCL::ComponentMethods.new
  bcl.login() # have to do this even if you don't set your username to get a session

  json = bcl.list_all_measures()
  if json[:result]
    m_cnt = 0
    json[:result].each do |measure|
      if measure[:measure][:name] && measure[:measure][:uuid]
        m_cnt += 1

        # Comment some bad measures
        next if measure[:measure][:name] =~ /Change this to whatever you want/
        next if measure[:measure][:name] =~ /Add Non-Integrated Water Side Economizer/

        #next if measure[:measure][:name] != "Add Daylight Sensor at Center of Spaces with a Specified Space Type Assigned"
        
        file_data = bcl.download_component(measure[:measure][:uuid])

        if file_data
          save_file = File.expand_path("./measures/#{measure[:measure][:name].downcase.gsub(" ", "_")}.zip")
          File.open(save_file, 'wb') { |f| f << file_data }

          # now unzip the file (MAC/LINUX Only) and remove zip
          `cd #{File.dirname(save_file)} && unzip -o #{save_file} && rm -f #{save_file}`

          # Read the measure.rb file and rename the directory
          temp_dir_name = "./measures/#{measure[:measure][:name]}"
          
          # catch a weird case where there is an extra space in an unzip file structure but not in the measure.name
          if measure[:measure][:name] == "Add Daylight Sensor at Center of Spaces with a Specified Space Type Assigned"
            temp_dir_name = "./measures/Add Daylight Sensor at Center of  Spaces with a Specified Space Type Assigned"   
          end
          puts "save dir name #{temp_dir_name}"
          measure_filename = "#{temp_dir_name}/measure.rb"
          if File.exists?(measure_filename)
            measure_hash = {}
            # read in the measure file and extract some information
            measure_string = File.read(measure_filename)

            measure_hash[:classname] = measure_string.match(/class (.*) </)[1]
            measure_hash[:path] = "./measures/#{measure_hash[:classname]}"
            measure_hash[:name] = measure[:measure][:name]
            if measure_string =~ /OpenStudio::Ruleset::WorkspaceUserScript/
              measure_hash[:measure_type] = "EnergyPlusMeasure"
            elsif measure_string =~ /OpenStudio::Ruleset::ModelUserScript/
              measure_hash[:measure_type] = "RubyMeasure"
            elsif measure_string =~ /OpenStudio::Ruleset::ReportingUserScript/
              measure_hash[:measure_type] = "ReportingMeasure"
            else
              raise "measure type is unknown with an inherited class in #{measure_filename}"
            end

            # move the directory to the class name
            FileUtils.rm_rf(measure_hash[:path]) if Dir.exists?(measure_hash[:path]) && temp_dir_name != measure_hash[:path]
            FileUtils.move(temp_dir_name, measure_hash[:path]) unless temp_dir_name == measure_hash[:path]

            measure_hash[:arguments] = []

            args = measure_string.scan(/(.*).*=.*OpenStudio::Ruleset::OSArgument::make(.*)Argument\((.*).*\)/)
            puts args.inspect
            args.each do |arg|
              new_arg = {}
              new_arg[:local_variable] = arg[0].strip
              new_arg[:variable_type] = arg[1]
              new_arg[:name] = arg[2].split(",")[0].gsub(/"|'/, "")

              # local variable name to get other attributes
              new_arg[:display_name] = measure_string.match(/#{new_arg[:local_variable]}.setDisplayName\((.*)\)/)[1]
              new_arg[:display_name].gsub!(/"|'/, "") if new_arg[:display_name]

              if measure_string =~ /#{new_arg[:local_variable]}.setDefaultValue/
                new_arg[:default_value] = measure_string.match(/#{new_arg[:local_variable]}.setDefaultValue\((.*)\)/)[1]
                case new_arg[:variable_type]
                  when "Choice", "String", "Bool"
                    new_arg[:default_value].gsub!(/"|'/, "")
                  when "Integer"
                    new_arg[:default_value] = new_arg[:default_value].to_i
                  when "Double"
                    new_arg[:default_value] = new_arg[:default_value].to_f
                  else
                    raise "unknown variable type of #{new_arg[:variable_type]}"
                end
              end

              measure_hash[:arguments] << new_arg
            end

            # create a new measure.json file for parsing later if need be
            File.open("#{measure_hash[:path]}/measure.json", 'w') { |f| f << JSON.pretty_generate(measure_hash) }

          end


          #break if m_cnt > 2
        end
      end
    end
  end

  # delete the test files
  Dir.glob("./measures/**/tests").each do |file|
    puts "Deleting test file #{file}"
    FileUtils.rm_rf(file)
  end

end

