require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class SetRunPeriod_Test < Test::Unit::TestCase

  
  def test_SetRunPeriod
     
    # create an instance of the measure
    measure = SetRunPeriod.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # make an empty model
    model = OpenStudio::Model::Model.new
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(4, arguments.size)
    assert_equal("begin_month", arguments[0].name)
    assert_equal("begin_day", arguments[1].name)
    assert_equal("end_month", arguments[2].name)
    assert_equal("end_day", arguments[3].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    begin_month = arguments[0].clone
    assert(begin_month.setValue(2))
    argument_map["begin_month"] = begin_month

    begin_day = arguments[1].clone
    assert(begin_day.setValue(3))
    argument_map["begin_day"] = begin_day

    end_month = arguments[2].clone
    assert(end_month.setValue(11))
    argument_map["end_month"] = end_month

    end_day = arguments[3].clone
    assert(end_day.setValue(25))
    argument_map["end_day"] = end_day

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 1)
    #assert(result.info.size == 2)
    
  end  

end
