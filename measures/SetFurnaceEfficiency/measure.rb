#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SetFurnaceEfficiency < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetFurnaceEfficiency"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	# Determine how many boilers in model
	furnace_handles = OpenStudio::StringVector.new
	furnace_display_names = OpenStudio::StringVector.new
	
	# Get/show all boiler units from current loaded model.
	furnace_handles << '0'
	furnace_display_names <<'*All furnaces*'
	
	i_furnace = 1
	model.getAirLoopHVACs.each do |air_loop|
		supply_components = air_loop.supplyComponents	
		supply_components.each do |supply_component|	
			component = supply_component.to_CoilHeatingGas
			if not component.empty?
				unit = component.get
				unit_name = unit.name			
				furnace_handles << i_furnace.to_s
				furnace_display_names << unit_name.to_s	
				#furnace_display_names << i_furnace.to_s	
				i_furnace = i_furnace + 1	
			end				
		end		
	end
	
	if i_furnace == 1
	    info_widget = OpenStudio::Ruleset::OSArgument::makeBoolArgument("info_widget", true)
		info_widget.setDisplayName("!!!!*** This Measure is not Applicable to loaded Model. Read the description and choose an appropriate baseline model. ***!!!!")
		info_widget.setDefaultValue(true)
		args << info_widget	
		return args
	end
	
    furnace_widget = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("furnace_widget", furnace_handles, furnace_display_names,true)
    furnace_widget.setDisplayName("Apply the measure to ")
	furnace_widget.setDefaultValue(furnace_display_names[0])
    args << furnace_widget	
	
	# Add a check box for specify thermal efficiency manually
	input_option_manual = OpenStudio::Ruleset::OSArgument::makeBoolArgument("input_option_manual", false)
	input_option_manual.setDisplayName("Option 1, set furnace burner efficiency to a user defined value")
	input_option_manual.setDefaultValue(false)
	args << input_option_manual

	# Boiler Thermal Efficiency (default of 0.8)
	burner_efficiency = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("burner_efficiency")
	burner_efficiency.setDisplayName("Burner efficiency (between 0 and 1)")
	burner_efficiency.setDefaultValue(0.8)	
	args << burner_efficiency	
	
	input_option_standard = OpenStudio::Ruleset::OSArgument::makeBoolArgument("input_option_standard", false)
	input_option_standard.setDisplayName("Option 2, set furnace burner efficiency based on ASHRAE Standard 90.1 requirement")
	input_option_standard.setDefaultValue(false)	
	args << input_option_standard
	
	# Nominal Capacity [W] (default of blank)	
	nominal_capacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nominal_capacity", false)
	nominal_capacity.setDisplayName("Nominal capacity [W] ")
	args << nominal_capacity	
		
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
    standards_widget.setDisplayName("ASHRAE Standards 90.1")
	standards_widget.setDefaultValue(standards_display_names[0])
    args << standards_widget	    
		
    return args
  end #end the arguments method

  def getBurnerEfficiency(standard, capacity)
	min_efficiency = 0
	standard_list = ["ASHRAE 90.1-2004","ASHRAE 90.1-2007","ASHRAE 90.1-2010","ASHRAE 90.1-2013"]

	if (not standard_list.include? standard)
		return nil
	end				
	
	if standard == standard_list[0]
		if capacity < 65897
			min_efficiency = 0.8
		else
			min_efficiency = 0.7925
		end
	elsif standard == standard_list[1]
		if capacity < 65897
			min_efficiency = 0.8
		else
			min_efficiency = 0.7925
		end
	elsif standard == standard_list[3]
		if capacity < 65897
			min_efficiency = 0.8
		else
			min_efficiency = 0.8
		end		
	else standard == standard_list[4]
		if capacity < 65897
			min_efficiency = 0.8
		else
			min_efficiency = 0.8
		end		
	end

	return min_efficiency 												
	end
	
  def changeBurnerEfficiency(model, boiler_index, efficiency_value_new, nominal_capacity, runner)
	i_furnace = 0				
	#loop through to find burner
	model.getAirLoopHVACs.each do |air_loop|
		supply_components = air_loop.supplyComponents
		#find gas heating coil components in the baseline model
		supply_components.each do |supply_component|
			component = supply_component.to_CoilHeatingGas
			# apply user input to gas burner on the air loop
			if not component.empty?
				i_furnace = i_furnace + 1
				if boiler_index != 0 and (boiler_index != i_furnace)
					next
				end
			
				unit = component.get
				unit_name = unit.name
				efficiency_old = unit.gasBurnerEfficiency
								
				if not efficiency_old.is_a? Numeric
					runner.registerInfo("Initial: The Burner Efficiency for '#{unit_name}' was not set.")	
				else
					runner.registerInfo("Initial: The Burner Efficiency for '#{unit_name}' was #{efficiency_old}.")
				end
				
				unit.setGasBurnerEfficiency(efficiency_value_new)
				runner.registerInfo("Final: The Burner Efficiency for '#{unit_name}' was #{efficiency_value_new}")		

				# In case there is information about capacity
				if not nominal_capacity.nil?				
					unit.setNominalCapacity(nominal_capacity)
					runner.registerInfo("Final: The Burner Capacity for '#{unit_name}' was #{nominal_capacity}")	
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
	furnace_widget = runner.getOptionalWorkspaceObjectChoiceValue("furnace_widget",user_arguments,model)
	standards_widget = runner.getOptionalWorkspaceObjectChoiceValue("standards_widget",user_arguments,model)

	handle = runner.getStringArgumentValue("furnace_widget",user_arguments)
	boiler_index = handle.to_i
	
	#check which method is used, if both are checked used the first one
	is_option_manual = runner.getBoolArgumentValue("input_option_manual",user_arguments)
	is_option_standard = runner.getBoolArgumentValue("input_option_standard",user_arguments)

	if is_option_manual
		burner_efficiency = runner.getDoubleArgumentValue("burner_efficiency",user_arguments)
		
		# Check if input is valid
		if burner_efficiency < 0 or burner_efficiency > 1
			runner.registerError("Boiler Thermal Efficiency must be between 0 and 1.")
			return false
		end
		changeBurnerEfficiency(model, boiler_index, burner_efficiency, nil, runner)
	elsif is_option_standard
		handle = runner.getStringArgumentValue("standards_widget",user_arguments)
		standards_index = handle.to_i			

		standard_table = ["","ASHRAE 90.1-2004","ASHRAE 90.1-2007","ASHRAE 90.1-2010","ASHRAE 90.1-2013"]
	
		nominal_capacity = runner.getOptionalDoubleArgumentValue("nominal_capacity",user_arguments)
		if nominal_capacity.empty?
			runner.registerError("Nominal capacity is not specified.")
			return false
		else
			nominal_capacity = runner.getDoubleArgumentValue("nominal_capacity",user_arguments)
		end
		# Check if the required inputs
		if not nominal_capacity.is_a? Numeric	
			runner.registerError("'Nominal Capacity' is not specified but required for ASHRAE Standards.")
		elsif (nominal_capacity < 0)
			runner.registerError("OutOfBound! The Nominal Capacity must be greater than zero. Reset the value.")
		#elsif (nominal_capacity < 1000) 
		#	runner.registerError("The Nominal Capacity of 1000W is abnormally low. Verify if it is correct.")
		#elsif (nominal_capacity > 2343000)
		#	runner.registerError("The ASHRAE Standards 90.1 are not applicable to boilers with nominal capacity of greater than 2,343,000W. Verify if it is correct.")			
		end
		
		if standards_index <= 0
			runner.registerError("ASHRAE 90.1 standard is not specified.")
			return false
		else			
			runner.registerInfo("Final: ASHRAE Standards #{standard_table[standards_index]} is selected.")
		end
	
		burner_efficiency = getBurnerEfficiency(standard_table[standards_index],nominal_capacity)
		
		changeBurnerEfficiency(model, boiler_index, burner_efficiency, nominal_capacity, runner)	
	else
		runner.registerError("You have to specify using either Option 1 or Option 2.")
		return false
	end
	    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetFurnaceEfficiency.new.registerWithApplication