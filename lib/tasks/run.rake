def create_json(building_type, template, climate_zone, total_bldg_area_ip,settings,seed_model)

  # setup
  measures = []

  # start of OpenStudio measures

  # adding space_type_and_construction_set_wizard
  arguments = [] # :value is just a value
  variables = [] # :value needs to be a hash {type: nil,  minimum: nil, maximum: nil, mean: nil, status_value: nil}
  arguments << {:name => 'buildingType', :desc => 'Building Type', :value => building_type}
  arguments << {:name => 'template', :desc => 'Template', :value => template}
  arguments << {:name => 'climateZone', :desc => 'Climate Zone', :value => climate_zone}
  arguments << {:name => 'createConstructionSet', :desc => 'Create Construction Set?', :value => true}
  arguments << {:name => 'setBuildingDefaults', :desc => 'Set Building Defaults Using New Objects?', :value => true}
  measures << {
      :name => 'space_type_and_construction_set_wizard',
      :desc => 'Space Type And Construction Set Wizard',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'SpaceTypeAndConstructionSetWizard')}",
      :arguments => arguments,
      :variables => variables
  }

  # adding bar_aspect_ratio_study
  arguments = [] # :value is just a value
  variables = [] # :value needs to be a hash {type: nil,  minimum: nil, maximum: nil, mean: nil, status_value: nil}
  arguments << {:name => 'total_bldg_area_ip', :desc => 'Total Building Floor Area (ft^2).', :value => total_bldg_area_ip}
  arguments << {:name => 'surface_matching', :desc => 'Surface Matching', :value => true}
  arguments << {:name => 'make_zones', :desc => 'Make Zones', :value => true}
  variables << {:name => 'ns_to_ew_ratio', :desc => 'Ratio of North/South Facade Length Relative to East/West Facade Length.', :value => {type: 'uniform', minimum: 0.2, maximum: 5.0, mean: 2.0, static_value: 2.0}}
  variables << {:name => 'num_floors', :desc => 'Number of Floors.', :value => {type: 'uniform', minimum: 1, maximum: 10, mean: 2, static_value: 2}}
  variables << {:name => 'floor_to_floor_height_ip', :desc => 'Floor to Floor Height.', :value => {type: 'uniform', minimum: 8, maximum: 20, mean: 10, static_value: 10}}
  measures << {
      :name => 'bar_aspect_ratio_study',
      :desc => 'Bar Aspect Ratio Study',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'BarAspectRatioStudy')}",
      :arguments => arguments,
      :variables => variables
  }

  # populate hash for wwr measure
  wwr_hash = {}
  wwr_hash["North"] = {type: 'uniform', minimum: 0, maximum: 0.6, mean: 0.4, static_value: 0.4}
  wwr_hash["East"] = {type: 'uniform', minimum: 0, maximum: 0.6, mean: 0.15, static_value: 0.15}
  wwr_hash["South"] = {type: 'uniform', minimum: 0, maximum: 0.6, mean: 0.4, static_value: 0.4}
  wwr_hash["West"] = {type: 'uniform', minimum: 0, maximum: 0.6, mean: 0.15, static_value: 0.15}

  # loop through instances for wwr
  # note: measure description and variable names need to be unique for each instance
  wwr_hash.each do |facade,wwr|
    # adding bar_aspect_ratio_study
    arguments = [] # :value is just a value
    variables = [] # :value needs to be a hash {type: nil,  minimum: nil, maximum: nil, mean: nil, status_value: nil}
    variables << {:name => 'wwr', :desc => "#{facade}|Window to Wall Ratio (fraction)", :value => wwr} # keep name unique if used as variable
    arguments << {:name => 'sillHeight', :desc => "Sill Height (in)", :value => 30.0}
    arguments << {:name => 'facade', :desc => 'Cardinal Direction.', :value => facade}
    measures << {
        :name => "#{facade.downcase}|set_window_to_wall_ratio_by_facade", #keep this snake_case with a "|" separating the unique prefix.
        :desc => "#{facade}|Set Window to Wall Ratio by Facade",
        :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'SetWindowToWallRatioByFacade')}",
        :arguments => arguments,
        :variables => variables
    }
  end

  # adding assign_thermostats_basedon_standards_building_typeand_standards_space_type
  measures << {
      :name => 'assign_thermostats_basedon_standards_building_typeand_standards_space_type',
      :desc => 'Assign Thermostats Basedon Standards Building Typeand Standards Space Type',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'AssignThermostatsBasedonStandardsBuildingTypeandStandardsSpaceType')}",
      :variables => [],
      :arguments => []
  }

  # use case statement to choose HVAC based on building type
  case building_type

    when "Office"

      # adding aedg_office_hvac_ashp_doas
      arguments = [] # :value is just a value
      variables = [] # :value needs to be a hash {type: nil,  minimum: nil, maximum: nil, mean: nil, status_value: nil}
      arguments << {:name => 'ceilingReturnPlenumSpaceType', :desc => 'This space type should be part of a ceiling return air plenum.', :value => nil} # this is an optional argument
      arguments << {:name => 'costTotalHVACSystem', :desc => 'Total Cost for HVAC System ($).', :value => 0.0}
      arguments << {:name => 'remake_schedules', :desc => 'Apply recommended availability and ventilation schedules for air handlers?"', :value => true}
      measures << {
          :name => 'aedg_office_hvac_ashp_doas',
          :desc => 'AEDG Office Hvac Ashp Doas',
          :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'AedgOfficeHvacAshpDoas')}",
          :arguments => arguments,
          :variables => variables
      }

    when "PrimarySchool" , "SecondarySchool"

      # adding aedg_k12_hvac_dual_duct_doas
      arguments = [] # :value is just a value
      variables = [] # :value needs to be a hash {type: nil,  minimum: nil, maximum: nil, mean: nil, status_value: nil}
      arguments << {:name => 'ceilingReturnPlenumSpaceType', :desc => 'This space type should be part of a ceiling return air plenum.', :value => nil} # this is an optional argument
      arguments << {:name => 'costTotalHVACSystem', :desc => 'Total Cost for HVAC System ($).', :value => 0.0}
      arguments << {:name => 'remake_schedules', :desc => 'Apply recommended availability and ventilation schedules for air handlers?"', :value => true}
      measures << {
          :name => 'aedg_k12_hvac_dual_duct_doas',
          :desc => 'AEDG K12 Hvac Dual Duct Doas',
          :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'AedgK12HvacDualDuctDoas')}",
          :arguments => arguments,
          :variables => variables
      }

    else

      # adding enable_ideal_air_loads_for_all_zones
      measures << {
          :name => 'enable_ideal_air_loads_for_all_zones',
          :desc => 'Enable Ideal Air Loads For All Zones',
          :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'EnableIdealAirLoadsForAllZones')}",
          :variables => [],
          :arguments => []
      }

  end

  # adding set_building_location
  arguments = [] # :value is just a value
  variables = [] # :value needs to be a hash {type: nil,  minimum: nil, maximum: nil, mean: nil, status_value: nil}
  arguments << {:name => 'weather_directory', :desc => 'Weather Directory', :value => "../../weather"}
  #arguments << {:name => 'weather_directory', :desc => 'Weather Directory', :value => "../../../OpenStudio-analysis-spreadsheet/weather"}
  arguments << {:name => 'weather_file_name', :desc => 'Weather File Name', :value => WEATHER_FILE_NAME}
  measures << {
      :name => 'change_building_location',
      :desc => 'Change Building Location And Design Days',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'ChangeBuildingLocation')}",
      :arguments => arguments,
      :variables => variables
  }

  # start of energy plus measures

  # start of reporting measures

  # adding annual_end_use_breakdown
  measures << {
      :name => 'annual_end_use_breakdown',
      :desc => 'Annual End Use Breakdown',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'AnnualEndUseBreakdown')}",
      :variables => [],
      :arguments => []
  }

  # create analysis if requested
  if settings[:make_json]
    # populate outputs
    outputs = [
        {}
    ]

    weather_files = [
        "#{WEATHER_FILES_DIRECTORY}/*"
    ]
    default_weather_file = "#{WEATHER_FILES_DIRECTORY}/#{WEATHER_FILE_NAME}"

    # define path to seed model
    seed_model = seed_model

    # save path
    save_string = "#{building_type}_#{template}_#{climate_zone}"

    # configure analysis
    a = OpenStudio::Analysis.create(save_string)

    # add measures to analysis
    measures.each do |m|
      measure = a.workflow.add_measure_from_path(m[:name], m[:desc], m[:path])
      m[:arguments].each do |a|
        measure.argument_value(a[:name], a[:value])
      end
      m[:variables].each do |v|
        measure.make_variable(v[:name], v[:desc], v[:value])
      end
    end

    # add output to analysis
    outputs.each do |o|
      a.add_output(o)
    end

    # add weather files to analysis
    weather_files.each do |p|
      a.weather_files.add_files(p)
    end

    # make sure to set the default weather file as well
    a.weather_file(default_weather_file)

    # seed model
    a.seed_model(seed_model)

    # add in the other libraries
    # use this if the measures have shared resources
    #a.libraries.add("#{MEASURES_ROOT_DIRECTORY}/lib", { library_name: 'lib'})

    # Save the analysis JSON
    formulation_file = "analysis/#{save_string.downcase.squeeze(' ').gsub(' ', '_')}.json"
    zip_file = "analysis/#{save_string.downcase.squeeze(' ').gsub(' ', '_')}.zip"

    # set the analysis type here as well.
    a.analysis_type = ANALYSIS_TYPE

    # save files
    a.save formulation_file
    a.save_zip zip_file
  end

  # create analysis if requested
  if settings[:make_osm]

    # todo - to accommodate measures with string/path arguments it would be better for this section to run on the contents of the zip file. Then paths would match what happens on the server.

    # define path to seed model
    seed_model = seed_model

    # add in necessary requires (these used to be at the top but should work here)
    require 'openstudio'
    require 'openstudio/ruleset/ShowRunnerOutput'

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{Dir.pwd}/#{seed_model}")
    model = translator.loadModel(path)

    # confirm that model was opened
    if not model.empty?
      model = model.get
      puts "Opening #{seed_model}"
    else
      puts "Couldn't open seed model, creating a new empty model"
      model = OpenStudio::Model::Model.new
    end

    # add measures to analysis
    measures.each do |m|

      # load the measure
      require_relative (Dir.pwd + "../" + m[:path] + "/measure.rb")

      # infer class from name
      name_without_prefix = m[:name].split("|")
      measure_class = "#{name_without_prefix.last}".split('_').collect(&:capitalize).join

      # create an instance of the measure
      measure = eval(measure_class).new

      # skip from this loop if it is an E+ or Reporting measure
      if not measure.is_a?(OpenStudio::Ruleset::ModelUserScript)
        puts "Skipping #{measure.name}. It isn't a model measure."
        next
      end

      # get arguments
      arguments = measure.arguments(model)
      argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

      # todo - could be better to just run on contents of zip file instead of doing this
      # adjust path of arguments using shared resources to work on local run
      m[:arguments].each do |a|
        if a[:value].to_s.include? "../../weather"
          a[:value] = a[:value].gsub("../../weather","../../../OpenStudio-analysis-spreadsheet/weather")
        end
        if a[:value].to_s.include? "../../lib"
          a[:value] = a[:value].gsub("../../lib","../../../OpenStudio-analysis-spreadsheet/lib")
        end
      end
      m[:variables].each do |v|
        if v[:value][:static_value].to_s.include? "../../weather"
          v[:value][:static_value] = v[:value][:static_value].gsub("../../weather","../../../OpenStudio-analysis-spreadsheet/weather")
        end
        if v[:value][:static_value].to_s.include? "../../lib"
          v[:value][:static_value] = v[:value][:static_value].gsub("../../lib","../../../OpenStudio-analysis-spreadsheet/lib")
        end
      end

      # get argument values
      args_hash = {}
      m[:arguments].each do |a|
        args_hash[a[:name]] = a[:value]
      end
      m[:variables].each do |v|
        # todo - add logic to use something other than static value when argument is variable
        args_hash[v[:name]] = v[:value][:static_value]
      end

      # populate argument with specified hash value if specified
      arguments.each do |arg|
        temp_arg_var = arg.clone
        if args_hash[arg.name]
          temp_arg_var.setValue(args_hash[arg.name])
        end
        argument_map[arg.name] = temp_arg_var
      end

      # just added as test of where measure is running from
      #puts "Measure is running from #{Dir.pwd}"

      # run the measure
      measure.run(model, runner, argument_map)
      result = runner.result
      show_output(result)

    end

    # save path
    save_string = "#{building_type}_#{template}_#{climate_zone}"
    output_file_path = OpenStudio::Path.new("analysis_local/#{save_string}.osm")
    puts "Saving #{output_file_path}"
    model.save(output_file_path,true)

    # todo - look at ChnageBuildingLocation, it things it is in files, not weather? Can I save the folder like app does

    # todo - add support for E+ and reporting measures (will require E+ run)

  end

end

def populate_value_sets()
  # jobs to run
  value_sets = []
  value_sets << {:building_type => "Office", :template => "DOE Ref 2004", :climate_zone => "ASHRAE 169-2006-5B", :area => 50000.0}
  value_sets << {:building_type => "LargeHotel", :template => "DOE Ref 2004", :climate_zone => "ASHRAE 169-2006-5B", :area => 50000.0}
  value_sets << {:building_type => "Warehouse", :template => "DOE Ref 1980-2004", :climate_zone => "ASHRAE 169-2006-5B", :area => 50000.0}
  value_sets << {:building_type => "SecondarySchool", :template => "DOE Ref 1980-2004", :climate_zone => "ASHRAE 169-2006-3A", :area => 50000.0}

  return value_sets
end

namespace :test_models do

  # set constants
  MEASURES_ROOT_DIRECTORY = "../OpenStudio-measures/NREL working measures"
  WEATHER_FILE_NAME = "USA_CO_Denver.Intl.AP.725650_TMY3.epw"
  WEATHER_FILES_DIRECTORY = "weather"
  SEED_FILE_NAME = "empty_seed.osm"
  SEED_FILES_DIRECTORY = "seeds"
  ANALYSIS_TYPE = 'single_run'
  HOSTNAME = 'http://localhost:8080'

  #create_json(structure_id, building_type, year, system_type)
  desc 'run create analysis.json scripts'
  task :jsons do

    # jobs to run
    value_sets = populate_value_sets
    settings = {:make_json => true, :make_osm => true, :osm_logic => "static"} # osm_logic options are: static, min, max, mean, random_in_range, random_below_range random_above_range, random
    seed_model = "#{SEED_FILES_DIRECTORY}/#{SEED_FILE_NAME}"

    value_sets.each do |value_set|
      create_json(value_set[:building_type], value_set[:template], value_set[:climate_zone], value_set[:total_bldg_area_ip],settings,seed_model)
    end

  end

  desc 'queue the jsons'
  task :queue do

    # jobs to run
    value_sets = populate_value_sets

    value_sets.each do |value_set|
      save_string = "#{value_set[:building_type]}_#{value_set[:template]}_#{value_set[:climate_zone]}"
      save_string_cleaned = save_string.downcase.gsub(' ','_')

      formulation_file = "analysis/#{save_string_cleaned}.json"
      zip_file = "analysis/#{save_string_cleaned}.zip"
      if File.exist?(formulation_file) && File.exist?(zip_file)
        puts "Running #{save_string_cleaned}"
        api = OpenStudio::Analysis::ServerApi.new( { hostname: HOSTNAME } )
        api.queue_single_run(formulation_file, zip_file, ANALYSIS_TYPE)
      else
        puts "Could not file JSON or ZIP for #{save_string_cleaned}"
      end
    end

  end

  desc 'start the run queue'
  task :start do
    api = OpenStudio::Analysis::ServerApi.new( { hostname: HOSTNAME } )
    api.run_batch_run_across_analyses(nil, nil, ANALYSIS_TYPE)
  end

end