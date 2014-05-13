
class SetConstantVolumeFanStaticPressure < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "SetConstantVolumeFanStaticPressure"
  end
  
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    static_pressure_rise = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("static_pressure_rise",true)
    static_pressure_rise.setDisplayName("Static Pressure Rise (in. H2O)")
    args << static_pressure_rise
    
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
    static_pressure_rise_ip = runner.getDoubleArgumentValue("static_pressure_rise",user_arguments)
    
    if static_pressure_rise_ip < 0.0
      runner.registerError("Static pressure rise must be positive (entered value was " + 
                           "#{OpenStudio::toNeatStringBySigFigs(static_pressure_rise_ip)} in H2O).")
      return false
    end
    
    # initial condition
    fans = model.getFanConstantVolumes
    runner.registerInitialCondition("The building has #{fans.size} constant volume fans.")
    
    # make change
    static_pressure_rise_si = OpenStudio::convert(static_pressure_rise_ip,"inH_{2}O","Pa").get
    fans.each { |fan|
      fan.setPressureRise(static_pressure_rise_si)
    }
    
    # final condition
    runner.registerFinalCondition("Set the #{fans.size} constant volume fans' pressure rise to " + 
                                  "#{OpenStudio::toNeatStringBySigFigs(static_pressure_rise_ip)} in H2O (" + 
                                  "#{OpenStudio::toNeatStringBySigFigs(static_pressure_rise_si)} Pa)")
   
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetConstantVolumeFanStaticPressure.new.registerWithApplication
