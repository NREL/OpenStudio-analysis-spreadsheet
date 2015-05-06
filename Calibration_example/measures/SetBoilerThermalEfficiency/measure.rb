#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SetBoilerThermalEfficiency < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetBoilerThermalEfficiency"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	# Determine how many boilers in model
	boiler_handles = OpenStudio::StringVector.new
	boiler_display_names = OpenStudio::StringVector.new
	
	# Get/show all boiler units from current loaded model.
	boiler_handles << '0'
	boiler_display_names <<'*All boilers*'
	
	i_boiler = 1
	model.getBoilerHotWaters.each do |boiler_water|
		if not boiler_water.to_BoilerHotWater.empty?
			water_unit = boiler_water.to_BoilerHotWater.get	
			boiler_handles << i_boiler.to_s
			boiler_display_names << water_unit.name.to_s	
			
			i_boiler = i_boiler + 1
		end
	end		
	model.getBoilerSteams.each do |boiler_steam|
		if not boiler_steam.to_BoilerSteam.empty?
			steam_unit = boiler_water.to_BoilerSteam.get	
			boiler_handles << i_boiler.to_s
			boiler_display_names << steam_unit.name.to_s	
			i_boiler = i_boiler + 1	
		end			
	end			
	
	if i_boiler == 1
	    info_widget = OpenStudio::Ruleset::OSArgument::makeBoolArgument("info_widget", true)
		info_widget.setDisplayName("!!!!*** This Measure is not Applicable to loaded Model. Read the description and choose an appropriate baseline model. ***!!!!")
		info_widget.setDefaultValue(true)
		args << info_widget	
		return args
	end
	
    boiler_widget = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("boiler_widget", boiler_handles, boiler_display_names,true)
    boiler_widget.setDisplayName("Apply the measure to ")
	boiler_widget.setDefaultValue(boiler_display_names[0])
    args << boiler_widget	
	
	# Add a check box for specify thermal efficiency manually
	input_option_manual = OpenStudio::Ruleset::OSArgument::makeBoolArgument("input_option_manual", false)
	input_option_manual.setDisplayName("Option 1, set boiler nominal thermal efficiency to a user defined value")
	input_option_manual.setDefaultValue(false)
	args << input_option_manual

	# Boiler Thermal Efficiency (default of 0.8)
	boiler_thermal_efficiency = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boiler_thermal_efficiency")
	boiler_thermal_efficiency.setDisplayName("Boiler nominal thermal efficiency (between 0 and 1)")
	boiler_thermal_efficiency.setDefaultValue(0.8)	
	args << boiler_thermal_efficiency	
	
	input_option_standard = OpenStudio::Ruleset::OSArgument::makeBoolArgument("input_option_standard", false)
	input_option_standard.setDisplayName("Option 2, set boiler nominal thermal efficiency based on ASHRAE Standard 90.1 requirement")
	input_option_standard.setDefaultValue(false)	
	args << input_option_standard
	
	# Nominal Capacity [W] (default of blank)	
	nominal_capacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nominal_capacity", false)
	nominal_capacity.setDisplayName("Boiler nominal capacity [W] ")
	args << nominal_capacity	
	
	# Show fuel type selection
	fuel_type_handles = OpenStudio::StringVector.new
	fuel_type_display_names = OpenStudio::StringVector.new
	
	fuel_type_handles << '0'	
	fuel_type_display_names << 'NaturalGas'
	fuel_type_handles << '1'	
	fuel_type_display_names << 'FuelOil#1'	
	fuel_type_handles << '2'	
	fuel_type_display_names << 'FuelOil#2'		
	
    # Make a choice argument for Boiler Fuel Type (default of NaturalGas)
    fuel_type_widget = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("fuel_type_widget", fuel_type_handles, fuel_type_display_names,false)
    fuel_type_widget.setDisplayName("Fuel type")
	fuel_type_widget.setDefaultValue(fuel_type_display_names[0])	
    args << fuel_type_widget
	
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

  def getMinEfficiencyWaterBoiler(standard, capacity, heating_type)
	min_efficiency = 0
	standard_list = ["ASHRAE 90.1-2004","ASHRAE 90.1-2007","ASHRAE 90.1-2010","ASHRAE 90.1-2013"]
	heating_type_list = ["Gas","Oil"]
	if (not standard_list.include? standard) || (not heating_type_list.include? heating_type)
		return nil
	end
	
	if standard == standard_list[0]
		if heating_type == heating_type_list[0]		
			if capacity < 87862
				min_efficiency = 0.8
			elsif capacity < 732188			
				min_efficiency = 0.75
			else
				min_efficiency = 0.85
			end
		else
			if capacity < 87862
				min_efficiency = 0.8
			elsif capacity < 732188			
				min_efficiency = 0.75
			else
				min_efficiency = 0.7925
			end
		end
	elsif standard == standard_list[1]
		if heating_type == heating_type_list[0]		
			if capacity < 87862
				min_efficiency = 0.8
			elsif capacity < 732188			
				min_efficiency = 0.8
			else
				min_efficiency = 0.8125
			end
		else
			if capacity < 87862
				min_efficiency = 0.8
			elsif capacity < 732188			
				min_efficiency = 0.82
			else
				min_efficiency = 0.8325
			end
		end	
	elsif standard == standard_list[3]
		if heating_type == heating_type_list[0]		
			if capacity < 87862
				min_efficiency = 0.8
			elsif capacity < 732188			
				min_efficiency = 0.8
			else
				min_efficiency = 0.8125
			end
		else
			if capacity < 87862
				min_efficiency = 0.8
			elsif capacity < 732188			
				min_efficiency = 0.82
			else
				min_efficiency = 0.8325
			end
		end			
	elsif standard == standard_list[4]
		if heating_type == heating_type_list[0]		
			if capacity < 87862
				min_efficiency = 0.82
			elsif capacity < 732188			
				min_efficiency = 0.8
			else
				min_efficiency = 0.8125
			end
		else
			if capacity < 87862
				min_efficiency = 0.84
			elsif capacity < 732188			
				min_efficiency = 0.82
			else
				min_efficiency = 0.8325
			end
		end			
	end

	return min_efficiency 												
	end
	
  def getMinEfficiencySteamBoiler(standard, capacity, heating_type)
	min_efficiency = 0
	standard_list = ["ASHRAE 90.1-2004","ASHRAE 90.1-2007","ASHRAE 90.1-2010","ASHRAE 90.1-2013"]
	heating_type_list = ["Gas","Oil"]
	if (not standard_list.include? standard) || (not heating_type_list.include? heating_type)
		return nil
	end
	
	if standard == standard_list[0]
		if heating_type == heating_type_list[0]		
			if capacity < 87862
				min_efficiency = 0.75
			elsif capacity < 732188			
				min_efficiency = 0.75
			else
				min_efficiency = 0.7925
			end
		else
			if capacity < 87862
				min_efficiency = 0.8
			elsif capacity < 732188			
				min_efficiency = 0.75
			else
				min_efficiency = 0.7925
			end
		end
	elsif standard == standard_list[1]
		if heating_type == heating_type_list[0]		
			if capacity < 87862
				min_efficiency = 0.75
			elsif capacity < 732188			
				min_efficiency = 0.79
			else
				min_efficiency = 0.79
			end
		else
			if capacity < 87862
				min_efficiency = 0.8
			elsif capacity < 732188			
				min_efficiency = 0.81
			else
				min_efficiency = 0.81
			end
		end	
	elsif standard == standard_list[3]
		if heating_type == heating_type_list[0]		
			if capacity < 87862
				min_efficiency = 0.75
			elsif capacity < 732188			
				min_efficiency = 0.79
			else
				min_efficiency = 0.79
			end
		else
			if capacity < 87862
				min_efficiency = 0.8
			elsif capacity < 732188			
				min_efficiency = 0.81
			else
				min_efficiency = 0.81
			end
		end			
	else standard == standard_list[4]
		if heating_type == heating_type_list[0]		
			if capacity < 87862
				min_efficiency = 0.8
			elsif capacity < 732188			
				min_efficiency = 0.79
			else
				min_efficiency = 0.79
			end
		else
			if capacity < 87862
				min_efficiency = 0.82
			elsif capacity < 732188			
				min_efficiency = 0.81
			else
				min_efficiency = 0.81
				min_efficiency = 0.81
			end
		end			
	end

	return min_efficiency 												
	end
	
  def changeThermalEfficiency(model, boiler_index, efficiency_value_new, runner)
	i_boiler = 0				
	#loop through to find water boiler
	model.getBoilerHotWaters.each do |boiler_water|
		if not boiler_water.to_BoilerHotWater.empty?
			i_boiler = i_boiler + 1
			if boiler_index != 0 and (boiler_index != i_boiler)
				next
			end
			
			water_unit = boiler_water.to_BoilerHotWater.get
			unit_name = water_unit.name
			
			# check capacity, fuel type, and thermal efficiency 
			thermal_efficiency_old = water_unit.nominalThermalEfficiency()
						
			#if thermal_efficiency_old.nil?	
			if not thermal_efficiency_old.is_a? Numeric
				runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was not set.")	
			else
				runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was not set.")
			end
			
			water_unit.setNominalThermalEfficiency(efficiency_value_new)
			runner.registerInfo("Final: The Thermal Efficiency for '#{unit_name}' was #{efficiency_value_new}")	
		end
	end	
	
	#loop through to find steam boiler	
	model.getBoilerSteams.each do |boiler_steam|
		if not boiler_steam.to_BoilerSteam.empty?
			i_boiler = i_boiler + 1
			if boiler_index != 0 and (boiler_index != i_boiler)
				next
			end
			
			steam_unit = boiler.to_BoilerSteam.get
			steam_unit_fueltype = steam_unit.fuelType
			unit_name = steam_unit.name
			
			thermal_efficiency_old = steam_unit.theoreticalEfficiency()
						
			if not thermal_efficiency_old.is_a? Numeric
				runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was not set.")			
			else
				runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was #{efficiency_value_new}.")
			end

			steam_unit.setNominalThermalEfficiency(efficiency_value_new)
			runner.registerInfo("Final: The Thermal Efficiency for '#{unit_name}' was #{efficiency_value_new}")
		end
	end				
  end
  
  def changeThermalEfficiencyByStandard(model, boiler_index, efficiency_value_water, efficiency_value_steam, nominal_capacity, fuel_type, runner)
	i_boiler = 0				
	#loop through to find water boiler
	model.getBoilerHotWaters.each do |boiler_water|
		if not boiler_water.to_BoilerHotWater.empty?
			i_boiler = i_boiler + 1
			if boiler_index != 0 and (boiler_index != i_boiler)
				next
			end
			
			water_unit = boiler_water.to_BoilerHotWater.get
			unit_name = water_unit.name
			
			# check capacity, fuel type, and thermal efficiency 
			thermal_efficiency_old = water_unit.nominalThermalEfficiency()
						
			#if thermal_efficiency_old.nil?	
			if not thermal_efficiency_old.is_a? Numeric
				runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was not set.")	
			else
				runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was not set.")
			end
			
			water_unit.setNominalThermalEfficiency(efficiency_value_water)
			runner.registerInfo("Final: The Thermal Efficiency for '#{unit_name}' was #{efficiency_value_water}")	
			
			# In case there is information about capacity and fuel_type
			if not nominal_capacity.nil?
				water_unit.setFuelType(fuel_type)
				
				nominal_capacity_old = water_unit.nominalCapacity()
				if not nominal_capacity_old.is_a? Numeric
					runner.registerInfo("Initial: The Nominal Capacity for '#{unit_name}' was not set.")
				else					
					runner.registerInfo("Initial: The Nominal Capacity for '#{unit_name}' was #{nominal_capacity_old}.")					
				end
				water_unit.setNominalCapacity(nominal_capacity)
				runner.registerInfo("Final: The Nominal Capacity for '#{unit_name}' was #{nominal_capacity}")	
			end
		end
	end	
	
	#loop through to find steam boiler	
	model.getBoilerSteams.each do |boiler_steam|
		if not boiler_steam.to_BoilerSteam.empty?
			i_boiler = i_boiler + 1
			if boiler_index != 0 and (boiler_index != i_boiler)
				next
			end
			
			steam_unit = boiler.to_BoilerSteam.get
			steam_unit_fueltype = steam_unit.fuelType
			unit_name = steam_unit.name
			
			thermal_efficiency_old = steam_unit.theoreticalEfficiency()
						
			if not thermal_efficiency_old.is_a? Numeric
				runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was not set.")			
			else
				runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was #{thermal_efficiency_old}.")
			end

			steam_unit.setNominalThermalEfficiency(efficiency_value_steam)
			runner.registerInfo("Final: The Thermal Efficiency for '#{unit_name}' was #{efficiency_value_steam}")
			
			# In case there is information about capacity and fuel_type
			if not nominal_capacity.nil?
				steam_unit.setFuelType(fuel)
				
				nominal_capacity_old = steam_unit.nominalCapacity()
				if not nominal_capacity_old.is_a? Numeric
					runner.registerInfo("Initial: The Nominal Capacity for '#{unit_name}' was not set.")
				else					
					runner.registerInfo("Initial: The Nominal Capacity for '#{unit_name}' was #{nominal_capacity_old}.")					
				end
				steam_unit.setNominalCapacity(nominal_capacity)
				runner.registerInfo("Final: The Nominal Capacity for '#{unit_name}' was #{nominal_capacity}")	
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
	boiler_widget = runner.getOptionalWorkspaceObjectChoiceValue("boiler_widget",user_arguments,model)
	standards_widget = runner.getOptionalWorkspaceObjectChoiceValue("standards_widget",user_arguments,model)
	nominal_capacity_method_widget = runner.getOptionalWorkspaceObjectChoiceValue("nominal_capacity_method_widget",user_arguments,model)
	fuel_type_widget = runner.getOptionalWorkspaceObjectChoiceValue("fuel_type_widget",user_arguments,model)

	handle = runner.getStringArgumentValue("boiler_widget",user_arguments)
	boiler_index = handle.to_i
	
	#check which method is used, if both are checked used the first one
	is_option_manual = runner.getBoolArgumentValue("input_option_manual",user_arguments)
	is_option_standard = runner.getBoolArgumentValue("input_option_standard",user_arguments)

	if is_option_manual
		boiler_thermal_efficiency = runner.getDoubleArgumentValue("boiler_thermal_efficiency",user_arguments)
		
		# Check if input is valid
		if boiler_thermal_efficiency < 0 or boiler_thermal_efficiency > 1
			runner.registerError("Boiler Thermal Efficiency must be between 0 and 1.")
			return false
		end
		
		changeThermalEfficiency(model, boiler_index, boiler_thermal_efficiency, runner)	
	elsif is_option_standard
		handle = runner.getStringArgumentValue("standards_widget",user_arguments)
		standards_index = handle.to_i			
		
		handle = runner.getStringArgumentValue("fuel_type_widget",user_arguments)
		fuel_type_index = handle.to_i		

		standard_table = ["","ASHRAE 90.1-2004","ASHRAE 90.1-2007","ASHRAE 90.1-2010","ASHRAE 90.1-2013"]
		fuel_table = ["Gas","Oil","Oil"]
		fuel_formal_name = ['NaturalGas', 'FuelOil#1', 'FuelOil#2']
		fuel_type = fuel_formal_name[fuel_type_index]
	
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
			runner.registerError("'Nominal Capacity' can not be negative.")			
		#elsif (nominal_capacity < 87862) or (nominal_capacity > 732188) then
		#	runner.registerError("'Nominal Capacity' should be between 87.862kW and 732.188kW.")
		end
		
		if standards_index <= 0
			runner.registerError("ASHRAE 90.1 standard is not specified.")
			return false
		else			
			runner.registerInfo("Final: ASHRAE Standards #{standard_table[standards_index]} is selected.")
		end
	
		water_unit_min_efficiency = getMinEfficiencyWaterBoiler(standard_table[standards_index],nominal_capacity, fuel_table[fuel_type_index])
		steam_unit_min_efficiency = getMinEfficiencySteamBoiler(standard_table[standards_index],nominal_capacity, fuel_table[fuel_type_index])
		
		changeThermalEfficiencyByStandard(model, boiler_index, water_unit_min_efficiency, steam_unit_min_efficiency, nominal_capacity, fuel_type, runner)
	
	else
		runner.registerError("You have to specify using either Option 1 or Option 2.")
		return false
	end
	    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetBoilerThermalEfficiency.new.registerWithApplication