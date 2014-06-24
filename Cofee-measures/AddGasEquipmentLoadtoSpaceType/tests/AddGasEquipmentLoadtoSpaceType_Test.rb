require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class AddGasEquipmentLoadtoSpaceType_Test < Test::Unit::TestCase

  
  def test_AddGasEquipmentLoadtoSpaceType
     
    # create an instance of the measure
    measure = AddGasEquipmentLoadtoSpaceType.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # make a model with spaces
    model = OpenStudio::Model::exampleModel
    model.save("test.osm", true)
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(2, arguments.size)
    assert_equal("object", arguments[0].name)
    assert_equal("gas_per_space_floor_area", arguments[1].name)

    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    object = arguments[0].clone
    assert(object.setValue("*Entire Building*"))
    argument_map["object"] = object
    gas_per_space_floor_area = arguments[1].clone
    assert(gas_per_space_floor_area.setValue(1.0))
    argument_map["gas_per_space_floor_area"] = gas_per_space_floor_area    
    
    measure.run(model, runner, argument_map)
    result = runner.result
    assert(result.value.valueName == "Success")
    model.save("test2.osm", true)
  end  

end
