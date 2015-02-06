require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'fileutils'

def create_template(structure_id, building_type, year)

  #measures_root_directory = "../cofee-measures"
  measures_root_directory = "../../GitHub/cofee-measures"  # this is path I need to use - dfg

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

  # create loop for gather space type ratio instances
  space_type_hash.each do |space_type_name,values|
    measure = {
      :name => "gather_space_type_ratio_data_#{space_type_name}", 
      :desc => "Gather Space Type Ratio Data #{space_type_name}",
      :path => "#{File.join(measures_root_directory, 'model0', 'gather_space_type_ratio_data')}",
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
        :name => 'fraction_of_building_area',
        :value => values[:static_value]
      }
      measure[:arguments] << {
        :name => 'is_primary_space_type',
        :value => true

      }
    else
      measure[:arguments] << {
        :name => 'fraction_of_building_area',
        :value => values[:static_value]
      }
      measure[:arguments] <<
      {
        :name => 'is_primary_space_type',
        :value => false
      }
    end
    measure[:arguments] << {
      :name => 'hvac_system_type', 
      :value => "na" # not using this
    }
    measures << measure
  end

  measures <<
  {
    :name => 'do_not_make_envelope',
    :desc => 'Do Not Make Envelope',
    :path => "#{File.join(measures_root_directory, 'model0', 'do_not_make_envelope')}",
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
    :path => "#{File.join(measures_root_directory, 'model0', 'add_schedules_to_model')}",
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
    :path => "#{File.join(measures_root_directory, 'model0', 'add_people_to_space_types')}",
    :arguments => [
      {
        :name => 'multiplier_occ',
        :value => 1.0
      }
    ],
    :variables => []
  }
  
  measures << {
    :name => 'add_ventilation_to_space_types', 
    :desc => 'Add Ventilation to Space Types',
    :path => "#{File.join(measures_root_directory, 'model0', 'add_ventilation_to_space_types')}",
    :arguments => [
      {
        :name => 'multiplier_ventilation',
        :value => 1.0
      }

    ],
    :variables => []
  }

  measures << {
    :name => 'add_infiltration_to_space_types', 
    :desc => 'Add Infiltration to Space Types',
    :path => "#{File.join(measures_root_directory, 'model0', 'add_infiltration_to_space_types')}",
    :arguments => [
      {
        :name => 'multiplier_infiltration',
        :value => 1.0
      }
    ],
    :variables => []
  }

  measures << {
    :name => 'add_constructions_to_space_types', 
    :desc => 'Add Constructions to Space Types',
    :path => "#{File.join(measures_root_directory, 'model0', 'add_constructions_to_space_types')}",
    :arguments => [],
    :variables => []
  }

  # infered data for template
  template = nil
  if year.to_i < 1980
    template = "DOE Ref Pre-1980"
  elsif year.to_i < 2004
    template = "DOE Ref 1980-2004"
  else
    template = "DOE Ref 2004"
  end

  # hard coded climate zone
  climate_zone =  "ASHRAE 169-2006-5A"

  puts "Creating #{building_type}_#{template}_#{climate_zone}.osm"

  # create an instance of a runner
  runner = OpenStudio::Ruleset::OSRunner.new

  # load the test model
  translator = OpenStudio::OSVersion::VersionTranslator.new
  path = OpenStudio::Path.new("#{Dir.pwd}/seeds/EmptySeedModel.osm")
  model = translator.loadModel(path)
  #assert((not model.empty?))
  model = model.get

  # make an empty model
  #model = OpenStudio::Model::Model.new

  # delete resource.json before each building runs. Other wise keeps extending and breaks
  FileUtils.rm("../resource.json")

  measures.each do |m|

    # load the measure
    require_relative (Dir.pwd + "../" + m[:path] + "/measure.rb")

    # infer snake case
    measure_class = "#{m[:name]}".split('_').collect(&:capitalize).join

    if measure_class.include? "GatherSpaceTypeRatioData"
      measure_class = "GatherSpaceTypeRatioData" # this is needed to get class correctly
    end

    # create an instance of the measure
    measure = eval(measure_class).new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # get argument values
    arg_value = []
    m[:arguments].each do |a|
      #measure.argument_value(a[:name], a[:value])
      arg_value << a[:value]
    end
    #m[:variables].each do |v|
    #  measure.make_variable(v[:name], v[:desc], v[:value])
    #end

    # set argument values
    count = -1
    arguments.each do |arg|
      temp_arg_var = arguments[count += 1].clone
      temp_arg_var.setValue(arg_value[count]) #assert(temp_arg_var.setValue(arg_value[count]))
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    #assert_equal("Success", result.value.valueName)

  end

  #save the model
  save_string = "#{building_type}_#{template}_#{climate_zone}"
  output_file_path = OpenStudio::Path.new("seeds/#{save_string}.osm")
  model.save(output_file_path,true)

end

desc 'create seed models'
namespace :make_seeds do

  #create_template(structure_id, building_type, year, system_type)
  task :run do

    # jobs to send
    hash = {}

    # pre 1980
    test_vintage = "1970"
    hash["1970_d_#{test_vintage}"] = ["AssistedLiving",test_vintage]
    hash["1970_e_#{test_vintage}"] = ["AutoRepair",test_vintage]
    hash["1970_f_#{test_vintage}"] = ["AutoSales",test_vintage]
    hash["1970_g_#{test_vintage}"] = ["Bank",test_vintage]
    hash["1970_h_#{test_vintage}"] = ["ChildCare",test_vintage]
    hash["1970_i_#{test_vintage}"] = ["FullServiceRestaurant",test_vintage]
    hash["1970_j_#{test_vintage}"] = ["GasStation",test_vintage]
    hash["1970_k_#{test_vintage}"] = ["Hospital",test_vintage]
    hash["1970_l_#{test_vintage}"] = ["Laboratory",test_vintage]
    hash["1970_ad_#{test_vintage}"] = ["LargeHotel",test_vintage]
    hash["1970_ac_#{test_vintage}"] = ["MidriseApartment",test_vintage]
    hash["1970_ae_#{test_vintage}"] = ["Office",test_vintage]
    hash["1970_a_#{test_vintage}"] = ["OfficeData",test_vintage]
    hash["1970_m_#{test_vintage}"] = ["Outpatient",test_vintage]
    hash["1970_p_#{test_vintage}"] = ["PrimarySchool",test_vintage]
    hash["1970_q_#{test_vintage}"] = ["QuickServiceRestaurant",test_vintage]
    hash["1970_n_#{test_vintage}"] = ["Retail",test_vintage]
    hash["1970_r_#{test_vintage}"] = ["SecondarySchool",test_vintage]
    hash["1970_b_#{test_vintage}"] = ["SingleMultiPlexRes",test_vintage]
    hash["1970_s_#{test_vintage}"] = ["SmallHotel",test_vintage]
    hash["1970_c_#{test_vintage}"] = ["StripMall",test_vintage]
    hash["1970_t_#{test_vintage}"] = ["SuperMarket",test_vintage]
    hash["1970_o_#{test_vintage}"] = ["Warehouse",test_vintage]

    # 1980-2004
    test_vintage = "1985"
    hash["1985_d_#{test_vintage}"] = ["AssistedLiving",test_vintage]
    hash["1985_e_#{test_vintage}"] = ["AutoRepair",test_vintage]
    hash["1985_f_#{test_vintage}"] = ["AutoSales",test_vintage]
    hash["1985_g_#{test_vintage}"] = ["Bank",test_vintage]
    hash["1985_h_#{test_vintage}"] = ["ChildCare",test_vintage]
    hash["1985_i_#{test_vintage}"] = ["FullServiceRestaurant",test_vintage]
    hash["1985_j_#{test_vintage}"] = ["GasStation",test_vintage]
    hash["1985_k_#{test_vintage}"] = ["Hospital",test_vintage]
    hash["1985_l_#{test_vintage}"] = ["Laboratory",test_vintage]
    hash["1985_ad_#{test_vintage}"] = ["LargeHotel",test_vintage]
    hash["1985_ac_#{test_vintage}"] = ["MidriseApartment",test_vintage]
    hash["1985_ae_#{test_vintage}"] = ["Office",test_vintage]
    hash["1985_a_#{test_vintage}"] = ["OfficeData",test_vintage]
    hash["1985_m_#{test_vintage}"] = ["Outpatient",test_vintage]
    hash["1985_p_#{test_vintage}"] = ["PrimarySchool",test_vintage]
    hash["1985_q_#{test_vintage}"] = ["QuickServiceRestaurant",test_vintage]
    hash["1985_n_#{test_vintage}"] = ["Retail",test_vintage]
    hash["1985_r_#{test_vintage}"] = ["SecondarySchool",test_vintage]
    hash["1985_b_#{test_vintage}"] = ["SingleMultiPlexRes",test_vintage]
    hash["1985_s_#{test_vintage}"] = ["SmallHotel",test_vintage]
    hash["1985_c_#{test_vintage}"] = ["StripMall",test_vintage]
    hash["1985_t_#{test_vintage}"] = ["SuperMarket",test_vintage]
    hash["1985_o_#{test_vintage}"] = ["Warehouse",test_vintage]

    # 2004
    test_vintage = "2008"
    hash["999999_d_#{test_vintage}"] = ["AssistedLiving",test_vintage]
    hash["999999_e_#{test_vintage}"] = ["AutoRepair",test_vintage]
    hash["999999_f_#{test_vintage}"] = ["AutoSales",test_vintage]
    hash["999999_g_#{test_vintage}"] = ["Bank",test_vintage]
    hash["999999_h_#{test_vintage}"] = ["ChildCare",test_vintage]
    hash["999999_i_#{test_vintage}"] = ["FullServiceRestaurant",test_vintage]
    hash["999999_j_#{test_vintage}"] = ["GasStation",test_vintage]
    hash["999999_k_#{test_vintage}"] = ["Hospital",test_vintage]
    hash["999999_l_#{test_vintage}"] = ["Laboratory",test_vintage]
    hash["999999_ad_#{test_vintage}"] = ["LargeHotel",test_vintage]
    hash["999999_ac_#{test_vintage}"] = ["MidriseApartment",test_vintage]
    hash["999999_ae_#{test_vintage}"] = ["Office",test_vintage]
    hash["999999_a_#{test_vintage}"] = ["OfficeData",test_vintage]
    hash["999999_m_#{test_vintage}"] = ["Outpatient",test_vintage]
    hash["999999_p_#{test_vintage}"] = ["PrimarySchool",test_vintage]
    hash["999999_q_#{test_vintage}"] = ["QuickServiceRestaurant",test_vintage]
    hash["999999_n_#{test_vintage}"] = ["Retail",test_vintage]
    hash["999999_r_#{test_vintage}"] = ["SecondarySchool",test_vintage]
    hash["999999_b_#{test_vintage}"] = ["SingleMultiPlexRes",test_vintage]
    hash["999999_s_#{test_vintage}"] = ["SmallHotel",test_vintage]
    hash["999999_c_#{test_vintage}"] = ["StripMall",test_vintage]
    hash["999999_t_#{test_vintage}"] = ["SuperMarket",test_vintage]
    hash["999999_o_#{test_vintage}"] = ["Warehouse",test_vintage]

    hash.each do |k,v|
      analytic_record = k.split("_")[0]
      hash_building_type = v[0]
      hash_year = v[1]
      create_template(analytic_record, hash_building_type, hash_year)
    end

  end

end