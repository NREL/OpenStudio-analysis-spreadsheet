require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class BarAspectRatioStudySlicedBySpaceTypeOffice_Test < Test::Unit::TestCase

  
  def test_BarAspectRatioStudySlicedBySpaceTypeOffice
     
    # create an instance of the measure
    measure = BarAspectRatioStudySlicedBySpaceTypeOffice.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/OfficeWizard.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    count = -1
    #assert_equal(7, arguments.size)
    assert_equal("total_bldg_area_ip", arguments[count += 1].name)
    assert_equal("ns_to_ew_ratio", arguments[count += 1].name)
    assert_equal("num_floors", arguments[count += 1].name)
    assert_equal("floor_to_floor_height_ip", arguments[count += 1].name)
    assert_equal("openOffice", arguments[count += 1].name)
    assert_equal("closedOffice", arguments[count += 1].name)
    assert_equal("breakRoom", arguments[count += 1].name)
    assert_equal("conference", arguments[count += 1].name)
    assert_equal("corridor", arguments[count += 1].name)
    assert_equal("elecMechRoom", arguments[count += 1].name)
    assert_equal("iT_Room", arguments[count += 1].name)
    assert_equal("lobby", arguments[count += 1].name)
    assert_equal("printRoom", arguments[count += 1].name)
    assert_equal("restroom", arguments[count += 1].name)
    assert_equal("stair", arguments[count += 1].name)
    assert_equal("storage", arguments[count += 1].name)
    assert_equal("vending", arguments[count += 1].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    total_bldg_area_ip = arguments[count += 1].clone
    assert(total_bldg_area_ip.setValue(50000.0))
    argument_map["total_bldg_area_ip"] = total_bldg_area_ip

    ns_to_ew_ratio = arguments[count += 1].clone
    assert(ns_to_ew_ratio.setValue(2.0))
    argument_map["ns_to_ew_ratio"] = ns_to_ew_ratio

    num_floors = arguments[count += 1].clone
    assert(num_floors.setValue(5))
    argument_map["num_floors"] = num_floors

    floor_to_floor_height_ip = arguments[count += 1].clone
    assert(floor_to_floor_height_ip.setValue(10.0))
    argument_map["floor_to_floor_height_ip"] = floor_to_floor_height_ip

    openOffice = arguments[count += 1].clone
    assert(openOffice.setValue(0.25))
    argument_map["openOffice"] = openOffice

    closedOffice = arguments[count += 1].clone
    assert(closedOffice.setValue(0.20))
    argument_map["closedOffice"] = closedOffice

    breakRoom = arguments[count += 1].clone
    assert(breakRoom.setValue(0.05))
    argument_map["breakRoom"] = breakRoom

    conference = arguments[count += 1].clone
    assert(conference.setValue(0.05))
    argument_map["conference"] = conference

    corridor = arguments[count += 1].clone
    assert(corridor.setValue(0.05))
    argument_map["corridor"] = corridor

    elecMechRoom = arguments[count += 1].clone
    assert(elecMechRoom.setValue(0.05))
    argument_map["elecMechRoom"] = elecMechRoom

    iT_Room = arguments[count += 1].clone
    assert(iT_Room.setValue(0.05))
    argument_map["iT_Room"] = iT_Room

    lobby = arguments[count += 1].clone
    assert(lobby.setValue(0.05))
    argument_map["lobby"] = lobby

    printRoom = arguments[count += 1].clone
    assert(printRoom.setValue(0.05))
    argument_map["printRoom"] = printRoom

    restroom = arguments[count += 1].clone
    assert(restroom.setValue(0.05))
    argument_map["restroom"] = restroom

    stair = arguments[count += 1].clone
    assert(stair.setValue(0.05))
    argument_map["stair"] = stair

    storage = arguments[count += 1].clone
    assert(storage.setValue(0.05))
    argument_map["storage"] = storage

    vending = arguments[count += 1].clone
    assert(vending.setValue(0.05))
    argument_map["vending"] = vending

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    assert(result.warnings.size == 2)
    assert(result.info.size == 0)

    #save the model
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osm")
    model.save(output_file_path,true)
    
  end

end
