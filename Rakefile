require "bundler"
Bundler.setup

require 'rake'
require 'rake/clean'

# uncomment if doing development
#require 'bcl'

require 'openstudio-aws'
require 'openstudio-analysis'
require 'colored'

PROJECT_NAME = "medium_office"

CLEAN.include('./server_data.json', 'worker_data.json', 'ec2_server_key.pem')


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
  if File.exists?("#{excel.machine_name}.json")
    puts
    puts "It appears that a cluster for #{excel.machine_name} is already running.  If this is not the case then delete ./#{excel.machine_name}.json file".red
    puts "Will try to continue".blue
  else
    puts "Creating cluster for #{excel.machine_name}".cyan
    aws = OpenStudio::Aws::Aws.new()
    #server_options = {instance_type: "m1.small"}  # 1 core ($0.06/hour)
    server_options = {instance_type: excel.settings["server_instance_type"]} # 2 cores ($0.410/hour)
    worker_options = {instance_type: excel.settings["worker_instance_type"]} # 16 cores ($2.40/hour) | we turn off hyperthreading
  
    # Create the server
    aws.create_server(server_options, "#{excel.machine_name}.json")
  
    # Create the worker
    aws.create_workers(excel.settings["worker_nodes"].to_i, worker_options)
  
    # This saves off a file called named #{excelfile}.json that can be used to read in to run the 
    # next step
  
    puts "Cluster setup and awaiting analyses".blue
  end
end

def run_analysis(excel, run_vagrant = false)
  puts "Running the analysis"
  if File.exists?("#{excel.machine_name}.json") || run_vagrant
    # for each model in the excel file submit the analysis
    server_dns = nil
    if run_vagrant
      server_dns = "http://localhost:8080"
    else
      json = JSON.parse(File.read("#{excel.machine_name}.json"), :symbolize_names => true)
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
          without_delay: false,
          analysis_type: "lhs",
          allow_multiple_jobs: true
      }
      api.run_analysis(analysis_id, run_options)

      run_options = {
          analysis_action: "start",
          without_delay: false,
          analysis_type: "batch_run",
          allow_multiple_jobs: true,
          use_server_as_worker: false,
          simulate_data_point_filename: "simulate_data_point_lhs.rb", # keep for backwards compatibility for 2 versions
          run_data_point_filename: "run_openstudio_workflow.rb"
      }
      api.run_analysis(analysis_id, run_options)
    end

    puts
    puts "Server URL is: #{server_dns}".bold.cyan
    puts "Make sure to check the AWS console and terminate any jobs when you are finished!".bold.red
  else
    puts "There doesn't appear to be a cluster running for this project #{excel.machine_name}"
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

desc "create the analysis files"
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
task :run_vagrant => [:setup] do
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
      values << '' # units
                   # watch out because :default_value can be a boolean 
      argument[:default_value].nil? ? values << '' : values << argument[:default_value]
      argument[:choices] ? values << "|#{argument[:choices].join(",")}|" : values << ''

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

        # Comment some bad measures (for some reason) 
        next if measure[:measure][:name] =~ /Change this to whatever you want/
        next if measure[:measure][:name] =~ /Add Non-Integrated Water Side Economizer/

        # Change and uncomment the below if you want to restrict the tests to a specific measure
        #next if measure[:measure][:name] != "Improve Fan Belt Efficiency"

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
            args.each do |arg|
              new_arg = {}
              new_arg[:local_variable] = arg[0].strip
              new_arg[:variable_type] = arg[1]
              arg_params = arg[2].split(",")
              new_arg[:name] = arg_params[0].gsub(/"|'/, "")
              choice_vector = arg_params[1]

              # local variable name to get other attributes
              new_arg[:display_name] = measure_string.match(/#{new_arg[:local_variable]}.setDisplayName\((.*)\)/)[1]
              new_arg[:display_name].gsub!(/"|'/, "") if new_arg[:display_name]

              if measure_string =~ /#{new_arg[:local_variable]}.setDefaultValue/
                new_arg[:default_value] = measure_string.match(/#{new_arg[:local_variable]}.setDefaultValue\((.*)\)/)[1]
                case new_arg[:variable_type]
                  when "Choice"
                    # Choices to appear to only be strings?
                    new_arg[:default_value].gsub!(/"|'/, "")

                    # parse the choices from the measure 
                    choices = measure_string.scan(/#{choice_vector}.*<<.*("|')(.*)("|')/)

                    new_arg[:choices] = choices.map { |c| c[1] }
                    # if the choices are inherited from the model, then need to just display the default value which
                    # somehow magically works because that is the display name
                    new_arg[:choices] << new_arg[:default_value] unless new_arg[:choices].include?(new_arg[:default_value])
                  when "String"
                    new_arg[:default_value].gsub!(/"|'/, "")
                  when "Bool"
                    new_arg[:default_value] = new_arg[:default_value].downcase == "true" ? true : false
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

