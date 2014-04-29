require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class BarAspectRatioStudy_Test < Test::Unit::TestCase

  
  def test_BarAspectRatioStudy
     
    # create an instance of the measure
    measure = BarAspectRatioStudy.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # make an empty model
    model = OpenStudio::Model::Model.new
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal("total_bldg_area_ip", arguments[0].name)
    assert_equal("ns_to_ew_ratio", arguments[1].name)
    assert_equal("num_floors", arguments[2].name)
    assert_equal("floor_to_floor_height_ip", arguments[3].name)
    assert_equal("surface_matching", arguments[4].name)
    assert_equal("make_zones", arguments[5].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    total_bldg_area_ip = arguments[0].clone
    assert(total_bldg_area_ip.setValue(10000.0))
    argument_map["total_bldg_area_ip"] = total_bldg_area_ip

    ns_to_ew_ratio = arguments[1].clone
    assert(ns_to_ew_ratio.setValue(2.0))
    argument_map["ns_to_ew_ratio"] = ns_to_ew_ratio

    num_floors = arguments[2].clone
    assert(num_floors.setValue(2))
    argument_map["num_floors"] = num_floors

    floor_to_floor_height_ip = arguments[3].clone
    assert(floor_to_floor_height_ip.setValue(10.0))
    argument_map["floor_to_floor_height_ip"] = floor_to_floor_height_ip

    surface_matching = arguments[4].clone
    assert(surface_matching.setValue(true))
    argument_map["surface_matching"] = surface_matching

    make_zones = arguments[5].clone
    assert(make_zones.setValue(true))
    argument_map["make_zones"] = make_zones

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    assert(result.warnings.size == 0)
    assert(result.info.size == 0)

    #save the model
    output_file_path = OpenStudio::Path.new('C:\SVN_Utilities\OpenStudio\measures\test.osm')
    model.save(output_file_path,true)
    
  end

  def test_BarAspectRatioStudy_small

    # create an instance of the measure
    measure = BarAspectRatioStudy.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    total_bldg_area_ip = arguments[0].clone
    assert(total_bldg_area_ip.setValue(100.0))
    argument_map["total_bldg_area_ip"] = total_bldg_area_ip

    ns_to_ew_ratio = arguments[1].clone
    assert(ns_to_ew_ratio.setValue(0.5))
    argument_map["ns_to_ew_ratio"] = ns_to_ew_ratio

    num_floors = arguments[2].clone
    assert(num_floors.setValue(2))
    argument_map["num_floors"] = num_floors

    floor_to_floor_height_ip = arguments[3].clone
    assert(floor_to_floor_height_ip.setValue(10.0))
    argument_map["floor_to_floor_height_ip"] = floor_to_floor_height_ip

    surface_matching = arguments[4].clone
    assert(surface_matching.setValue(true))
    argument_map["surface_matching"] = surface_matching

    make_zones = arguments[5].clone
    assert(make_zones.setValue(true))
    argument_map["make_zones"] = make_zones

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    assert(result.warnings.size == 1)
    assert(result.info.size == 0)

  end

end
