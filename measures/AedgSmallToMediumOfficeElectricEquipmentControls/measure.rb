#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"
require "#{File.dirname(__FILE__)}/resources/OsLib_HelperMethods"
require "#{File.dirname(__FILE__)}/resources/OsLib_LightingAndEquipment"
require "#{File.dirname(__FILE__)}/resources/OsLib_Schedules"

#start the measure
class AedgSmallToMediumOfficeElectricEquipmentControls < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AedgSmallToMediumOfficeElectricEquipmentControls"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for material and installation cost
    costTotal = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("costTotal",true)
    costTotal.setDisplayName("Total cost for all Electric Equipment Controls in the Building ($).")
    costTotal.setDefaultValue(0.0)
    args << costTotal

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
    costTotal = runner.getDoubleArgumentValue("costTotal",user_arguments)

    # make hash of argument display name and value  #todo - would be better to get these directly from the display name
    argumentHash = {
        "Total cost for all Electric Equipment Controls in the Building" => costTotal
    }
    #check arguments for reasonableness (runner, min, max, argumentArray)
    checkDoubleArguments = OsLib_HelperMethods.checkDoubleArguments(runner,0,nil,argumentHash)
    if not checkDoubleArguments
      return false
    end

    # create not applicable flag if building doesn't have any equipment.
    if model.getBuilding.electricEquipmentPower == 0
      runner.registerAsNotApplicable("The model does not appear to have electric equipment, the model will not be altered.")
      return true
    end

    #prepare rule hash
    rules = [] #target, space type, LPD_ip

    # currently only target is lower energy, but setup hash this way so could add baseline in future
    # climate zone doesn't impact values for LPD in AEDG

    # get the initial range of equipment schedule values in the building for initial condition
    electricEquipmentHash = {} # key = existSch, value = newSch
    affectedSpaceTypeArray = []

    existMin = []
    existMax = []
    newMin = []
    newMax = []

    # make array of space and space types to loop through
    spacesAndSpaceTypes = []
    model.getSpaceTypes.each do |spaceType|
      next if spaceType.spaces.size == 0
      standardsInfo = OsLib_HelperMethods.getSpaceTypeStandardsInformation([spaceType])
      spacesAndSpaceTypes << spaceType
      affectedSpaceTypeArray << spaceType
    end
    model.getSpaces.each do |space|
      next if space.spaceType.empty?
      spaceType = space.spaceType.get
      standardsInfo = OsLib_HelperMethods.getSpaceTypeStandardsInformation([spaceType])
      spacesAndSpaceTypes << space
    end

    # loop through used space types and spaces
    spacesAndSpaceTypes.each do |object|

      # only alter space types that are used
      if not object.to_SpaceType.empty?
        next if not object.to_SpaceType.get.spaces.size > 0
      end

      # get standards
      if object.to_SpaceType.empty?
        if not object.spaceType.empty?
          spaceType = object.spaceType.get
          standardsInfo = OsLib_HelperMethods.getSpaceTypeStandardsInformation([spaceType])
        end
      else
        standardsInfo = OsLib_HelperMethods.getSpaceTypeStandardsInformation([object])
      end

      electricEquipment = object.electricEquipment
      electricEquipment.each do |equipment|
        # get schedule
        if not equipment.schedule.empty?
          existSch = equipment.schedule.get

          # can't process if not ruleset
          if existSch.to_ScheduleRuleset.empty?
            runner.registerWarning("#{existSch.name} isn't a ruleset schedule. It can't be altered by this measure.")
            next
          end

          # update schedule
          if electricEquipmentHash.has_key?(existSch)
            # connect equipment to new schedule
            equipment.setSchedule(electricEquipmentHash[existSch])
          else

            # make new schedule
            newSchedule = existSch.clone(model).to_ScheduleRuleset.get
            newSchedule.setName("#{existSch.name} - Controls Reduction")

            # connect to equipments
            equipment.setSchedule(newSchedule)

            # edit schedule
            valueTestDouble = 0.5 # if the profile value is lower than this value then uses passDouble for value adjustment, otherwise it uses failDouble as value adjustment
            passDouble = -0.1
            failDouble = -0.05
            floorDouble = 0.1 #values below this level will be left alone, and adjusted values will not be lowered beyond this.
            modificationType = "Sum" # double will be added to current value (in this case passing a negative value to lower it)
            OsLib_Schedules.conditionalScheduleValueAdjust(model,newSchedule,valueTestDouble,passDouble,failDouble, floorDouble,modificationType)

            # add info to hash
            electricEquipmentHash[existSch] = newSchedule

            # get sch values from new and old schedules to use in initial and final condition
            existMinMax = OsLib_Schedules.getMinMaxAnnualProfileValue(model, existSch.to_ScheduleRuleset.get)
            existMin <<  existMinMax["min"]
            existMax <<  existMinMax["max"]
            newMinMax = OsLib_Schedules.getMinMaxAnnualProfileValue(model, newSchedule)
            newMin <<  newMinMax["min"]
            newMax <<  newMinMax["max"]
          end

        else
          runner.registerWarning("Can't find schedule for #{equipment.name} in #{object.name}. Won't attempt to create schedule for it.")
        end
      end
    end  # end of spacesAndSpaceTypes each do

    affectedSpaceTypeArray.each do |spaceType|
      runner.registerInfo("Adjusting equipment schedules for #{spaceType.name}.")
    end

    #reporting initial condition of model
    runner.registerInitialCondition("Fractional schedule values for electric equipment in the initial model range from #{OpenStudio::toNeatString(existMin.min,2,true)} to #{OpenStudio::toNeatString(existMax.max,2,true)}.")

    #get building to add cost to
    building = model.getBuilding

    # global variables for costs
    expected_life = 25
    years_until_costs_start = 0

    # add cost to building
    if costTotal > 0
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Electric Equipment Controls", building, costTotal, "CostPerEach", "Construction", expected_life, years_until_costs_start)
      lcc_mat_TotalCost = lcc_mat.get.totalCost
    else
      lcc_mat_TotalCost = 0
    end

    # populate AEDG tip keys
    aedgTips = ["PL03"]

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips("SmMdOff",aedgTips.uniq.sort,runner)
    if not aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    #reporting final condition of model
    if lcc_mat_TotalCost > 0
      runner.registerFinalCondition("Fractional schedule values for electric equipment in the final model range from #{OpenStudio::toNeatString(newMin.min,2,true)} to #{OpenStudio::toNeatString(newMax.max,2,true)}. The cost for these control improvements is $#{OpenStudio::toNeatString(lcc_mat_TotalCost,2,true)}. #{aedgTipsLong}")
    else
      runner.registerFinalCondition("Fractional schedule values for electric equipment in the final model range from #{OpenStudio::toNeatString(newMin.min,2,true)} to #{OpenStudio::toNeatString(newMax.max,2,true)}. #{aedgTipsLong}")
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AedgSmallToMediumOfficeElectricEquipmentControls.new.registerWithApplication