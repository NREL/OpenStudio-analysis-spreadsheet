desc 'run create analysis.json scripts'
namespace :office do
  NAME = 'Office - test with tariff, fixed system type arg, fixed supply side of water'
  RAILS = false
  #MEAURES_ROOT_DIRECTORY = "../cofee-measures"
  MEAURES_ROOT_DIRECTORY = "../../GitHub/cofee-measures"  # this is path I need to use - dfg
  BUILDING_TYPE = 'office'
  WEATHER_FILE_NAME = 'Lawrence109_2013CST.epw'
  HVAC_SYSTEM_TYPE = 'SysType 7'
  STRUCTURE_ID = 183871

  ANALYSIS_TYPE = 'single_run'
  #HOSTNAME = 'http://localhost:8080'
  HOSTNAME = 'http://bball-130590.nrel.gov:8080'

  task :json do
    #def create_json
    a = OpenStudio::Analysis.create(NAME)

    # start of OpenStudio measures
    a.workflow.add_measure_from_path('ngrid_monthly_uility_data', 'NGrid Add Monthly Utility Data',
                                     "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'NGridAddMonthlyUtilityData')}")
    a.workflow.add_measure_from_path('calibration_reports', 'Calibration Reports',
                                     "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'CalibrationReports')}")
    m = a.workflow.add_measure_from_path('set_building_location', 'Set Building Location And Design Days',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'ChangeBuildingLocation')}")
    m.argument_value('weather_directory', '../../weather')
    m.argument_value('weather_file_name', WEATHER_FILE_NAME)

    # temp array to hold space type ratios
    space_type_array = []
    space_type_array << "Office BlendA"
    space_type_array << "Office BlendB"
    space_type_array << "Office BlendC"
    space_type_array << "Office Restroom"

    case BUILDING_TYPE
      when 'office'
        # TODO: look this up from somewhere
        (1..4).each do |index|
          m = a.workflow.add_measure_from_path("gather_space_type_ratio_data_#{index}", "Gather Space Type Ratio Data #{index}",
                                               "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'gather_space_type_ratio_data')}")
          m.argument_value('standards_bldg_and_space_type', space_type_array[index-1])

          # this should be in a hash of some sort
          if index == 1
            m.argument_value('is_primary_space_type', true)
          else
            m.argument_value('is_primary_space_type', false)
          end
          m.argument_value('hvac_system_type', HVAC_SYSTEM_TYPE)

          case index
            when 1
              # make variables, expect for primary space type which should be an argument
              m.argument_value('fraction_of_building_area', 0)
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
    m.argument_value('floor_to_floor_multiplier', 1)
    m.argument_value('aspect_ratio_ns_to_ew', 2)
    # Add this back in once the right measure is in the repo
    m.argument_value('zoning_logic', 'Each SpaceType on at Least One Story Advanced Form')

    m = a.workflow.add_measure_from_path('add_schedules_to_model', 'Add Schedules to Model',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_schedules_to_model')}")
    d = {type: 'uniform', minimum: 7, maximum: 10, mean: 8, static_value: 8}
    m.make_variable('hoo_start', 'Hours of Operation Start', d)
    d = {type: 'uniform', minimum: 16, maximum: 20, mean: 17, static_value: 17}
    m.make_variable('hoo_finish', 'Hours of Operation Finish', d)

    m = a.workflow.add_measure_from_path('add_people_to_space_types', 'Add People to Space Types',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_people_to_space_types')}")
    d = {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
    m.make_variable('multiplier_occ', 'Occupancy Multiplier', d)

    m = a.workflow.add_measure_from_path('add_ventilation_to_space_types', 'Add Ventilation to Space Types',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_ventilation_to_space_types')}")
    d = {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
    m.make_variable('multiplier_ventilation', 'Ventilation Multiplier', d)

    m = a.workflow.add_measure_from_path('add_infiltration_to_space_types', 'Add Infiltration to Space Types',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_infiltration_to_space_types')}")
    d = {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
    m.make_variable('multiplier_infiltration', 'Infiltration Multiplier', d)

    m = a.workflow.add_measure_from_path('add_constructions_to_space_types', 'Add Constructions to Space Types',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_constructions_to_space_types')}")

    m = a.workflow.add_measure_from_path('add_interior_constructions_to_adiabatic_surfaces', 'Add Interior Constructions to Adiabatic Surfaces',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_interior_constructions_to_adiabatic_surfaces')}")

    m = a.workflow.add_measure_from_path('add_thermostats', 'Add Thermostats',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_thermostats')}")

    m = a.workflow.add_measure_from_path('RotateBuilding', 'Rotate Building',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'RotateBuilding')}")
    m.argument_value('relative_building_rotation', 0)

    m = a.workflow.add_measure_from_path('add_fenestration_and_overhangs_by_space_type', 'Add Fenestration And Overhangs By SpaceType',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_fenestration_and_overhangs_by_space_type')}")
    d = {type: 'uniform', minimum: 0.1, maximum: 2, mean: 0.125, static_value: 1}
    m.make_variable('multiplier_wwr', 'Window to Wall Ratio Multiplier', d)
    m.argument_value('multiplier_overhang', 1)
    m.argument_value('multiplier_srr', 1)
    m.argument_value('multiplier_odwr', 1)

    m = a.workflow.add_measure_from_path('add_elevators_to_building', 'Add Elevators To Building',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_elevators_to_building')}")
    d = {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
    m.make_variable('multiplier_elevator_eff', 'Elevator Efficiency Multiplier', d)

    m = a.workflow.add_measure_from_path('add_lamps_to_spaces_by_space_type', 'Add Lamps to Spaces by Space Type',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_lamps_to_spaces_by_space_type')}")
    d = {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
    m.make_variable('multiplier_lighting', 'Lighting Multiplier', d)

    m = a.workflow.add_measure_from_path('add_elec_equip_to_spaces_by_space_type', 'Add Elec Equip to Spaces by Space Type',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_elec_equip_to_spaces_by_space_type')}")
    d = {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
    m.make_variable('multiplier_elec_equip', 'Electric Equipment Multiplier', d)

    m = a.workflow.add_measure_from_path('add_gas_equip_to_spaces_by_space_type', 'Add Gas Equip to Spaces by Space Type',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_gas_equip_to_spaces_by_space_type')}")
    d = {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
    m.make_variable('multiplier_gas_equip', 'Gas Equipment Multiplier', d)

    m = a.workflow.add_measure_from_path('add_water_use_connection_and_equipment', 'Add Water Use Connection and Equipment',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_water_use_connection_and_equipment')}")
    d = {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
    m.make_variable('multiplier_water_use', 'Water Use Multiplier', d)

    m = a.workflow.add_measure_from_path('add_exhaust_to_zones_by_space_type', 'Add Exhaust to Zones by Space Type',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_exhaust_to_zones_by_space_type')}")
    d = {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
    m.make_variable('exhaust_fan_eff', 'Exhaust Efficiency Multiplier', d)

    m = a.workflow.add_measure_from_path('add_site_loads_to_building', 'Add Site Loads to Building',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_site_loads_to_building')}")
    m.argument_value('multiplier_site_perim_lighting', 1)
    m.argument_value('multiplier_site_parking_lighting', 1)

    m = a.workflow.add_measure_from_path('add_system01_by_space_type', 'Add System 01 By Space Type',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_system01_by_space_type')}")

    m = a.workflow.add_measure_from_path('add_system02_by_space_type', 'Add System 02 By Space Type',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_system02_by_space_type')}")

    m = a.workflow.add_measure_from_path('add_system03_by_space_type', 'Add System 03 By Space Type',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_system03_by_space_type')}")

    m = a.workflow.add_measure_from_path('add_system04_by_space_type', 'Add System 04 By Space Type',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_system04_by_space_type')}")

    m = a.workflow.add_measure_from_path('add_system05_by_space_type', 'Add System 05 By Space Type',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_system05_by_space_type')}")

    m = a.workflow.add_measure_from_path('add_system06_by_space_type', 'Add System 06 By Space Type',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_system06_by_space_type')}")

    m = a.workflow.add_measure_from_path('add_system07_by_space_type', 'Add System 07 By Space Type',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_system07_by_space_type')}")

    m = a.workflow.add_measure_from_path('add_system08_by_space_type', 'Add System 08 By Space Type',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_system08_by_space_type')}")

    m = a.workflow.add_measure_from_path('add_service_water_heating_supply', 'Add Service Water Heating Supply',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'add_service_water_heating_supply')}")

    m = a.workflow.add_measure_from_path('adjust_hours_of_operation', 'Adjust Hours Of Operation',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'adjust_hours_of_operation')}")
    m.argument_value('base_start_hoo', 8)
    m.argument_value('base_finish_hoo', 17)
    d = {type: 'uniform', minimum: -2, maximum: 2, mean: 0, static_value: 0}
    m.make_variable('delta_length_hoo', 'Adjust Length of Hours of Operation', d)
    d = {type: 'uniform', minimum: -2, maximum: 2, mean: 0, static_value: 0}
    m.make_variable('shift_hoo', 'Shift Hours of Operation', d)

    # currently this gathers in demand data out of analytic record and stories it in resource.json for use by ee measures
    m = a.workflow.add_measure_from_path('gather_indemand_data', 'Gather Indemand Data',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'ee', 'gather_indemand_data')}")

    m = a.workflow.add_measure_from_path('EH03DualEnthalpyEconomizerControls', 'EH03: Dual Enthalpy Economizer Controls',
                                               "#{File.join(MEAURES_ROOT_DIRECTORY, 'ee', 'EH03DualEnthalpyEconomizerControls')}")
    m.argument_value('economizer_type', "DifferentialEnthalpy")
    m.argument_value('econoMaxDryBulbTemp', 69.0)
    m.argument_value('econoMaxEnthalpy', 28.0)
    m.argument_value('econoMaxDewpointTemp', 55.0)
    m.argument_value('econoMinDryBulbTemp', -148.0)
    m.argument_value('use_case', "Update M0 with Indemand data") # to use as an EE measure change this argument to "Apply EE to calibrated model""

    # start of energy plus measures
    m = a.workflow.add_measure_from_path('ElectricityTariffModelForMA', 'ElectricityTariffModelForMA',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'ElectricityTariffModelForMA')}")
    m.argument_value('tariff_type', "MA-Electricity")

    # start of reporting measures
    m = a.workflow.add_measure_from_path('coffee_annual_summary_report', 'COFFEE Annual Summary Report',
                                         "#{File.join(MEAURES_ROOT_DIRECTORY, 'model0', 'coffee_annual_summary_report')}")

    # below is how you change argument values after it has already been added
    # go through and change the values of known fields
    m = a.workflow.find_measure('ngrid_monthly_uility_data')
    m.argument_value('electric_json', '../../../lib/calibration_data/electric_billed_usage.json')
    m.argument_value('gas_json', '../../../lib/calibration_data/gas_billed_usage.json')
    m.argument_value('start_date', '2013-01-10')
    m.argument_value('end_date', '2013-12-12')


    o = {
        display_name: 'Total Natural Gas',
        display_name_short: 'Total Natural Gas',
        metadata_id: nil,
        name: 'total_natural_gas',
        units: 'MJ/m2',
        objective_function: true,
        objective_function_index: 0,
        objective_function_target: 330.7,
        scaling_factor: nil,
        objective_function_group: nil
    }
    a.add_output(o)

    # add all the weather files that are needed.
    a.weather_files.add_files('weather_183871/*')

    # make sure to set the default weather file as well
    a.weather_file('weather_183871/Lawrence109_2013CST.epw')

    # seed model
    a.seed_model('seeds/EmptySeedModel.osm')

    # add in the other libraries
    a.libraries.add('../../GitHub/cofee-measures/lib', { library_name: 'cofee'})
    a.libraries.add('lib_m0/183871', { library_name: 'calibration_data'})


    # add any worker init / finalization scripts - the files will run in the order that they are added
    # this is just an example file
    #a.worker_inits.add('project_ruby/office_blend.rb', {args: [19837,"z",{b: 'something'}]})
    #a.worker_finalizes.add('project_ruby/office_blend.rb')
    # Save the analysis JSON
    formulation_file = "analysis/#{NAME.downcase.squeeze(' ').gsub(' ', '_')}.json"
    zip_file = "analysis/#{NAME.downcase.squeeze(' ').gsub(' ', '_')}.zip"

    # set the analysis type here as well. I plan on not having this required in the near future
    a.analysis_type = ANALYSIS_TYPE

    a.save formulation_file
    a.save_zip zip_file
  end

  desc 'create and run the office json'
  task :run => [:json] do
    formulation_file = "analysis/#{NAME.downcase.squeeze(' ').gsub(' ', '_')}.json"
    zip_file = "analysis/#{NAME.downcase.squeeze(' ').gsub(' ', '_')}.zip"

    api = OpenStudio::Analysis::ServerApi.new( { hostname: HOSTNAME } )
    api.run(formulation_file, zip_file, ANALYSIS_TYPE)

  end

end