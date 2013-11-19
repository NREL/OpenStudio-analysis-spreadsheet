#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#start the measure
class SetEnergyPlusLightObjectsLPD < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetEnergyPlusLightObjectsLPD"
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument LPD
    lpd = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("lpd",true)
    lpd.setDisplayName("Lighting Power Density (W/m^2)")
    lpd.setDefaultValue(10.76)
    args << lpd
    
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
    lpd = runner.getDoubleArgumentValue("lpd",user_arguments)

    #check the lpd for reasonableness
    if lpd < 0 or lpd > 538
      runner.registerError("A Lighting Power Density of #{lpd} W/m^2 is above the measure limit.")
      return false
    elsif lpd > 226
      runner.registerWarning("A Lighting Power Density of #{lpd} W/m^2 is abnormally high.")
    end

    #get all lights in model
    lights = workspace.getObjectsByType("Lights".to_IddObjectType)

    if lights.size == 0
      runner.registerAsNotApplicable("The model does not contain any lights. The model will not be altered.")
      return true
    end

    starting_lpd_values = []
    non_lpd_starting = []
    final_lpd_values = []

    lights.each do |light|
      light_name =  light.getString(0) # Name
      light_starting_calc = light.getString(3) # Design Level Calculation Method
      light_starting_lpd = light.getString(5) # Watts per Zone Floor Area
      light.setString(3,"Watts/Area") # Design Level Calculation Method
      light.setString(5,lpd.to_s) # Watts per Zone Floor Area

      #populate reporting arrays
      if light_starting_calc.to_s == "Watts/Area"
        runner.registerInfo("Changing LPD of #{light_name} from #{light_starting_lpd}(W/m^2) to #{light.getString(5)}(W/m^2).")
        starting_lpd_values << light_starting_lpd.get.to_f
        final_lpd_values << light.getString(5).get.to_f
      else
        runner.registerInfo("Setting LPD of #{light_name} to #{light.getString(5)}(W/m^2). Original design level calculation method was #{light_starting_calc}.")
        non_lpd_starting << light_name
        final_lpd_values << light.getString(5).get.to_f
      end

    end  #end of lights.each do

    # todo - add warning if a thermal zone has more than one lights object, as that may not result in the desired impact.

    # todo - may also want to warn or have info message for zones that dont have any lights

    #unique initial conditions based on
    if starting_lpd_values.size > 0 and  non_lpd_starting.size == 0
      runner.registerInitialCondition("The building has #{lights.size} light objects, and started with LPD values ranging from #{starting_lpd_values.min} to #{starting_lpd_values.max}.")
    elsif starting_lpd_values.size > 0 and  non_lpd_starting.size > 0
      runner.registerInitialCondition("The building has #{lights.size} light objects, and started with LPD values ranging from #{starting_lpd_values.min} to #{starting_lpd_values.max}. #{non_lpd_starting.size} light objects did not start as Watts/Area, and are not included in the LPD range.")
    else
      runner.registerInitialCondition("The building has #{lights.size} light objects. None of the lights started as Watts/Area.")
    end

    #reporting final condition of model
    runner.registerFinalCondition("The building finished with LPD values ranging from #{final_lpd_values.min} to #{final_lpd_values.max}.")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetEnergyPlusLightObjectsLPD.new.registerWithApplication