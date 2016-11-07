# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class CreateVariableSpeedRTU < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Create Variable Speed RTU"
  end

  # human readable description
  def description
    return "This measure examines the existing HVAC system(s) present in the current OpenStudio model. If a constant-speed system is found, the user can opt to have the measure replace that system with a variable-speed RTU. 'Variable speed' in this case means that the compressor will be operated using either two or four stages (user's choice). The user can choose between using a gas heating coil, or a direct-expansion (DX) heating coil. Additionally, the user is able to enter the EER (cooling) and COP (heating) values for each DX stage. This measure allows users to easily identify the impact of improved part-load efficiency."
  end

  # human readable description of modeling approach
  def modeler_description
    return "This measure loops through the existing airloops, looking for loops that have a constant speed fan. (Note that if an object such as an AirloopHVAC:UnitarySystem is present in the model, that the measure will NOT identify that loop as either constant- or variable-speed, since the fan is located inside the UnitarySystem object.) The user can designate which constant-speed airloop they'd like to apply the measure to, or opt to apply the measure to all airloops. The measure then replaces the supply components on the airloop with an AirloopHVAC:UnitarySystem object. Any DX coils added to the UnitarySystem object are of the type CoilCoolingDXMultiSpeed / CoilHeatingDXMultiSpeed, with the number of stages set to either two or four, depending on user input. If the user opts for a gas furnace, an 80% efficient CoilHeatingGas object is added. Fan properties (pressure rise and total efficiency) are transferred automatically from the existing (but deleted) constant speed fan to the new variable-speed fan. Currently, this measure is only applicable to the Standalone Retail DOE Prototype building model, but it has been structured to facilitate expansion to other models with a minimum of effort."
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #populate choice argument for air loops in the model
    air_loop_handles = OpenStudio::StringVector.new
    air_loop_display_names = OpenStudio::StringVector.new

    #putting air loop names into hash
    air_loop_args = model.getAirLoopHVACs
    air_loop_args_hash = {}
    air_loop_args.each do |air_loop_arg|
      air_loop_args_hash[air_loop_arg.name.to_s] = air_loop_arg
    end

    #looping through sorted hash of air loops
    air_loop_args_hash.sort.map do |air_loop_name,air_loop|
      air_loop.supplyComponents.each do |supply_comp|
        #find CAV fans
        if supply_comp.to_FanConstantVolume.is_initialized
          air_loop_handles << air_loop.handle.to_s
          air_loop_display_names << air_loop_name
        end
      end
    end

    #add building to string vector with air loops
    building = model.getBuilding
    air_loop_handles << building.handle.to_s
    air_loop_display_names << "*All CAV Air Loops*"

    #make an argument for air loops
    object = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("object", air_loop_handles, air_loop_display_names,true)
    object.setDisplayName("Choose an Air Loop to change from CAV to VAV.")
    object.setDefaultValue("*All CAV Air Loops*") #if no air loop is chosen this will run on all air loops
    args << object

    #make an argument for cooling type
    cooling_coil_options = OpenStudio::StringVector.new
    cooling_coil_options << "Two-Stage Compressor"
    cooling_coil_options << "Four-Stage Compressor"
    cooling_coil_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('cooling_coil_type', cooling_coil_options, true)
    cooling_coil_type.setDisplayName("Choose the type of cooling coil.")
    cooling_coil_type.setDefaultValue("Two-Stage Compressor")
    args << cooling_coil_type
    
    #make an argument for rated cooling coil EER
    rated_cc_eer = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('rated_cc_eer', false)
    rated_cc_eer.setDisplayName("Rated Cooling Coil EER")
    #rated_cc_eer.setDefaultValue(0.0)
    args << rated_cc_eer

    #make an argument for 75% cooling coil EER
    three_quarter_cc_eer = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('three_quarter_cc_eer', false)
    three_quarter_cc_eer.setDisplayName("Cooling Coil EER at 75% Capacity")
    #three_quarter_cc_eer.setDefaultValue(0.0)
    args << three_quarter_cc_eer

    #make an argument for 50% cooling coil EER
    half_cc_eer = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('half_cc_eer', false)
    half_cc_eer.setDisplayName("Cooling Coil EER at 50% Capacity")
    #half_cc_eer.setDefaultValue(0.0)
    args << half_cc_eer

    #make an argument for 25% cooling coil EER
    quarter_cc_eer = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('quarter_cc_eer', false)
    quarter_cc_eer.setDisplayName("Cooling Coil EER at 25% Capacity")
    #quarter_cc_eer.setDefaultValue(0.0)
    args << quarter_cc_eer

    #make an argument for heating type
    heating_coil_options = OpenStudio::StringVector.new
    heating_coil_options << "Gas Heating Coil"
    heating_coil_options << "Heat Pump"
    heating_coil_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('heating_coil_type', heating_coil_options, true)
    heating_coil_type.setDisplayName("Choose the type of heating coil.")
    heating_coil_type.setDefaultValue("Gas Heating Coil")
    args << heating_coil_type

    #make an argument for rated gas heating coil efficiency
    rated_hc_gas_efficiency = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('rated_hc_gas_efficiency', false)
    rated_hc_gas_efficiency.setDisplayName("Rated Gas Heating Coil Efficiency (0-1.00)")
    #rated_hc_gas_efficiency.setDefaultValue(0.0)
    args << rated_hc_gas_efficiency

    #make an argument for rated heating coil COP
    rated_hc_cop = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('rated_hc_cop', false)
    rated_hc_cop.setDisplayName("Rated Heating Coil COP")
    #rated_hc_cop.setDefaultValue(0.0)
    args << rated_hc_cop

    #make an argument for 75% heating coil COP
    three_quarter_hc_cop = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('three_quarter_hc_cop', false)
    three_quarter_hc_cop.setDisplayName("Heating Coil COP at 75% Capacity")
    #three_quarter_hc_cop.setDefaultValue(0.0)
    args << three_quarter_hc_cop

    #make an argument for 50% heating coil COP
    half_hc_cop = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('half_hc_cop', false)
    half_hc_cop.setDisplayName("Heating Coil COP at 50% Capacity")
    #half_hc_cop.setDefaultValue(0.0)
    args << half_hc_cop

    #make an argument for 25% heating coil COP
    quarter_hc_cop = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('quarter_hc_cop', false)
    quarter_hc_cop.setDisplayName("Heating Coil COP at 25% Capacity")
    #quarter_hc_cop.setDefaultValue(0.0)
    args << quarter_hc_cop
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    # Use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Assign the user inputs to variables
    object = runner.getOptionalWorkspaceObjectChoiceValue("object",user_arguments,model)
    cooling_coil_type = runner.getStringArgumentValue("cooling_coil_type",user_arguments)
    rated_cc_eer = runner.getOptionalDoubleArgumentValue("rated_cc_eer",user_arguments)
    three_quarter_cc_eer = runner.getOptionalDoubleArgumentValue("three_quarter_cc_eer",user_arguments)    
    half_cc_eer = runner.getOptionalDoubleArgumentValue("half_cc_eer",user_arguments)    
    quarter_cc_eer = runner.getOptionalDoubleArgumentValue("quarter_cc_eer",user_arguments)
    heating_coil_type = runner.getStringArgumentValue("heating_coil_type",user_arguments)
    rated_hc_gas_efficiency = runner.getOptionalDoubleArgumentValue("rated_hc_gas_efficiency",user_arguments)    
    rated_hc_cop = runner.getOptionalDoubleArgumentValue("rated_hc_cop",user_arguments)
    three_quarter_hc_cop = runner.getOptionalDoubleArgumentValue("three_quarter_hc_cop",user_arguments)
    half_hc_cop = runner.getOptionalDoubleArgumentValue("half_hc_cop",user_arguments)
    quarter_hc_cop = runner.getOptionalDoubleArgumentValue("quarter_hc_cop",user_arguments)
    
    if rated_cc_eer.empty?
      runner.registerError("User must enter a value for the rated capacity cooling coil EER.")
      return false
    elsif rated_cc_eer.to_f <= 0
      runner.registerError("Invalid rated cooling coil EER value of #{rated_cc_eer} entered. EER must be >0.")
      return false
    end

    if three_quarter_cc_eer.empty? && cooling_coil_type == "Four-Stage Compressor"
      runner.registerError("User must enter a value for 75% capacity cooling coil EER.")
      return false
    elsif three_quarter_cc_eer.to_f <= 0 && cooling_coil_type == "Four-Stage Compressor"
      runner.registerError("Invalid 75% capacity cooling coil EER value of #{three_quarter_cc_eer} entered. EER must be >0.")
      return false
    end

    if half_cc_eer.empty?
      runner.registerError("User must enter a value for 50% capacity cooling coil EER.")
      return false
    elsif half_cc_eer.to_f <= 0
      runner.registerError("Invalid 50% capacity cooling coil EER value of #{half_cc_eer} entered. EER must be >0.")
      return false
    end
 
     if quarter_cc_eer.empty? && cooling_coil_type == "Four-Stage Compressor"
      runner.registerError("User must enter a value for 25% capacity cooling coil EER.")
      return false
     elsif quarter_cc_eer.to_f <= 0 && cooling_coil_type == "Four-Stage Compressor"
       runner.registerError("Invalid 25% capacity cooling coil EER value of #{quarter_cc_eer} entered. EER must be >0.")
       return false
     end

    if rated_hc_gas_efficiency.empty? && heating_coil_type == "Gas Heating Coil"
      runner.registerError("User must enter a value for the rated gas heating coil efficiency.")
      return false
    elsif rated_hc_gas_efficiency.to_f <= 0 && heating_coil_type == "Gas Heating Coil"
      runner.registerError("Invalid rated heating coil efficiency value of #{rated_hc_gas_efficiency} entered. Value must be >0.")
      return false
    elsif rated_hc_gas_efficiency.to_f > 1 && heating_coil_type == "Gas Heating Coil"
      runner.registerError("Invalid rated heating coil efficiency value of #{rated_hc_gas_efficiency} entered. Value must be between 0 and 1.")
      return false
    end
    
    if rated_hc_cop.empty? && heating_coil_type == "Heat Pump"
      runner.registerError("User must enter a value for the rated heating coil COP.")
      return false
    elsif rated_hc_cop.to_f <= 0 && heating_coil_type == "Heat Pump"
      runner.registerError("Invalid rated heating coil COP value of #{rated_hc_cop} entered. COP must be >0.")
      return false
    end
    
    if three_quarter_hc_cop.empty? && heating_coil_type == "Heat Pump" && cooling_coil_type == "Four-Stage Compressor"
      runner.registerError("User must enter a value for 75% capacity heating coil COP.")
      return false
    elsif half_hc_cop.to_f <= 0 && heating_coil_type == "Heat Pump" && cooling_coil_type == "Four-Stage Compressor"
      runner.registerError("Invalid 75% capacity heating coil COP value of #{three_quarter_hc_cop} entered. COP must be >0.")
      return false
    end

    if half_hc_cop.empty? && heating_coil_type == "Heat Pump"
      runner.registerError("User must enter a value for 50% capacity heating coil COP.")
      return false
    elsif half_hc_cop.to_f <= 0 && heating_coil_type == "Heat Pump"
      runner.registerError("Invalid 50% capacity heating coil COP value of #{half_hc_cop} entered. COP must be >0.")
      return false
    end

    if quarter_hc_cop.empty? && heating_coil_type == "Heat Pump" && cooling_coil_type == "Four-Stage Compressor"
      runner.registerError("User must enter a value for 25% capacity heating coil COP.")
      return false
    elsif quarter_hc_cop.to_f <= 0 && heating_coil_type == "Heat Pump" && cooling_coil_type == "Four-Stage Compressor"
      runner.registerError("Invalid 25% capacity heating coil COP value of #{quarter_hc_cop} entered. COP must be >0.")
      return false
    end
    
    # Report initial condition of model
    initial_cav_airloops = 0
    initial_vav_airloops = 0
    model.getAirLoopHVACs.each do |air_loop|
      # Loop through all supply components on the airloop and find CAV and VAV fans
      air_loop.supplyComponents.each do |supply_comp|
        if supply_comp.to_FanConstantVolume.is_initialized
          initial_cav_airloops += 1
        elsif supply_comp.to_FanVariableVolume.is_initialized
          initial_vav_airloops += 1
        end
      end
    end
    runner.registerInitialCondition("The building started with #{initial_cav_airloops} CAV air loops and #{initial_vav_airloops} VAV air loops.")
    
    # Check the air loop selection
    apply_to_all_air_loops = false
    selected_airloop = nil
    if object.empty?
      handle = runner.getStringArgumentValue("object",user_arguments)
      if handle.empty?
        runner.registerError("No air loop was chosen.")
      else
        runner.registerError("The selected air loop with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not object.get.to_AirLoopHVAC.empty?
        selected_airloop = object.get.to_AirLoopHVAC.get
      elsif not object.get.to_Building.empty?
        apply_to_all_air_loops = true
      else
        runner.registerError("Script Error - argument not showing up as air loop.")
        return false
      end
    end  #end of if object.empty?
    
    # Add selected airloops to an array
    selected_airloops = [] 
    if apply_to_all_air_loops == true
       selected_airloops = model.getAirLoopHVACs
    else
      selected_airloops << selected_airloop
    end
    
    # Change CAV to VAV on the selected airloops, where applicable
    selected_airloops.each do |air_loop|
         
    changed_cav_to_vav = false
    
    #Make a new AirLoopHVAC:UnitarySystem object
    air_loop_hvac_unitary_system = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    
    # Find CAV fan and replace with VAV fan
    air_loop.supplyComponents.each do |supply_comp|
      if supply_comp.to_FanConstantVolume.is_initialized
         
	# Preserve characteristics of the original fan
        cav_fan = supply_comp.to_FanConstantVolume.get
        fan_pressure_rise = cav_fan.pressureRise
        fan_efficiency = cav_fan.fanEfficiency
        motor_efficiency = cav_fan.motorEfficiency
        fan_availability_schedule = cav_fan.availabilitySchedule
        
        # Get the previous and next components on the loop     
        prev_node = cav_fan.inletModelObject.get.to_Node.get        
        next_node = cav_fan.outletModelObject.get.to_Node.get
        
        # Make the new vav_fan and transfer existing parameters to it
        vav_fan = OpenStudio::Model::FanVariableVolume.new(model, model.alwaysOnDiscreteSchedule)
        vav_fan.setPressureRise(fan_pressure_rise)
        vav_fan.setFanEfficiency(fan_efficiency)
        vav_fan.setMotorEfficiency(motor_efficiency)
        vav_fan.setAvailabilitySchedule(fan_availability_schedule)
        
        # Remove the supply fan
        supply_comp.remove
        
        # Get back the remaining node
        remaining_node = nil
        if prev_node.outletModelObject.is_initialized
          remaining_node = prev_node
        elsif next_node.inletModelObject.is_initialized
          remaining_node = next_node
        end
           
        # Add a new AirLoopHVAC:UnitarySystem object to the node where the old fan was
        if remaining_node.nil?
          runner.registerError("Couldn't add the new AirLoopHVAC:UnitarySystem object to the loop after removing existing CAV fan.")
          return false
        else
          air_loop_hvac_unitary_system.addToNode(remaining_node)    
        end
        
        # Change the unitary system control type to setpoint to enable the VAV fan to ramp down.
        air_loop_hvac_unitary_system.setString(2,"Setpoint")
        
        # Add the VAV fan to the AirLoopHVAC:UnitarySystem object
        air_loop_hvac_unitary_system.setSupplyFan(vav_fan)
        
        # Set the AirLoopHVAC:UnitarySystem fan placement
        air_loop_hvac_unitary_system.setFanPlacement("BlowThrough")
        
        # Set the AirLoopHVAC:UnitarySystem Supply Air Fan Operating Mode Schedule
        air_loop_hvac_unitary_system.setSupplyAirFanOperatingModeSchedule(model.alwaysOnDiscreteSchedule)

        #let the user know that a change was made
        changed_cav_to_vav = true
        runner.registerInfo("AirLoop '#{air_loop.name}' was changed from CAV to VAV")
          
        end
      end #next supply component
      
      # Move on to the next air loop if no CAV to VAV change happened
      next if not changed_cav_to_vav == true

      #initialize COP variables to make available in both multi-speed heating and cooling coils
      low_speed_cop = nil
      high_speed_cop = nil
      
      # Move the cooling coil to the AirLoopHVAC:UnitarySystem object
      air_loop.supplyComponents.each do |supply_comp|
        if supply_comp.to_CoilCoolingDXTwoSpeed.is_initialized
          
          existing_cooling_coil = supply_comp.to_CoilCoolingDXTwoSpeed.get
          
          # Add a new cooling coil object
          if cooling_coil_type == "Two-Stage Compressor"
            new_cooling_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
            half_speed_cc_cop = half_cc_eer.to_f/3.412            
            new_cooling_coil_data_1 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
            new_cooling_coil_data_1.setGrossRatedCoolingCOP(half_speed_cc_cop.to_f)
            rated_speed_cc_cop = rated_cc_eer.to_f/3.412            
            new_cooling_coil_data_2 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
            new_cooling_coil_data_2.setGrossRatedCoolingCOP(rated_speed_cc_cop.to_f)
            new_cooling_coil.setFuelType("Electricity")
            new_cooling_coil.addStage(new_cooling_coil_data_1)
            new_cooling_coil.addStage(new_cooling_coil_data_2)
            air_loop_hvac_unitary_system.setCoolingCoil(new_cooling_coil)                 
          elsif cooling_coil_type == "Four-Stage Compressor"
            new_cooling_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
            quarter_speed_cc_cop = quarter_cc_eer.to_f/3.412
            new_cooling_coil_data_1 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
            new_cooling_coil_data_1.setGrossRatedCoolingCOP(quarter_speed_cc_cop.to_f)
            half_speed_cc_cop = half_cc_eer.to_f/3.412
            new_cooling_coil_data_2 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
            new_cooling_coil_data_2.setGrossRatedCoolingCOP(half_speed_cc_cop.to_f)
            three_quarter_speed_cc_cop = three_quarter_cc_eer.to_f/3.412
            new_cooling_coil_data_3 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
            new_cooling_coil_data_3.setGrossRatedCoolingCOP(three_quarter_speed_cc_cop.to_f)
            rated_speed_cc_cop = rated_cc_eer.to_f/3.412
            new_cooling_coil_data_4 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
            new_cooling_coil_data_4.setGrossRatedCoolingCOP(rated_speed_cc_cop.to_f)
            new_cooling_coil.setFuelType("Electricity")
            new_cooling_coil.addStage(new_cooling_coil_data_1)
            new_cooling_coil.addStage(new_cooling_coil_data_2)
            new_cooling_coil.addStage(new_cooling_coil_data_3)
            new_cooling_coil.addStage(new_cooling_coil_data_4)
            air_loop_hvac_unitary_system.setCoolingCoil(new_cooling_coil)                 
          end 
          
          # Remove the existing cooling coil.
          existing_cooling_coil.remove          
        end
      end #next supply component
      
      # Move the heating coil to the AirLoopHVAC:UnitarySystem object
      air_loop.supplyComponents.each do |supply_comp|  
        if supply_comp.to_CoilHeatingGas.is_initialized
          
          existing_heating_coil = supply_comp.to_CoilHeatingGas.get
          
          # Remove the existing heating coil.
          existing_heating_coil.remove

          # Add a new heating coil object
          if heating_coil_type == "Gas Heating Coil"
            new_heating_coil = OpenStudio::Model::CoilHeatingGas.new(model)                    
            new_heating_coil.setGasBurnerEfficiency(rated_hc_gas_efficiency.to_f)
            air_loop_hvac_unitary_system.setHeatingCoil(new_heating_coil)   
            
          elsif heating_coil_type == "Heat Pump" && cooling_coil_type == "Two-Stage Compressor"
            new_heating_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
            new_heating_coil_data_1 = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model)
            new_heating_coil_data_1.setGrossRatedHeatingCOP(half_hc_cop.to_f)
            new_heating_coil_data_2 = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model)
            new_heating_coil_data_2.setGrossRatedHeatingCOP(rated_hc_cop.to_f)
            new_heating_coil.setFuelType("Electricity")
            new_heating_coil.addStage(new_heating_coil_data_1)
            new_heating_coil.addStage(new_heating_coil_data_2)
            air_loop_hvac_unitary_system.setHeatingCoil(new_heating_coil)
          elsif heating_coil_type == "Heat Pump" && cooling_coil_type == "Four-Stage Compressor"
            new_heating_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
            new_heating_coil_data_1 = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model)
            new_heating_coil_data_1.setGrossRatedHeatingCOP(quarter_hc_cop.to_f)
            new_heating_coil_data_2 = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model)
            new_heating_coil_data_2.setGrossRatedHeatingCOP(half_hc_cop.to_f)
            new_heating_coil_data_3 = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model)
            new_heating_coil_data_3.setGrossRatedHeatingCOP(three_quarter_hc_cop.to_f)
            new_heating_coil_data_4 = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model)
            new_heating_coil_data_4.setGrossRatedHeatingCOP(rated_hc_cop.to_f)
            new_heating_coil.setFuelType("Electricity")
            new_heating_coil.addStage(new_heating_coil_data_1)
            new_heating_coil.addStage(new_heating_coil_data_2)
            new_heating_coil.addStage(new_heating_coil_data_3)
            new_heating_coil.addStage(new_heating_coil_data_4)
            air_loop_hvac_unitary_system.setHeatingCoil(new_heating_coil)
          end         
        end
         
      end #next supply component
      
      # Find the supply outlet node for the current AirLoop
      airloop_outlet_node = air_loop.supplyOutletNode
      
      # Identify if there is a setpoint manager on the AirLoop outlet node
      if airloop_outlet_node.setpointManagers.size >0
        setpoint_manager = airloop_outlet_node.setpointManagers[0]
        #runner.registerInfo("Setpoint manager on node '#{airloop_outlet_node.name}' is '#{setpoint_manager.name}'.")
      else
        runner.registerInfo("No setpoint manager on node '#{airloop_outlet_node.name}'.")
      end

      # Set the controlling zone location to the zone on the airloop
      air_loop.demandComponents.each do |demand_comp|
        if demand_comp.to_AirTerminalSingleDuctUncontrolled.is_initialized 
	
    	  terminal_obj = demand_comp.to_AirTerminalSingleDuctUncontrolled.get
    	   
          # Record the zone that the terminal unit is in.
          # If zone cannot be determined, skip to next demand component
          # and warn user that this the associated zone could not be found
          term_zone = nil
          model.getThermalZones.each do |zone|
            zone.equipment.each do |equip|
              if equip == terminal_obj
                term_zone = zone
              end
            end
          end
          if term_zone.nil?
            runner.registerWarning("Could not determine the zone for terminal '#{new_vav_terminal.name}', cannot assign to AirLoopHVAC:UnitarySystem object.")
            next
          else
            # Associate the zone with the AirLoopHVAC:UnitarySystem object
            air_loop_hvac_unitary_system.setControllingZoneorThermostatLocation(term_zone)
          end
        end  
      end
      
    end # Next selected airloop

    # Report final condition of model
    final_cav_airloops = 0
    final_vav_airloops = 0
    model.getAirLoopHVACs.each do |air_loop|
      # Loop through all supply components on the airloop and find CAV and VAV fans
      air_loop.supplyComponents.each do |supply_comp|
        if supply_comp.to_FanConstantVolume.is_initialized
          final_cav_airloops += 1
        elsif supply_comp.to_AirLoopHVACUnitarySystem.is_initialized
          final_vav_airloops += 1
        end
      end
    end
    runner.registerFinalCondition("The building finished with #{final_cav_airloops} constant-speed RTUs and #{final_vav_airloops} multi-speed RTUs.")
    
    if final_cav_airloops == initial_cav_airloops 
      runner.registerAsNotApplicable("This measure is not applicable; no variable speed RTUs were added.")
    end
   
    return true
 
  end #end the run method

end #end the measure

# register the measure to be used by the application
CreateVariableSpeedRTU.new.registerWithApplication
