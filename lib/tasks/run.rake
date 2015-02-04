def create_json(structure_id, building_type, year, system_type)

  # hash to hold space type data
  space_type_hash = {}
  # not adding system type for now
  building_static_hoo_start = nil
  building_static_hoo_finish = nil
  case building_type
    when 'AssistedLiving'
      space_type_hash['AssistedLiving BlendPat'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash['AssistedLiving BlendCom'] = {is_primary: false, type: 'uniform', minimum: 0.2, maximum: 0.5, mean: 0.325, static_value: 0.325}
      space_type_hash['AssistedLiving Kitchen'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.1, mean: 0.075, static_value: 0.075}
      building_static_hoo_start = 6
      building_static_hoo_finish = 22
    when 'AutoRepair'
      space_type_hash['AutoRepair Garage'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash['AutoRepair BlendFront'] = {is_primary: false, type: 'uniform', minimum: 0.2, maximum: 0.6, mean: 0.3, static_value: 0.3}
      space_type_hash['AutoRepair Restroom'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.1, mean: 0.05, static_value: 0.05}
      building_static_hoo_start = 8
      building_static_hoo_finish = 19
    when 'AutoSales'
      space_type_hash['AutoSales BlendFront'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash['AutoSales Garage'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.4, mean: 0.2, static_value: 0.2}
      space_type_hash['AutoSales Restroom'] = {is_primary: false, type: 'uniform', minimum: 0.025, maximum: 0.5, mean: 0.01, static_value: 0.01}
      building_static_hoo_start = 9
      building_static_hoo_finish = 20
    when 'Bank'
      space_type_hash['Bank BlendFront'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash['Bank Elec/MechRoom'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.1, mean: 0.05, static_value: 0.05}
      space_type_hash['Bank Restroom'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.1, mean: 0.05, static_value: 0.05}
      space_type_hash['Bank Vault'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.1, mean: 0.05, static_value: 0.05}
      building_static_hoo_start = 8
      building_static_hoo_finish = 17
    when 'ChildCare'
      space_type_hash['ChildCare BlendEdu'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash['ChildCare Office'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.2, mean: 0.1, static_value: 0.1}
      space_type_hash['ChildCare Restroom'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.15, mean: 0.1, static_value: 0.1}
      building_static_hoo_start = 6
      building_static_hoo_finish = 19
    when 'FullServiceRestaurant'
      space_type_hash['FullServiceRestaurant Dining'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash['FullServiceRestaurant Kitchen'] = {is_primary: false, type: 'uniform', minimum: 0.1, maximum: 0.5, mean: 0.273, static_value: 0.273}
      building_static_hoo_start = 7
      building_static_hoo_finish = 23
    when 'GasStation'
      space_type_hash['GasStation Retail'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash['GasStation Restroom'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.2, mean: 0.05, static_value: 0.05}
      space_type_hash['GasStation ClosedOffice'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.1, mean: 0.05, static_value: 0.05}
      building_static_hoo_start = 6
      building_static_hoo_finish = 20
    when 'Hospital'
      space_type_hash['Hospital BlendPat'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash['Hospital BlendCirc'] = {is_primary: false, type: 'uniform', minimum: 0.15, maximum: 0.35, mean: 0.322, static_value: 0.322}
      space_type_hash['Hospital Kitchen'] = {is_primary: false, type: 'uniform', minimum: 0.025, maximum: 0.075, mean: 0.05, static_value: 0.05}
      space_type_hash['Hospital Dining'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.075, mean: 0.037, static_value: 0.037}
      space_type_hash['Hospital Lab'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.05, mean: 0.028, static_value: 0.028}
      space_type_hash['Hospital Radiology'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.05, mean: 0.026, static_value: 0.026}
      building_static_hoo_start = 4
      building_static_hoo_finish = 22
    when 'Laboratory'
      space_type_hash['Laboratory BlendOff'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
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
      space_type_hash["LargeHotel BlendMisc"] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.05, mean: 0.028, static_value: 0.028}
      space_type_hash["LargeHotel Kitchen"] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.025, mean: 0.011, static_value: 0.011}
      space_type_hash["LargeHotel Laundry"] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.015, mean: 0.008, static_value: 0.008}
      building_static_hoo_start = 6
      building_static_hoo_finish = 22
    when 'MidriseApartment'
      space_type_hash["MidriseApartment BlendA"] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
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
      space_type_hash['Outpatient BlendCirc'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash['Outpatient BlendOff'] = {is_primary: false, type: 'uniform', minimum: 0.2, maximum: 0.35, mean: 0.283, static_value: 0.283}
      space_type_hash['Outpatient BlendPat'] = {is_primary: false, type: 'uniform', minimum: 0.2, maximum: 0.35, mean: 0.253, static_value: 0.253}
      space_type_hash['Outpatient BlendImg'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.075, mean: 0.041, static_value: 0.041}
      space_type_hash['Outpatient BlendMedStg'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.05, mean: 0.025, static_value: 0.025}
      space_type_hash['Outpatient BlendMisc'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.125, mean: 0.1, static_value: 0.1}
      building_static_hoo_start = 4
      building_static_hoo_finish = 22
    when 'PrimarySchool'
      space_type_hash['PrimarySchool BlendEdu'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash['PrimarySchool BlendOff'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.15, mean: 0.126, static_value: 0.126}
      space_type_hash['PrimarySchool Library'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.1, mean: 0.058, static_value: 0.058}
      space_type_hash['PrimarySchool Gym'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.1, mean: 0.052, static_value: 0.052}
      space_type_hash['PrimarySchool Cafeteria'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.075, mean: 0.046, static_value: 0.046}
      space_type_hash['PrimarySchool Kitchen'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.05, mean: 0.024, static_value: 0.024}
      building_static_hoo_start = 8
      building_static_hoo_finish = 16
    when 'QuickServiceRestaurant'
      space_type_hash['QuickServiceRestaurant Dining'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
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
      space_type_hash['SecondarySchool BlendEdu'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash['SecondarySchool BlendOff'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.15, mean: 0.11, static_value: 0.11}
      space_type_hash['SecondarySchool Gym'] = {is_primary: false, type: 'uniform', minimum: 0.1, maximum: 0.15, mean: 0.165, static_value: 0.165}
      space_type_hash['SecondarySchool Auditorium'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.075, mean: 0.05, static_value: 0.05}
      space_type_hash['SecondarySchool Library'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.075, mean: 0.043, static_value: 0.043}
      space_type_hash['SecondarySchool Cafeteria'] = {is_primary: false, type: 'uniform', minimum: 0.015, maximum: 0.05, mean: 0.032, static_value: 0.032}
      space_type_hash['SecondarySchool Kitchen'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.03, mean: 0.011, static_value: 0.011}
      building_static_hoo_start = 8
      building_static_hoo_finish = 16
    when 'SingleMultiPlexRes'
      space_type_hash["MidriseApartment Apartment"] = {is_primary: true, type: 'na_is_primary', minimum: 1.0, maximum: 1.0, mean: 1.0, static_value: 1.0}
      building_static_hoo_start = 8
      building_static_hoo_finish = 18
    when 'SmallHotel'
      space_type_hash['SmallHotel BlendGuest'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
      space_type_hash['SmallHotel BlendMtg'] = {is_primary: false, type: 'uniform', minimum: 0.05, maximum: 0.4, mean: 0.11, static_value: 0.11}
      space_type_hash['SmallHotel BlendMisc'] = {is_primary: false, type: 'uniform', minimum: 0.02, maximum: 0.18, mean: 0.082, static_value: 0.082}
      space_type_hash['SmallHotel Laundry'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.05, mean: 0.025, static_value: 0.025}
      space_type_hash['SmallHotel Exercise'] = {is_primary: false, type: 'uniform', minimum: 0.01, maximum: 0.03, mean: 0.008, static_value: 0.008}
      building_static_hoo_start = 6
      building_static_hoo_finish = 22
    when 'StripMall'
      space_type_hash["StripMall WholeBuilding"] = {is_primary: true, type: 'na_is_primary', minimum: 1.0, maximum: 1.0, mean: 1.0, static_value: 1.0}
      building_static_hoo_start = 7
      building_static_hoo_finish = 21
    when 'SuperMarket' # todo - I need to make schedules for this, missed it earlier in the week. Still won't have refrigeration
      space_type_hash['SuperMarket Sales/Produce'] = {is_primary: true, type: 'uniform', minimum: 0.0, maximum: 0.0, mean: 0.0, static_value: 0.0}
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
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'NGridAddMonthlyUtilityData')}",
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
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'CalibrationReports')}",
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
        :name => 'is_primary_space_type',
        :value => true
      }
      measure[:arguments] << {
        :name => 'fraction_of_building_area', 
        :value => values[:static_value]
      }
    else
      measure[:arguments] << {
        :name => 'is_primary_space_type',
        :value => false
      }
      measure[:variables] <<
      {
        :name => 'fraction_of_building_area',
        :desc => 'Building Area Fraction',
        :value => values
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
    # original measure
    #:name => 'make_envelope_from_space_type_ratios',
    #:desc => 'Make Envelope From Space Type Ratios',
    #:path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'make_envelope_from_space_type_ratios')}",

    # version with pre-loaded resources
    :name => 'make_envelope_from_space_type_ratios_populated_seed_model',
    :desc => 'Make Envelope From Space Type Ratios Populated Seed Model',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'make_envelope_from_space_type_ratios_populated_seed_model')}",

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

=begin
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
=end

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
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'RotateBuilding')}",
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
    :desc => 'Add Gas Equip to Spaces by Space Type',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_gas_equip_to_spaces_by_space_type')}",
    :variables => [
      {
        :name => 'multiplier_gas_equip',
        :desc => 'Gas Equipment Multiplier',
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

  # this is to streamline the system to only add necessary HVAC measures
  # written for whole building system type. Will have to update when there can be multiple in workflow
  case system_type

  when "SysType 1"
    measures << {
      :name => 'add_system01_by_space_type',
      :desc => 'Add System 01 By Space Type',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system01_by_space_type')}",
      :variables => [],
      :arguments => []
    }

  when "SysType 2"
    measures << {
      :name => 'add_system02_by_space_type',
      :desc => 'Add System 02 By Space Type',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system02_by_space_type')}",
      :variables => [],
      :arguments => []
    }

  when "SysType 3"
    measures << {
      :name => 'add_system03_by_space_type',
      :desc => 'Add System 03 By Space Type',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system03_by_space_type')}",
      :variables => [],
      :arguments => []
    }

  when "SysType 4"
    measures << {
      :name => 'add_system04_by_space_type',
      :desc => 'Add System 04 By Space Type',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system04_by_space_type')}",
      :variables => [],
      :arguments => []
    }

  when "SysType 5"
    measures << {
      :name => 'add_system05_by_space_type',
      :desc => 'Add System 05 By Space Type',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system05_by_space_type')}",
      :variables => [],
      :arguments => []
    }

  when "SysType 6"
    measures << {
      :name => 'add_system06_by_space_type',
      :desc => 'Add System 06 By Space Type',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system06_by_space_type')}",
      :variables => [],
      :arguments => []
    }

  when "SysType 7"
    measures << {
      :name => 'add_system07_by_space_type',
      :desc => 'Add System 07 By Space Type',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system07_by_space_type')}",
      :variables => [],
      :arguments => []
    }

  when "SysType 8"
    measures << {
      :name => 'add_system08_by_space_type',
      :desc => 'Add System 08 By Space Type',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'add_system08_by_space_type')}",
      :variables => [],
      :arguments => []
    }

  else
    fail "#{system_type} is not a supported system type"
  end

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

# we don't want this in by default, but may use in calibration some times.
=begin
  measures << {
      :name => 'adjust_water_heater_mixed',
      :desc => 'Adjust Water Heater Mixed',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'adjust_water_heater_mixed')}",
      :variables => [],
      :arguments => [
          {
          :name => 'heater_thermal_efficiency',
          :value => 0.85
      },
      {
          :name => 'fuel_type',
          :value => 'Electricity'
      }
    ]
  }
=end


=begin
  # currently this gathers in demand data out of analytic record and stories it in resource.json for use by ee measures
  measures << {
    :name => 'gather_indemand_data', 
    :desc => 'Gather Indemand Data',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'ee', 'gather_indemand_data')}",
    :arguments => [],
    :variables => []
  }

  # start of ee measures
  measures << {
    :name => 'EH03DualEnthalpyEconomizerControls', 
    :desc => 'EH03: Dual Enthalpy Economizer Controls',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'ee', 'EH03DualEnthalpyEconomizerControls')}",
    :variables => [],
    :arguments => [
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
        :name => 'use_case',
        :value => "Apply EE to calibrated model"  # valid options are "Update M0 with Indemand data" or "Apply EE to calibrated model"
      },
      {
        :name => 'run_measure',
        :value => true
      }
    ]
  }

  measures << {
      :name => 'EH04ECMFanMotors',
      :desc => 'EH04: ECM Fan Motors',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'ee', 'EH04ECMFanMotors')}",
      :variables => [],
      :arguments => [
          {
              :name => 'psc_eff',
              :value => 0.45
          },
          {
              :name => 'ecm_eff',
              :value => 0.75
          },
          {
              :name => 'use_case',
              :value => "Apply EE to calibrated model"  # valid options are "Update M0 with Indemand data" or "Apply EE to calibrated model"
          },
          {
              :name => 'run_measure',
              :value => true
          }
      ]
  }

  measures << {
      :name => 'EH05EnergyManagementSystemDemandControlledVentilation',
      :desc => 'EH05: Energy Management System-Demand Controlled Ventilation',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'ee', 'EH05EnergyManagementSystemDemandControlledVentilation')}",
      :variables => [],
      :arguments => [
          {
              :name => 'use_case',
              :value => "Apply EE to calibrated model"  # valid options are "Update M0 with Indemand data" or "Apply EE to calibrated model"
          },
          {
              :name => 'run_measure',
              :value => true
          }
      ]
  }

  measures << {
      :name => 'EL02LightingSystems',
      :desc => 'EL02:Lighting Systems',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'ee', 'EL02LightingSystems')}",
      :variables => [],
      :arguments => [
          {
              :name => 'use_case',
              :value => "Apply EE to calibrated model"  # valid options are "Update M0 with Indemand data" or "Apply EE to calibrated model"
          },
          {
              :name => 'run_measure',
              :value => "LED Troffer"
          }
      ]
  }

  measures << {
      :name => 'EL03LightingControls',
      :desc => 'EL03:Lighting Controls',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'ee', 'EL03LightingControls')}",
      :variables => [],
      :arguments => [
          {
              :name => 'fixtures_per_sensor',
              :value => 9.0
          },
          {
              :name => 'use_case',
              :value => "Apply EE to calibrated model"  # valid options are "Update M0 with Indemand data" or "Apply EE to calibrated model"
          },
          {
              :name => 'run_measure',
              :value => "Occupancy Controls and Daylighitng"
          }
      ]
  }

  # some ee measures (with the ee vs. indemand use case) need a hard sized model. Typically this would be done at the end of calibration
  measures << {
      :name => 'HardSizeHVAC',
      :desc => 'Hard Size HVAC',
      :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'hard_size_hvac')}",
      :variables => [],
      :arguments => []
  }
=end

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

=begin
  measures << {
    :name => 'schedule_profile_report', 
    :desc => 'Schedule Profile Report',
    :path => "#{File.join(MEASURES_ROOT_DIRECTORY, 'model0', 'schedule_profile_report')}",
    :variables => [],
    :arguments => []
  }
=end

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
    "#{WEATHER_FILES_DIRECTORY}/*"
  ]
  default_weather_file = "#{WEATHER_FILES_DIRECTORY}/Lawrence109_2013CST.epw"
  #seed_model = 'seeds/EmptySeedModel.osm'
  seed_model = 'seeds/Office2004_Seed.osm'


  # configure analysis
  save_string = "#{structure_id}_#{building_type}_#{year}"
  a = OpenStudio::Analysis.create(save_string)

  measures.each do |m|
    measure = a.workflow.add_measure_from_path(m[:name], m[:desc], m[:path])
    m[:arguments].each do |a|
      measure.argument_value(a[:name], a[:value])
    end
    m[:variables].each do |v|
      measure.make_variable(v[:name], v[:desc], v[:value])
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

  # will be handled by cofee-grinder

  # add in the other libraries
  a.libraries.add("#{MEASURES_ROOT_DIRECTORY}/lib", { library_name: 'cofee'})
  a.libraries.add('lib_m0/183871', { library_name: 'calibration_data'})


  # add any worker init / finalization scripts - the files will run in the order that they are added
  # this is just an example file
  #a.worker_inits.add('project_ruby/office_blend.rb', {args: [19837,"z",{b: 'something'}]})
  #a.worker_finalizes.add('project_ruby/office_blend.rb')
  # Save the analysis JSON
  formulation_file = "analysis/#{save_string.downcase.squeeze(' ').gsub(' ', '_')}.json"
  zip_file = "analysis/#{save_string.downcase.squeeze(' ').gsub(' ', '_')}.zip"

  # set the analysis type here as well. I plan on not having this required in the near future
  a.analysis_type = ANALYSIS_TYPE

  a.save formulation_file
  a.save_zip zip_file

end

desc 'run create analysis.json scripts'
namespace :test_models do
  #NAME = 'Office - test with tariff, fixed system type arg, fixed supply side of water'
  RAILS = false
  MEASURES_ROOT_DIRECTORY = "../cofee-measures"
  MEASURES_ROOT_DIRECTORY = "../../GitHub/cofee-measures"  # this is path I need to use - dfg
  BUILDING_TYPE = 'office'
  WEATHER_FILE_NAME = 'Lawrence109_2013CST.epw'
  WEATHER_FILES_DIRECTORY = 'weather_183871'
  HVAC_SYSTEM_TYPE = 'SysType 7'
  STRUCTURE_ID = 183871

  ANALYSIS_TYPE = 'single_run'
  #HOSTNAME = 'http://localhost:8080'
  HOSTNAME = 'http://bball-130553.nrel.gov:8080' #nrel24a
  #HOSTNAME = 'http://bball-130590.nrel.gov:8080' #nrel24b

  #create_json(structure_id, building_type, year, system_type)
  task :jsons do

    # jobs to send
    hash = {}

    # test out each building type one or more times (more than once when have real analytic records)
    # note - date is only for me looking at what vintages have been tested. There isn't currently a measure argument that uses this, it gets pulled out of teh analytic record similar to area and num floors
    # comments at end of hash entry - eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes: list dominant loads, errors, and other comments here

=begin
    hash["999999_d"] = ["AssistedLiving","2004",HVAC_SYSTEM_TYPE] # eui 96, unmet_htg_and_clg 354/691, dur_sec 154, notes: no errors, dominant end use is equip
    hash["999999_e"] = ["AutoRepair","2004",HVAC_SYSTEM_TYPE] # eui 115, unmet_htg_and_clg 673/6202, dur_sec 244, notes: no errors, dominant end use is equip, very high unmet cooling maybe due to garage on main system?
    hash["999999_f"] = ["AutoSales","2004",HVAC_SYSTEM_TYPE] # eui 141, unmet_htg_and_clg 1675/2097, dur_sec 176, notes: no errors, dominant end use is heating
    hash["999999_g"] = ["Bank","2004",HVAC_SYSTEM_TYPE] # eui 48, unmet_htg_and_clg 2062/1742, dur_sec 184, notes:,notes: no errors, dominant end uses are heating lighting, and equip
    hash["999999_h"] = ["ChildCare","2004",HVAC_SYSTEM_TYPE] # eui 62, unmet_htg_and_clg 1383/3771, dur_sec 181, notes: no errors, dominant end uses are heating lighting and equip
    hash["999999_i"] = ["FullServiceRestaurant","2004",HVAC_SYSTEM_TYPE] # eui 494, unmet_htg_and_clg 662/22, dur_sec 197, notes: no errors, dominant end use is equip then swh
    hash["999999_j"] = ["GasStation","2004",HVAC_SYSTEM_TYPE] # eui 71, unmet_htg_and_clg 1561/1411, dur_sec 163, notes: no errors, dominant end use is heating then lighting and swh
    hash["999999_k"] = ["Hospital","2004",HVAC_SYSTEM_TYPE] # eui 104, unmet_htg_and_clg 384/1158, dur_sec 232, notes: no errors, equip is dominant load, EUI seems low
    hash["999999_l"] = ["Laboratory","2004",HVAC_SYSTEM_TYPE] # eui 62, unmet_htg_and_clg 1879/1844, dur_sec 247, notes: no errors, equip is dominant load then heating and lighting
    hash["213097"] = ["LargeHotel","1985",HVAC_SYSTEM_TYPE] # eui 112, unmet_htg_and_clg 15/0, dur_sec 272, notes: no errors, dominant end use is equip then swh heating and lighting
    hash["999999_ac"] = ["MidriseApartment","2004",HVAC_SYSTEM_TYPE] # eui 74, unmet_htg_and_clg 0,0, dur_sec 159, notes: no errors, dominant end use is swh then heating equip and lighting
    hash["37149"] = ["Office","1987",HVAC_SYSTEM_TYPE] # eui 71, unmet_htg_and_clg 1569/1521, dur_sec 205, notes: no errors, dominant end use is heating then lighting and equip
    hash["183871"] = ["Office","1989",HVAC_SYSTEM_TYPE] # eui 72, unmet_htg_and_clg 1517/1494, dur_sec 182, notes: no errors, dominant end use is heating then lighting and equip
    hash["272799"] = ["Office","2000",HVAC_SYSTEM_TYPE] # eui 67, unmet_htg_and_clg 1637/2820, dur_sec 214, notes: no errors, dominant end uses are heating lighting and equip
    hash["999999_a"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE] # 52, unmet_htg_and_clg 1746/2227, dur_sec 234, notes: no errors, dominant end use is equip then lighting and heating
    hash["999999_m"] = ["Outpatient","2004",HVAC_SYSTEM_TYPE] # 100, unmet_htg_and_clg 677/2996, dur_sec 232, notes: no errors, dominant end use is equip then heating
    hash["999999_p"] = ["PrimarySchool","2004",HVAC_SYSTEM_TYPE] # eui 76, unmet_htg_and_clg 1216/3863, dur_sec 309, notes: no errors, dominant end uses are equip and heating then lighting, swh seems higher than expected
    hash["999999_q"] = ["QuickServiceRestaurant","2004",HVAC_SYSTEM_TYPE] # eui 678, unmet_htg_and_clg 550/0, dur_sec 186, notes: no errors, dominant end use is equip (gas and elec) then swh
    hash["999999_n"] = ["Retail","2004",HVAC_SYSTEM_TYPE] # eui 58, unmet_htg_and_clg 1123/3880, dur_sec 172, notes: no errors, dominant end use is heating lighting and equip
    hash["999999_r"] = ["SecondarySchool","2004",HVAC_SYSTEM_TYPE]# eui 77, unmet_htg_and_clg 1459/3252, dur_sec 320, notes: no errors, heating is primary end use then lighting equip and swh
    hash["999999_b"] = ["SingleMultiPlexRes","2004",HVAC_SYSTEM_TYPE] # eui 87, unmet_htg_and_clg 0,0, dur_sec 107, notes: no errors, dominant end use swh
    hash["999999_s"] = ["SmallHotel","2004",HVAC_SYSTEM_TYPE] # eui 74, unmet_htg_and_clg 76/0, dur_sec 207, notes: no errors, dominant end use is equip then heating and swh
    hash["999999_c"] = ["StripMall","2004",HVAC_SYSTEM_TYPE]  # eui 48, unmet_htg_and_clg 561/3547, dur_sec 128, notes: no errors, dominant end use is lighting then equip and heating
    hash["999999_t"] = ["SuperMarket","2004",HVAC_SYSTEM_TYPE] # eui 77, unmet_htg_and_clg 751/3215, dur_sec 188, notes: no errors, dominant end uses are heating equip and lighting
    hash["999999_o"] = ["Warehouse","2004",HVAC_SYSTEM_TYPE]  # eui 43, unmet_htg_and_clg 694/644, dur_sec 137, notes: no errors, dominant end use is heating
    #hash[46568] = "DK_????"

    # pre 1980
    test_vintage = "1970"
    hash["999999_d_#{test_vintage}"] = ["AssistedLiving",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_e_#{test_vintage}"] = ["AutoRepair",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_f_#{test_vintage}"] = ["AutoSales",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_g_#{test_vintage}"] = ["Bank",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_h_#{test_vintage}"] = ["ChildCare",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_i_#{test_vintage}"] = ["FullServiceRestaurant",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_j_#{test_vintage}"] = ["GasStation",test_vintage,HVAC_SYSTEM_TYPE] 
    hash["999999_k_#{test_vintage}"] = ["Hospital",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_l_#{test_vintage}"] = ["Laboratory",test_vintage,HVAC_SYSTEM_TYPE]
    hash["213097_#{test_vintage}"] = ["LargeHotel","1985",HVAC_SYSTEM_TYPE]
    hash["999999_ac_#{test_vintage}"] = ["MidriseApartment",test_vintage,HVAC_SYSTEM_TYPE]
    hash["272799_#{test_vintage}"] = ["Office",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_a_#{test_vintage}"] = ["OfficeData",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_m_#{test_vintage}"] = ["Outpatient",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_p_#{test_vintage}"] = ["PrimarySchool",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_q_#{test_vintage}"] = ["QuickServiceRestaurant",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_n_#{test_vintage}"] = ["Retail",test_vintage,HVAC_SYSTEM_TYPE] 
    hash["999999_r_#{test_vintage}"] = ["SecondarySchool",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_b_#{test_vintage}"] = ["SingleMultiPlexRes",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_s_#{test_vintage}"] = ["SmallHotel",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_c_#{test_vintage}"] = ["StripMall",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_t_#{test_vintage}"] = ["SuperMarket",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_o_#{test_vintage}"] = ["Warehouse",test_vintage,HVAC_SYSTEM_TYPE]

    # 1980-2004
    test_vintage = "1985"
    hash["999999_d_#{test_vintage}"] = ["AssistedLiving",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_e_#{test_vintage}"] = ["AutoRepair",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_f_#{test_vintage}"] = ["AutoSales",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_g_#{test_vintage}"] = ["Bank",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_h_#{test_vintage}"] = ["ChildCare",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_i_#{test_vintage}"] = ["FullServiceRestaurant",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_j_#{test_vintage}"] = ["GasStation",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_k_#{test_vintage}"] = ["Hospital",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_l_#{test_vintage}"] = ["Laboratory",test_vintage,HVAC_SYSTEM_TYPE]
    hash["213097_#{test_vintage}"] = ["LargeHotel","1985",HVAC_SYSTEM_TYPE]
    hash["999999_ac_#{test_vintage}"] = ["MidriseApartment",test_vintage,HVAC_SYSTEM_TYPE]
    hash["272799_#{test_vintage}"] = ["Office",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_a_#{test_vintage}"] = ["OfficeData",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_m_#{test_vintage}"] = ["Outpatient",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_p_#{test_vintage}"] = ["PrimarySchool",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_q_#{test_vintage}"] = ["QuickServiceRestaurant",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_n_#{test_vintage}"] = ["Retail",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_r_#{test_vintage}"] = ["SecondarySchool",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_b_#{test_vintage}"] = ["SingleMultiPlexRes",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_s_#{test_vintage}"] = ["SmallHotel",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_c_#{test_vintage}"] = ["StripMall",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_t_#{test_vintage}"] = ["SuperMarket",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_o_#{test_vintage}"] = ["Warehouse",test_vintage,HVAC_SYSTEM_TYPE]

    # add in other 9999* test files. That will test 1,2,3 story. 999999 tests 4 story
    hash["999998"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999997"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999996"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999995"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:

=end
    # test different system types
    hash["999999_u"] = ["OfficeData","2004SysType1",'SysType 1'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_v"] = ["OfficeData","2004SysType2",'SysType 2'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_w"] = ["OfficeData","2004SysType3",'SysType 3'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_x"] = ["OfficeData","2004SysType4",'SysType 4'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_y"] = ["OfficeData","2004SysType5",'SysType 5'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_z"] = ["OfficeData","2004SysType6",'SysType 6'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_aa"] = ["OfficeData","2004SysType7",'SysType 7'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_ab"] = ["OfficeData","2004SysType8",'SysType 8'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:

    hash.each do |k,v|
      analytic_record = k.split("_")[0]
      hash_building_type = v[0]
      hash_year = v[1]
      hvac_sys = v[2]
      create_json(analytic_record, hash_building_type, hash_year,hvac_sys)
    end

  end

  desc 'create and run the office json'
  task :queue do

    # jobs to run
    hash = {}

    # test out each building type one or more times (more than once when have real analytic records)
    # note - date is only for me looking at what vintages have been tested. There isn't currently a measure argument that uses this, it gets pulled out of teh analytic record similar to area and num floors
    # comments at end of hash entry - eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes: list dominant loads, errors, and other comments here

=begin
    hash["999999_d"] = ["AssistedLiving","2004",HVAC_SYSTEM_TYPE] # eui 96, unmet_htg_and_clg 354/691, dur_sec 154, notes: no errors, dominant end use is equip
    hash["999999_e"] = ["AutoRepair","2004",HVAC_SYSTEM_TYPE] # eui 115, unmet_htg_and_clg 673/6202, dur_sec 244, notes: no errors, dominant end use is equip, very high unmet cooling maybe due to garage on main system?
    hash["999999_f"] = ["AutoSales","2004",HVAC_SYSTEM_TYPE] # eui 141, unmet_htg_and_clg 1675/2097, dur_sec 176, notes: no errors, dominant end use is heating
    hash["999999_g"] = ["Bank","2004",HVAC_SYSTEM_TYPE] # eui 48, unmet_htg_and_clg 2062/1742, dur_sec 184, notes:,notes: no errors, dominant end uses are heating lighting, and equip
    hash["999999_h"] = ["ChildCare","2004",HVAC_SYSTEM_TYPE] # eui 62, unmet_htg_and_clg 1383/3771, dur_sec 181, notes: no errors, dominant end uses are heating lighting and equip
    hash["999999_i"] = ["FullServiceRestaurant","2004",HVAC_SYSTEM_TYPE] # eui 494, unmet_htg_and_clg 662/22, dur_sec 197, notes: no errors, dominant end use is equip then swh
    hash["999999_j"] = ["GasStation","2004",HVAC_SYSTEM_TYPE] # eui 71, unmet_htg_and_clg 1561/1411, dur_sec 163, notes: no errors, dominant end use is heating then lighting and swh
    hash["999999_k"] = ["Hospital","2004",HVAC_SYSTEM_TYPE] # eui 104, unmet_htg_and_clg 384/1158, dur_sec 232, notes: no errors, equip is dominant load, EUI seems low
    hash["999999_l"] = ["Laboratory","2004",HVAC_SYSTEM_TYPE] # eui 62, unmet_htg_and_clg 1879/1844, dur_sec 247, notes: no errors, equip is dominant load then heating and lighting
    hash["213097"] = ["LargeHotel","1985",HVAC_SYSTEM_TYPE] # eui 112, unmet_htg_and_clg 15/0, dur_sec 272, notes: no errors, dominant end use is equip then swh heating and lighting
    hash["999999_ac"] = ["MidriseApartment","2004",HVAC_SYSTEM_TYPE] # eui 74, unmet_htg_and_clg 0,0, dur_sec 159, notes: no errors, dominant end use is swh then heating equip and lighting
    hash["37149"] = ["Office","1987",HVAC_SYSTEM_TYPE] # eui 71, unmet_htg_and_clg 1569/1521, dur_sec 205, notes: no errors, dominant end use is heating then lighting and equip
    hash["183871"] = ["Office","1989",HVAC_SYSTEM_TYPE] # eui 72, unmet_htg_and_clg 1517/1494, dur_sec 182, notes: no errors, dominant end use is heating then lighting and equip
    hash["272799"] = ["Office","2000",HVAC_SYSTEM_TYPE] # eui 67, unmet_htg_and_clg 1637/2820, dur_sec 214, notes: no errors, dominant end uses are heating lighting and equip
    hash["999999_a"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE] # 52, unmet_htg_and_clg 1746/2227, dur_sec 234, notes: no errors, dominant end use is equip then lighting and heating
    hash["999999_m"] = ["Outpatient","2004",HVAC_SYSTEM_TYPE] # 100, unmet_htg_and_clg 677/2996, dur_sec 232, notes: no errors, dominant end use is equip then heating
    hash["999999_p"] = ["PrimarySchool","2004",HVAC_SYSTEM_TYPE] # eui 76, unmet_htg_and_clg 1216/3863, dur_sec 309, notes: no errors, dominant end uses are equip and heating then lighting, swh seems higher than expected
    hash["999999_q"] = ["QuickServiceRestaurant","2004",HVAC_SYSTEM_TYPE] # eui 678, unmet_htg_and_clg 550/0, dur_sec 186, notes: no errors, dominant end use is equip (gas and elec) then swh
    hash["999999_n"] = ["Retail","2004",HVAC_SYSTEM_TYPE] # eui 58, unmet_htg_and_clg 1123/3880, dur_sec 172, notes: no errors, dominant end use is heating lighting and equip
    hash["999999_r"] = ["SecondarySchool","2004",HVAC_SYSTEM_TYPE]# eui 77, unmet_htg_and_clg 1459/3252, dur_sec 320, notes: no errors, heating is primary end use then lighting equip and swh
    hash["999999_b"] = ["SingleMultiPlexRes","2004",HVAC_SYSTEM_TYPE] # eui 87, unmet_htg_and_clg 0,0, dur_sec 107, notes: no errors, dominant end use swh
    hash["999999_s"] = ["SmallHotel","2004",HVAC_SYSTEM_TYPE] # eui 74, unmet_htg_and_clg 76/0, dur_sec 207, notes: no errors, dominant end use is equip then heating and swh
    hash["999999_c"] = ["StripMall","2004",HVAC_SYSTEM_TYPE]  # eui 48, unmet_htg_and_clg 561/3547, dur_sec 128, notes: no errors, dominant end use is lighting then equip and heating
    hash["999999_t"] = ["SuperMarket","2004",HVAC_SYSTEM_TYPE] # eui 77, unmet_htg_and_clg 751/3215, dur_sec 188, notes: no errors, dominant end uses are heating equip and lighting
    hash["999999_o"] = ["Warehouse","2004",HVAC_SYSTEM_TYPE]  # eui 43, unmet_htg_and_clg 694/644, dur_sec 137, notes: no errors, dominant end use is heating
    #hash[46568] = "DK_????"

    # pre 1980
    test_vintage = "1970"
    hash["999999_d_#{test_vintage}"] = ["AssistedLiving",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_e_#{test_vintage}"] = ["AutoRepair",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_f_#{test_vintage}"] = ["AutoSales",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_g_#{test_vintage}"] = ["Bank",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_h_#{test_vintage}"] = ["ChildCare",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_i_#{test_vintage}"] = ["FullServiceRestaurant",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_j_#{test_vintage}"] = ["GasStation",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_k_#{test_vintage}"] = ["Hospital",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_l_#{test_vintage}"] = ["Laboratory",test_vintage,HVAC_SYSTEM_TYPE]
    hash["213097_#{test_vintage}"] = ["LargeHotel","1985",HVAC_SYSTEM_TYPE]
    hash["999999_ac_#{test_vintage}"] = ["MidriseApartment",test_vintage,HVAC_SYSTEM_TYPE]
    hash["272799_#{test_vintage}"] = ["Office",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_a_#{test_vintage}"] = ["OfficeData",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_m_#{test_vintage}"] = ["Outpatient",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_p_#{test_vintage}"] = ["PrimarySchool",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_q_#{test_vintage}"] = ["QuickServiceRestaurant",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_n_#{test_vintage}"] = ["Retail",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_r_#{test_vintage}"] = ["SecondarySchool",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_b_#{test_vintage}"] = ["SingleMultiPlexRes",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_s_#{test_vintage}"] = ["SmallHotel",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_c_#{test_vintage}"] = ["StripMall",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_t_#{test_vintage}"] = ["SuperMarket",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_o_#{test_vintage}"] = ["Warehouse",test_vintage,HVAC_SYSTEM_TYPE]

    # 1980-2004
    test_vintage = "1985"
    hash["999999_d_#{test_vintage}"] = ["AssistedLiving",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_e_#{test_vintage}"] = ["AutoRepair",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_f_#{test_vintage}"] = ["AutoSales",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_g_#{test_vintage}"] = ["Bank",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_h_#{test_vintage}"] = ["ChildCare",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_i_#{test_vintage}"] = ["FullServiceRestaurant",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_j_#{test_vintage}"] = ["GasStation",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_k_#{test_vintage}"] = ["Hospital",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_l_#{test_vintage}"] = ["Laboratory",test_vintage,HVAC_SYSTEM_TYPE]
    hash["213097_#{test_vintage}"] = ["LargeHotel","1985",HVAC_SYSTEM_TYPE]
    hash["999999_ac_#{test_vintage}"] = ["MidriseApartment",test_vintage,HVAC_SYSTEM_TYPE]
    hash["272799_#{test_vintage}"] = ["Office",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_a_#{test_vintage}"] = ["OfficeData",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_m_#{test_vintage}"] = ["Outpatient",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_p_#{test_vintage}"] = ["PrimarySchool",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_q_#{test_vintage}"] = ["QuickServiceRestaurant",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_n_#{test_vintage}"] = ["Retail",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_r_#{test_vintage}"] = ["SecondarySchool",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_b_#{test_vintage}"] = ["SingleMultiPlexRes",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_s_#{test_vintage}"] = ["SmallHotel",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_c_#{test_vintage}"] = ["StripMall",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_t_#{test_vintage}"] = ["SuperMarket",test_vintage,HVAC_SYSTEM_TYPE]
    hash["999999_o_#{test_vintage}"] = ["Warehouse",test_vintage,HVAC_SYSTEM_TYPE]

    # add in other 9999* test files. That will test 1,2,3 story. 999999 tests 4 story
    hash["999998"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999997"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999996"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999995"] = ["OfficeData","2004",HVAC_SYSTEM_TYPE] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:

=end
    # test different system types
    hash["999999_u"] = ["OfficeData","2004SysType1",'SysType 1'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_v"] = ["OfficeData","2004SysType2",'SysType 2'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_w"] = ["OfficeData","2004SysType3",'SysType 3'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_x"] = ["OfficeData","2004SysType4",'SysType 4'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_y"] = ["OfficeData","2004SysType5",'SysType 5'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_z"] = ["OfficeData","2004SysType6",'SysType 6'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_aa"] = ["OfficeData","2004SysType7",'SysType 7'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:
    hash["999999_ab"] = ["OfficeData","2004SysType8",'SysType 8'] # eui TBD, unmet_htg_and_clg TBD/TBD, dur_sec TBD, notes:

    hash.each do |k,v|
      analytic_record = k.split("_")[0]
      v = "#{v[0].downcase}_#{v[1].downcase}"
      formulation_file = "analysis/#{analytic_record}_#{v}.json"
      zip_file = "analysis/#{analytic_record}_#{v}.zip"
      if File.exist?(formulation_file) && File.exist?(zip_file)
        puts "Running #{analytic_record}_#{v}"
        api = OpenStudio::Analysis::ServerApi.new( { hostname: HOSTNAME } )
        api.queue_single_run(formulation_file, zip_file, ANALYSIS_TYPE)
      else
        puts "Could not file JSON or ZIP for #{analytic_record}_#{v}"
      end
    end
  end

  desc 'start the run queue'
  task :start do
    api = OpenStudio::Analysis::ServerApi.new( { hostname: HOSTNAME } )
    api.run_batch_run_across_analyses(nil, nil, ANALYSIS_TYPE)
  end

end