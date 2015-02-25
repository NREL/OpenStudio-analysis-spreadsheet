def create_json(building_type, template, climate_zone, total_bldg_area_ip)

  # setup
  measures = []

  # start of OpenStudio measures
  measures << {
      :name => 'space_type_and_construction_set_wizard',
      :desc => 'Space Type And Construction Set Wizard',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'SpaceTypeAndConstructionSetWizard')}",
      :arguments => [
          {
              :name => 'buildingType',
              :desc => 'Building Type',
              :value => building_type
          },
          {
              :name => 'template',
              :desc => 'Template',
              :value => template
          },
          {
              :name => 'climateZone',
              :desc => 'Climate Zone',
              :value => climate_zone
          },
          {
              :name => 'createConstructionSet',
              :desc => 'Create Construction Set?',
              :value => true
          },
          {
              :name => 'setBuildingDefaults',
              :desc => 'Set Building Defaults Using New Objects?',
              :value => true
          }
      ],
      :variables => []
  }

  measures << {
      :name => 'bar_aspect_ratio_study',
      :desc => 'Bar Aspect Ratio Study',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'BarAspectRatioStudy')}",
      :arguments => [
          {
              :name => 'total_bldg_area_ip',
              :desc => 'Total Building Floor Area (ft^2).',
              :value => total_bldg_area_ip
          },
          {
              :name => 'surface_matching',
              :desc => 'Surface Matching',
              :value => true
          },
          {
              :name => 'make_zones',
              :desc => 'Make Zones',
              :value => true
          }
      ],
      :variables => [
          {
              :name => 'ns_to_ew_ratio',
              :desc => 'Ratio of North/South Facade Length Relative to East/West Facade Length.',
              :value => {type: 'uniform', minimum: 0.2, maximum: 5.0, mean: 2.0, static_value: 2.0}
          },
          {
              :name => 'num_floors',
              :desc => 'Number of Floors.',
              :value => {type: 'uniform', minimum: 1, maximum: 10, mean: 2, static_value: 2}
          },
          {
              :name => 'floor_to_floor_height_ip',
              :desc => 'Floor to Floor Height.',
              :value => {type: 'uniform', minimum: 8, maximum: 20, mean: 10, static_value: 10}
          }
      ]
  }

  measures << {
      :name => 'set_building_location',
      :desc => 'Set Building Location And Design Days',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'ChangeBuildingLocation')}",
      :variables => [],
      :arguments => [
          {
              :name => "weather_directory",
              :value => "../../weather"
          },
          {
              :name => "weather_file_name",
              :value => WEATHER_FILE_NAME
          },
      ]
  }

  # start of energy plus measures

  # start of reporting measures
  measures << {
      :name => 'annual_end_use_breakdown',
      :desc => 'Annual End Use Breakdown',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'AnnualEndUseBreakdown')}",
      :variables => [],
      :arguments => []
  }

  # populate outputs
  outputs = [
      {}
  ]

  weather_files = [
      "#{WEATHER_FILES_DIRECTORY}/*"
  ]
  default_weather_file = "#{WEATHER_FILES_DIRECTORY}/#{WEATHER_FILE_NAME}"

  # define path to seed model
  seed_model = "seeds/empty_seed.osm"

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

def populate_value_sets()
  # jobs to run
  value_sets = []
  value_sets << {:building_type => "Office", :template => "DOE Ref 2004", :climate_zone => "ASHRAE 169-2006-5B", :area => 50000.0}
  value_sets << {:building_type => "LargeHotel", :template => "DOE Ref 2004", :climate_zone => "ASHRAE 169-2006-5B", :area => 50000.0}

  return value_sets
end

namespace :test_models do

  # set constants
  MEASURES_ROOT_DIRECTORY = "../OpenStudio-measures/NREL working measures"
  WEATHER_FILE_NAME = "USA_CO_Golden-NREL.724666_TMY3.epw"
  WEATHER_FILES_DIRECTORY = "C:/EnergyPlusV8-2-0/WeatherData"
  ANALYSIS_TYPE = 'single_run'
  HOSTNAME = 'http://localhost:8080'

  #create_json(structure_id, building_type, year, system_type)
  desc 'run create analysis.json scripts'
  task :jsons do

    # jobs to run
    value_sets = populate_value_sets

    value_sets.each do |value_set|
      create_json(value_set[:building_type], value_set[:template], value_set[:climate_zone], value_set[:total_bldg_area_ip])
    end

  end

  desc 'create and run the office json'
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