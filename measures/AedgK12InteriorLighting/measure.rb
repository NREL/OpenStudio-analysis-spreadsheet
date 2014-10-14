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
class AedgK12InteriorLighting < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AedgK12InteriorLighting"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for material and installation cost
    material_cost_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost_ip",true)
    material_cost_ip.setDisplayName("Material and Installation Costs for Lights per Floor Area ($/ft^2).")
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
    rules = [] #target, space type, LPD_ip

    # currently only target is lower energy, but setup hash this way so could add baseline in future
    # climate zone doesn't impact values for LPD in AEDG

    # populate rules hash
    rules << ["LowEnergy","Auditorium",0.5]
    rules << ["LowEnergy","Cafeteria",0.7]
    rules << ["LowEnergy","Classroom",0.8]
    rules << ["LowEnergy","Corridor",0.4]
    rules << ["LowEnergy","Gym",1.0]
    rules << ["LowEnergy","Kitchen",0.8]
    rules << ["LowEnergy","Library",0.8]
    rules << ["LowEnergy","Lobby",0.7]
    rules << ["LowEnergy","Mechanical",0.4]
    rules << ["LowEnergy","Office",0.6]
    rules << ["LowEnergy","Restroom",0.5]

    #make rule hash for cleaner code
    rulesHash = {}
    rules.each do |rule|
      rulesHash["#{rule[0]} #{rule[1]}"] = rule[2]
    end

    # calculate building LPD
    building = model.getBuilding
    initialLpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(building.lightingPowerPerFloorArea,"W/m^2","W/ft^2",1) # can add choices for unit display

    # calculate initial LPD to use later
    lightDefs = model.getLightsDefinitions
    initialCostForLights = OsLib_HelperMethods.getTotalCostForObjects(lightDefs)

    #reporting initial condition of model
    runner.registerInitialCondition("The building started with an LPD #{initialLpdDisplay}.")

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
        runner.registerInfo("Couldn't map #{spaceType.name} to a recognized space type used in the AEDG. Lighting levels for this SpaceType will not be altered.")
        next
      end

      # get initial LPD for space type
      initialSpaceTypeLpd = OsLib_LightingAndEquipment.getLpdForSpaceArray(spaceType.spaces)

      # get target LPD
      targetLPD = OpenStudio::convert(rulesHash["LowEnergy #{standardsInfo[spaceType][1]}"],"W/ft^2","W/m^2").to_f

      # harvest any hard assigned schedules along with lighting power of light. If there is no default the use the largest one of these
      oldLights = []
      spaceType.lights.each do |light|
        oldLights << light
      end

      # remove lights associated directly with spaces
      spaceLightRemoved = false
      spaceLightsSchedules = []
      spaceType.spaces.each do |space|
        lights = space.lights
        lights.each do |light|
          oldLights << light
          light.remove
          spaceLightRemoved = true
        end
      end # end of spaces.each do

      # in future versions will use (lighting power)weighted average schedule merge for new schedule
      oldScheduleHash = OsLib_LightingAndEquipment.createHashOfInternalLoadWithHardAssignedSchedules(oldLights)
      if oldLights.size == oldScheduleHash.size then defaultUsedAtLeastOnce = false else defaultUsedAtLeastOnce = true end

      # add new lights
      spaceType.setLightingPowerPerFloorArea(targetLPD) # not sure if this is instance or def?
      newLight = spaceType.lights[0]
      newLightDef = newLight.lightsDefinition
      newLightDef.setName("AEDG K12 - #{standardsInfo[spaceType][1]} lights")

      # add cost to lights
      lcc_lights = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("lcc_#{newLightDef.name}", newLightDef, material_cost_ip, "CostPerArea", "Construction", expected_life, years_until_costs_start)

      # report change
      if not spaceType.lightingPowerPerFloorArea.empty?
        oldLpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(initialSpaceTypeLpd,"W/m^2","W/ft^2",1)
        newLpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(spaceType.lightingPowerPerFloorArea.get,"W/m^2","W/ft^2",1) # can add choices for unit display
        runner.registerInfo("Changing LPD of #{spaceType.name} space type to #{newLpdDisplay} from #{oldLpdDisplay}")
      else
        runner.registerInfo("For some reason no LPD was set for #{spaceType.name} space type.")
      end

      if spaceLightRemoved
        runner.registerInfo("One more more lights directly assigned to spaces using #{spaceType.name} were removed. This is to limit lighting to what is added by this measure.")
      end

      # adjust schedules as necessary only hard assign if the default schedule was never used
      if defaultUsedAtLeastOnce == false and oldLights.size > 0
        # retrieve hard assigned schedule
        newLight.setSchedule(oldScheduleHash.sort.reverse[0][0])
      else
        if newLight.schedule.empty?
          runner.registerWarning("Didn't find an inherited or hard assigned schedule for lights in #{spaceType.name} or underlying spaces. Please add a schedule before running a simulation.")
        end
      end

    end # end of spaceTypes each do

    # warn if some spaces didn't have lights altered at all (this would apply to spaces with space types not mapped)
    model.getSpaces.each do |space|
      next if not space.spaceType.empty?
      runner.registerWarning("#{space.name} doesn't have a space type. Couldn't identify target LPD without a space type. Lights were not altered.")
    end

    # populate AEDG tip keys
    aedgTips = []
    aedgTips.push("EL02","EL03","EL04","EL05","EL06","EL07","EL10","EL12","EL13","EL14","EL15","EL16","EL17","EL18","EL19")

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips("K12",aedgTips.uniq.sort,runner)
    if not aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    # calculate final building LPD
    building = model.getBuilding
    finalLpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(building.lightingPowerPerFloorArea,"W/m^2","W/ft^2",1) # can add choices for unit display

    # calculate final LPD to use later
    lightDefs = model.getLightsDefinitions
    finalCostForLights = OsLib_HelperMethods.getTotalCostForObjects(lightDefs)

    # change in cost
    costRelatedToMeasure = finalCostForLights - initialCostForLights
    costRelatedToMeasureDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(costRelatedToMeasure,"$","$",0,true,false,false,false) # bools (prefix,suffix,space,parentheses)

    #reporting final condition of model
    if costRelatedToMeasure > 0
      runner.registerFinalCondition("The resulting building has an LPD #{finalLpdDisplay}. Initial capital cost related to this measure is #{costRelatedToMeasureDisplay}. #{aedgTipsLong}")
    else
      runner.registerFinalCondition("The resulting building has an LPD #{finalLpdDisplay}. #{aedgTipsLong}")
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AedgK12InteriorLighting.new.registerWithApplication