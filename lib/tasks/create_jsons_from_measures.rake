def create_json(structure_id, building_type, year, system_type)

  # hash to hold space type data
  space_type_hash = {}
  # not adding system type for now
  building_static_hoo_start = nil
  building_static_hoo_finish = nil
  case building_type
    when 'AssistedLiving'
      space_type_hash['AssistedLiving BlendPat'] = {is_primary: true, type: 'uniform', minimum: 0.4, maximum: 0.75, mean: 0.6, static_value: 0.6}
      space_type_hash['AssistedLiving BlendCom'] = {is_primary: false, type: 'uniform', minimum: 0.2, maximum: 0.5, mean: 0.325, static_value: 0.325}
      space_type_hash['AssistedLiving Kitchen'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.1, mean: 0.075, static_value: 0.075}
      building_static_hoo_start = 6
      building_static_hoo_finish = 22
    when 'AutoRepair'
      space_type_hash['AutoRepair Garage'] = {is_primary: true, type: 'uniform', minimum: 0.3, maximum: 0.8, mean: 0.65, static_value: 0.65}
      space_type_hash['AutoRepair BlendFront'] = {is_primary: false, type: 'uniform', minimum: 0.2, maximum: 0.6, mean: 0.3, static_value: 0.3}
      space_type_hash['AutoRepair Restroom'] = {is_primary: false, type: 'uniform', minimum: 0, maximum: 0.1, mean: 0.05, static_value: 0.05}
      building_static_hoo_start = 8
      building_static_hoo_finish = 19
    when 'AutoSales'
      space_type_hash['AutoSales BlendFront'] = {is_primary: true, type: 'uniform', minimum: 0.1, maximum: 0.925, mean: 0.79, static_value: 0.79}
      space_type_hash['AutoSales Garage'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.4, mean: 0.2, static_value: 0.2}
      space_type_hash['AutoSales Restroom'] = {is_primary: false, type: 'uniform', minimum: 0.025, maximum: 0.5, mean: 0.01, static_value: 0.01}
      building_static_hoo_start = 9
      building_static_hoo_finish = 20
    when 'Bank'
      space_type_hash['Bank BlendFront'] = {is_primary: true, type: 'uniform', minimum: 0.7, maximum: 0.94, mean: 0.85, static_value: 0.85}
      space_type_hash['Bank Elec/MechRoom'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.1, mean: 0.05, static_value: 0.05}
      space_type_hash['Bank Restroom'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.1, mean: 0.05, static_value: 0.05}
      space_type_hash['Bank Vault'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.1, mean: 0.05, static_value: 0.05}
      building_static_hoo_start = 8
      building_static_hoo_finish = 17
    when 'ChildCare'
      space_type_hash['ChildCare BlendEdu'] = {is_primary: true, type: 'uniform', minimum: 0.65, maximum: 0.9, mean: 0.8, static_value: 0.8}
      space_type_hash['ChildCare Office'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.2, mean: 0.1, static_value: 0.1}
      space_type_hash['ChildCare Restroom'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.15, mean: 0.1, static_value: 0.1}
      building_static_hoo_start = 6
      building_static_hoo_finish = 19
    when 'FullServiceRestaurant'
      space_type_hash['FullServiceRestaurant Dining'] = {is_primary: true, type: 'uniform', minimum: 0.5, maximum: 0.9, mean: 0.727, static_value: 0.727}
      space_type_hash['FullServiceRestaurant Kitchen'] = {is_primary: false, type: 'uniform', minimum: 0.1, maximum: 0.5, mean: 0.273, static_value: 0.273}
      building_static_hoo_start = 7
      building_static_hoo_finish = 23
    when 'GasStation'
      space_type_hash['GasStation Retail'] = {is_primary: true, type: 'uniform', minimum: 0.7, maximum: 0.98, mean: 0.9, static_value: 0.9}
      space_type_hash['GasStation Restroom'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.2, mean: 0.05, static_value: 0.05}
      space_type_hash['GasStation ClosedOffice'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.1, mean: 0.05, static_value: 0.05}
      building_static_hoo_start = 6
      building_static_hoo_finish = 20
    when 'Hospital'
      space_type_hash['Hospital BlendPat'] = {is_primary: true, type: 'uniform', minimum: 0.4, maximum: 0.785, mean: 0.537, static_value: 0.537}
      space_type_hash['Hospital BlendCirc'] = {is_primary: false, type: 'uniform', minimum: 0.15, maximum: 0.35, mean: 0.322, static_value: 0.322}
      space_type_hash['Hospital Kitchen'] = {is_primary: false, type: 'uniform', minimum: 0.025, maximum: 0.075, mean: 0.05, static_value: 0.05}
      space_type_hash['Hospital Dining'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.075, mean: 0.037, static_value: 0.037}
      space_type_hash['Hospital Lab'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.05, mean: 0.028, static_value: 0.028}
      space_type_hash['Hospital Radiology'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.05, mean: 0.026, static_value: 0.026}
      building_static_hoo_start = 4
      building_static_hoo_finish = 22
    when 'Laboratory'
      space_type_hash['Laboratory BlendOff'] = {is_primary: true, type: 'uniform', minimum: 0.2, maximum: 0.7, mean: 0.32, static_value: 0.32}
      space_type_hash['Laboratory Lab'] = {is_primary: false, type: 'uniform', minimum: 0.15, maximum: 0.35, mean: 0.25, static_value: 0.25}
      space_type_hash['Laboratory BlendCirc'] = {is_primary: false, type: 'uniform', minimum: 0.12, maximum: 0.3, mean: 0.36, static_value: 0.36}
      space_type_hash['Laboratory BlendMisc'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.1, mean: 0.03, static_value: 0.03}
      space_type_hash['Laboratory Restroom'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.05, mean: 0.04, static_value: 0.04}
      building_static_hoo_start = 8
      building_static_hoo_finish = 17
    when 'LargeHotel'
      space_type_hash["LargeHotel BlendGst"] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash["LargeHotel BlendLob"] = {is_primary: false, type: 'uniform', minimum: 0.1, maximum: 0.3, mean: 0.173, static_value: 0.173}
      space_type_hash["LargeHotel BlendFds"] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.25, mean: 0.091, static_value: 0.091}
      space_type_hash["LargeHotel BlendMisc"] = {is_primary: false, type: 'uniform', minimum: 0.1, maximum: 0.05, mean: 0.028, static_value: 0.028}
      space_type_hash["LargeHotel Kitchen"] = {is_primary: false, type: 'uniform', minimum: 0.0, maximum: 0.025, mean: 0.011, static_value: 0.011}
      space_type_hash["LargeHotel Laundry"] = {is_primary: false, type: 'uniform', minimum: 0.0, maximum: 0.015, mean: 0.008, static_value: 0.008}
      building_static_hoo_start = 6
      building_static_hoo_finish = 22
    when 'MidriseApartment'
      space_type_hash["MidriseApartment BlendA"] = {is_primary: true, type: 'na_is_primary', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash["MidriseApartment Office"] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.2, mean: 0.028, static_value: 0.28}
      building_static_hoo_start = 8
      building_static_hoo_finish = 18
    when 'Office'
      space_type_hash["Office BlendA"] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash["Office BlendB"] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.2, mean: 0.1, static_value: 0.1}
      space_type_hash["Office BlendC"] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.3, mean: 0.07, static_value: 0.07}
      space_type_hash["Office Restroom"] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.1, mean: 0.04, static_value: 0.04}
      building_static_hoo_start = 8
      building_static_hoo_finish = 17
    when 'OfficeData'
      space_type_hash["Office BlendA"] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash["Office BlendB"] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.15, mean: 0.1, static_value: 0.1}
      space_type_hash["Office IT_Room"] = {is_primary: false, type: 'uniform', minimum: 0.35, maximum: 0.65, mean: 0.5, static_value: 0.5}
      space_type_hash["Office Elec/MechRoom"] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.02, mean: 0.01, static_value: 0.01}
      space_type_hash["Office PrintRoom"] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.02, mean: 0.015, static_value: 0.015}
      space_type_hash["Office Restroom"] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.01, mean: 0.04, static_value: 0.04}
      building_static_hoo_start = 8
      building_static_hoo_finish = 17
    when 'Outpatient'
      space_type_hash['Outpatient BlendCirc'] = {is_primary: true, type: 'uniform', minimum: 0.05, maximum: 0.54, mean: 0.298, static_value: 0.298}
      space_type_hash['Outpatient BlendOff'] = {is_primary: false, type: 'uniform', minimum: 0.2, maximum: 0.35, mean: 0.283, static_value: 0.283}
      space_type_hash['Outpatient BlendPat'] = {is_primary: false, type: 'uniform', minimum: 0.2, maximum: 0.35, mean: 0.253, static_value: 0.253}
      space_type_hash['Outpatient BlendImg'] = {is_primary: false, type: 'uniform', minimum: 0, maximum: 0.075, mean: 0.041, static_value: 0.041}
      space_type_hash['Outpatient BlendMedStg'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.05, mean: 0.025, static_value: 0.025}
      space_type_hash['Outpatient BlendMisc'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.125, mean: 0.1, static_value: 0.1}
      building_static_hoo_start = 4
      building_static_hoo_finish = 22
    when 'PrimarySchool'
      space_type_hash['PrimarySchool BlendEdu'] = {is_primary: true, type: 'uniform', minimum: 0.525, maximum: 0.91, mean: 0.694, static_value: 0.694}
      space_type_hash['PrimarySchool BlendOff'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.15, mean: 0.126, static_value: 0.126}
      space_type_hash['PrimarySchool Library'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.1, mean: 0.058, static_value: 0.058}
      space_type_hash['PrimarySchool Gym'] = {is_primary: false, type: 'uniform', minimum: 0, maximum: 0.1, mean: 0.052, static_value: 0.052}
      space_type_hash['PrimarySchool Cafeteria'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.075, mean: 0.046, static_value: 0.046}
      space_type_hash['PrimarySchool Kitchen'] = {is_primary: false, type: 'uniform', minimum: 0, maximum: 0.05, mean: 0.024, static_value: 0.024}
      building_static_hoo_start = 8
      building_static_hoo_finish = 16
    when 'QuickServiceRestaurant'
      space_type_hash['QuickServiceRestaurant Dining'] = {is_primary: true, type: 'uniform', minimum: 0.25, maximum: 0.9, mean: 0.5, static_value: 0.5}
      space_type_hash['QuickServiceRestaurant Kitchen'] = {is_primary: false, type: 'uniform', minimum: 0.1, maximum: 0.75, mean: 0.5, static_value: 0.5}
      building_static_hoo_start = 7
      building_static_hoo_finish = 23
    when 'Retail'
      space_type_hash["Retail Retail"] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash["Retail Back_Space"] = {is_primary: false, type: 'uniform', minimum: 0.025, maximum: 0.5, mean: 0.166, static_value: 0.166}
      space_type_hash["Retail BlendFront"] = {is_primary: false, type: 'uniform', minimum: 0.025, maximum: 0.25, mean: 0.071, static_value: 0.071}
      building_static_hoo_start = 7
      building_static_hoo_finish = 21
    when 'SecondarySchool'
      space_type_hash['SecondarySchool BlendEdu'] = {is_primary: true, type: 'uniform', minimum: 0.47, maximum: 0.815, mean: 0.589, static_value: 0.589}
      space_type_hash['SecondarySchool BlendOff'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.15, mean: 0.11, static_value: 0.11}
      space_type_hash['SecondarySchool Gym'] = {is_primary: false, type: 'uniform', minimum: 0.1, maximum: 0.15, mean: 0.165, static_value: 0.165}
      space_type_hash['SecondarySchool Auditorium'] = {is_primary: false, type: 'uniform', minimum: 0, maximum: 0.075, mean: 0.05, static_value: 0.05}
      space_type_hash['SecondarySchool Library'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.075, mean: 0.043, static_value: 0.043}
      space_type_hash['SecondarySchool Cafeteria'] = {is_primary: false, type: 'uniform', minimum: 0.015, maximum: 0.05, mean: 0.032, static_value: 0.032}
      space_type_hash['SecondarySchool Kitchen'] = {is_primary: false, type: 'uniform', minimum: 0, maximum: 0.03, mean: 0.011, static_value: 0.011}
      building_static_hoo_start = 8
      building_static_hoo_finish = 16
    when 'SingleMultiPlexRes'
      space_type_hash["MidriseApartment Apartment"] = {is_primary: true, type: 'na_is_primary', minimum: 1.0, maximum: 1.0, mean: 1.0, static_value: 1.0}
      building_static_hoo_start = 8
      building_static_hoo_finish = 18
    when 'SmallHotel'
      space_type_hash['SmallHotel BlendGuest'] = {is_primary: true, type: 'uniform', minimum: 0.34, maximum: 0.93, mean: 0.775, static_value: 0.775}
      space_type_hash['SmallHotel BlendMtg'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.4, mean: 0.11, static_value: 0.11}
      space_type_hash['SmallHotel BlendMisc'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.18, mean: 0.082, static_value: 0.082}
      space_type_hash['SmallHotel Laundry'] = {is_primary: false, type: 'uniform', minimum: 0, maximum: 0.05, mean: 0.025, static_value: 0.025}
      space_type_hash['SmallHotel Exercise'] = {is_primary: false, type: 'uniform', minimum: 0, maximum: 0.03, mean: 0.008, static_value: 0.008}
      building_static_hoo_start = 6
      building_static_hoo_finish = 22
    when 'StripMall'
      space_type_hash["StripMall WholeBuilding"] = {is_primary: true, type: 'na_is_primary', minimum: 1.0, maximum: 1.0, mean: 1.0, static_value: 1.0}
      building_static_hoo_start = 7
      building_static_hoo_finish = 21
    when 'SuperMarket' # todo - I need to make schedules for this, missed it earlier in the week. Still won't have refrigeration
      space_type_hash['SuperMarket Sales/Produce'] = {is_primary: true, type: 'uniform', minimum: 0.45, maximum: 0.89, mean: 0.726, static_value: 0.726}
      space_type_hash['SuperMarket DryStorage'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.25, mean: 0.149, static_value: 0.149}
      space_type_hash['SuperMarket Deli/Bakery'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.25, mean: 0.104, static_value: 0.104}
      space_type_hash['SuperMarket Office'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.05, mean: 0.021, static_value: 0.021}
      building_static_hoo_start = 6
      building_static_hoo_finish = 22
    when 'Warehouse'
      space_type_hash["Warehouse BlendA"] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash["Warehouse Office"] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.3, mean: 0.048, static_value: 0.048}
      building_static_hoo_start = 7
      building_static_hoo_finish = 17
    else
      fail "#{building_type} is not a supported building type"
  end

    # setup
  measures = []

  # start of OpenStudio measures
  measures << {
    :name => 'ngrid_monthly_uility_data', 
    :desc => 'NGrid Add Monthly Utility Data', 
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'NGridAddMonthlyUtilityData')}"
    :variables => [],
    :arguments => [

      # todo set these dynamically in cofee-rails
      { 
        :name => 'electric_json', 
        :value => '../../../lib/calibration_data/electric_billed_usage.json'
      },
      {
        :name => 'gas_json', 
        :value => '../../../lib/calibration_data/gas_billed_usage.json'
      },
      {
        :name => 'start_date', 
        :value => '2013-01-10'
      },
      { 
        :name => 'end_date', 
        :value => '2013-12-12'
      }
    ]
  }
  measures << {
    :name => 'calibration_reports', 
    :desc => 'Calibration Reports',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'CalibrationReports')}"
    :variables => [],
    :arguments => []
  }
  measures << {
    :name => 'set_building_location', 
    :desc => 'Set Building Location And Design Days',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'ChangeBuildingLocation')}",
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

  # create loop for gather space type ratio instances
  space_type_hash.each do |space_type_name,values|
    measure = {
      :name => "gather_space_type_ratio_data_#{space_type_name}", 
      :desc => "Gather Space Type Ratio Data #{space_type_name}",
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'gather_space_type_ratio_data')}",
      :arguments => [
        {
          :name => "standards_bldg_and_space_type",
          :value => space_type_name
        }
      ],
      :variables => []
    }

    # this should be in a hash of some sort
    if values[:is_primary]
      measure[:arguments] << {
        :name => is_primary_space_type,
        :value => true
      }
      measure[:arguments] << {
        :name => 'fraction_of_building_area', 
        :value => values[:static_value]
      }
    else
      measure[:arguments] << {
        :name => is_primary_space_type,
        :value => false
      }
      measures[:variables] << 
      {
        :name => 'fraction_of_building_area',
        :desc => 'Building Area Fraction',
        :values => values
      }
    end
    measure[:arguments] << {
      :name => 'hvac_system_type', 
      :value => system_type
    }
    measures << measure
  end
  measures << 
  {
    :name => 'make_envelope_from_space_type_ratios', 
    :desc => 'Make Envelope From Space Type Ratios',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'make_envelope_from_space_type_ratios')}",
    :variables => [],
    :arguments => [
      {
        :name => 'structure_id',
        :value => structure_id
      },
      {
        :name => 'perim_zone_depth',
        :value => 10,
      },
      # Add this back in once the right measure is in the repo
      {
        :name => 'floor_to_floor_multiplier',
        :value => 1
      },
      {
        :name => 'aspect_ratio_ns_to_ew',
        :value => 2
      },
      # Add this back in once the right measure is in the repo
      {
        :name => 'zoning_logic',
        :value => 'Each SpaceType on at Least One Story Advanced Form'
      }
    ]
  }
  measures << 
  {
    :name => 'add_schedules_to_model',
    :desc => 'Add Schedules to Model',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_schedules_to_model')}",
    :arguments => [
      {
        :name => 'hoo_start',
        :value => building_static_hoo_start
      },
      {
        :name => 'hoo_finish',
        :value => building_static_hoo_finish
      }
    ],
    :variables => []
  }

  measures << {
    :name => 'add_people_to_space_types', 
    :desc => 'Add People to Space Types',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_people_to_space_types')}",
    :arguments => [],
    :variables => [
      {
        :name => 'multiplier_occ',
        :desc => 'Occupancy Multiplier',
        :value => {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
      }
    ]
  }
  
  measures << {
    :name => 'add_ventilation_to_space_types', 
    :desc => 'Add Ventilation to Space Types',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_ventilation_to_space_types')}",
    :arguments => [],
    :variables => [
      {
        :name => 'multiplier_ventilation',
        :desc => 'Ventilation Multiplier',
        :value => {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
      }
    ]
  }

  measures << {
    :name => 'add_infiltration_to_space_types', 
    :desc => 'Add Infiltration to Space Types',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_infiltration_to_space_types')}",
    :arguments => [],
    :variables => [
      {
        :name => 'multiplier_infiltration',
        :desc => 'Infiltration Multiplier',
        :value => {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
      }
    ]
  }

  measures << {
    :name => 'add_constructions_to_space_types', 
    :desc => 'Add Constructions to Space Types',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_constructions_to_space_types')}",
    :arguments => [],
    :variables => []
  }
  measures << {
    :name => 'add_interior_constructions_to_adiabatic_surfaces', 
    :desc => 'Add Interior Constructions to Adiabatic Surfaces',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_interior_constructions_to_adiabatic_surfaces')}",
    :arguments => [],
    :variables => []
  }
  measures << {
    :name => 'add_thermostats', 
    :desc => 'Add Thermostats',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_thermostats')}",
    :arguments => [],
    :variables => []
  }
  measures << {
    :name => 'RotateBuilding', 
    :desc => 'Rotate Building',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'RotateBuilding')}"
    :arguments => [
      {
        :name => 'relative_building_rotation',
        :value => 0
      }
    ],
    :variables => []
  }
  measures << {
    :name => 'add_fenestration_and_overhangs_by_space_type', 
    :desc => 'Add Fenestration And Overhangs By SpaceType',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_fenestration_and_overhangs_by_space_type')}",
    :variables => [
      {
        :name => 'multiplier_wwr',
        :desc => 'Window to Wall Ratio Multiplier',
        :value => {type: 'uniform', minimum: 0.1, maximum: 2, mean: 0.125, static_value: 1}
      }
    ],
    :arguments => [
      {
        :name => 'multiplier_overhang',
        :value => 1
      },
      {
        :name => 'multiplier_srr',
        :value => 1
      },
      {
        :name => 'multiplier_odwr',
        :value => 1
      }
    ]
  }
  measures << {
    :name => 'add_elevators_to_building', 
    :desc => 'Add Elevators To Building',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_elevators_to_building')}",
    :variables => [
      {
        :name => 'multiplier_elevator_eff',
        :desc => 'Elevator Efficiency Multiplier',
        :value => {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
      }
    ],
    :arguments => []
  }
  measures << {
    :name => 'add_lamps_to_spaces_by_space_type', 
    :desc => 'Add Lamps to Spaces by Space Type',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_lamps_to_spaces_by_space_type')}",
    :variables => [
      {
        :name => 'multiplier_lighting',
        :desc => 'Lighting Multiplier',
        :value => {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
      }
    ],
    :arguments => []
  }
  measures << {
    :name => 'add_elec_equip_to_spaces_by_space_type', 
    :desc => 'Add Elec Equip to Spaces by Space Type',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_elec_equip_to_spaces_by_space_type')}",
    :variables => [
      {
        :name => 'multiplier_elec_equip',
        :desc => 'Electric Equipment Multiplier',
        :value => {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
      }
    ],
    :arguments => []
  }
  measures << {
    :name => 'add_gas_equip_to_spaces_by_space_type',
    :desc => 'Add Gas Equip to Spaces by Space Type'
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_gas_equip_to_spaces_by_space_type')}",
    :variables => [
      {
        :name => 'multiplier_gas_equip',
        :desc => 'Add Water Use Connection and Equipment',
        :value => {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
      }
    ],
    :arguments => []
  }

  measures << {
    :name => 'add_water_use_connection_and_equipment', 
    :desc => 'Add Water Use Connection and Equipment',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_water_use_connection_and_equipment')}",
    :variables => [
      {
        :name => 'multiplier_water_use',
        :desc => 'Water Use Multiplier',
        :value => {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
      }
    ],
    :arguments => []
  }

  measures << {
    :name => 'add_exhaust_to_zones_by_space_type', 
    :desc => 'Add Exhaust to Zones by Space Type',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_exhaust_to_zones_by_space_type')}",
    :variables => [
      {
        :name => 'exhaust_fan_eff',
        :desc => 'Exhaust Efficiency Multiplier',
        :value => {type: 'uniform', minimum: 0.1, maximum: 3, mean: 1, static_value: 1}
      }
    ],
    :arguments => []
  }

  measures << {
    :name => 'add_site_loads_to_building', 
    :desc => 'Add Site Loads to Building',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_site_loads_to_building')}",
    :variables => [],
    :arguments => [
      {
        :name => 'multiplier_site_perim_lighting',
        :value => 1
      },
      {
        :name => 'multiplier_site_parking_lighting',
        :value => 1
      }
    ]
  }

  measures << {
    :name => 'add_system01_by_space_type', 
    :desc => 'Add System 01 By Space Type',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system01_by_space_type')}",
    :variables => [],
    :arguments => []
  }

  measures << {
    :name => 'add_system02_by_space_type',
    :desc => 'Add System 02 By Space Type',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system02_by_space_type')}",
    :variables => [],
    :arguments => []
  }

  measures << {
    :name => 'add_system03_by_space_type', 
    :desc => 'Add System 03 By Space Type',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system03_by_space_type')}",
    :variables => [],
    :arguments => []
  }

  measures << {
    :name => 'add_system04_by_space_type', 
    :desc => 'Add System 04 By Space Type',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system04_by_space_type')}",
    :variables => [],
    :arguments => []
  }

  measures << {
    :name => 'add_system05_by_space_type', 
    :desc => 'Add System 05 By Space Type',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system05_by_space_type')}",
    :variables => [],
    :arguments => []
  }

  measures << {
    :name => 'add_system06_by_space_type', 
    :desc => 'Add System 06 By Space Type',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system06_by_space_type')}",
    :variables => [],
    :arguments => []
  }

  measures << {
    :name => 'add_system07_by_space_type', 
    :desc => 'Add System 07 By Space Type',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system07_by_space_type')}",
    :variables => [],
    :arguments => []
  }

  measures << {
    :name => 'add_system08_by_space_type', 
    :desc => 'Add System 08 By Space Type',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system08_by_space_type')}",
    :variables => [],
    :arguments => []
  }

  measures << {
    :name => 'add_service_water_heating_supply', 
    :desc => 'Add Service Water Heating Supply',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_service_water_heating_supply')}",
    :variables => [],
    :arguments => []
  }

  measures << {
    :name => 'adjust_hours_of_operation', 
    :desc => 'Adjust Hours Of Operation',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'adjust_hours_of_operation')}",
    :arguments => [
      {
        :name => 'base_start_hoo',
        :value => building_static_hoo_start
      },
      {
        :name => 'base_finish_hoo',
        :value => building_static_hoo_finish
      }
    ],
    :variables => [
      {
        :name => 'delta_length_hoo',
        :desc => 'Adjust Length of Hours of Operation',
        :value => {type: 'uniform', minimum: -2, maximum: 2, mean: 0, static_value: 0}
      },
      {
        :name => 'shift_hoo',
        :desc => 'Shift Hours of Operation',
        :value => {type: 'uniform', minimum: -2, maximum: 2, mean: 0, static_value: 0}
      }
    ]
  }

  # currently this gathers in demand data out of analytic record and stories it in resource.json for use by ee measures
  measures << {
    :name => 'gather_indemand_data', 
    :desc => 'Gather Indemand Data',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'ee', 'gather_indemand_data')}",
    :arguments => [],
    :variables => []
  }

  measures << {
    :name => 'EH03DualEnthalpyEconomizerControls', 
    :desc => 'EH03: Dual Enthalpy Economizer Controls',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'ee', 'EH03DualEnthalpyEconomizerControls')}",
    :variables => [],
    :arguments [
      {
        :name => 'economizer_type', 
        :value => "DifferentialEnthalpy"
      },
      { 
        :name => 'econoMaxDryBulbTemp', 
        :value => 69.0
      },
      {
        :name => 'econoMaxEnthalpy', 
        :value => 28.0
      },
      {
        :name => 'econoMaxDewpointTemp', 
        :value => 55.0
      },
      {
        :name => 'econoMinDryBulbTemp', 
        :value => -148.0
      },
      {
        :name =>'use_case', 
        :value => "Update M0 with Indemand data"
      }
    ]
  }
  # start of energy plus measures
  measures << {
    :name => 'ElectricityTariffModelForMA', 
    :desc => 'ElectricityTariffModelForMA',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'ElectricityTariffModelForMA')}",
    :variables => [],
    :arguments => [
      {
        :name => 'tariff_type', 
        :value => "MA-Electricity"
      }
    ]
  }

  # start of reporting measures
  measures << {
    :name => 'coffee_annual_summary_report', 
    :desc => 'COFFEE Annual Summary Report',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'coffee_annual_summary_report')}",
    :variables => [],
    :arguments => []
  }

  measures << {
    :name => 'schedule_profile_report', 
    :desc => 'Schedule Profile Report',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'schedule_profile_report')}",
    :variables => [],
    :arguments => []
  }

  outputs = [
    {
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
  ]

  weather_files = [
    'weather_183871/*'
  ]
  default_weather_file = 'weather_183871/Lawrence109_2013CST.epw'
  seed_model = 'seeds/EmptySeedModel.osm'


  # configure analysis
  save_string = "#{structure_id}_#{building_type}_#{year}"
  a = OpenStudio::Analysis.create(save_string)

  measures.each do |m|
    m = a.workflow.add_measure_from_path(m[:name], m[:desc], m[:path])
    m[:arguments].each do |a|
      m.argument_value(a[:name], a[:value])
    end
    m[:variables].each do |v|
      m.make_variable(v[:name], v[:desc], v[:value])
    end
  end

  outputs.each do |o|
    a.add_output(o)
  end

  weather_files.each do |p|
    a.weather_files.add_files(p)
  end 

  # make sure to set the default weather file as well
  a.weather_file(default_weather_file)

  # seed model
  a.seed_model(seed_model)


end
namespace :new do
desc 'run create analysis.json scripts'
namespace :office do
  #NAME = 'Office - test with tariff, fixed system type arg, fixed supply side of water'
  RAILS = false
  #MEASURES_ROOT_DIRECTORY = "../cofee-measures"
  MEASURES_ROOT_DIRECTORY = "../../GitHub/cofee-measures"  # this is path I need to use - dfg
  BUILDING_TYPE = 'office'
  WEATHER_FILE_NAME = 'Lawrence109_2013CST.epw'
  HVAC_SYSTEM_TYPE = 'SysType 7'
  STRUCTURE_ID = 183871

  ANALYSIS_TYPE = 'single_run'
  HOSTNAME = 'http://localhost:8080'
  #HOSTNAME = 'http://bball-130553.nrel.gov:8080' #nrel24a
  #HOSTNAME = 'http://bball-130590.nrel.gov:8080' #nrel24b

  #create_json(structure_id, building_type, year, system_type)
  task :jsons do

    # jobs to send
    hash = {}

    # note - date is only for me looking at what vintages have been tested. There isn't currently a measure argument that uses this, it gets pulled out of teh analytic record similar to area and num floors

    # test out each building type one or more times (more than once when have real analytic records)
    hash["999999_d"] = ["AssistedLiving","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 99)
    hash["999999_e"] = ["AutoRepair","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 131)
    hash["999999_f"] = ["AutoSales","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 98)
    hash["999999_g"] = ["Bank","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 48)
    hash["999999_h"] = ["ChildCare","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 62)
    hash["999999_i"] = ["FullServiceRestaurant","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EU 415)
    hash["999999_j"] = ["GasStation","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 79)
    hash["999999_k"] = ["Hospital","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 102)
    hash["999999_l"] = ["Laboratory","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 56)
    hash["213097"] = ["LargeHotel","1985",HVAC_SYSTEM_TYPE] # ryun 1/18 run (EUI 76) SWH seems way too low
    hash["999999_p"] = ["MidriseApartment","2004",HVAC_SYSTEM_TYPE] # 1/16 runs
    hash["37149"] = ["Office","1987",HVAC_SYSTEM_TYPE] # 1/16 runs
    hash["183871"] = ["Office","1989",HVAC_SYSTEM_TYPE] # 1/16 runs
    hash["272799"] = ["Office","2000",HVAC_SYSTEM_TYPE] # 1/16 runs
    hash["999999_a"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE] # 1/16 runs
    hash["999999_m"] = ["Outpatient","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 100)
    hash["999999_p"] = ["PrimarySchool","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 76)
    hash["999999_q"] = ["QuickServiceRestaurant","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 677)
    hash["999999_n"] = ["Retail","2004",HVAC_SYSTEM_TYPE]  # 1/18 run (EUI 58)
    hash["999999_r"] = ["SecondarySchool","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 73)
    hash["999999_b"] = ["SingleMultiPlexRes","2004",HVAC_SYSTEM_TYPE] # 1/16 runs
    hash["999999_s"] = ["SmallHotel","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 73)
    hash["999999_c"] = ["StripMall","2004",HVAC_SYSTEM_TYPE]  # 1/16 runs
    hash["999999_t"] = ["SuperMarket","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 76)
    hash["999999_o"] = ["Warehouse","2004",HVAC_SYSTEM_TYPE]  # 1/18 (EUI 43)
    #hash[46568] = "DK_????"

    # add in other 9999* test files. That will test 1,2,3 story. 999999 tests 4 story
    hash["999998"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE]# 1/18 run
    hash["999997"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE]# 1/18 run
    hash["999996"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE]# 1/18 run
    hash["999995"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE]# 1/18 run

    # test different system types
    hash["999999_u"] = ["Office","2004SysType1",'SysType 1'] # 1/19 run (EUI 49, unmet htg and clg 575/393)
    hash["999999_v"] = ["Office","2004SysType2",'SysType 2'] # 1/19 run (EUI 46, unmet htg and clg 408/484)
    hash["999999_w"] = ["Office","2004SysType3",'SysType 3'] # 1/19 run (EUI 60, unmet htg and clg 1100/2495)
    hash["999999_x"] = ["Office","2004SysType4",'SysType 4'] # 1/19 run (EUI 49, unmet htg and clg 1055/2495)
    hash["999999_y"] = ["Office","2004SysType5",'SysType 5'] # 1/19 run (EUI 57, unmet htg and clg 2106/3985)
    hash["999999_z"] = ["Office","2004SysType6",'SysType 6'] # 1/19 run (EUI 57, unmet htg and clg 958/1884)
    hash["999999_aa"] = ["Office","2004SysType7",'SysType 7'] # 1/19 run (EUI 56, unmet htg and clg 2105/2045)
    hash["999999_ab"] = ["Office","2004SysType8",'SysType 8'] # 1/19 run (EUI 54, unmet htg and clg 959/1880)

    hash.each do |k,v|
      analytic_record = k.split("_")[0]
      hash_building_type = v[0]
      hash_year = v[1]
      hvac_sys = v[2]
      create_json(analytic_record, hash_building_type, hash_year,hvac_sys)
    end

  end

  desc 'create and run the office json'
  task :run => [:jsons] do

    # jobs to run
    hash = {}

    # note - date is only for me looking at what vintages have been tested. There isn't currently a measure argument that uses this, it gets pulled out of teh analytic record similar to area and num floors

    # test out each building type one or more times (more than once when have real analytic records)
    hash["999999_d"] = ["AssistedLiving","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 99)
    hash["999999_e"] = ["AutoRepair","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 131)
    hash["999999_f"] = ["AutoSales","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 98)
    hash["999999_g"] = ["Bank","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 48)
    hash["999999_h"] = ["ChildCare","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 62)
    hash["999999_i"] = ["FullServiceRestaurant","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EU 415)
    hash["999999_j"] = ["GasStation","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 79)
    hash["999999_k"] = ["Hospital","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 102)
    hash["999999_l"] = ["Laboratory","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 56)
    hash["213097"] = ["LargeHotel","1985",HVAC_SYSTEM_TYPE] # ryun 1/18 run (EUI 76) SWH seems way too low
    hash["999999_p"] = ["MidriseApartment","2004",HVAC_SYSTEM_TYPE] # 1/16 runs
    hash["37149"] = ["Office","1987",HVAC_SYSTEM_TYPE] # 1/16 runs
    hash["183871"] = ["Office","1989",HVAC_SYSTEM_TYPE] # 1/16 runs
    hash["272799"] = ["Office","2000",HVAC_SYSTEM_TYPE] # 1/16 runs
    hash["999999_a"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE] # 1/16 runs
    hash["999999_m"] = ["Outpatient","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 100)
    hash["999999_p"] = ["PrimarySchool","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 76)
    hash["999999_q"] = ["QuickServiceRestaurant","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 677)
    hash["999999_n"] = ["Retail","2004",HVAC_SYSTEM_TYPE]  # 1/18 run (EUI 58)
    hash["999999_r"] = ["SecondarySchool","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 73)
    hash["999999_b"] = ["SingleMultiPlexRes","2004",HVAC_SYSTEM_TYPE] # 1/16 runs
    hash["999999_s"] = ["SmallHotel","2004",HVAC_SYSTEM_TYPE] # 1/18 run (EUI 73)
    hash["999999_c"] = ["StripMall","2004",HVAC_SYSTEM_TYPE]  # 1/16 runs
    hash["999999_t"] = ["SuperMarket","2004",HVAC_SYSTEM_TYPE] # 1/19 run (EUI 76)
    hash["999999_o"] = ["Warehouse","2004",HVAC_SYSTEM_TYPE]  # 1/18 (EUI 43)
    #hash[46568] = "DK_????"

    # add in other 9999* test files. That will test 1,2,3 story. 999999 tests 4 story
    hash["999998"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE]# 1/18 run
    hash["999997"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE]# 1/18 run
    hash["999996"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE]# 1/18 run
    hash["999995"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE]# 1/18 run

    # test different system types
    hash["999999_u"] = ["Office","2004SysType1",'SysType 1'] # 1/19 run (EUI 49, unmet htg and clg 575/393)
    hash["999999_v"] = ["Office","2004SysType2",'SysType 2'] # 1/19 run (EUI 46, unmet htg and clg 408/484)
    hash["999999_w"] = ["Office","2004SysType3",'SysType 3'] # 1/19 run (EUI 60, unmet htg and clg 1100/2495)
    hash["999999_x"] = ["Office","2004SysType4",'SysType 4'] # 1/19 run (EUI 49, unmet htg and clg 1055/2495)
    hash["999999_y"] = ["Office","2004SysType5",'SysType 5'] # 1/19 run (EUI 57, unmet htg and clg 2106/3985)
    hash["999999_z"] = ["Office","2004SysType6",'SysType 6'] # 1/19 run (EUI 57, unmet htg and clg 958/1884)
    hash["999999_aa"] = ["Office","2004SysType7",'SysType 7'] # 1/19 run (EUI 56, unmet htg and clg 2105/2045)
    hash["999999_ab"] = ["Office","2004SysType8",'SysType 8'] # 1/19 run (EUI 54, unmet htg and clg 959/1880)

    hash.each do |k,v|
      analytic_record = k.split("_")[0]
      v = "#{v[0].downcase}_#{v[1].downcase}"
      formulation_file = "analysis/#{analytic_record}_#{v}.json"
      zip_file = "analysis/#{analytic_record}_#{v}.zip"
      api = OpenStudio::Analysis::ServerApi.new( { hostname: HOSTNAME } )
      api.run(formulation_file, zip_file, ANALYSIS_TYPE)
    end

  end
end
end