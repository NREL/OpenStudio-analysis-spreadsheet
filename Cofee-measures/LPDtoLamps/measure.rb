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
class LPDtoLamps < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "LPDtoLamps"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    

    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # lookup table for LPD by space type
    rules = [] #buildingTypeStandard,spaceTypeStandard,spaceTypeAdjustmentFactor
    # these came from pre-1980 with the assumption that they were incandescent (but not sure if that is true)
    rules << ["Retail","Back_Space",0.77]
    rules << ["Retail","Entry",5.04]
    rules << ["Retail","Point_of_Sale",5.04]
    rules << ["Retail","Retail",5.04]
    rules << ["Office","BreakRoom",2.0]
    rules << ["Office","ClosedOffice",1.69]
    rules << ["Office","Conference",1.69]
    rules << ["Office","Corridor",1.38]
    rules << ["Office","Elec/MechRoom",3.80]
    rules << ["Office","IT_Room",2.34]
    rules << ["Office","Lobby",2.92]
    rules << ["Office","OpenOffice",2.68]
    rules << ["Office","PrintRoom",2.68]
    rules << ["Office","Stair",3.09]
    rules << ["Office","Restroom",2.22]
    rules << ["Office","Storage",1.37]
    rules << ["Office","Vending",1.71]

    #make rule hash for cleaner code
    rulesHash = {}
    rules.each do |rule|
      rulesHash["#{rule[0]} #{rule[1]}"] = rule[2]
    end

    # technology multiplier for values normalized to 1 w/ft^2
    techMultiplierHash = {}
    techMultiplierHash["Incandescent"] = 60/60
    techMultiplierHash["Fluorescent"] = 14/60
    techMultiplierHash["LED"] = 10/60

    # variable to use later
    lamp = nil

    #reporting initial condition of model
    startingLightingPower =  OpenStudio::toNeatString(model.getBuilding.lightingPower,0,true)# double,decimals, show commas
    runner.registerInitialCondition("The building started with a lighting power of #{startingLightingPower} watts.")

    lightsDefs = model.getLightsDefinitions
    if lightsDefs.size == 0
      runner.registerAsNotApplicable("Nothing to do,this model doesn't have lights.")
      return true
    end

    # loop through light defs
    lightsDefs.sort.each do |lightsDef|

      # get power per floor area
      lightDefPowerPerFloorArea = lightsDef.wattsperSpaceFloorArea.get

      spaceTypes = model.getSpaceTypes
      spaceTypes.sort.each do |spaceType|

        # stop here if this space type doesn't use the lightsDef
        # todo - make this more robust to handle multiple light instances using same def in a model
        usesDefFlag = false
        lights = spaceType.lights
        lights.each do |light|
          if light.lightsDefinition == lightsDef
            usesDefFlag = true
          end
        end

        next if usesDefFlag == false

        # get standards info and looking techMultiplier
        spaceTypeStandards = OsLib_HelperMethods.getSpaceTypeStandardsInformation([spaceType])
        techMultiplier = rulesHash["#{spaceTypeStandards[spaceType][0]} #{spaceTypeStandards[spaceType][1]}"]

        # catchall for bad hash lookup
        if techMultiplier.nil?
          techMultiplier = techMultiplierHash["Incandescent"]
          runner.registerWarning("Couldn't find a mapping for #{spaceTypeStandards[spaceType][0]} #{spaceTypeStandards[spaceType][1]}. Will assume lights are incandescent.")
        end

        # infer lighting technology based on lookup using space type and LPD
        minValue = nil
        minType = nil
        techMultiplierHash.each do |k,v|
          if minValue == nil
            minValue = (v-techMultiplier).abs
            minType = k
          elsif minValue > (v-techMultiplier).abs
            minValue = (v-techMultiplier).abs
            minType = k
          end
        end

        # set and report lamp type
        lamp = minValue
        runner.registerInfo("Lamps in #{spaceType.name}appear to be #{minType}.")

        spaceType.spaces.sort.each do |space|

          # todo check and see if there were any space lights to start with

          # for now I'm not going to deal with schedules, I'll let schedule sets pick it up but not very robust.

          # get area of lights.
          floorArea = space.floorArea # don't want to add space.multiplier to area because zone multiplier will already pick this up.
          floorAreaDisplay =  OsLib_HelperMethods.neatConvertWithUnitDisplay(floorArea,"m^2","ft^2",0)

          # find total power wattage for this instance
          totalPower = lightDefPowerPerFloorArea*floorArea  # todo should confirm that original light instance multiplier is 1

          # calculate number of fixtures needed
          numFixtures = totalPower/lamp

          # add space instance based on space type instance
          new_light_inst = OpenStudio::Model::Lights.new(lightsDef)
          new_light_inst.setName("#{lamp} watt fixtures for #{space.name}")
          new_light_inst.setMultiplier(numFixtures)
          new_light_inst.setSpace(space)

        end # end of spaceType.spaces each do

        # remove instance from space type
        lights.each do |light|
          if light.lightsDefinition == lightsDef
            light.remove
          end
        end

      end # end of spaceTypes.sort.each do

      # change value to 60 watts
      # todo - may hit issues here if same lightsDef used in different space types
      lightsDef.setLightingLevel(lamp)
      runner.registerInfo("Changing value of #{lightsDef.name} to #{OpenStudio::toNeatString(lamp,2,true)} watts.")

    end # end of lightsDefs.sort.each do

    #reporting final condition of model
    finalLightingPower =  OpenStudio::toNeatString(model.getBuilding.lightingPower,0,true)# double,decimals, show commas
    runner.registerFinalCondition("The building finished with a lighting power of #{finalLightingPower} watts.")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
LPDtoLamps.new.registerWithApplication