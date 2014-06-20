require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class LPDtoLamps_Test < Test::Unit::TestCase

  
  def test_LPDtoLamps
     
    # create an instance of the measure
    measure = LPDtoLamps.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    #path = OpenStudio::Path.new(File.dirname(__FILE__) + "/RetailModelZeroSample.osm")
    #path = OpenStudio::Path.new(File.dirname(__FILE__) + "/RetailAndOfficeBreakRoom.osm")
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/AnalysisTestFile.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
       
    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 1)
    #assert(result.info.size == 2)

    #save the model
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osm")
    model.save(output_file_path,true)

  end  

end
