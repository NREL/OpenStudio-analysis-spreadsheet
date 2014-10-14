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
class AedgSmallToMediumOfficeElectricEquipment < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AedgSmallToMediumOfficeElectricEquipment"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for material and installation cost
    material_cost_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost_ip",true)
    material_cost_ip.setDisplayName("Material and Installation Costs for Electric Equipment per Floor Area ($/ft^2).")
    material_cost_ip.setDefaultValue(0.0)
    args << material_cost_ip

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
    material_cost_ip = runner.getDoubleArgumentValue("material_cost_ip",user_arguments)

    #prepare rule hash
    rules = [] #target, space type, EPD_ip

    # currently only target is lower energy, but setup hash this way so could add baseline in future
    # climate zone doesn't impact values for EPD in AEDG

    # populate rules hash # todo - find spreadsheet I setup to create multi-space type office and adapt that
    rules << ["LowEnergy","BreakRoom",4.46]
    rules << ["LowEnergy","ClosedOffice",0.64]
    rules << ["LowEnergy","Conference",0.37]
    rules << ["LowEnergy","Corridor",0.16]
    rules << ["LowEnergy","IT_Room",1.56]
    rules << ["LowEnergy","Lobby",0.07]
    rules << ["LowEnergy","Elec/MechRoom",0.07]
    rules << ["LowEnergy","OpenOffice",0.71]
    rules << ["LowEnergy","PrintRoom",2.79]
    rules << ["LowEnergy","Restroom",0.07]
    rules << ["LowEnergy","Stair",0.0]
    rules << ["LowEnergy","Storage",0.0]
    rules << ["LowEnergy","Vending",3.85]

    #make rule hash for cleaner code
    rulesHash = {}
    rules.each do |rule|
      rulesHash["#{rule[0]} #{rule[1]}"] = rule[2]
    end

    # calculate building EPD
    building = model.getBuilding
    initialLpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(building.electricEquipmentPowerPerFloorArea,"W/m^2","W/ft^2",1) # can add choices for unit display

    # calculate initial EPD to use later
    equipmentDefs = model.getElectricEquipmentDefinitions
    initialCostForElecEquip = OsLib_HelperMethods.getTotalCostForObjects(equipmentDefs)

    #reporting initial condition of model
    runner.registerInitialCondition("The building started with an EPD #{initialLpdDisplay}.")

    # global variables for costs
    expected_life = 25
    years_until_costs_start = 0

    # loop through space types
    model.getSpaceTypes.each do |spaceType|

      # skip of not used in model
      next if spaceType.spaces.size == 0

      # confirm recognized spaceType standards information
      standardsInfo = OsLib_HelperMethods.getSpaceTypeStandardsInformation([spaceType])
      if rulesHash["LowEnergy #{standardsInfo[spaceType][1]}"].nil?
        runner.registerInfo("Couldn't map #{spaceType.name} to a recognized space type used in the AEDG. Electric equipment levels for this SpaceType will not be altered.")
        next
      end

      # get target EPD
      targetEPD = OpenStudio::convert(rulesHash["LowEnergy #{standardsInfo[spaceType][1]}"],"W/ft^2","W/m^2").to_f

      # get initial LPD for space type
      initialSpaceTypeLpd = OsLib_LightingAndEquipment.getEpdForSpaceArray(spaceType.spaces)

      # harvest any hard assigned schedules along with equipment power of elecEquip. If there is no default the use the largest one of these
      oldElecEquip = []
      spaceType.electricEquipment.each do |elecEquip|
        oldElecEquip << elecEquip
      end

      # remove equipment associated directly with spaces
      spaceElecEquipRemoved = false
      spaceElecEquipSchedules = []
      spaceType.spaces.each do |space|
        equipment = space.electricEquipment
        equipment.each do |elecEquip|
          oldElecEquip << elecEquip
          elecEquip.remove
          spaceElecEquipRemoved = true
        end
      end # end of spaces.each do

      # in future versions will use (equipment power)weighted average schedule merge for new schedule
      oldScheduleHash = OsLib_LightingAndEquipment.createHashOfInternalLoadWithHardAssignedSchedules(oldElecEquip)
      if oldElecEquip.size == oldScheduleHash.size then defaultUsedAtLeastOnce = false else defaultUsedAtLeastOnce = true end

      # add new equipment
      spaceType.setElectricEquipmentPowerPerFloorArea(targetEPD)
      newElecEquip = spaceType.electricEquipment[0]
      newElecEquipDef = newElecEquip.electricEquipmentDefinition
      newElecEquipDef.setName("AEDG SmMdOff - #{standardsInfo[spaceType][1]} electric equipment")

      # add cost to equipment
      lcc_equipment = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("lcc_#{newElecEquipDef.name}", newElecEquipDef, material_cost_ip, "CostPerArea", "Construction", expected_life, years_until_costs_start)

      # report change
      if not spaceType.electricEquipmentPowerPerFloorArea.empty?
        oldLpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(initialSpaceTypeLpd,"W/m^2","W/ft^2",1)
        newLpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(spaceType.electricEquipmentPowerPerFloorArea.get,"W/m^2","W/ft^2",1) # can add choices for unit display
        runner.registerInfo("Changing EPD of #{spaceType.name} space type to #{newLpdDisplay} from #{oldLpdDisplay}")
      else
        runner.registerInfo("For some reason no EPD was set for #{spaceType.name} space type.")
      end

      if spaceElecEquipRemoved
        runner.registerInfo("One more more electric equipment objects directly assigned to spaces using #{spaceType.name} were removed. This is to limit EPD to what is added by this measure.")
      end

      # adjust schedules as necessary only hard assign if the default schedule was never used
      if defaultUsedAtLeastOnce == false and oldElecEquip.size > 0
        # retrieve hard assigned schedule
        newElecEquip.setSchedule(oldScheduleHash.sort.reverse[0][0]) # todo - see why this is failing. Need to spend some time looking through this closely, maybe 
      else
        if newElecEquip.schedule.empty?
          runner.registerWarning("Didn't find an inherited or hard assigned schedule for equipment in #{spaceType.name} or underlying spaces. Please add a schedule before running a simulation.")
        end
      end

    end # end of spaceTypes each do

    # warn if some spaces didn't have equipment altered at all (this would apply to spaces with space types not mapped)
    model.getSpaces.each do |space|
      next if not space.spaceType.empty?
      runner.registerWarning("#{space.name} doesn't have a space type. Couldn't identify target EPD without a space type. EPD was not altered.")
    end

    # populate AEDG tip keys
    aedgTips = []
    aedgTips.push("PL01","PL02","PL04","PL05","PL06")

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips("SmMdOff",aedgTips.uniq.sort,runner)
    if not aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    # calculate final building EPD
    building = model.getBuilding
    finalLpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(building.electricEquipmentPowerPerFloorArea,"W/m^2","W/ft^2",1) # can add choices for unit display

    # calculate final EPD to use later
    equipmentDefs = model.getElectricEquipmentDefinitions
    finalCostForElecEquip = OsLib_HelperMethods.getTotalCostForObjects(equipmentDefs)

    # change in cost
    costRelatedToMeasure = finalCostForElecEquip - initialCostForElecEquip
    costRelatedToMeasureDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(costRelatedToMeasure,"$","$",0,true,false,false,false) # bools (prefix,suffix,space,parentheses)

    #reporting final condition of model
    if costRelatedToMeasure > 0
      runner.registerFinalCondition("The resulting building has an EPD #{finalLpdDisplay}. Initial capital cost related to this measure is #{costRelatedToMeasureDisplay}. #{aedgTipsLong}")
    else
      runner.registerFinalCondition("The resulting building has an EPD #{finalLpdDisplay}. #{aedgTipsLong}")
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AedgSmallToMediumOfficeElectricEquipment.new.registerWithApplication