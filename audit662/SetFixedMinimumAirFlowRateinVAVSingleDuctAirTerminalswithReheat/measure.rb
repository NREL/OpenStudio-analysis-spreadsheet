
class SetFixedMinimumAirFlowRateinVAVSingleDuctAirTerminalswithReheat < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "SetFixedMinimumAirFlowRateinVAVSingleDuctAirTerminalswithReheat"
  end
  
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
  
    fixed_minimum_air_flow_rate = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fixed_minimum_air_flow_rate",true)
    fixed_minimum_air_flow_rate.setDisplayName("Fixed Minimum Air Flow Rate (cfm)")
    args << fixed_minimum_air_flow_rate
    
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
    fixed_minimum_air_flow_rate_ip = runner.getDoubleArgumentValue("fixed_minimum_air_flow_rate",
                                                                   user_arguments)

    if fixed_minimum_air_flow_rate_ip < 0.0
      runner.registerError("The minimum air flow rate must be >= 0.0 cfm. It is " + 
                           "#{OpenStudio::toNeatStringBySigFigs(fixed_minimum_air_flow_rate_ip)} cfm.")
      return false
    end

    terminals = model.getAirTerminalSingleDuctVAVReheats
    runner.registerInitialCondition("The model has #{terminals.size} VAV single duct air terminals with reheat.")
    
    fixed_minimum_air_flow_rate_si = OpenStudio::convert(fixed_minimum_air_flow_rate_ip,"cfm","m^3/s").get
    terminals.each { |terminal|
      terminal.setFixedMinimumAirFlowRate(fixed_minimum_air_flow_rate_si)
    }    
    
    runner.registerFinalCondition("Set the fixed minimum air flow rate of all the VAV single " + 
                                  "duct air terminals with reheat to " + 
                                  "#{OpenStudio::toNeatStringBySigFigs(fixed_minimum_air_flow_rate_ip)} cfm" + 
                                  "(#{OpenStudio::toNeatStringBySigFigs(fixed_minimum_air_flow_rate_si)} m^3/s).")
        
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetFixedMinimumAirFlowRateinVAVSingleDuctAirTerminalswithReheat.new.registerWithApplication