#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SwapAllLightsForNewDefinition < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SwapAllLightsForNewDefinition"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # create hard coded choice list for lighting options

    #make choice argument for facade
    choices = OpenStudio::StringVector.new
    choices << "Incandescent"
    choices << "Fluorescent"
    choices << "LED"
    lightsDef = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("lightsDef", choices,true)
    lightsDef.setDisplayName("Choose a Lighting Fixture Type")
    lightsDef.setDefaultValue("Fluorescent")
    args << lightsDef

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
    lightsDef = runner.getStringArgumentValue("lightsDef",user_arguments)

    # get target lighting power for new definition
    if lightsDef == "Incandescent"
      target = 60
    elsif lightsDef == "Fluorescent"
      target = 14
    elsif lightsDef == "LED"
      target = 10
    else
      runner.registerError("Unexpected lighting choice.")
      return false
    end

    # create a new LightsDefinition and new Lights object to use with setLightingPowerPerFloorArea
    new_light_def = OpenStudio::Model::LightsDefinition.new(model)
    new_light_def.setName("#{target} watt fixture.")
    new_light_def.setLightingLevel(target)

    #reporting initial condition of model
    startingLightingPower =  OpenStudio::toNeatString(model.getBuilding.lightingPower,0,true)# double,decimals, show commas
    runner.registerInitialCondition("The building started with a lighting power of #{startingLightingPower} watts.")

    # loop through all light instances and apply new light
    lights = model.getLightss
    lights.each do |light|

      # issue warning if light is per area or person and then don't change it, if not then swap out definition
      if not light.lightingLevel.empty?
        # change definition
        light.setLightsDefinition(new_light_def)
      else
        runner.registerWarning("#{light.name} appears to use a per area or person lighting level, and won't be changed by this measure.")        
      end

    end

    #reporting final condition of model
    finalLightingPower =  OpenStudio::toNeatString(model.getBuilding.lightingPower,0,true)# double,decimals, show commas
    runner.registerFinalCondition("The building finished with a lighting power of #{finalLightingPower} watts.")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SwapAllLightsForNewDefinition.new.registerWithApplication