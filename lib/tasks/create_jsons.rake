desc 'run create analysis.json scripts'
namespace :json do
  task :office do
    NAME = 'name of the analysis'
    RAILS = false
    MEAURES_ROOT_DIRECTORY = "../cofee-measures"
    BUILDING_TYPE = 'office'
    WEATHER_FILE_NAME = 'Lawrence109_2013CST.epw'
    HVAC_SYSTEM_TYPE = 'SysType7'
    STRUCTURE_ID = 183871

    #def create_json
    a = OpenStudio::Analysis.create(NAME)

    a.workflow.add_measure_from_path('ngrid_monthly_uility_data', 'NGrid Add Monthly Utility Data',
                                     "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'NGridAddMonthlyUtilityData')}")
    a.workflow.add_measure_from_path('calibration_reports', 'Calibration Reports',
                                     "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'CalibrationReports')}")
    m = a.workflow.add_measure_from_path('set_building_location', 'Set Building Location And Design Days',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'ChangeBuildingLocation')}")
    m.argument_value('weather_directory', '../../weather')
    m.argument_value('weather_file_name', WEATHER_FILE_NAME)

    case BUILDING_TYPE
      when 'office'
        # TODO: look this up from somewhere
        (1..4).each do |index|
          m = a.workflow.add_measure_from_path("gather_space_type_ratio_data_#{index}", "Gather Space Type Ratio Data #{index}",
                                               "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'gather_space_type_ratio_data')}")
          m.argument_value('standards_bldg_and_space_type', "Office Blend #{index}")

          # this should be in a hash of some sort
          m.argument_value('fraction_of_building_area', 0.0) if index == 1
          m.argument_value('fraction_of_building_area', 0.35) if index == 2
          m.argument_value('fraction_of_building_area', 0.07) if index == 3
          m.argument_value('fraction_of_building_area', 0.04) if index == 4
          if index == 1
            m.argument_value('is_primary_space_type', true)
          else
            m.argument_value('is_primary_space_type', false)
          end
          m.argument_value('hvac_system_type', HVAC_SYSTEM_TYPE)


          case index
            when 1
              # make variables
              d = {type: 'uniform', minimum: 0.5, maximum: 0.9, mean: 0.6, static_value: 0}
              m.make_variable('fraction_of_building_area', 'Building Area Fraction', d)
            when 2
              d = {type: 'uniform', minimum: 0.05, maximum: 0.2, mean: 0.2, static_value: 0.35}
              m.make_variable('fraction_of_building_area', 'Building Area Fraction', d)
            when 3
              d = {type: 'uniform', minimum: 0.05, maximum: 0.3, mean: 0.1, static_value: 0.07}
              m.make_variable('fraction_of_building_area', 'Building Area Fraction', d)
            when 4
              d = {type: 'uniform', minimum: 0.02, maximum: 0.1, mean: 0.04, static_value: 0.04}
              m.make_variable('fraction_of_building_area', 'Building Area Fraction', d)
            else
              fail "index overflow"
          end
        end
      else
        fail 'building type not supported'
    end

    m = a.workflow.add_measure_from_path('make_envelope_from_space_type_ratios', 'Make Envelope From Space Type Ratios',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'make_envelope_from_space_type_ratios')}")

    m.argument_value('structure_id', STRUCTURE_ID)
    m.argument_value('perim_zone_depth', 10)
    # Add this back in once the right measure is in the repo
    # m.argument_value('floor_to_floor_multiplier', 1)
    m.argument_value('aspect_ratio_ns_to_ew', 2)
    # Add this back in once the right measure is in the repo
    # m.argument_value('zoning_logic', 'Each SpaceType on at Least One Story Advanced Form')

    m = a.workflow.add_measure_from_path('add_schedules_to_model', 'Add Schedules to Model',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_schedules_to_model')}")
    d = {type: 'uniform', minimum: 7, maximum: 10, mean: 8, static_value: 8}
    m.make_variable('hoo_start', 'Hours of Operation Start', d)
    d = {type: 'uniform', minimum: 16, maximum: 20, mean: 17, static_value: 17}
    m.make_variable('hoo_finish', 'Hours of Operation Finish', d)


    # below is how you change argument values after it has already been added
    # go through and change the values of known fields
    m = a.workflow.find_measure('ngrid_monthly_uility_data')
    m.argument_value('electric_json', '../../../lib/calibration_data/electric_billed_usage.json')
    m.argument_value('gas_json', '../../../lib/calibration_data/gas_billed_usage.json')
    m.argument_value('start_date', '2013-01-10')
    m.argument_value('end_date', '2013-12-12')

    # Save the analysis JSON
    a.save "analysis/#{NAME.downcase.squeeze(' ').gsub(' ', '_')}.json"

    # TODO: zip up the files

    # a.analysis_type = 'single_run'
    # a.algorithm.set_attribute('sample_method', 'all_variables')
    # o = {
    #     display_name: 'Total Natural Gas',
    #     display_name_short: 'Total Natural Gas',
    #     metadata_id: nil,
    #     name: 'total_natural_gas',
    #     units: 'MJ/m2',
    #     objective_function: true,
    #     objective_function_index: 0,
    #     objective_function_target: 330.7,
    #     scaling_factor: nil,
    #     objective_function_group: nil
    # }
    # a.add_output(o)
    #
    # a.seed_model('spec/files/small_seed.osm')
    # a.weather_file('spec/files/partial_weather.epw')
    #end


  end

end