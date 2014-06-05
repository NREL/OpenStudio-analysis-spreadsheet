#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class EnableIdealAirLoadsForAllZones < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "EnableIdealAirLoadsForAllZones"
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

    # array of zones initially using ideal air loads
    startingIdealAir = []

    thermalZones = model.getThermalZones
    thermalZones.each do |zone|
      if zone.useIdealAirLoads
        startingIdealAir << zone
      else
        zone.setUseIdealAirLoads(true)
      end
    end

    #reporting initial condition of model
    runner.registerInitialCondition("In the initial model #{startingIdealAir.size} zones use ideal air loads.")

    #reporting final condition of model
    finalIdealAir = []
    thermalZones.each do |zone|
      if zone.useIdealAirLoads
        finalIdealAir << zone
      end
    end
    runner.registerFinalCondition("In the final model #{finalIdealAir.size} zones use ideal air loads.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
EnableIdealAirLoadsForAllZones.new.registerWithApplication