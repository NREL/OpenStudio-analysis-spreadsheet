#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SetAirCooledAirConditionerCOP < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetAirCooledAirConditionerCOP"
  end
  
  #define supporting methods for both arguments and runner
  def isUnitaryAC(supply_components)
	is_unitary_ac = false
	
	has_cooling_dxcoil = false	
	has_heating_dxcoil = false
	# loop through all the supply components on an air loop
	supply_components.each do |supply_component|
		cooling_coil_single_speed = supply_component.to_CoilCoolingDXSingleSpeed
		cooling_coil_two_speed = supply_component.to_CoilCoolingDXTwoSpeed
		
		heating_coil_DX = supply_component.to_CoilHeatingDXSingleSpeed
				
		if (not cooling_coil_single_speed.empty?) or (not cooling_coil_two_speed.empty?)
			has_cooling_dxcoil = true
		end
		
		if (not heating_coil_DX.empty?) 
			has_heating_dxcoil = true
		end		
	end

	if has_cooling_dxcoil and (not has_heating_dxcoil)
		is_unitary_ac = true
	end
	
	return is_unitary_ac
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	# Determine how many unitary AC in model
	unitary_ac_handles = OpenStudio::StringVector.new
	unitary_ac_display_names = OpenStudio::StringVector.new
	
	# Get/show all unitary AC from current loaded model.
	unitary_ac_handles << '0'
	unitary_ac_display_names <<'*All air conditioners*'
	
	i_unitary_ac = 1
	model.getAirLoopHVACs.each do |air_loop|
		supply_components = air_loop.supplyComponents	
		if isUnitaryAC(supply_components)
			unitary_ac_handles << i_unitary_ac.to_s
			unitary_ac_display_names << air_loop.name.to_s			
			i_unitary_ac = i_unitary_ac + 1			
		end		
	end
	
	if i_unitary_ac == 1
	    info_widget = OpenStudio::Ruleset::OSArgument::makeBoolArgument("info_widget", true)
		info_widget.setDisplayName("!!!!*** This Measure is not Applicable to loaded Model. Read the description and choose an appropriate baseline model. ***!!!!")
		info_widget.setDefaultValue(true)
		args << info_widget	
		return args
	end
	
    unitary_ac_widget = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("unitary_ac_widget", unitary_ac_handles, unitary_ac_display_names,true)
    unitary_ac_widget.setDisplayName("Apply the measure to ")
	unitary_ac_widget.setDefaultValue(unitary_ac_display_names[0])
    args << unitary_ac_widget	
	
	# Add a check box for specify Rated COP
	input_option_manual = OpenStudio::Ruleset::OSArgument::makeBoolArgument("input_option_manual", false)
	input_option_manual.setDisplayName("Option 1, set rated COP to a user defined value")
	input_option_manual.setDefaultValue(false)
	args << input_option_manual

	# Rated COP [W/W]
	rated_COP = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("rated_COP")
	rated_COP.setDisplayName("Rated COP [W/W]")
	rated_COP.setDefaultValue(3.0)	
	args << rated_COP	
	
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

  def getCOP(standard, capacity, heating_type)
	min_efficiency = 0
	standard_list = ["ASHRAE 90.1-2004","ASHRAE 90.1-2007","ASHRAE 90.1-2010","ASHRAE 90.1-2013"]
	heating_type_list = ["Electric","AllOther"]
	if (not standard_list.include? standard) || (not heating_type_list.include? heating_type)
		return nil
	end
	
	if standard == standard_list[0]
		if capacity < 19037
			min_efficiency = 3.69
		elsif capacity < 39538
			if heating_type == heating_type_list[0]
				min_efficiency = 3.57
			else
				min_efficiency = 3.5
			end
		elsif capacity < 70290
			if heating_type == heating_type_list[0]
				min_efficiency = 3.37
			else
				min_efficiency = 3.3
			end				
		elsif capacity < 222585
			if heating_type == heating_type_list[0]
				min_efficiency = 3.3
			else
				min_efficiency = 3.23
			end		
		else
			if heating_type == heating_type_list[0]
				min_efficiency = 3.2
			else
				min_efficiency = 3.13
			end		
		end
	else
		if capacity < 19037
			min_efficiency = 3.91
		elsif capacity < 39538
			if heating_type == heating_type_list[0]
				min_efficiency = 3.87
			else
				min_efficiency = 3.8
			end
		elsif capacity < 70290
			if heating_type == heating_type_list[0]
				min_efficiency = 3.8
			else
				min_efficiency = 3.73
			end				
		elsif capacity < 222585
			if heating_type == heating_type_list[0]
				min_efficiency = 3.47
			else
				min_efficiency = 3.4
			end		
		else
			if heating_type == heating_type_list[0]
				min_efficiency = 3.37
			else
				min_efficiency = 3.3
			end		
		end	
	end

	return min_efficiency 												
	end
	
  def changeRatedCOP(model, unitary_ac_index, value_new, runner)
	i_unitary_ac = 0				
	#loop through to find burner
	model.getAirLoopHVACs.each do |air_loop|
		supply_components = air_loop.supplyComponents

		model.getAirLoopHVACs.each do |air_loop|
			supply_components = air_loop.supplyComponents	
			if isUnitaryAC(supply_components)
				i_unitary_ac = i_unitary_ac + 1	
			else
				next
			end	

			if unitary_ac_index != 0 and (unitary_ac_index != i_unitary_ac)
				next
			end
			
			supply_components.each do |supply_component|
				cooling_coil_single_speed = supply_component.to_CoilCoolingDXSingleSpeed
				cooling_coil_two_speed = supply_component.to_CoilCoolingDXTwoSpeed
				
				# for CoilCoolingDXSingleSpeed
				if (not cooling_coil_single_speed.empty?)
					unit = cooling_coil_single_speed.get
					unit_name = unit.name
					old_COP = unit.getRatedCOP()
					runner.registerInfo("Initial: The rated COP of the #{unit_name} was #{old_COP}.")
					
					if old_COP.empty?					
						runner.registerInfo("Initial: The rated COP of the #{unit_name} was not set.")
					else
						runner.registerInfo("Initial: The rated COP of the #{unit_name} was #{old_COP}.")
					end
					optional_variable = OpenStudio::OptionalDouble.new(value_new)
					unit.setRatedCOP(optional_variable)
					runner.registerInfo("Final: The rated COP of the #{unit_name} was set to be #{value_new}.")	   					
				end
				# for CoilCoolingDXTwoSpeed
				if (not cooling_coil_two_speed.empty?)					
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
					unit.setRatedLowSpeedCOP(value_new)
					unit.setRatedHighSpeedCOP(value_new)
					runner.registerInfo("Final: The rated Low Speed COP of the #{unit_name} was set to be #{value_new}.")
					runner.registerInfo("Final: The rated High Speed COP of the #{unit_name} was set to be #{value_new}.")
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
	unitary_ac_widget = runner.getOptionalWorkspaceObjectChoiceValue("unitary_ac_widget",user_arguments,model)
	standards_widget = runner.getOptionalWorkspaceObjectChoiceValue("standards_widget",user_arguments,model)

	handle = runner.getStringArgumentValue("unitary_ac_widget",user_arguments)
	unitary_ac_index = handle.to_i
	
	#check which method is used, if both are checked used the first one
	is_option_manual = runner.getBoolArgumentValue("input_option_manual",user_arguments)
	is_option_standard = runner.getBoolArgumentValue("input_option_standard",user_arguments)

	if is_option_manual
		rated_COP = runner.getDoubleArgumentValue("rated_COP",user_arguments)
		
		# Check if input is valid
		if rated_COP < 0 #or rated_COP > 1
			runner.registerError("Rated COP must be positive.")
			return false
		end
		changeRatedCOP(model, unitary_ac_index, rated_COP, runner)
		
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
		elsif (total_cooling_capacity < 0)
			runner.registerError("OutOfBound! The Nominal Capacity must be greater than zero. Reset the value.")
		#elsif (total_cooling_capacity < 1000) 
		#	runner.registerError("The Nominal Capacity of 1000W is abnormally low. Verify if it is correct.")
		#elsif (total_cooling_capacity > 2343000)
		#	runner.registerError("The ASHRAE Standards 90.1 are not applicable to boilers with nominal capacity of greater than 2,343,000W. Verify if it is correct.")			
		end
		
		if standards_index <= 0
			runner.registerError("ASHRAE 90.1 standard is not specified.")
			return false
		else			
			runner.registerInfo("Final: ASHRAE Standards #{standard_table[standards_index]} is selected.")
		end
	
		rated_COP = getCOP(standard_table[standards_index],total_cooling_capacity, "Electric")
		
		changeRatedCOP(model, unitary_ac_index, rated_COP, runner)	
	else
		runner.registerError("You have to specify using either Option 1 or Option 2.")
		return false
	end
	    
    return true
  
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetAirCooledAirConditionerCOP.new.registerWithApplication