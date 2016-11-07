# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AddVariableSpeedRTUControlLogic < OpenStudio::Ruleset::WorkspaceUserScript

  # human readable name
  def name
    return "Add Variable-Speed RTU Control Logic"
  end

  # human readable description
  def description
    return "This measure adds control logic for a variable-speed RTU to the model. The control logic is responsible for staging the fan in response to the amount of heating/cooling required. It is meant to be paired specifically with the Create Variable Speed RTU OpenStudio measure. Users enter the fan flow rate fractions for up to nine different stages: ventilation, up to four cooling stages, and up to four heating stages. The measure examines the amount of heating/cooling required at each time step, identifies which heating/cooling stage is required to supply that amount of heating/cooling, and modifies the fan flow accordingly. This measure allows users to identify the impact of different fan flow control strategies.

"
  end

  # human readable description of modeling approach
  def modeler_description
    return "This measure inserts EMS code for each airloop found to contain an AirLoopHVAC:UnitarySystem object. It is meant to be paired specifically with the Create Variable Speed RTU OpenStudio measure.

Users can select the fan mass flow fractions for up to nine stages (ventilation, two or four cooling, and two or four heating). The default control logic is as follows:
When the unit is ventilating (heating and cooling coil energy is zero), the fan flow rate is set to 40% of nominal.
When the unit is in heating (gas heating coil), the fan flow rate is set to 100% of nominal (not changeable).
When the unit is in staged heating/cooling, as indicated by the current heating/cooling coil energy rate divided by the nominal heating/cooling coil size, the fan flow rate is set to either 50/100% (two-stage compressor), or 40/50/75/100% (four-stage compressor).

When applied to staged coils, the measure assumes that all stages are of equal capacity. That is, for two-speed coils, that the compressors are split 50/50, and that in four-stage units, that each of the four compressors represents 25% of the total capacity.

The measure is set up so that a separate block of EMS code is inserted for each applicable airloop (i.e., the EMS text is not hard-coded)."
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for ventilation fan speed fraction
    vent_fan_speed = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('vent_fan_speed', false)
    vent_fan_speed.setDisplayName("Fan speed fraction during ventilation mode.")
    vent_fan_speed.setDefaultValue(0.4)
    args << vent_fan_speed

    #make an argument for stage_one cooling fan speed fraction
    stage_one_cooling_fan_speed = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('stage_one_cooling_fan_speed', false)
    stage_one_cooling_fan_speed.setDisplayName("Fan speed fraction during stage one DX cooling.")
    stage_one_cooling_fan_speed.setDefaultValue(0.4)
    args << stage_one_cooling_fan_speed

    #make an argument for stage_two cooling fan speed fraction
    stage_two_cooling_fan_speed = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('stage_two_cooling_fan_speed', false)
    stage_two_cooling_fan_speed.setDisplayName("Fan speed fraction during stage two DX cooling.")
    stage_two_cooling_fan_speed.setDefaultValue(0.5)
    args << stage_two_cooling_fan_speed

    #make an argument for stage_three cooling fan speed fraction
    stage_three_cooling_fan_speed = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('stage_three_cooling_fan_speed', false)
    stage_three_cooling_fan_speed.setDisplayName("Fan speed fraction during stage three DX cooling. Not used for two-speed systems.")
    stage_three_cooling_fan_speed.setDefaultValue(0.75)
    args << stage_three_cooling_fan_speed

    #make an argument for stage_four cooling fan speed fraction
    stage_four_cooling_fan_speed = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('stage_four_cooling_fan_speed', false)
    stage_four_cooling_fan_speed.setDisplayName("Fan speed fraction during stage four DX cooling. Not used for two-speed systems.")
    stage_four_cooling_fan_speed.setDefaultValue(1.0)
    args << stage_four_cooling_fan_speed

    #make an argument for stage_one heating fan speed fraction
    stage_one_heating_fan_speed = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('stage_one_heating_fan_speed', false)
    stage_one_heating_fan_speed.setDisplayName("Fan speed fraction during stage one DX heating.")
    stage_one_heating_fan_speed.setDefaultValue(0.4)
    args << stage_one_heating_fan_speed

    #make an argument for stage_two heating fan speed fraction
    stage_two_heating_fan_speed = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('stage_two_heating_fan_speed', false)
    stage_two_heating_fan_speed.setDisplayName("Fan speed fraction during stage two DX heating.")
    stage_two_heating_fan_speed.setDefaultValue(0.5)
    args << stage_two_heating_fan_speed

    #make an argument for stage_three heating fan speed fraction
    stage_three_heating_fan_speed = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('stage_three_heating_fan_speed', false)
    stage_three_heating_fan_speed.setDisplayName("Fan speed fraction during stage three DX heating. Not used for two-speed systems.")
    stage_three_heating_fan_speed.setDefaultValue(0.75)
    args << stage_three_heating_fan_speed

    #make an argument for stage_four heating fan speed fraction
    stage_four_heating_fan_speed = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('stage_four_heating_fan_speed', false)
    stage_four_heating_fan_speed.setDisplayName("Fan speed fraction during stage four DX heating. Not used for two-speed systems.")
    stage_four_heating_fan_speed.setDefaultValue(1.0)
    args << stage_four_heating_fan_speed
    
    return args
  end 

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # Assign the user inputs to variables
    vent_fan_speed = runner.getOptionalDoubleArgumentValue("vent_fan_speed",user_arguments)
    stage_one_cooling_fan_speed = runner.getOptionalDoubleArgumentValue("stage_one_cooling_fan_speed",user_arguments)    
    stage_two_cooling_fan_speed = runner.getOptionalDoubleArgumentValue("stage_two_cooling_fan_speed",user_arguments)    
    stage_three_cooling_fan_speed = runner.getOptionalDoubleArgumentValue("stage_three_cooling_fan_speed",user_arguments) 
    stage_four_cooling_fan_speed = runner.getOptionalDoubleArgumentValue("stage_four_cooling_fan_speed",user_arguments)
    stage_one_heating_fan_speed = runner.getOptionalDoubleArgumentValue("stage_one_heating_fan_speed",user_arguments)    
    stage_two_heating_fan_speed = runner.getOptionalDoubleArgumentValue("stage_two_heating_fan_speed",user_arguments)    
    stage_three_heating_fan_speed = runner.getOptionalDoubleArgumentValue("stage_three_heating_fan_speed",user_arguments) 
    stage_four_heating_fan_speed = runner.getOptionalDoubleArgumentValue("stage_four_heating_fan_speed",user_arguments)
    
    if vent_fan_speed.empty?
      runner.registerError("User must enter a value for fan speed fraction during ventilation.")
      return false
    elsif vent_fan_speed.to_f <= 0
      runner.registerError("Invalid ventilation fan speed fraction of #{vent_fan_speed} entered. Value must be >0 and <=1.")
      return false
    elsif vent_fan_speed.to_f > 1      
      runner.registerError("Invalid ventilation fan speed fraction of #{vent_fan_speed} entered. Value must be >0 and <=1.")
      return false
    end

    if stage_one_cooling_fan_speed.empty?
      runner.registerError("User must enter a value for fan speed fraction during first-stage cooling.")
      return false
    elsif stage_one_cooling_fan_speed.to_f <= 0
      runner.registerError("Invalid first-stage cooling fan speed fraction of #{stage_one_cooling_fan_speed} entered. Value must be >0 and <=1.")
      return false
    elsif stage_one_cooling_fan_speed.to_f > 1      
      runner.registerError("Invalid first-stage cooling fan speed fraction of #{stage_one_cooling_fan_speed} entered. Value must be >0 and <=1.")
      return false
    end

    if stage_two_cooling_fan_speed.empty?
      runner.registerError("User must enter a value for fan speed fraction during first-stage cooling.")
      return false
    elsif stage_two_cooling_fan_speed.to_f <= 0
      runner.registerError("Invalid first-stage cooling fan speed fraction of #{stage_two_cooling_fan_speed} entered. Value must be >0 and <=1.")
      return false
    elsif stage_two_cooling_fan_speed.to_f > 1      
      runner.registerError("Invalid first-stage cooling fan speed fraction of #{stage_two_cooling_fan_speed} entered. Value must be >0 and <=1.")
      return false
    end

    if stage_three_cooling_fan_speed.empty?
      runner.registerError("User must enter a value for fan speed fraction during first-stage cooling.")
      return false
    elsif stage_three_cooling_fan_speed.to_f <= 0
      runner.registerError("Invalid first-stage cooling fan speed fraction of #{stage_three_cooling_fan_speed} entered. Value must be >0 and <=1.")
      return false
    elsif stage_three_cooling_fan_speed.to_f > 1      
      runner.registerError("Invalid first-stage cooling fan speed fraction of #{stage_three_cooling_fan_speed} entered. Value must be >0 and <=1.")
      return false
    end

    if stage_four_cooling_fan_speed.empty?
      runner.registerError("User must enter a value for fan speed fraction during first-stage cooling.")
      return false
    elsif stage_four_cooling_fan_speed.to_f <= 0
      runner.registerError("Invalid first-stage cooling fan speed fraction of #{stage_four_cooling_fan_speed} entered. Value must be >0 and <=1.")
      return false
    elsif stage_four_cooling_fan_speed.to_f > 1      
      runner.registerError("Invalid first-stage cooling fan speed fraction of #{stage_four_cooling_fan_speed} entered. Value must be >0 and <=1.")
      return false
    end

    if stage_one_heating_fan_speed.empty?
      runner.registerError("User must enter a value for fan speed fraction during first-stage heating.")
      return false
    elsif stage_one_heating_fan_speed.to_f <= 0
      runner.registerError("Invalid first-stage heating fan speed fraction of #{stage_one_heating_fan_speed} entered. Value must be >0 and <=1.")
      return false
    elsif stage_one_heating_fan_speed.to_f > 1      
      runner.registerError("Invalid first-stage heating fan speed fraction of #{stage_one_heating_fan_speed} entered. Value must be >0 and <=1.")
      return false
    end

    if stage_two_heating_fan_speed.empty?
      runner.registerError("User must enter a value for fan speed fraction during first-stage heating.")
      return false
    elsif stage_two_heating_fan_speed.to_f <= 0
      runner.registerError("Invalid first-stage heating fan speed fraction of #{stage_two_heating_fan_speed} entered. Value must be >0 and <=1.")
      return false
    elsif stage_two_heating_fan_speed.to_f > 1      
      runner.registerError("Invalid first-stage heating fan speed fraction of #{stage_two_heating_fan_speed} entered. Value must be >0 and <=1.")
      return false
    end

    if stage_three_heating_fan_speed.empty?
      runner.registerError("User must enter a value for fan speed fraction during first-stage heating.")
      return false
    elsif stage_three_heating_fan_speed.to_f <= 0
      runner.registerError("Invalid first-stage heating fan speed fraction of #{stage_three_heating_fan_speed} entered. Value must be >0 and <=1.")
      return false
    elsif stage_three_heating_fan_speed.to_f > 1      
      runner.registerError("Invalid first-stage heating fan speed fraction of #{stage_three_heating_fan_speed} entered. Value must be >0 and <=1.")
      return false
    end

    if stage_four_heating_fan_speed.empty?
      runner.registerError("User must enter a value for fan speed fraction during first-stage heating.")
      return false
    elsif stage_four_heating_fan_speed.to_f <= 0
      runner.registerError("Invalid first-stage heating fan speed fraction of #{stage_four_heating_fan_speed} entered. Value must be >0 and <=1.")
      return false
    elsif stage_four_heating_fan_speed.to_f > 1      
      runner.registerError("Invalid first-stage heating fan speed fraction of #{stage_four_heating_fan_speed} entered. Value must be >0 and <=1.")
      return false
    end

    ems_strings = []   
    selected_terminal_units = []
    revised_terminal_unit_name = nil
    number_of_cooling_speeds = nil
    selected_terminal_units = workspace.getObjectsByType("AirTerminal:SingleDuct:Uncontrolled".to_IddObjectType)  
    selected_terminal_units.each do |terminal_unit| 
      terminal_unit_name = terminal_unit.getString(0,true).get
      revised_terminal_unit_name = terminal_unit_name.gsub(' ','_')
      revised_terminal_unit_name = revised_terminal_unit_name.gsub('-','_')
      
      ems_strings << "    
	EnergyManagementSystem:Actuator,
	  #{revised_terminal_unit_name}_mass_flow_actuator,     !- Name
	  #{terminal_unit_name},                                !- Actuated Component Unique Name
	  AirTerminal:SingleDuct:Uncontrolled,                      !- Actuated Component Type
	  Mass Flow Rate;                         !- Actuated Component Control Type
	  "
    end
    
    selected_cooling_coils = workspace.getObjectsByType("Coil:Cooling:DX:MultiSpeed".to_IddObjectType)  
    # This will only return the number of speeds for the last coil in the array, but is fine for now. All coils should be the same type.
    selected_cooling_coils.each do |cooling_coil| 
      number_of_cooling_speeds = cooling_coil.getString(16,true).get
    end
    
    selected_airloops = [] 
    selected_airloops = workspace.getObjectsByType("AirLoopHVAC:UnitarySystem".to_IddObjectType)
    selected_airloops.each do |air_loop|
      air_loop_name = air_loop.getString(0, true).get
      air_loop_zone_name = air_loop.getString(2, true).get
      air_loop_outlet_node = air_loop.getString(6, true).get
      air_loop_fan = air_loop.getString(8, true).get
      air_loop_heating_coil_type = air_loop.getString(11, true).get
      air_loop_heating_coil = air_loop.getString(12, true).get   
      air_loop_cooling_coil_type = air_loop.getString(14, true).get
      air_loop_cooling_coil = air_loop.getString(15, true).get
      #air_loop_sup_heating_coil_type = air_loop.getString(19, true).get
      #air_loop_sup_heating_coil = air_loop.getString(20, true).get
      revised_air_loop_name = air_loop_name.gsub(' ','_')
      revised_zone_name = air_loop_zone_name.gsub(' ','_')
      revised_fan_name = air_loop_fan.gsub(' ','_')
      revised_cc_name = air_loop_cooling_coil.gsub(' ','_')
      revised_hc_name = air_loop_heating_coil.gsub(' ','_')

      selected_heating_coils = []
      selected_heating_coil_outlet_node = ""
      selected_heating_coils = workspace.getObjectsByType("#{air_loop_heating_coil_type}".to_IddObjectType)      
      selected_heating_coils.each do |heating_coil|
        hc_name_test = heating_coil.getString(0, true).get
        puts "#{hc_name_test}"
        if "#{hc_name_test}.to_s" == "#{air_loop_heating_coil}.to_s"
          if "#{air_loop_heating_coil_type}" == "Coil:Heating:Gas"
            selected_heating_coil_outlet_node = heating_coil.getString(5, true).get
          elsif "#{air_loop_heating_coil_type}" == "Coil:Heating:DX:MultiSpeed"
            selected_heating_coil_outlet_node = heating_coil.getString(3, true).get
          end
        end
      end

      selected_cooling_coils = []
      selected_cooling_coil_outlet_node = ""
      selected_cooling_coils = workspace.getObjectsByType("#{air_loop_cooling_coil_type}".to_IddObjectType)      
      selected_cooling_coils.each do |cooling_coil|
        cc_name_test = cooling_coil.getString(0, true).get
        if "#{cc_name_test}.to_s" == "#{air_loop_cooling_coil}.to_s"
          selected_cooling_coil_outlet_node = cooling_coil.getString(3, true).get
        end
      end

      # Add Nodelist to the code to enable proper control
      ems_strings << "
      NodeList,
      #{revised_air_loop_name}_NodeList,
      #{selected_cooling_coil_outlet_node},
      #{selected_heating_coil_outlet_node};
      "
      
      # Find the proper setpoint manager so that we can assign the newly created NodeList object to it
      selected_setpoint_manager = []
      selected_setpoint_manager = workspace.getObjectsByType("SetpointManager:SingleZone:Reheat".to_IddObjectType)
      selected_setpoint_manager.each do |setpoint_manager|
        setpoint_manager_setpoint_node_name = setpoint_manager.getString(7, true).get
        if "#{selected_heating_coil_outlet_node}" == setpoint_manager_setpoint_node_name
          puts "#{selected_heating_coil_outlet_node}"
          setpoint_manager.setString(7, "#{revised_air_loop_name}_NodeList")
        end
      end
          
      # Add EMS code to the model
      ems_strings << "    
      EnergyManagementSystem:Sensor,
	#{revised_cc_name}_cooling_rate,             !- Name
	#{air_loop_cooling_coil},                  !- Output:Variable or Output:Meter Index Key Name
	Cooling Coil Total Cooling Rate;              !- Output:Variable or Output:Meter Name
	"    

      # Add EMS code to the model
      ems_strings << "    
      EnergyManagementSystem:InternalVariable,
        #{revised_fan_name}_mass_flow_rate,
        #{air_loop_fan},
        Fan Maximum Mass Flow Rate;
	"

      # Add EMS code to the model
      ems_strings << "    
      EnergyManagementSystem:InternalVariable,
        #{revised_air_loop_name}_heating_cap,
        #{air_loop_name},
        Unitary HVAC Design Heating Capacity;
	"

      # Add EMS code to the model
      ems_strings << "    
      EnergyManagementSystem:InternalVariable,
        #{revised_air_loop_name}_cooling_cap,
        #{air_loop_name},
        Unitary HVAC Design Cooling Capacity;
	"
      
      # Add EMS code to the model
      ems_strings << "    
      EnergyManagementSystem:Actuator,
	#{revised_fan_name}_mass_flow_actuator,                           !- Name
	#{air_loop_fan},                                !- Actuated Component Unique Name
	Fan,                      !- Actuated Component Type
	Fan Air Mass Flow Rate;                         !- Actuated Component Control Type
	"

      # Add EMS code to the model
      ems_strings << "
      EnergyManagementSystem:Program,
        #{revised_zone_name}_Initialization_Prgm,                          !- Name    
      	SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = null,
      	SET #{revised_fan_name}_mass_flow_actuator = null; !- Added for test of two actuator code
      	"

      # Add EMS code to the model
      ems_strings << " 
      EnergyManagementSystem:Program,
	#{revised_zone_name}_Vent_Ctrl_Prgm,                          !- Name    
	SET Current_Cooling_Capacity = #{revised_cc_name}_cooling_rate,
	SET Current_Heating_Capacity = #{revised_hc_name}_heating_rate,
	SET Design_Fan_Mass_Flow = #{revised_fan_name}_mass_flow_rate,
	IF (Current_Cooling_Capacity == 0 && Current_Heating_Capacity == 0),
	  SET Timestep_Fan_Mass_Flow = (#{vent_fan_speed} * Design_Fan_Mass_Flow),
	  SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	  SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	ENDIF;	
	"

      if number_of_cooling_speeds == "2"
        # Add EMS code to the model      
        ems_strings << "    
	EnergyManagementSystem:Program,
	  #{revised_zone_name}_CC_Ctrl_Prgm,                          !- Name    
	  SET Design_CC_Capacity = #{revised_air_loop_name}_cooling_cap,
	  SET Current_Cooling_Capacity = #{revised_cc_name}_cooling_rate,
	  SET Design_Fan_Mass_Flow = #{revised_fan_name}_mass_flow_rate,
	  IF (Current_Cooling_Capacity > 0 && Current_Cooling_Capacity <= (0.5 * Design_CC_Capacity)),
	    SET Timestep_Fan_Mass_Flow = (#{stage_one_cooling_fan_speed} * Design_Fan_Mass_Flow),
	    SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	    SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	  ELSEIF Current_Cooling_Capacity > (0.5 * Design_CC_Capacity),
	    SET Timestep_Fan_Mass_Flow = (#{stage_two_cooling_fan_speed} * Design_Fan_Mass_Flow),
	    SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	    SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	  ENDIF;
	  "
	    
      elsif number_of_cooling_speeds == "4"
        # Add EMS code to the model
	ems_strings << " 
	EnergyManagementSystem:Program,
	  #{revised_zone_name}_CC_Ctrl_Prgm,                          !- Name    
	  SET Design_CC_Capacity = #{revised_air_loop_name}_cooling_cap,
	  SET Current_Cooling_Capacity = #{revised_cc_name}_cooling_rate,
	  SET Design_Fan_Mass_Flow = #{revised_fan_name}_mass_flow_rate,
	  IF (Current_Cooling_Capacity > 0 && Current_Cooling_Capacity <= (0.25 * Design_CC_Capacity)),
	    SET Timestep_Fan_Mass_Flow = (#{stage_one_cooling_fan_speed} * Design_Fan_Mass_Flow),
	    SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	    SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	  ELSEIF (Current_Cooling_Capacity > (0.25 * Design_CC_Capacity) && Current_Cooling_Capacity <= (0.50 * Design_CC_Capacity)),
	    SET Timestep_Fan_Mass_Flow = (#{stage_two_cooling_fan_speed} * Design_Fan_Mass_Flow),
	    SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	    SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	  ELSEIF (Current_Cooling_Capacity > (0.50 * Design_CC_Capacity) && Current_Cooling_Capacity <= (0.75 * Design_CC_Capacity)),
	    SET Timestep_Fan_Mass_Flow = (#{stage_three_cooling_fan_speed} * Design_Fan_Mass_Flow),
	    SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	    SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	  ELSEIF Current_Cooling_Capacity > (0.75 * Design_CC_Capacity),
	    SET Timestep_Fan_Mass_Flow = (#{stage_four_cooling_fan_speed} * Design_Fan_Mass_Flow),
	    SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	    SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	  ENDIF;
	  "
      end

      if air_loop_heating_coil_type == "Coil:Heating:Gas"
          
        # Add EMS code to the model
        ems_strings << "    
	EnergyManagementSystem:Sensor,
	  #{revised_hc_name}_heating_rate,             !- Name
	  #{air_loop_heating_coil},                  !- Output:Variable or Output:Meter Index Key Name
	  Heating Coil Air Heating Rate;              !- Output:Variable or Output:Meter Name
	  "

        # Add EMS code to the model	  
        ems_strings << " 
        EnergyManagementSystem:Program,
	  #{revised_zone_name}_HC_Ctrl_Prgm,                          !- Name    
	  SET Current_Heating_Capacity = #{revised_hc_name}_heating_rate,
	  SET Design_Fan_Mass_Flow = #{revised_fan_name}_mass_flow_rate,
	  IF Current_Heating_Capacity > 0,
	    SET Timestep_Fan_Mass_Flow = Design_Fan_Mass_Flow,
	    SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	    SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	  ENDIF;
	  "
	    
      elsif air_loop_heating_coil_type == "Coil:Heating:DX:MultiSpeed"
        
        # Add EMS code to the model
        ems_strings << "    
	EnergyManagementSystem:Sensor,
	  #{revised_hc_name}_heating_rate,             !- Name
	  #{air_loop_heating_coil},                  !- Output:Variable or Output:Meter Index Key Name
	  Heating Coil Total Heating Rate;              !- Output:Variable or Output:Meter Name
	  "

        if number_of_cooling_speeds == "2"
          # Add EMS code to the model	  
          ems_strings << " 
          EnergyManagementSystem:Program,
	    #{revised_zone_name}_HC_Ctrl_Prgm,                          !- Name    
	    SET Design_HC_Capacity = #{revised_air_loop_name}_cooling_cap,
	    SET Current_Heating_Capacity = #{revised_hc_name}_heating_rate,
	    SET Design_Fan_Mass_Flow = #{revised_fan_name}_mass_flow_rate,
	    IF (Current_Heating_Capacity > 0 && Current_Heating_Capacity <= (0.50 * Design_HC_Capacity)),
	      SET Timestep_Fan_Mass_Flow = (#{stage_one_heating_fan_speed} * Design_Fan_Mass_Flow),
	      SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	      SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	    ELSEIF Current_Heating_Capacity > (0.50 * Design_HC_Capacity),
	      SET Timestep_Fan_Mass_Flow = (#{stage_two_heating_fan_speed} * Design_Fan_Mass_Flow),
	      SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	      SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	    ENDIF;
	    "
	    
        elsif number_of_cooling_speeds == "4"
          # Add EMS code to the model	  
          ems_strings << " 
          EnergyManagementSystem:Program,
	    #{revised_zone_name}_HC_Ctrl_Prgm,                          !- Name    
	    SET Design_HC_Capacity = #{revised_air_loop_name}_cooling_cap,
	    SET Current_Heating_Capacity = #{revised_hc_name}_heating_rate,
	    SET Design_Fan_Mass_Flow = #{revised_fan_name}_mass_flow_rate,
	    IF (Current_Heating_Capacity > 0 && Current_Heating_Capacity <= (0.25 * Design_HC_Capacity)),
	      SET Timestep_Fan_Mass_Flow = (#{stage_one_heating_fan_speed} * Design_Fan_Mass_Flow),
	      SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	      SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	    ELSEIF (Current_Heating_Capacity > (0.25 * HC_Design_Capacity) && Current_Heating_Capacity <= (0.50 * Design_HC_Capacity)),
	      SET Timestep_Fan_Mass_Flow = (#{stage_two_heating_fan_speed} * Design_Fan_Mass_Flow),
	      SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	      SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	    ELSEIF (Current_Heating_Capacity > (0.50 * HC_Design_Capacity) && Current_Heating_Capacity <= (0.75 * Design_HC_Capacity)),
	      SET Timestep_Fan_Mass_Flow = (#{stage_three_heating_fan_speed} * Design_Fan_Mass_Flow),
	      SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	      SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	    ELSEIF Current_Heating_Capacity > (0.75 * HC_Design_Capacity),
	      SET Timestep_Fan_Mass_Flow = (#{stage_four_heating_fan_speed} * Design_Fan_Mass_Flow),
	      SET #{revised_zone_name}_PSZ_AC_Diffuser_mass_flow_actuator = Timestep_Fan_Mass_Flow,
	      SET #{revised_fan_name}_mass_flow_actuator = Timestep_Fan_Mass_Flow, !- Added for test of two actuator code
	    ENDIF;
	    "
	end
      end

      # Add EMS code to the model	  
      ems_strings << "    
      EnergyManagementSystem:ProgramCallingManager,
	#{revised_zone_name} Control Program,                    !- Name
	AfterPredictorBeforeHVACManagers,  !- EnergyPlus Model Calling Point
	#{revised_zone_name}_Initialization_Prgm,                          !- Program Name 1
	#{revised_zone_name}_Vent_Ctrl_Prgm,                          !- Program Name 2
	#{revised_zone_name}_CC_Ctrl_Prgm,                          !- Program Name 4
	#{revised_zone_name}_HC_Ctrl_Prgm;                          !- Program Name 3
	"

    end # Next airloop

    # Add EMS code to the model
    ems_strings << "   
      Output:EnergyManagementSystem,
      None,
      None,
      None;
      "

    ems_strings.each do |ems_string|
      idfObject = OpenStudio::IdfObject::load(ems_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
    end
    
  return true
 
end #end the run method

end #end the measure

# register the measure to be used by the application
AddVariableSpeedRTUControlLogic.new.registerWithApplication
