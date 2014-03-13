#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SetMinimumVAVTerminalFlowFraction < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetMinimumVAVTerminalFlowFraction"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument to add new space true/false
    min_vav_frac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("min_vav_frac",true)
    min_vav_frac.setDisplayName("Minimum VAV Terminal Flow Fraction (%)")
    min_vav_frac.setDefaultValue(30.0)
    args << min_vav_frac
    
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
    min_vav_frac = runner.getDoubleArgumentValue("min_vav_frac",user_arguments)
    min_vav_percent = min_vav_frac/100
 
    #loop through each zone and it's zone equipment to find VAV terminals
    model.getThermalZones.each do |zone|
      zone.equipment.each do |zone_equip|
        if zone_equip.to_AirTerminalSingleDuctVAVReheat.is_initialized
          vav_terminal = zone_equip.to_AirTerminalSingleDuctVAVReheat.get
          vav_terminal.setZoneMinimumAirFlowMethod("Constant")
          vav_terminal.setConstantMinimumAirFlowFraction(min_vav_percent)
          runner.registerInfo("set the min vav frac to #{min_vav_percent} for #{vav_terminal.name.get}")
        elsif zone_equip.to_AirTerminalSingleDuctVAVNoReheat.is_initialized
          vav_terminal = zone_equip.to_AirTerminalSingleDuctVAVNoReheat.get
          vav_terminal.setZoneMinimumAirFlowInputMethod("Constant")
          vav_terminal.setConstantMinimumAirFlowFraction(min_vav_percent)
          runner.registerInfo("set the min vav frac to #{min_vav_percent} for #{vav_terminal.name.get}")          
        end
      end
    end
 
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetMinimumVAVTerminalFlowFraction.new.registerWithApplication