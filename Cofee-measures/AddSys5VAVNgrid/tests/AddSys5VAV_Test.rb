require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class AddSys5PSVAVNgrid_Test < Test::Unit::TestCase

  
  def test_AddSys5PSVAVNgrid
     
    # create an instance of the measure
    measure = AddSys5PSVAVNgrid.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # make model
    model = OpenStudio::Model::exampleModel
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(2, arguments.size)
    assert_equal("heating_efficiency", arguments[0].name)
    assert_equal("cooling_cop", arguments[1].name)
       
    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    heating_efficiency = arguments[0].clone
    assert(heating_efficiency.setValue(0.8))
    argument_map["heating_efficiency"] = heating_efficiency
    cooling_cop = arguments[1].clone
    assert(cooling_cop.setValue(3))
    argument_map["cooling_cop"] = cooling_cop
    
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    
  end  

end
