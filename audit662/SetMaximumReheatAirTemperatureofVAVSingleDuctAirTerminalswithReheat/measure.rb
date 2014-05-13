
class SetMaximumReheatAirTemperatureofVAVSingleDuctAirTerminalswithReheat < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetMaximumReheatAirTemperatureofVAVSingleDuctAirTerminalswithReheat"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    maximum_reheat_air_temperature = OpenStudio::Ruleset::OSArgument::makeDoubleArgument(
        "maximum_reheat_air_temperature",true)
    maximum_reheat_air_temperature.setDisplayName("Maximum Reheat Air Temperature (F)")
    args << maximum_reheat_air_temperature

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
    maximum_reheat_air_temperature_ip = runner.getDoubleArgumentValue("maximum_reheat_air_temperature",
                                                                      user_arguments)
                                                                   
    if maximum_reheat_air_temperature_ip < 60.0 or maximum_reheat_air_temperature_ip > 130.0
      runner.registerError("The maximum reheat air temperature must be between 60.0 F and 130.0 F. " + 
                           "The supplied value is " + 
                           "#{OpenStudio::toNeatStringBySigFigs(maximum_reheat_air_temperature_ip)} F.")
      return false
    end

    terminals = model.getAirTerminalSingleDuctVAVReheats
    runner.registerInitialCondition("The model has #{terminals.size} VAV single duct air terminals with reheat.")
    
    maximum_reheat_air_temperature_si = OpenStudio::convert(maximum_reheat_air_temperature_ip,"F","C").get
    terminals.each { |terminal|
      terminal.setMaximumReheatAirTemperature(maximum_reheat_air_temperature_si)
    }    
    
    runner.registerFinalCondition("Set the maximum reheat air temperature of all the VAV single " + 
                                  "duct air terminals with reheat to " + 
                                  "#{OpenStudio::toNeatStringBySigFigs(maximum_reheat_air_temperature_ip)} F" + 
                                  "(#{OpenStudio::toNeatStringBySigFigs(maximum_reheat_air_temperature_si)} C).")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetMaximumReheatAirTemperatureofVAVSingleDuctAirTerminalswithReheat.new.registerWithApplication