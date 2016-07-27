require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'minitest/autorun'

class IncreaseRValueOfInsulationForConstructionByASpecifiedPercentage_Test < MiniTest::Unit::TestCase

  # def setup
  # end

  # def teardown
  # end

  def test_IncreaseRValueOfInsulationForConstructionByASpecifiedPercentage_NewConstruction

    # create an instance of the measure
    measure = IncreaseRValueOfInsulationForConstructionByASpecifiedPercentage.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/EnvelopeAndLoadTestModel_01.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    # set all argument values

    count = -1

    construction = arguments[count += 1].clone
    assert(construction.setValue("ASHRAE_189.1-2009_ExtWall_Mass_ClimateZone_alt-res 5"))
    argument_map["construction"] = construction

    r_value_prct_inc = arguments[count += 1].clone
    assert(r_value_prct_inc.setValue(30.0))
    argument_map["r_value_prct_inc"] = r_value_prct_inc

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result) #this displays the output when you run the test
    assert(result.value.valueName == "Success")
    #assert(result.info.size == 2)
    #assert(result.warnings.size == 0)

  end

end