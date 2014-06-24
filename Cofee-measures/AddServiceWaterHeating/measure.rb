#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddServiceWaterHeating < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddServiceWaterHeating"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make choice argument economizer control type
    choices = OpenStudio::StringVector.new
    choices << "NaturalGas"
    choices << "Electricity"
    water_heater_fuel_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("water_heater_fuel_type", choices, true)
    water_heater_fuel_type.setDisplayName("Water Heater Fuel Type")
    water_heater_fuel_type.setDefaultValue("NaturalGas")
    args << water_heater_fuel_type    
 
    #make choice argument economizer control type
    hot_water_per_occ_per_day_gal = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hot_water_per_occ_per_day_gal", true)
    hot_water_per_occ_per_day_gal.setDisplayName("Gallons Hot Water per Occupant per Day")
    hot_water_per_occ_per_day_gal.setDefaultValue(1.0)
    args << hot_water_per_occ_per_day_gal
        
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Assign the user inputs to variables
    hot_water_per_occ_per_day_gal = runner.getDoubleArgumentValue("hot_water_per_occ_per_day_gal",user_arguments)    
    hot_water_per_occ_per_day_m3 = OpenStudio::convert(hot_water_per_occ_per_day_gal,"gal","m^3").get
    water_heater_fuel_type = runner.getStringArgumentValue("water_heater_fuel_type",user_arguments)
      
    # Note if hot_water_per_occ_per_day_gal == false
    # and register as N/A
    if hot_water_per_occ_per_day_gal == 0.0
      runner.registerAsNotApplicable("N/A - User requested no service water use per occupant.")
      return true
    end  
      
    # Define sch limits for temp schedule  
    temp_sch_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
    temp_sch_limits.setName("Temperature Schedule Type Limits")
    temp_sch_limits.setLowerLimitValue(0.0)
    temp_sch_limits.setUpperLimitValue(100.0)
    temp_sch_limits.setNumericType("Continuous")
    temp_sch_limits.setUnitType("Temperature")
    
    # Assume ambient temp for water heater (assume inside at 70F)
    default_water_heater_ambient_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    default_water_heater_ambient_temp_sch.setName("Water Heater Ambient Temp Schedule - 70F")
    default_water_heater_ambient_temp_sch.defaultDaySchedule.setName("Water Heater Ambient Temp Schedule - 70F Default")
    default_water_heater_ambient_temp_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),OpenStudio::convert(70,"F","C").get)
    default_water_heater_ambient_temp_sch.setScheduleTypeLimits(temp_sch_limits)    

    # Get the properties of the system
    hw_temp_f = 140
    hw_temp_c = OpenStudio::convert(hw_temp_f,"F","C").get 
    
    mixed_water_temp_f = 100
    mixed_water_temp_c = OpenStudio::convert(mixed_water_temp_f,"F","C").get 

    hw_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    hw_temp_sch.setName("Service/Domestic Water Temp - #{hw_temp_f}F")
    hw_temp_sch.defaultDaySchedule.setName("Service/Domestic Water Temp Default")
    hw_temp_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), hw_temp_c)
    hw_temp_sch.setScheduleTypeLimits(temp_sch_limits)    
    
    # Make a new service hot water loop
    service_water_loop = OpenStudio::Model::PlantLoop.new(model)   
    service_water_loop.setName("Service Water Heating Loop")

    # Create a pump because every loop in E+ must have pump
    # setting rated head to 0 to get no power consumption
    # TODO this is a bad assumption for larger buildings (need recirc pump)
    zero_energy_pump = OpenStudio::Model::PumpConstantSpeed.new(model)
    zero_energy_pump.setRatedPumpHead(0.0)
    zero_energy_pump.setPumpControlType("Intermittent")
    zero_energy_pump.addToNode(service_water_loop.supplyInletNode)    
    
    # Translate the hot water heater  
    water_heater = OpenStudio::Model::WaterHeaterMixed.new(model)
    water_heater.setSetpointTemperatureSchedule(hw_temp_sch)
    water_heater.setAmbientTemperatureIndicator("Schedule")
    water_heater.setAmbientTemperatureSchedule(default_water_heater_ambient_temp_sch)
    water_heater.setMaximumTemperatureLimit(OpenStudio::convert(212,"F","C").get)
    water_heater.setHeaterFuelType(water_heater_fuel_type)
    water_heater.setOffCycleParasiticFuelType(water_heater_fuel_type)
    water_heater.setOnCycleParasiticFuelType(water_heater_fuel_type)
    
    service_water_loop.addSupplyBranchForComponent(water_heater)
    
    # Create the setpoint manager to control HW temperature    
    hw_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, hw_temp_sch)
    service_water_loop.supplyOutletNode.addSetpointManager(hw_stpt_manager)

    # Set the sizing temperatures for the hot water loop
    service_water_loop.sizingPlant.setLoopType("Heating")
    service_water_loop.sizingPlant.setDesignLoopExitTemperature(hw_temp_c)
    service_water_loop.sizingPlant.setLoopDesignTemperatureDifference(OpenStudio::convert(20,"R","K").get)    
    runner.registerInfo("Added a service water loop set to #{hw_temp_f}F.")
    
    # Figure out how many people are in the building
    num_occupants = 0
    model.getSpaces.each do |space|
      # runner.registerInfo("#{space.name} has #{space.numberOfPeople} people")
      num_occupants += space.numberOfPeople
    end
    runner.registerInfo("Assuming that this building has #{num_occupants} people for Service Water Heating.")
    
    # Convert water flow rate to equivalent constant flow
    hot_water_gal_per_day = hot_water_per_occ_per_day_gal*num_occupants
    hot_water_gal_per_year = hot_water_gal_per_day*365
    hot_water_gal_per_s = hot_water_gal_per_day/86400 # 86,400 sec/day
    hot_water_flow_rate_m3_per_s = OpenStudio::convert(hot_water_gal_per_s,"gal/s","m^3/s").get
    runner.registerInfo("At #{hot_water_per_occ_per_day_gal} gal/day per occupant, this is #{hot_water_gal_per_year} gal annually.")
    runner.registerInfo("This translates to a 24/7/365 flow rate of #{hot_water_gal_per_s} gal/s, or #{hot_water_flow_rate_m3_per_s}m^3/s.")  
      
    # Create a mixed water temperature schedule
    mixed_water_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    mixed_water_temp_sch.setName("Water Fixture Mixed Temp - #{mixed_water_temp_f}F")
    mixed_water_temp_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0),mixed_water_temp_c)
    mixed_water_temp_sch.setScheduleTypeLimits(temp_sch_limits)
           
    # Create the water fixture definition
    water_fixture_definition = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
    water_fixture_definition.setName("Water fixture def for #{num_occupants} people at #{hot_water_per_occ_per_day_gal} gal/day each")
    water_fixture_definition.setPeakFlowRate(hot_water_flow_rate_m3_per_s)
    water_fixture_definition.setTargetTemperatureSchedule(mixed_water_temp_sch)
    
    # Create a single water fixture that uses all the hot water in the building
    water_fixture = OpenStudio::Model::WaterUseEquipment.new(water_fixture_definition)
    water_fixture.setName("Water fixture instance for #{num_occupants} people at #{hot_water_per_occ_per_day_gal} gal/day each")
    
    # Create a service water connection to hold the fixture
    service_water_connection = OpenStudio::Model::WaterUseConnections.new(model)
    service_water_connection.addWaterUseEquipment(water_fixture)

    # Add the service water connection to the plant loop
    service_water_loop.addDemandBranchForComponent(service_water_connection)
    runner.registerInfo("Added a single water fixture to the loop drawing water at #{mixed_water_temp_f}F.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddServiceWaterHeating.new.registerWithApplication