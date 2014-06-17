#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_Geometry"
require "#{File.dirname(__FILE__)}/resources/OsLib_HelperMethods"
require "#{File.dirname(__FILE__)}/resources/OsLib_Cofee"

#start the measure
class BarAspectRatioStudySlicedBySpaceTypeOffice < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "BarAspectRatioStudySlicedBySpaceTypeOffice"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for total floor area
    total_bldg_area_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("total_bldg_area_ip",true)
    total_bldg_area_ip.setDisplayName("Total Building Floor Area (ft^2).")
    total_bldg_area_ip.setDefaultValue(10000.0)
    args << total_bldg_area_ip

    #make an argument for aspect ratio
    ns_to_ew_ratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ns_to_ew_ratio",true)
    ns_to_ew_ratio.setDisplayName("Ratio of North/South Facade Length Relative to East/West Facade Length.")
    ns_to_ew_ratio.setDefaultValue(2.0)
    args << ns_to_ew_ratio

    #make an argument for number of floors
    num_floors = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("num_floors",true)
    num_floors.setDisplayName("Number of Floors.")
    num_floors.setDefaultValue(2)
    args << num_floors

    #make an argument for floor height
    floor_to_floor_height_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("floor_to_floor_height_ip",true)
    floor_to_floor_height_ip.setDisplayName("Floor to Floor Height (ft).")
    floor_to_floor_height_ip.setDefaultValue(10.0)
    args << floor_to_floor_height_ip

    #make an argument for openOffice
    openOffice = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("openOffice",true)
    openOffice.setDisplayName("Fraction of Floor Area for Open Office Space Type.")
    args << openOffice

    #make an argument for closedOffice
    closedOffice = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("closedOffice",true)
    closedOffice.setDisplayName("Fraction of Floor Area for Closed Office Space Type.")
    args << closedOffice

    #make an argument for breakRoom
    breakRoom = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("breakRoom",true)
    breakRoom.setDisplayName("Fraction of Floor Area for Break Room Space Type.")
    args << breakRoom

    #make an argument for conference
    conference = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("conference",true)
    conference.setDisplayName("Fraction of Floor Area for Conference Space Type.")
    args << conference

    #make an argument for corridor
    corridor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("corridor",true)
    corridor.setDisplayName("Fraction of Floor Area for Corridor Space Type.")
    args << corridor

    #make an argument for elecMechRoom
    elecMechRoom = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("elecMechRoom",true)
    elecMechRoom.setDisplayName("Fraction of Floor Area for Elec/MechRoom Space Type.")
    args << elecMechRoom

    #make an argument for iT_Room
    iT_Room = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("iT_Room",true)
    iT_Room.setDisplayName("Fraction of Floor Area for IT Room Space Type.")
    args << iT_Room

    #make an argument for lobby
    lobby = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("lobby",true)
    lobby.setDisplayName("Fraction of Floor Area for Lobby Space Type.")
    args << lobby

    #make an argument for printRoom
    printRoom = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("printRoom",true)
    printRoom.setDisplayName("Fraction of Floor Area for Print Room Space Type.")
    args << printRoom

    #make an argument for restroom
    restroom = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("restroom",true)
    restroom.setDisplayName("Fraction of Floor Area for Restroom Space Type.")
    args << restroom

    #make an argument for stair
    stair = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("stair",true)
    stair.setDisplayName("Fraction of Floor Area for Stair Space Type.")
    args << stair

    #make an argument for storage
    storage = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("storage",true)
    storage.setDisplayName("Fraction of Floor Area for Apartment Space Type.")
    args << storage

    #make an argument for vending
    vending = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("vending",true)
    vending.setDisplayName("Fraction of Floor Area for Vending Space Type.")
    args << vending

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    total_bldg_area_ip = runner.getDoubleArgumentValue("total_bldg_area_ip",user_arguments)
    ns_to_ew_ratio = runner.getDoubleArgumentValue("ns_to_ew_ratio",user_arguments)
    num_floors = runner.getIntegerArgumentValue("num_floors",user_arguments)
    floor_to_floor_height_ip = runner.getDoubleArgumentValue("floor_to_floor_height_ip",user_arguments)
    openOffice = runner.getDoubleArgumentValue("openOffice",user_arguments) 
    closedOffice = runner.getDoubleArgumentValue("closedOffice",user_arguments) 
    breakRoom = runner.getDoubleArgumentValue("breakRoom",user_arguments)
    conference = runner.getDoubleArgumentValue("breakRoom",user_arguments)
    corridor = runner.getDoubleArgumentValue("corridor",user_arguments) 
    elecMechRoom = runner.getDoubleArgumentValue("elecMechRoom",user_arguments) 
    iT_Room = runner.getDoubleArgumentValue("iT_Room",user_arguments)
    lobby = runner.getDoubleArgumentValue("lobby",user_arguments) 
    printRoom = runner.getDoubleArgumentValue("printRoom",user_arguments)
    restroom = runner.getDoubleArgumentValue("restroom",user_arguments)
    stair = runner.getDoubleArgumentValue("stair",user_arguments)
    storage = runner.getDoubleArgumentValue("storage",user_arguments)
    vending = runner.getDoubleArgumentValue("vending",user_arguments)

    #test for positive inputs
    if not total_bldg_area_ip > 0
      runner.registerError("Enter a total building area greater than 0.")
    end
    if not ns_to_ew_ratio > 0
      runner.registerError("Enter ratio grater than 0.") # todo - consider making this greater than 1 so that the relative n/s side is bigger than e/w
    end
    if not num_floors > 0
      runner.registerError("Enter a number of stories 1 or greater.")
    end
    if not floor_to_floor_height_ip > 0
      runner.registerError("Enter a positive floor height.")
    end
    fractionalValues = [openOffice,closedOffice,breakRoom,conference,corridor,elecMechRoom,iT_Room,lobby,printRoom,restroom,stair,storage,vending]
    fractionalValues.each do |value|
      if value < 0 or value > 1
        runner.registerError("Enter a value between 0 and 1 for fractional values.")
      end
    end

    #calculate needed variables
    total_bldg_area_si = OpenStudio::convert(total_bldg_area_ip,"ft^2","m^2").get
    footprint_ip = total_bldg_area_ip/num_floors
    footprint_si = OpenStudio::convert(footprint_ip,"ft^2","m^2").get
    floor_to_floor_height =  OpenStudio::convert(floor_to_floor_height_ip,"ft","m").get

    #variables from original rectangle script not exposed in this measure
    width = Math.sqrt(footprint_si/ns_to_ew_ratio)
    length = footprint_si/width

    #reporting initial condition of model
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("The building started with #{starting_spaces.size} spaces.")

    # sum of hash values
    hashValues = 0

    spaceTypeHash = Hash.new
    model.getSpaceTypes.each do |spaceType|

      # get standards space type
      standardsInfo = OsLib_HelperMethods.getSpaceTypeStandardsInformation([spaceType])

      if standardsInfo[spaceType][1] == "OpenOffice"
        spaceTypeHash[spaceType] = openOffice*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += openOffice
      elsif standardsInfo[spaceType][1] == "ClosedOffice"
        spaceTypeHash[spaceType] = closedOffice*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += closedOffice
      elsif standardsInfo[spaceType][1] == "BreakRoom"
        spaceTypeHash[spaceType] = breakRoom*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += breakRoom
      elsif standardsInfo[spaceType][1] == "Conference"
        spaceTypeHash[spaceType] = conference*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += conference
      elsif standardsInfo[spaceType][1] == "Corridor"
        spaceTypeHash[spaceType] = corridor*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += corridor
      elsif standardsInfo[spaceType][1] == "Elec/MechRoom"
        spaceTypeHash[spaceType] = elecMechRoom*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += elecMechRoom
      elsif standardsInfo[spaceType][1] == "Corridor"
        spaceTypeHash[spaceType] = corridor*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += corridor
      elsif standardsInfo[spaceType][1] == "IT_Room"
        spaceTypeHash[spaceType] = iT_Room*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += iT_Room
      elsif standardsInfo[spaceType][1] == "Lobby"
        spaceTypeHash[spaceType] = lobby*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += lobby
      elsif standardsInfo[spaceType][1] == "PrintRoom"
        spaceTypeHash[spaceType] = printRoom*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += printRoom
      elsif standardsInfo[spaceType][1] == "Restroom"
        spaceTypeHash[spaceType] = restroom*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += restroom
      elsif standardsInfo[spaceType][1] == "Stair"
        spaceTypeHash[spaceType] = stair*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += stair
      elsif standardsInfo[spaceType][1] == "Storage"
        spaceTypeHash[spaceType] = storage*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += storage
      elsif standardsInfo[spaceType][1] == "Vending"
        spaceTypeHash[spaceType] = vending*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += vending
      else
        runner.registerWarning("#{spaceType.name} doesn't map to an expected standards space type.")
      end

    end # end of model.getSpaceTypes.each do

    if hashValues > 1.00001 # 1.0 for some reason I got odd numbers like 1.0000000000000002 which failed this
      runner.registerWarning("Fractional hash values do not add up to 1.0. Resulting geometry may not have expected area.")
    end

    # see which path to take
    midFloorMultiplier = 1 # show as 1 even on 1 and 2 story buildings where there is no mid floor, in addition to 3 story building
    if num_floors > 3
      # use floor multiplier version. Set mid floor multiplier, use adibatic floors/ceilings and set constructions, raise up building
      midFloorMultiplier = num_floors - 2
    end

    # run method to create envelope
    bar_AspectRatio = OsLib_Cofee.createBar(model,spaceTypeHash,length,width,total_bldg_area_si,num_floors,midFloorMultiplier,0.0,0.0,length,width,0.0,floor_to_floor_height*num_floors,true)

    puts "building area #{model.getBuilding.floorArea}"

    #reporting final condition of model
    finishing_spaces = model.getSpaces
    runner.registerFinalCondition("The building finished with #{finishing_spaces.size} spaces.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
BarAspectRatioStudySlicedBySpaceTypeOffice.new.registerWithApplication