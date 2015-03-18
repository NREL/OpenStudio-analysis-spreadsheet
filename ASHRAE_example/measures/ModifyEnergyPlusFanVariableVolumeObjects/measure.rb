#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#start the measure
class ModifyEnergyPlusFanVariableVolumeObjects < OpenStudio::Ruleset::WorkspaceUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ModifyEnergyPlusFanVariableVolumeObjects"
  end

  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument
    pressureRise = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("pressureRise",false)
    pressureRise.setDisplayName("Pressure Rise (Pa).")
    #pressureRise.setDefaultValue(10.76)
    args << pressureRise

    #make an argument
    maximumFlowRate = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("maximumFlowRate",false)
    maximumFlowRate.setDisplayName("Maximum Flow Rate (m^3/s).")
    #maximumFlowRate.setDefaultValue(10.76)
    args << maximumFlowRate

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
    if not runner.getOptionalDoubleArgumentValue("pressureRise",user_arguments).empty?
      pressureRise = runner.getOptionalDoubleArgumentValue("pressureRise",user_arguments).get
    else
      pressureRise = nil
    end
    if not runner.getOptionalDoubleArgumentValue("maximumFlowRate",user_arguments).empty?
      maximumFlowRate = runner.getOptionalDoubleArgumentValue("maximumFlowRate",user_arguments).get
    else
      maximumFlowRate = nil
    end

    #check the pressureRise for reasonableness
    if pressureRise and pressureRise < 0
      runner.registerError("Please enter a non-negative value for Pressure Rise.")
      return false
    end

    #check the pressureRise for reasonableness
    if maximumFlowRate and maximumFlowRate < 0
      runner.registerError("Please enter a non-negative value for Maximum Flow Rate.")
      return false
    end

    #get all fanVariableVolumeObjects in model
    fanVariableVolumeObjects = workspace.getObjectsByType("Fan:VariableVolume".to_IddObjectType)

    if fanVariableVolumeObjects.size == 0
      runner.registerAsNotApplicable("The model does not contain any fanVariableVolumeObjects. The model will not be altered.")
      return true
    end
    puts "pressure rise: #{pressureRise}"
    fanVariableVolumeObjects.each do |fanVariableVolumeObject|
      fanVariableVolumeObject_name =  fanVariableVolumeObject.getString(0) # Name
      fanVariableVolumeObject_starting_pressureRise = fanVariableVolumeObject.getString(3) # Pressure Rise
      fanVariableVolumeObject_starting_maximumFlowRate = fanVariableVolumeObject.getString(4) # Maximum Flow Rate
      if pressureRise
        fanVariableVolumeObject.setString(3,pressureRise.to_s) # Pressure Rise
        runner.registerInfo("Changing pressure rise of #{fanVariableVolumeObject_name} from #{fanVariableVolumeObject_starting_pressureRise}(Pa) to #{fanVariableVolumeObject.getString(3)}(Pa).")
      end
      if maximumFlowRate
        fanVariableVolumeObject.setString(4,maximumFlowRate.to_s) # Maximum Flow Rate
        runner.registerInfo("Changing maximum flow rate of #{fanVariableVolumeObject_name} from #{fanVariableVolumeObject_starting_maximumFlowRate}(m^3/s) to #{fanVariableVolumeObject.getString(4)}(m^3/s).")
      end

    end  #end of fanVariableVolumeObjects.each do

    # todo - add warning if a thermal zone has more than one fanVariableVolumeObjects object, as that may not result in the desired impact.

    # todo - may also want to warn or have info message for zones that dont have any fanVariableVolumeObjects

    #unique initial conditions based on
    # removed listing ranges for variable values since we are editing multiple fields vs. a single field.
    runner.registerInitialCondition("The building has #{fanVariableVolumeObjects.size} fanVariableVolumeObject objects.")

    #reporting final condition of model
    runner.registerFinalCondition("The building finished with #{fanVariableVolumeObjects.size} fanVariableVolumeObject objects.")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ModifyEnergyPlusFanVariableVolumeObjects.new.registerWithApplication