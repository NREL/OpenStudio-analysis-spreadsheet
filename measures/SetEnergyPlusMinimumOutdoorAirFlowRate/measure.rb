#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#start the measure
class SetEnergyPlusMinimumOutdoorAirFlowRate < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetEnergyPlusMinimumOutdoorAirFlowRate"
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument
    minOutdoorAirFlow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("minOutdoorAirFlow",true)
    minOutdoorAirFlow.setDisplayName("Minimum Outdoor Air Flow Rate (m^3/s).")
    #minOutdoorAirFlow.setDefaultValue(10.76)
    args << minOutdoorAirFlow
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    #assign the user inputs to variables
    minOutdoorAirFlow = runner.getDoubleArgumentValue("minOutdoorAirFlow",user_arguments)

    #check the minOutdoorAirFlow for reasonableness
    if minOutdoorAirFlow < 0
      runner.registerError("Please enter a non-negative value for Minimum Outdoor Air Flow Rate.")
      return false
    end

    #get all outdoorAirObjects in model
    outdoorAirObjects = workspace.getObjectsByType("Controller:OutdoorAir".to_IddObjectType)

    if outdoorAirObjects.size == 0
      runner.registerAsNotApplicable("The model does not contain any outdoorAirObjects. The model will not be altered.")
      return true
    end

    starting_minOutdoorAirFlow_values = []
    final_minOutdoorAirFlow_values = []

    outdoorAirObjects.each do |outdoorAirObject|
      outdoorAirObject_name =  outdoorAirObject.getString(0) # Name
      outdoorAirObject_starting_minOutdoorAirFlow = outdoorAirObject.getString(5) # Minimum Outdoor Air Flow Rate
      outdoorAirObject.setString(5,minOutdoorAirFlow.to_s) # Minimum Outdoor Air Flow Rate

      #populate reporting arrays
      runner.registerInfo("Changing minimum outdoor air flow rate of #{outdoorAirObject_name} from #{outdoorAirObject_starting_minOutdoorAirFlow}(m^3/s) to #{outdoorAirObject.getString(5)}(m^3/s).")
      starting_minOutdoorAirFlow_values << outdoorAirObject_starting_minOutdoorAirFlow.get.to_f
      final_minOutdoorAirFlow_values << outdoorAirObject.getString(5).get.to_f

    end  #end of outdoorAirObjects.each do

    # todo - add warning if a thermal zone has more than one outdoorAirObjects object, as that may not result in the desired impact.

    # todo - may also want to warn or have info message for zones that dont have any outdoorAirObjects

    #unique initial conditions based on
    runner.registerInitialCondition("The building has #{outdoorAirObjects.size} outdoorAirObject objects, and started with minimum outdoor air flow rate values ranging from #{starting_minOutdoorAirFlow_values.min} to #{starting_minOutdoorAirFlow_values.max}.")

    #reporting final condition of model
    runner.registerFinalCondition("The building finished with minimum outdoor air flow rate values ranging from #{final_minOutdoorAirFlow_values.min} to #{final_minOutdoorAirFlow_values.max}.")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetEnergyPlusMinimumOutdoorAirFlowRate.new.registerWithApplication