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

require 'logger'

#start the measure
class BarAspectRatioStudySlicedBySpaceTypeRetail < OpenStudio::Ruleset::ModelUserScript

  def initialize(*args)
    super

    @logger = Logger.new 'BarAspectRatioStudySlicedBySpaceTypeRetail.log'
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "BarAspectRatioStudySlicedBySpaceTypeRetail"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for total floor area
    total_bldg_area_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("total_bldg_area_ip", true)
    total_bldg_area_ip.setDisplayName("Total Building Floor Area (ft^2).")
    total_bldg_area_ip.setDefaultValue(10000.0)
    args << total_bldg_area_ip

    #make an argument for aspect ratio
    ns_to_ew_ratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ns_to_ew_ratio", true)
    ns_to_ew_ratio.setDisplayName("Ratio of North/South Facade Length Relative to East/West Facade Length.")
    ns_to_ew_ratio.setDefaultValue(2.0)
    args << ns_to_ew_ratio

    #make an argument for number of floors
    num_floors = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("num_floors", true)
    num_floors.setDisplayName("Number of Floors.")
    num_floors.setDefaultValue(2)
    args << num_floors

    #make an argument for floor height
    floor_to_floor_height_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("floor_to_floor_height_ip", true)
    floor_to_floor_height_ip.setDisplayName("Floor to Floor Height (ft).")
    floor_to_floor_height_ip.setDefaultValue(10.0)
    args << floor_to_floor_height_ip

    #make an argument for retail
    @logger.info "current args are #{args}"
    @logger.info "added retail argument"
    retail = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("retail", true)
    retail.setDisplayName("Fraction of Floor Area for Retail Space Type.")
    args << retail

    #make an argument for point_of_sale
    point_of_sale = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("point_of_sale", true)
    point_of_sale.setDisplayName("Fraction of Floor Area for Point of Sale Space Type.")
    args << point_of_sale

    #make an argument for entry
    entry = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("entry", true)
    entry.setDisplayName("Fraction of Floor Area for Entry Space Type.")
    args << entry

    #make an argument for back_space
    back_space = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("back_space", true)
    back_space.setDisplayName("Fraction of Floor Area for BackSpace Space Type.")
    args << back_space

    @logger.info "last args are #{args}"

    return args
  end

  #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    total_bldg_area_ip = runner.getDoubleArgumentValue("total_bldg_area_ip", user_arguments)
    ns_to_ew_ratio = runner.getDoubleArgumentValue("ns_to_ew_ratio", user_arguments)
    num_floors = runner.getIntegerArgumentValue("num_floors", user_arguments)
    floor_to_floor_height_ip = runner.getDoubleArgumentValue("floor_to_floor_height_ip", user_arguments)
    retail = runner.getDoubleArgumentValue("retail", user_arguments) # if we have a catch all space type this will be it
    point_of_sale = runner.getDoubleArgumentValue("point_of_sale", user_arguments)
    entry = runner.getDoubleArgumentValue("entry", user_arguments)
    back_space = runner.getDoubleArgumentValue("back_space", user_arguments)

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
    fractionalValues = [retail, point_of_sale, entry, back_space]
    fractionalValues.each do |value|
      if value < 0 or value > 1
        runner.registerError("Enter a value between 0 and 1 for fractional values.")
      end
    end

    #calculate needed variables
    total_bldg_area_si = OpenStudio::convert(total_bldg_area_ip, "ft^2", "m^2").get
    footprint_ip = total_bldg_area_ip/num_floors
    footprint_si = OpenStudio::convert(footprint_ip, "ft^2", "m^2").get
    floor_to_floor_height = OpenStudio::convert(floor_to_floor_height_ip, "ft", "m").get

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

      if standardsInfo[spaceType][1] == "Retail"
        spaceTypeHash[spaceType] = retail*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += retail
      elsif standardsInfo[spaceType][1] == "Point_of_Sale"
        spaceTypeHash[spaceType] = point_of_sale*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += point_of_sale
      elsif standardsInfo[spaceType][1] == "Entry"
        spaceTypeHash[spaceType] = entry*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += entry
      elsif standardsInfo[spaceType][1] == "Back_Space"
        spaceTypeHash[spaceType] = back_space*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += back_space
      else
        runner.registerWarning("#{spaceType.name} doesn't map to an expected standards space type.")
      end

    end # end of model.getSpaceTypes.each do

    if hashValues != 1.0
      runner.registerWarning("Fractional hash values do not add up to one. Resulting geometry may not have expected area.")
    end

    # see which path to take
    midFloorMultiplier = 1 # show as 1 even on 1 and 2 story buildings where there is no mid floor, in addition to 3 story building
    if num_floors > 3
      # use floor multiplier version. Set mid floor multiplier, use adibatic floors/ceilings and set constructions, raise up building
      midFloorMultiplier = num_floors - 2
    end

    # run method to create envelope
    bar_AspectRatio = OsLib_Cofee.createBar(model, spaceTypeHash, length, width, total_bldg_area_si, num_floors, midFloorMultiplier, 0.0, 0.0, length, width, 0.0, floor_to_floor_height*num_floors, true)

    puts "building area #{model.getBuilding.floorArea}"

    #reporting final condition of model
    finishing_spaces = model.getSpaces
    runner.registerFinalCondition("The building finished with #{finishing_spaces.size} spaces.")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
BarAspectRatioStudySlicedBySpaceTypeRetail.new.registerWithApplication
