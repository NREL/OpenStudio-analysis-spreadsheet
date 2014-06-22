#see the URL below for information on how to write OpenStudio measures
# http:#openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http:#openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http:#openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddSys3PSZACNgrid < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add Sys 3 - PSZ-AC Ngrid"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # Heating efficiency
    heating_efficiency = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("heating_efficiency",true)
    heating_efficiency.setDisplayName("Heating Efficiency")
    heating_efficiency.setDefaultValue(0.8)
    args << heating_efficiency

    # Cooling cop
    cooling_cop = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cooling_cop",true)
    cooling_cop.setDisplayName("Cooling COP")
    cooling_cop.setDefaultValue(3.0)
    args << cooling_cop

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    heating_efficiency = runner.getDoubleArgumentValue('heating_efficiency',user_arguments)
    cooling_cop = runner.getDoubleArgumentValue('cooling_cop',user_arguments)

    # System Type 3: PSZ-AC
    # This measure creates:
    # a constant volume packaged single-zone A/C unit with gas heat 
    # and DX cooling for each zone in the building
    
    always_on = model.alwaysOnDiscreteSchedule

    # Make a PSZ-AC for each zone
    model.getThermalZones.each do |zone|
      
      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName("#{zone.name} Packaged Rooftop Air Conditioner")
      
      # When an air_loop is contructed, its constructor creates a sizing:system object
      # the default sizing:system contstructor makes a system:sizing object 
      # appropriate for a multizone VAV system
      # this systems is a constant volume system with no VAV terminals, 
      # and therfore needs different default settings
      air_loop_sizing = air_loop.sizingSystem # TODO units
      air_loop_sizing.setTypeofLoadtoSizeOn("Sensible")
      air_loop_sizing.autosizeDesignOutdoorAirFlowRate
      air_loop_sizing.setMinimumSystemAirFlowRatio(1.0)
      air_loop_sizing.setPreheatDesignTemperature(7.0)
      air_loop_sizing.setPreheatDesignHumidityRatio(0.008)
      air_loop_sizing.setPrecoolDesignTemperature(12.8)
      air_loop_sizing.setPrecoolDesignHumidityRatio(0.008)
      air_loop_sizing.setCentralCoolingDesignSupplyAirTemperature(12.8)
      air_loop_sizing.setCentralHeatingDesignSupplyAirTemperature(40.0)
      air_loop_sizing.setSizingOption("NonCoincident")
      air_loop_sizing.setAllOutdoorAirinCooling(false)
      air_loop_sizing.setAllOutdoorAirinHeating(false)
      air_loop_sizing.setCentralCoolingDesignSupplyAirHumidityRatio(0.0085)
      air_loop_sizing.setCentralHeatingDesignSupplyAirHumidityRatio(0.0080)
      air_loop_sizing.setCoolingDesignAirFlowMethod("DesignDay")
      air_loop_sizing.setCoolingDesignAirFlowRate(0.0)
      air_loop_sizing.setHeatingDesignAirFlowMethod("DesignDay")
      air_loop_sizing.setHeatingDesignAirFlowRate(0.0)
      air_loop_sizing.setSystemOutdoorAirMethod("ZoneSum")

      fan = OpenStudio::Model::FanConstantVolume.new(model,always_on)
      fan.setPressureRise(500)

      htg_coil = OpenStudio::Model::CoilHeatingGas.new(model,always_on)

      # set heating eff
      htg_coil.setGasBurnerEfficiency(heating_efficiency)

      clg_cap_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
      clg_cap_f_of_temp.setCoefficient1Constant(0.42415)
      clg_cap_f_of_temp.setCoefficient2x(0.04426)
      clg_cap_f_of_temp.setCoefficient3xPOW2(-0.00042)
      clg_cap_f_of_temp.setCoefficient4y(0.00333)
      clg_cap_f_of_temp.setCoefficient5yPOW2(-0.00008)
      clg_cap_f_of_temp.setCoefficient6xTIMESY(-0.00021)
      clg_cap_f_of_temp.setMinimumValueofx(17.0)
      clg_cap_f_of_temp.setMaximumValueofx(22.0)
      clg_cap_f_of_temp.setMinimumValueofy(13.0)
      clg_cap_f_of_temp.setMaximumValueofy(46.0)

      clg_cap_f_of_flow = OpenStudio::Model::CurveQuadratic.new(model)
      clg_cap_f_of_flow.setCoefficient1Constant(0.77136)
      clg_cap_f_of_flow.setCoefficient2x(0.34053)
      clg_cap_f_of_flow.setCoefficient3xPOW2(-0.11088)
      clg_cap_f_of_flow.setMinimumValueofx(0.75918)
      clg_cap_f_of_flow.setMaximumValueofx(1.13877)

      clg_energy_input_ratio_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
      clg_energy_input_ratio_f_of_temp.setCoefficient1Constant(1.23649)
      clg_energy_input_ratio_f_of_temp.setCoefficient2x(-0.02431)
      clg_energy_input_ratio_f_of_temp.setCoefficient3xPOW2(0.00057)
      clg_energy_input_ratio_f_of_temp.setCoefficient4y(-0.01434)
      clg_energy_input_ratio_f_of_temp.setCoefficient5yPOW2(0.00063)
      clg_energy_input_ratio_f_of_temp.setCoefficient6xTIMESY(-0.00038)
      clg_energy_input_ratio_f_of_temp.setMinimumValueofx(17.0)
      clg_energy_input_ratio_f_of_temp.setMaximumValueofx(22.0)
      clg_energy_input_ratio_f_of_temp.setMinimumValueofy(13.0)
      clg_energy_input_ratio_f_of_temp.setMaximumValueofy(46.0)

      clg_energy_input_ratio_f_of_flow = OpenStudio::Model::CurveQuadratic.new(model)
      clg_energy_input_ratio_f_of_flow.setCoefficient1Constant(1.20550)
      clg_energy_input_ratio_f_of_flow.setCoefficient2x(-0.32953)
      clg_energy_input_ratio_f_of_flow.setCoefficient3xPOW2(0.12308)
      clg_energy_input_ratio_f_of_flow.setMinimumValueofx(0.75918)
      clg_energy_input_ratio_f_of_flow.setMaximumValueofx(1.13877)

      clg_part_load_ratio = OpenStudio::Model::CurveQuadratic.new(model)
      clg_part_load_ratio.setCoefficient1Constant(0.77100)
      clg_part_load_ratio.setCoefficient2x(0.22900)
      clg_part_load_ratio.setCoefficient3xPOW2(0.0)
      clg_part_load_ratio.setMinimumValueofx(0.0)
      clg_part_load_ratio.setMaximumValueofx(1.0)

      clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model,
                                                                always_on,
                                                                clg_cap_f_of_temp,
                                                                clg_cap_f_of_flow,
                                                                clg_energy_input_ratio_f_of_temp,
                                                                clg_energy_input_ratio_f_of_flow,
                                                                clg_part_load_ratio)

      # set cop from user argument
      optionalDoubleCOP = OpenStudio::OptionalDouble.new(cooling_cop)
      clg_coil.setRatedCOP(optionalDoubleCOP)

      oa_controller = OpenStudio::Model::ControllerOutdoorAir.new(model)

      oa_system = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model,oa_controller)      

      # Add the components to the air loop
      # in order from closest to zone to furthest from zone
      supply_inlet_node = air_loop.supplyInletNode
      fan.addToNode(supply_inlet_node)
      htg_coil.addToNode(supply_inlet_node)      
      clg_coil.addToNode(supply_inlet_node)
      oa_system.addToNode(supply_inlet_node)
      
      # Add a setpoint manager single zone reheat to control the
      # supply air temperature based on the needs of this zone
      setpoint_mgr_single_zone_reheat = OpenStudio::Model::SetpointManagerSingleZoneReheat.new(model)
      setpoint_mgr_single_zone_reheat.setControlZone(zone)
      setpoint_mgr_single_zone_reheat.addToNode(air_loop.supplyOutletNode)

      # Create a diffuser and attach the zone/diffuser pair to the air loop
      diffuser = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model,always_on) 
      air_loop.addBranchForZone(zone,diffuser.to_StraightComponent)      

    end  
    
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddSys3PSZACNgrid.new.registerWithApplication