require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class IncreaseInsulationRValueForExteriorWallsByPercentage_Test < Test::Unit::TestCase

  # def setup
  # end

  # def teardown
  # end

  def test_IncreaseInsulationRValueForExteriorWallsByPercentage_NewConstruction

    # create an instance of the measure
    measure = IncreaseInsulationRValueForExteriorWallsByPercentage.new

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

    r_value = arguments[count += 1].clone
    assert(r_value.setValue(30.0))
    argument_map["r_value"] = r_value

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result) #this displays the output when you run the test
    assert(result.value.valueName == "Success")
    #assert(result.info.size == 2)
    #assert(result.warnings.size == 0)

  end

end