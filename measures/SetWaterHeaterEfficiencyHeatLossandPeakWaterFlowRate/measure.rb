#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SetWaterHeaterEfficiencyHeatLossandPeakWaterFlowRate < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetWaterHeaterEfficiencyHeatLossandPeakWaterFlowRate"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	# Determine how many air loops in model
	waterheater_handles = OpenStudio::StringVector.new
	waterheater_display_names = OpenStudio::StringVector.new
	
	# Get/show all airloop_hvac which has VAV terminal units from current loaded model.
	waterheater_handles << '0'
	waterheater_display_names <<'*All service water heaters*'
	
	water_heaters = model.getWaterHeaterMixeds
	i_water_heater = 1
	water_heaters.each do |water_heater|
		waterheater_handles << i_water_heater.to_s
		waterheater_display_names << water_heater.name.to_s	

		i_water_heater = i_water_heater + 1		
	end		
	
	if i_water_heater == 1
	    info_widget = OpenStudio::Ruleset::OSArgument::makeBoolArgument("info_widget", true)
		info_widget.setDisplayName("!!!!*** This Measure is not Applicable to loaded Model. Read the description and choose an appropriate baseline model. ***!!!!")
		info_widget.setDefaultValue(true)
		args << info_widget	
		return args
	end
	
    waterheater_widget = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("waterheater_widget", waterheater_handles, waterheater_display_names,true)
    waterheater_widget.setDisplayName("Apply the measure to")
	waterheater_widget.setDefaultValue(waterheater_display_names[0])
    args << waterheater_widget	
    
    #make a choice argument for economizer control type	
	heater_fuel_type_handles = OpenStudio::StringVector.new
	heater_fuel_type_display_names = OpenStudio::StringVector.new
	
	fuel_type_array = ["NaturalGas","Electricity","PropaneGas","FuelOil#1","FuelOil#2",\
		"Coal","Diesel","Gasoline","OtherFuel1","OtherFuel2","Steam","DistrictHeating"]

	for i in 0..fuel_type_array.size-1
		heater_fuel_type_handles << i.to_s	
		heater_fuel_type_display_names << fuel_type_array[i]
	end
	
    #make a choice argument for economizer control type
    heater_fuel_type_widget = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("heater_fuel_type_widget", heater_fuel_type_handles, heater_fuel_type_display_names,true)
    heater_fuel_type_widget.setDisplayName("Fuel type")
	heater_fuel_type_widget.setDefaultValue(heater_fuel_type_display_names[0])	
    args << heater_fuel_type_widget

	#make an argument for heater Thermal Efficiency (default of 0.8)
	heater_thermal_efficiency = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("heater_thermal_efficiency", true)
    heater_thermal_efficiency.setDisplayName("Thermal efficiency [between 0 and 1]")
    heater_thermal_efficiency.setDefaultValue(0.8)
    args << heater_thermal_efficiency
	
    #make an argument for On/Off Cycle Loss Coefficient to Ambient Temperature [W/K]  [W/K] (default of 0.0)
	onoff_cycle_loss_coefficient_to_ambient_temperature = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("onoff_cycle_loss_coefficient_to_ambient_temperature", false)
    onoff_cycle_loss_coefficient_to_ambient_temperature.setDisplayName("Loss coefficient to ambient temperature [W/K] (optional input, baseline value will be used if empty)")
    #onoff_cycle_loss_coefficient_to_ambient_temperature.setDefaultValue(0.0)
    args << onoff_cycle_loss_coefficient_to_ambient_temperature

    #make an argument for Peak Use Flow Rate [m3/s] (No default, thus to be blank)
	peak_use_flow_rate = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("peak_use_flow_rate",false)
    peak_use_flow_rate.setDisplayName("Peak water use flow rate [m3/s] (optional input, baseline value will be used if empty)")
    args << peak_use_flow_rate
	
    return args
  end #end the arguments method

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
	waterheater_widget = runner.getOptionalWorkspaceObjectChoiceValue("waterheater_widget",user_arguments,model)
	heater_fuel_type_widget = runner.getOptionalWorkspaceObjectChoiceValue("heater_fuel_type_widget",user_arguments,model)

	handle = runner.getStringArgumentValue("waterheater_widget",user_arguments)
	waterheater_index = handle.to_i
	
	fuel_type_array = ['NaturalGas','Electricity','PropaneGas','FuelOil#1','FuelOil#2',\
		'Coal','Diesel','Gasoline','OtherFuel1','OtherFuel2','Steam','DistrictHeating']
	
	handle = runner.getStringArgumentValue("heater_fuel_type_widget",user_arguments)
	heater_fuel_type = handle.to_i
	heater_fuel = fuel_type_array[heater_fuel_type]

	heater_thermal_efficiency = runner.getDoubleArgumentValue("heater_thermal_efficiency",user_arguments)
	onoff_cycle_loss_coefficient_to_ambient_temperature = runner.getOptionalDoubleArgumentValue("onoff_cycle_loss_coefficient_to_ambient_temperature",user_arguments)
	
	peak_use_flow_rate = runner.getOptionalDoubleArgumentValue("peak_use_flow_rate",user_arguments)
	
	if heater_thermal_efficiency <= 0 
		runner.registerError("Enter a value greater than zero for the 'Heater Thermal Efficiency'.")
	elsif heater_thermal_efficiency > 1.0 
		runner.registerError("Enter a value less than or equal to 1.0 for the 'HeaterThermal Efficiency'.")
	end
	
	#if not onoff_cycle_loss_coefficient_to_ambient_temperature.empty?
	#	if onoff_cycle_loss_coefficient_to_ambient_temperature < 0 
	#		runner.registerError("Enter a value greater than or equal to zero for the 'On/Off Cycle Loss Coefficient to Ambient Temperature'.")
	#		return false
	#	elsif onoff_cycle_loss_coefficient_to_ambient_temperature == 0 
	#		runner.registerInfo("No heat loss was assumed.")
	#	end
	#else
	#	onoff_cycle_loss_coefficient_to_ambient_temperature = nil
	#end
	if onoff_cycle_loss_coefficient_to_ambient_temperature.is_a? Numeric	
		if onoff_cycle_loss_coefficient_to_ambient_temperature < 0 
			runner.registerError("Enter a value greater than or equal to zero for the 'On/Off Cycle Loss Coefficient to Ambient Temperature'.")
			return false
		elsif onoff_cycle_loss_coefficient_to_ambient_temperature == 0 
			runner.registerInfo("No heat loss was assumed.")
		end
	else
		onoff_cycle_loss_coefficient_to_ambient_temperature = nil		
	end
	
	if peak_use_flow_rate.is_a? Numeric	
		if peak_use_flow_rate <= 0.0  then
			runner.registerError("Enter a value greater than zero for the 'Peak Use Flow Rate'.")
		end
	end
	
	i_water_heater = 0
	model.getWaterHeaterMixeds.each do |water_heater|
		i_water_heater = i_water_heater + 1
		
		# check if AllAirloop is selected or not.
		if waterheater_index != 0 and (waterheater_index != i_water_heater)
			next
		end
		
		if not water_heater.to_WaterHeaterMixed.empty?
			unit = water_heater.to_WaterHeaterMixed.get
			
			#get the original value for reporting
			heater_thermal_efficiency_old = unit.heaterThermalEfficiency
			oncycle_loss_coeff_old = unit.onCycleLossCoefficienttoAmbientTemperature
			offcycle_loss_coeff_old = unit.offCycleLossCoefficienttoAmbientTemperature
			peak_use_flow_old = unit.peakUseFlowRate
			
			runner.registerInfo("Initial: Heater Thermal Efficiency of '#{unit.name}' was #{heater_thermal_efficiency_old}.")
			runner.registerInfo("Initial: On Cycle Loss Coefficient to Ambient Temperature of '#{unit.name}' was #{oncycle_loss_coeff_old}.")
			runner.registerInfo("Initial: Off Cycle Loss Coefficient to Ambient Temperature'#{unit.name}' was #{offcycle_loss_coeff_old}.")
			if peak_use_flow_old.is_a? Numeric	
				runner.registerInfo("Initial: Peak Use Flow Rate of '#{unit.name}' was #{peak_use_flow_old}.")
			end
					
			#now we have all user inputs, so set them to the new model
			unit.setHeaterFuelType(heater_fuel)
			unit.setHeaterThermalEfficiency(heater_thermal_efficiency)
			if not onoff_cycle_loss_coefficient_to_ambient_temperature.nil?
				unit.setOnCycleLossCoefficienttoAmbientTemperature(onoff_cycle_loss_coefficient_to_ambient_temperature)
				unit.setOffCycleLossCoefficienttoAmbientTemperature(onoff_cycle_loss_coefficient_to_ambient_temperature)
				runner.registerInfo("Final: On/Off Cycle Loss Coefficient to Ambient Temperature of '#{unit.name}' was set to be #{onoff_cycle_loss_coefficient_to_ambient_temperature}.")
			end
			if peak_use_flow_rate.is_a? Numeric	
				unit.setPeakUseFlowRate(peak_use_flow_rate) 
			end
			
			runner.registerInfo("Final: Heater Thermal Efficiency of '#{unit.name}' was set to be #{heater_thermal_efficiency}.")				
			if peak_use_flow_rate.is_a? Numeric	
				runner.registerInfo("Final: Peak Use Flow Rate of '#{unit.name}' was set to be #{peak_use_flow_rate}.")			
			end
		end
	end

    return true
  
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetWaterHeaterEfficiencyHeatLossandPeakWaterFlowRate.new.registerWithApplication