#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SetAirCooledUnitaryHeatPumpCOP < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetAirCooledUnitaryHeatPumpCOP"
  end
  
  #define supporting methods for both arguments and runner
  def isUnitaryHP(supply_components)
	is_unitary_hp = false
	
	# loop through all the supply components on an air loop
	has_dx_coil = false
	has_heating_coil = false	
	
	supply_components.each do |supply_component|
		#get unitary heat pump system
		unitary_hp = supply_component.to_AirLoopHVACUnitaryHeatPumpAirToAir
		if not unitary_hp.empty?
			is_unitary_hp = true		
		end
		
		dx_coil_single_speed = supply_component.to_CoilCoolingDXSingleSpeed
		dx_coil_two_speed = supply_component.to_CoilCoolingDXTwoSpeed
		heating_coil = supply_component.to_CoilHeatingDXSingleSpeed
		
		if (not dx_coil_single_speed.empty?) or (not dx_coil_two_speed.empty?)
			has_dx_coil = true
		end
		
		if (not heating_coil.empty?)
			has_heating_coil = true
		end		
	end
	
	if has_heating_coil and has_dx_coil
		is_unitary_hp = true
	end
	
	return is_unitary_hp
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	# Determine how many unitary HP in model
	unitary_hp_handles = OpenStudio::StringVector.new
	unitary_hp_display_names = OpenStudio::StringVector.new
	
	# Get/show all unitary HP from current loaded model.
	unitary_hp_handles << '0'
	unitary_hp_display_names <<'*All heat pumps *'
	
	i_unitary_hp = 1
	model.getAirLoopHVACs.each do |air_loop|
		supply_components = air_loop.supplyComponents	
		if isUnitaryHP(supply_components)
			unitary_hp_handles << i_unitary_hp.to_s
			unitary_hp_display_names << air_loop.name.to_s			
			i_unitary_hp = i_unitary_hp + 1			
		end		
	end
	
	if i_unitary_hp == 1
	    info_widget = OpenStudio::Ruleset::OSArgument::makeBoolArgument("info_widget", true)
		info_widget.setDisplayName("!!!!*** This Measure is not Applicable to loaded Model. Read the description and choose an appropriate baseline model. ***!!!!")
		info_widget.setDefaultValue(true)
		args << info_widget	
		return args
	end
	
    unitary_hp_widget = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("unitary_hp_widget", unitary_hp_handles, unitary_hp_display_names,true)
    unitary_hp_widget.setDisplayName("Apply the measure to ")
	unitary_hp_widget.setDefaultValue(unitary_hp_display_names[0])
    args << unitary_hp_widget	
	
	# Add a check box for specify Rated COP
	input_option_manual = OpenStudio::Ruleset::OSArgument::makeBoolArgument("input_option_manual", false)
	input_option_manual.setDisplayName("Option 1, set rated COP to a user defined value")
	input_option_manual.setDefaultValue(false)
	args << input_option_manual

	# Rated COP [W/W]
	rated_heating_COP = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("rated_heating_COP")
	rated_heating_COP.setDisplayName("Rated heating COP [W/W]")
	rated_heating_COP.setDefaultValue(3)	
	args << rated_heating_COP	
	
	rated_cooling_COP = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("rated_cooling_COP")
	rated_cooling_COP.setDisplayName("Rated cooling COP [W/W]")
	rated_cooling_COP.setDefaultValue(3)	
	args << rated_cooling_COP	
	
	input_option_standard = OpenStudio::Ruleset::OSArgument::makeBoolArgument("input_option_standard", false)
	input_option_standard.setDisplayName("Option 2, set rated COP based on ASHRAE Standard 90.1 requirement")
	input_option_standard.setDefaultValue(false)	
	args << input_option_standard
	
	# Estimated total cooling capacity [W] (default of blank)	
	total_cooling_capacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("total_cooling_capacity", false)
	total_cooling_capacity.setDisplayName("Estimated total cooling capacity [W] (Only used to lookup 90.1 requirements, not used to change model capacity)")
	args << total_cooling_capacity	
		
	# Show ASHRAE standards
	standards_handles = OpenStudio::StringVector.new
	standards_display_names = OpenStudio::StringVector.new
	
	standards_handles << '0'
	standards_handles << '1'
	standards_handles << '2'
	standards_handles << '3'
	standards_handles << '4'
	
	standards_display_names << ''
	standards_display_names << 'ASHRAE 90.1-2004'
	standards_display_names << 'ASHRAE 90.1-2007'
	standards_display_names << 'ASHRAE 90.1-2010'
	standards_display_names << 'ASHRAE 90.1-2013'	
	
    standards_widget = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("standards_widget", standards_handles, standards_display_names,false)
    standards_widget.setDisplayName("ASHRAE Standard 90.1")
	standards_widget.setDefaultValue(standards_display_names[0])
    args << standards_widget	    
		
    return args
  end #end the arguments method

 #define supporting methods
  def getCOPCoolingMode(standard, capacity)
	min_efficiency = 0
	standard_list = ["ASHRAE 90.1-2004","ASHRAE 90.1-2007","ASHRAE 90.1-2010","ASHRAE 90.1-2013"]
	if (not standard_list.include? standard)
		return nil
	end
	
	if standard == standard_list[0]
		if capacity < 19037
			min_efficiency = 3.69
		elsif capacity < 39538
			min_efficiency = 3.5
		elsif capacity < 70290
			min_efficiency = 3.23	
		else
			min_efficiency = 3.13
		end
	else
		if capacity < 19037
			min_efficiency = 3.91
		elsif capacity < 39538
			min_efficiency = 3.8
		elsif capacity < 70290
			min_efficiency = 3.67	
		else
			min_efficiency = 3.3
		end		
	end		
	return min_efficiency 		
  end
  
  def getCOPHeatingMode(standard, capacity)
	min_efficiency = 0
	standard_list = ["ASHRAE 90.1-2004","ASHRAE 90.1-2007","ASHRAE 90.1-2010","ASHRAE 90.1-2013"]
	if (not standard_list.include? standard)
		return nil
	end
													
	if standard == standard_list[0]
		if capacity < 19037
			min_efficiency = 3.22
		elsif capacity < 39538
			min_efficiency = 3.2
		else
			min_efficiency = 3.1
		end

	elsif standard == standard_list[1]
		if capacity < 19037
			min_efficiency = 3.3
		elsif capacity < 39538
			min_efficiency = 3.3
		else
			min_efficiency = 3.2
		end
	elsif standard == standard_list[2]
		if capacity < 19037
			min_efficiency = 3.3
		elsif capacity < 39538
			min_efficiency = 3.3
		else
			min_efficiency = 3.2
		end	
	elsif standard == standard_list[3]
		if capacity < 19037
			min_efficiency = 3.36
		elsif capacity < 39538
			min_efficiency = 3.3
		else
			min_efficiency = 3.2
		end		
	end				
	return min_efficiency 		
  end

  def setCoolingSingleSpeedCOP(cooling_coil_single_speed, rated_cooling_COP, runner)
	unit = cooling_coil_single_speed.get
	unit_name = unit.name
	old_COP = unit.getRatedCOP()
	runner.registerInfo("Initial: The rated COP of the #{unit_name} was #{old_COP}.")
	
	if old_COP.empty?					
		runner.registerInfo("Initial: The rated COP of the #{unit_name} was not set.")
	else
		runner.registerInfo("Initial: The rated COP of the #{unit_name} was #{old_COP}.")
	end
	optional_variable = OpenStudio::OptionalDouble.new(rated_cooling_COP)
	unit.setRatedCOP(optional_variable)
	runner.registerInfo("Final: The rated COP of the #{unit_name} was set to be #{rated_cooling_COP}.")
	return
  end
  
  def setCoolingTwoSpeedCOP(cooling_coil_two_speed, rated_cooling_COP, runner)
	unit = cooling_coil_two_speed.get
	unit_name = unit.name
	
	old_COP_low = unit.getRatedLowSpeedCOP()
	old_COP_high = unit.getRatedHighSpeedCOP()
	
	if old_COP_low.empty?					
		runner.registerInfo("Initial: The rated Low Speed COP of the #{unit_name} was not set.")
	else
		runner.registerInfo("Initial: The rated Low Speed COP of the #{unit_name} was #{old_COP_low}.")
	end
	if old_COP_high.empty?					
		runner.registerInfo("Initial: The rated High Speed COP of the #{unit_name} was not set.")
	else
		runner.registerInfo("Initial: The rated High Speed COP of the #{unit_name} was #{old_COP_high}.")
	end					
	unit.setRatedLowSpeedCOP(rated_cooling_COP)
	unit.setRatedHighSpeedCOP(rated_cooling_COP)
	runner.registerInfo("Final: The rated Low Speed COP of the #{unit_name} was set to be #{rated_cooling_COP}.")
	runner.registerInfo("Final: The rated High Speed COP of the #{unit_name} was set to be #{rated_cooling_COP}.")	    
	
	return
  end
  
  def setHeatingSingleSpeedCOP(dx_heating_coil, rated_heating_COP, runner)
	unit = dx_heating_coil.get
	unit_name = unit.name
	old_COP = unit.ratedCOP
	
	if old_COP.nil?					
		runner.registerInfo("Initial: The rated COP of the #{unit_name} was not set.")
	else
		runner.registerInfo("Initial: The rated COP of the #{unit_name} was #{old_COP}.")
	end
	#optional_variable = OpenStudio::OptionalDouble.new(rated_heating_COP)
	#unit.setRatedCOP(optional_variable)
	unit.setRatedCOP(rated_heating_COP)
	runner.registerInfo("Final: The rated COP of the #{unit_name} was set to be #{rated_heating_COP}.")	    
    return 
  end
  
  def changeRatedCOP(model, unitary_hp_index, rated_heating_COP, rated_cooling_COP, runner)
	i_unitary_hp = 0			

	#loop through each air loop to find burner
	model.getAirLoopHVACs.each do |air_loop|
		supply_components = air_loop.supplyComponents	
		if isUnitaryHP(supply_components)
			i_unitary_hp = i_unitary_hp + 1
		else
			next
		end	

		if unitary_hp_index != 0 and (unitary_hp_index != i_unitary_hp)
			next
		end
		
		has_AirLoopHVACUnitaryHeatPumpAirToAir = false
		supply_components.each do |supply_component|
			unitary_hp = supply_component.to_AirLoopHVACUnitaryHeatPumpAirToAir
			if not unitary_hp.empty?
				has_AirLoopHVACUnitaryHeatPumpAirToAir = true
				
				unit = unitary_hp.get
				dx_cooling = unit.coolingCoil
				dx_heating = unit.heatingCoil
				#search dx coils belonging to the unitary system
				#first dx cooling coils
				
				#if the cooling coil is a CoilCoolingDXSingleSpeed
				cooling_coil_single_speed = dx_cooling.to_CoilCoolingDXSingleSpeed					
				if not cooling_coil_single_speed.empty?
					setCoolingSingleSpeedCOP(cooling_coil_single_speed, rated_cooling_COP, runner)
				end	
				
				#if the cooling coil is a CoilCoolingDXTwoSpeed
				cooling_coil_two_speed = dx_cooling.to_CoilCoolingDXTwoSpeed
				if not cooling_coil_two_speed.empty?					
					setCoolingTwoSpeedCOP(cooling_coil_two_speed, rated_cooling_COP, runner)
				end	

				# for dx heating coil
				heating_coil_single_speed = dx_heating.to_CoilHeatingDXSingleSpeed
				if not heating_coil_single_speed.empty?
					setHeatingSingleSpeedCOP(heating_coil_single_speed, rated_heating_COP, runner)
				end
				
				break
			end	
		end
		
		# Another way to check for heat pump coils
		if not has_AirLoopHVACUnitaryHeatPumpAirToAir
			supply_components.each do |supply_component|
				cooling_coil_single_speed = supply_component.to_CoilCoolingDXSingleSpeed
				cooling_coil_two_speed = supply_component.to_CoilCoolingDXTwoSpeed
				heating_coil_single_speed = supply_component.to_CoilHeatingDXSingleSpeed
				
				# for CoilCoolingDXSingleSpeed
				if not cooling_coil_single_speed.empty?
					setCoolingSingleSpeedCOP(cooling_coil_single_speed, rated_cooling_COP, runner)				
				end
				# for CoilCoolingDXTwoSpeed
				if not cooling_coil_two_speed.empty?
					setCoolingTwoSpeedCOP(cooling_coil_two_speed, rated_cooling_COP, runner)
				end	
				# for dx heating coil
				if not heating_coil_single_speed.empty?
					setHeatingSingleSpeedCOP(heating_coil_single_speed, rated_heating_COP, runner)
				end				
			end	
		end
	end	
	
  end 
  
  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

	# Determine if the measure is applicable to the model, if not just return and no changes are made.
	info_widget = runner.getOptionalWorkspaceObjectChoiceValue("info_widget",user_arguments,model)
	if not (info_widget.nil? or info_widget.empty?)
		runner.registerInfo("This measure is not applicable.")
		return true
	end		

	#assign the user inputs to variables
	unitary_hp_widget = runner.getOptionalWorkspaceObjectChoiceValue("unitary_hp_widget",user_arguments,model)
	standards_widget = runner.getOptionalWorkspaceObjectChoiceValue("standards_widget",user_arguments,model)

	handle = runner.getStringArgumentValue("unitary_hp_widget",user_arguments)
	unitary_hp_index = handle.to_i
	
	#check which method is used, if both are checked used the first one
	is_option_manual = runner.getBoolArgumentValue("input_option_manual",user_arguments)
	is_option_standard = runner.getBoolArgumentValue("input_option_standard",user_arguments)

	if is_option_manual
		rated_heating_COP = runner.getDoubleArgumentValue("rated_heating_COP",user_arguments)
		rated_cooling_COP = runner.getDoubleArgumentValue("rated_cooling_COP",user_arguments)
		
		# Check if input is valid
		if rated_heating_COP < 0 #or rated_COP > 1
			runner.registerError("Rated heating COP must be positive.")
			return false
		end
		if rated_cooling_COP < 0 #or rated_COP > 1
			runner.registerError("Rated cooling COP must be positive.")
			return false
		end		
		
		changeRatedCOP(model, unitary_hp_index, rated_heating_COP, rated_cooling_COP, runner)
		
	elsif is_option_standard
		handle = runner.getStringArgumentValue("standards_widget",user_arguments)
		standards_index = handle.to_i			

		standard_table = ["","ASHRAE 90.1-2004","ASHRAE 90.1-2007","ASHRAE 90.1-2010","ASHRAE 90.1-2013"]
	
		total_cooling_capacity = runner.getOptionalDoubleArgumentValue("total_cooling_capacity",user_arguments)
		if total_cooling_capacity.empty?
			runner.registerError("The Rated total cooling capacity field is required, but blank. Enter a valid input.")
			return false
		else
			total_cooling_capacity = runner.getDoubleArgumentValue("total_cooling_capacity",user_arguments)
		end
		# Check if the required inputs
		if not total_cooling_capacity.is_a? Numeric	
			runner.registerError("The Rated total cooling capacity field is required, but blank. Enter a valid input.")
			return false
		elsif (total_cooling_capacity < 0)
			runner.registerError("OutOfBound! The Nominal Capacity must be greater than zero. Reset the value.")	
			return false			
		end
		
		if standards_index <= 0
			runner.registerError("ASHRAE 90.1 standard is not specified.")
			return false
		else			
			runner.registerInfo("Final: ASHRAE Standards #{standard_table[standards_index]} is selected.")
		end
	
		rated_heating_COP = getCOPHeatingMode(standard_table[standards_index],total_cooling_capacity)
		rated_cooling_COP = getCOPCoolingMode(standard_table[standards_index],total_cooling_capacity)
		
		changeRatedCOP(model, unitary_hp_index, rated_heating_COP, rated_cooling_COP, runner)
	else
		runner.registerError("You have to specify using either Option 1 or Option 2.")
		return false
	end
	    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetAirCooledUnitaryHeatPumpCOP.new.registerWithApplication