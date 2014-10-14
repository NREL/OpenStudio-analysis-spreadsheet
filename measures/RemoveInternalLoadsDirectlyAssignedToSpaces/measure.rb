#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class RemoveInternalLoadsDirectlyAssignedToSpaces < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "RemoveInternalLoadsDirectlyAssignedToSpaces"
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

    #assign the user inputs to variables

    #reporting initial condition of model
    spaceLoads = model.getSpaceLoadInstances
    runner.registerInitialCondition("The building started with #{spaceLoads.size} space load instances.")

    # loop through spaces remove space loads
    spaces = model.getSpaces
    spaces.each do |space|

      # removing or detaching loads directly assigned to space objects.
      space.internalMass.each {|instance| instance.remove }
      space.people.each {|instance| instance.remove }
      space.lights.each {|instance| instance.remove }
      space.luminaires.each {|instance| instance.remove }
      space.electricEquipment.each {|instance| instance.remove }
      space.gasEquipment.each {|instance| instance.remove }
      space.hotWaterEquipment.each {|instance| instance.remove }
      space.steamEquipment.each {|instance| instance.remove }
      space.otherEquipment.each {|instance| instance.remove }
      space.spaceInfiltrationDesignFlowRates.each {|object| object.remove }
      space.spaceInfiltrationEffectiveLeakageAreas.each {|object| object.remove }

      space.resetDesignSpecificationOutdoorAir

    end

    #reporting final condition of model
    spaceLoads = model.getSpaceLoadInstances
    runner.registerFinalCondition("The building finished with #{spaceLoads.size} space load instances.")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
RemoveInternalLoadsDirectlyAssignedToSpaces.new.registerWithApplication