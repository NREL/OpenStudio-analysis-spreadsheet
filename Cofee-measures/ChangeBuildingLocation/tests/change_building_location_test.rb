require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'test/unit'

require 'fileutils'
require_relative '../measure.rb'

class ChangeBuildingLocation_Test < Test::Unit::TestCase
  def test_weather_file
    test_out_file = File.join(File.dirname(__FILE__), 'test_out.osm')
    FileUtils.rm_f test_out_file if File.exist? test_out_file

    #test_new_weather_file = 'another_weather_file.epw'
    test_new_weather_file = 'USA_MA_Boston-Logan.Intl.AP.725090_TMY3.epw'

    # create an instance of the measure
    measure = ChangeBuildingLocation.new
    measure.weather_directory = File.dirname(__FILE__)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = File.join(File.dirname(__FILE__), "test.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # convert this to measure attributes
    if model.weatherFile.empty?
      puts "No weather file in current model"
    else
      puts "Current weather file is #{model.weatherFile}"# unless model.weatherFile.empty?
    end

    arguments = measure.arguments(model)
    assert_equal(1, arguments.size)

    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1
    arg = arguments[count += 1].clone
    assert(arg.setValue(test_new_weather_file))
    argument_map["weather_file_name"] = arg

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    assert(result.warnings.size == 0)
    assert(result.info.size == 0)

    puts "Final weather file is #{model.weatherFile.get}" unless model.weatherFile.empty?
    puts "Final site data is #{model.getSite}" if model.getSite
    puts "Final Water Mains Temp is #{model.getSiteWaterMainsTemperature}" if model.getSiteWaterMainsTemperature
    model.save(test_out_file)

    assert(File.basename(model.weatherFile.get.path.get.to_s) == test_new_weather_file)
    if test_new_weather_file =~ /Boston/
      assert(model.getSite.latitude == 42.37)
      assert(model.getSite.longitude == -71.02)
    else
      assert(model.getSite.latitude == 45)
      assert(model.getSite.longitude == -45)
    end
  end
end
