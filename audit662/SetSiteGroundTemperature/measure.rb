
class SetSiteGroundTemperature < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "SetSiteGroundTemperature"
  end
  
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    ground_temperature = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ground_temperature",true)
    ground_temperature.setDisplayName("Ground Temperature (degC)")
    args << ground_temperature
   
    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    # use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    ground_temperature = runner.getDoubleArgumentValue("ground_temperature",user_arguments)

    # check variable values for reasonableness
    ground_temperature_ip = OpenStudio::convert(ground_temperature,"C","F")
    if ground_temperature < -50.0 or ground_temperature > 75.0
      runner.registerError("The ground under the building cannot possibly be #{OpenStudio::totoNeatStringBySigFigs(ground_temperature_ip)} F.")
      return false
    end
    if ground_temperature < 5.0 or ground_temperature > 38.0
      runner.registerWarning("It is unlikely that the ground under the building is #{OpenStudio::totoNeatStringBySigFigs(ground_temperature_ip)} F. A rule of thumb is that the ground under the building is about 2 C lower than the average indoor temperature.")
    end
    
    # register initial condition
    ground_temperature_object = model.getOptionalSiteGroundTemperatureBuildingSurface
    had_object = (not ground_temperature_object.empty?)
    avg_ground_temperature = nil
    avg_ground_temperature_ip = nil
    if had_object
      ground_temperature_object = ground_temperature_object.get
      # TODO: Put this in the SiteGroundTemperatureBuildingSurface object.
      avg_ground_temperature = (ground_temperature_object.januaryGroundTemperature + 
                                ground_temperature_object.februaryGroundTemperature + 
                                ground_temperature_object.marchGroundTemperature + 
                                ground_temperature_object.aprilGroundTemperature + 
                                ground_temperature_object.mayGroundTemperature + 
                                ground_temperature_object.juneGroundTemperature + 
                                ground_temperature_object.julyGroundTemperature + 
                                ground_temperature_object.augustGroundTemperature + 
                                ground_temperature_object.septemberGroundTemperature + 
                                ground_temperature_object.octoberGroundTemperature + 
                                ground_temperature_object.novemberGroundTemperature + 
                                ground_temperature_object.decemberGroundTemperature) / 12.0
      avg_ground_temperature_ip = OpenStudio::convert(avg_ground_temperature,"C","F").get    
      runner.registerInitialCondition("The initial model has a ground temperature object with an annual average " + 
                                      "of #{OpenStudio::toNeatStringBySigFigs(avg_ground_temperature)} C " + 
                                      "(#{OpenStudio::toNeatStringBySigFigs(avg_ground_temperature_ip)} F).")
    else
      avg_ground_temperature = 18.0
      avg_ground_temperature_ip = OpenStudio::convert(avg_ground_temperature,"C","F").get   
      runner.registerInitialCondition("The initial model does not contain a ground temperatures object, which " + 
                                      "corresponds to an EnergyPlus default of " + 
                                      "#{OpenStudio::toNeatStringBySigFigs(avg_ground_temperature)} C " + 
                                      "(#{OpenStudio::toNeatStringBySigFigs(avg_ground_temperature_ip)} F).")
      ground_temperature_object = model.getSiteGroundTemperatureBuildingSurface
    end
    runner.registerValue("avg_ground_temperature_before",avg_ground_temperature,"C")
    runner.registerValue("avg_ground_temperature_before_ip",avg_ground_temperature_ip,"F")    

    # set the ground temperature
    ground_temperature_object.setJanuaryGroundTemperature(ground_temperature)
    ground_temperature_object.setFebruaryGroundTemperature(ground_temperature)
    ground_temperature_object.setMarchGroundTemperature(ground_temperature)
    ground_temperature_object.setAprilGroundTemperature(ground_temperature)
    ground_temperature_object.setMayGroundTemperature(ground_temperature)
    ground_temperature_object.setJuneGroundTemperature(ground_temperature)
    ground_temperature_object.setJulyGroundTemperature(ground_temperature)
    ground_temperature_object.setAugustGroundTemperature(ground_temperature)
    ground_temperature_object.setSeptemberGroundTemperature(ground_temperature)
    ground_temperature_object.setOctoberGroundTemperature(ground_temperature)
    ground_temperature_object.setNovemberGroundTemperature(ground_temperature)
    ground_temperature_object.setDecemberGroundTemperature(ground_temperature)

    # report out the final condition of the model
    # do so in a way that checks the programmer's work
    avg_ground_temperature = (ground_temperature_object.januaryGroundTemperature + 
                              ground_temperature_object.februaryGroundTemperature + 
                              ground_temperature_object.marchGroundTemperature + 
                              ground_temperature_object.aprilGroundTemperature + 
                              ground_temperature_object.mayGroundTemperature + 
                              ground_temperature_object.juneGroundTemperature + 
                              ground_temperature_object.julyGroundTemperature + 
                              ground_temperature_object.augustGroundTemperature + 
                              ground_temperature_object.septemberGroundTemperature + 
                              ground_temperature_object.octoberGroundTemperature + 
                              ground_temperature_object.novemberGroundTemperature + 
                              ground_temperature_object.decemberGroundTemperature) / 12.0
    avg_ground_temperature_ip = OpenStudio::convert(avg_ground_temperature,"C","F").get
    runner.registerFinalCondition("The final model has a ground temperature object with an annual average " + 
                                  "of #{OpenStudio::toNeatStringBySigFigs(avg_ground_temperature)} C " + 
                                  "(#{OpenStudio::toNeatStringBySigFigs(avg_ground_temperature_ip)} F).")
    runner.registerValue("avg_ground_temperature_after",avg_ground_temperature,"C")
    runner.registerValue("avg_ground_temperature_after_ip",avg_ground_temperature_ip,"F")    
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetSiteGroundTemperature.new.registerWithApplication
