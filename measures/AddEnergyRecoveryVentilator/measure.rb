#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddEnergyRecoveryVentilator < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddEnergyRecoveryVentilator"
  end
  
  #define the arguments that the user will input
  #define the arguments that the user will input
   #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	# Determine how many air loops in model
	air_loop_handles = OpenStudio::StringVector.new
	air_loop_display_names = OpenStudio::StringVector.new
	
	# Get/show all unitary air conditioners from current loaded model.
	air_loop_handles << '0'
	air_loop_display_names<<'*All air loops*'

	i_air_loop = 1
	model.getAirLoopHVACs.each do |air_loop|	
		air_loop_handles << i_air_loop.to_s
		air_loop_display_names << air_loop.name.to_s
				
		i_air_loop = i_air_loop + 1	
	end	
	
	if i_air_loop == 1
	    info_widget = OpenStudio::Ruleset::OSArgument::makeBoolArgument("info_widget", true)
		info_widget.setDisplayName("!!!!*** This Measure is not Applicable to loaded Model. Read the description and choose an appropriate baseline model. ***!!!!")
		info_widget.setDefaultValue(true)
		args << info_widget
		return args
	end

    air_loop_widget = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("air_loop_widget", air_loop_handles, air_loop_display_names,true)
    air_loop_widget.setDisplayName("Apply the measure to ")
	air_loop_widget.setDefaultValue(air_loop_display_names[0])
    args << air_loop_widget	    
	
	# Sensible Effectiveness at 100% Heating Air Flow (default of 0.76)
	sensible_eff_at_100_heating = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("sensible_eff_at_100_heating", false)
	sensible_eff_at_100_heating.setDisplayName("Sensible Effectiveness at 100% Heating Air Flow")
	sensible_eff_at_100_heating.setDefaultValue(0.76)
	args << sensible_eff_at_100_heating	
	
	# Latent Effectiveness at 100% Heating Air Flow (default of 0.76)
	latent_eff_at_100_heating = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("latent_eff_at_100_heating", false)
	latent_eff_at_100_heating.setDisplayName("Latent Effectiveness at 100% Heating Air Flow")
	latent_eff_at_100_heating.setDefaultValue(0.68)
	args << latent_eff_at_100_heating		
 
 	# Sensible Effectiveness at 75% Heating Air Flow (default of 0.76)
	sensible_eff_at_75_heating = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("sensible_eff_at_75_heating", false)
	sensible_eff_at_75_heating.setDisplayName("Sensible Effectiveness at 75% Heating Air Flow")
	sensible_eff_at_75_heating.setDefaultValue(0.81)
	args << sensible_eff_at_75_heating	
	
	# Latent Effectiveness at 100% Heating Air Flow (default of 0.76)
	latent_eff_at_75_heating = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("latent_eff_at_75_heating", false)
	latent_eff_at_75_heating.setDisplayName("Latent Effectiveness at 75% Heating Air Flow")
	latent_eff_at_75_heating.setDefaultValue(0.73)
	args << latent_eff_at_75_heating		

	# Sensible Effectiveness at 100% Cooling Air Flow (default of 0.76)
	sensible_eff_at_100_cooling = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("sensible_eff_at_100_cooling", false)
	sensible_eff_at_100_cooling.setDisplayName("Sensible Effectiveness at 100% Cooling Air Flow")
	sensible_eff_at_100_cooling.setDefaultValue(0.76)
	args << sensible_eff_at_100_cooling	
	
	# Latent Effectiveness at 100% Cooling Air Flow (default of 0.76)
	latent_eff_at_100_cooling = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("latent_eff_at_100_cooling", false)
	latent_eff_at_100_cooling.setDisplayName("Latent Effectiveness at 100% Cooling Air Flow")
	latent_eff_at_100_cooling.setDefaultValue(0.68)
	args << latent_eff_at_100_cooling		
 
 	# Sensible Effectiveness at 75% Cooling Air Flow (default of 0.76)
	sensible_eff_at_75_cooling = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("sensible_eff_at_75_cooling", false)
	sensible_eff_at_75_cooling.setDisplayName("Sensible Effectiveness at 75% Cooling Air Flow")
	sensible_eff_at_75_cooling.setDefaultValue(0.81)
	args << sensible_eff_at_75_cooling	
	
	# Latent Effectiveness at 100% Cooling Air Flow (default of 0.76)
	latent_eff_at_75_cooling = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("latent_eff_at_75_cooling", false)
	latent_eff_at_75_cooling.setDisplayName("Latent Effectiveness at 75% Cooling Air Flow")
	latent_eff_at_75_cooling.setDefaultValue(0.73)
	args << latent_eff_at_75_cooling	
	
	# Show ASHRAE standards
	heat_exchanger_type_handles = OpenStudio::StringVector.new
	heat_exchanger_type_display_names = OpenStudio::StringVector.new
	
	heat_exchanger_type_handles << '0'
	heat_exchanger_type_display_names << 'Rotary'
	
    heat_exchanger_type_widget = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("heat_exchanger_type_widget", heat_exchanger_type_handles, heat_exchanger_type_display_names,true)
    heat_exchanger_type_widget.setDisplayName("Heat Exchanger Type.")
	heat_exchanger_type_widget.setDefaultValue(heat_exchanger_type_display_names[0])
    args << heat_exchanger_type_widget	
	
	# Nominal electric power [W] (Note: this is optional. If no value is entered, do nothing)
	nominal_electric_power = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nominal_electric_power", false)
	nominal_electric_power.setDisplayName("Nominal electric power [W]")
	args << nominal_electric_power	

    return args
  end #end the arguments method

  def reportValueChangeInfo(value_old, value_new, value_name, airloop_name, runner)
	if value_old.nil?
		runner.registerInfo("Initial: The #{value_name} on #{airloop_name} was not set.")
	else
		runner.registerInfo("Initial: The #{value_name} on #{airloop_name} was #{value_old}.")
	end
	runner.registerInfo("Final: The #{value_name} on #{airloop_name} was set to be #{value_new}.")
	return 
  end	
  
  def setSensibleEffectiveness100Cooling(erv, value_new, airloop_name, runner)
	value_old = erv.getSensibleEffectivenessat100CoolingAirFlow()
	erv.setSensibleEffectivenessat100CoolingAirFlow(value_new)
	reportValueChangeInfo(value_old, value_new, "Sensible Effectiveness at 100% Cooling Air Flow", airloop_name, runner)	
	return
  end

  def setSensibleEffectiveness75Cooling(erv, value_new, airloop_name, runner)
	value_old = erv.getSensibleEffectivenessat75CoolingAirFlow()
	erv.setSensibleEffectivenessat75CoolingAirFlow(value_new)
	reportValueChangeInfo(value_old, value_new, "Sensible Effectiveness at 75% Cooling Air Flow", airloop_name, runner)	
	return
  end

  def setLatentEffectiveness100Cooling(erv, value_new, airloop_name, runner)
	value_old = erv.getLatentEffectivenessat100CoolingAirFlow()
	erv.setLatentEffectivenessat100CoolingAirFlow(value_new)
	reportValueChangeInfo(value_old, value_new, "Latent Effectiveness at 100% Cooling Air Flow", airloop_name, runner)	
	return
  end

  def setLatentEffectiveness75Cooling(erv, value_new, airloop_name, runner)
	value_old = erv.getLatentEffectivenessat75CoolingAirFlow()
	erv.setLatentEffectivenessat75CoolingAirFlow(value_new)
	reportValueChangeInfo(value_old, value_new, "Latent Effectiveness at 75% Cooling Air Flow", airloop_name, runner)	
	return
  end  

  def setSensibleEffectiveness100Heating(erv, value_new, airloop_name, runner)
	value_old = erv.getSensibleEffectivenessat100HeatingAirFlow()
	erv.setSensibleEffectivenessat100HeatingAirFlow(value_new)
	reportValueChangeInfo(value_old, value_new, "Sensible Effectiveness at 100% Heating Air Flow", airloop_name, runner)	
	return
  end

  def setSensibleEffectiveness75Heating(erv, value_new, airloop_name, runner)
	value_old = erv.getSensibleEffectivenessat75HeatingAirFlow()
	erv.setSensibleEffectivenessat75HeatingAirFlow(value_new)
	reportValueChangeInfo(value_old, value_new, "Sensible Effectiveness at 75% Heating Air Flow", airloop_name, runner)	
	return
  end

  def setLatentEffectiveness100Heating(erv, value_new, airloop_name, runner)
	value_old = erv.getLatentEffectivenessat100HeatingAirFlow()
	erv.setLatentEffectivenessat100HeatingAirFlow(value_new)
	reportValueChangeInfo(value_old, value_new, "Latent Effectiveness at 100% Heating Air Flow", airloop_name, runner)	
	return
  end

  def setLatentEffectiveness75Heating(erv, value_new, airloop_name, runner)
	value_old = erv.getLatentEffectivenessat75HeatingAirFlow()
	erv.setLatentEffectivenessat75HeatingAirFlow(value_new)
	reportValueChangeInfo(value_old, value_new, "Latent Effectiveness at 75% Heating Air Flow", airloop_name, runner)	
	return
  end 
  
  def setNominalElectricPower(erv, value_new, airloop_name, runner)
	value_old = erv.getNominalElectricPower()
	erv.setNominalElectricPower(value_new)
	reportValueChangeInfo(value_old, value_new, "Nominal electric power", airloop_name, runner)	
	return
  end 			
  
  def isOutOfRange(value_new, value_name, runner)
	if value_new < 0 or value_new > 1
		runner.registerError("OutOfBound! The #{value_name} must be between 0 and 1. Reset the value.")
		return true
	end
	return false
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

	air_loop_widget = runner.getOptionalWorkspaceObjectChoiceValue("air_loop_widget",user_arguments,model)
    handle = runner.getStringArgumentValue("air_loop_widget",user_arguments)
	air_loop_index = handle.to_i
	
	sensible_eff_at_100_heating = runner.getDoubleArgumentValue("sensible_eff_at_100_heating",user_arguments)		
	latent_eff_at_100_heating = runner.getDoubleArgumentValue("latent_eff_at_100_heating",user_arguments)	
	sensible_eff_at_75_heating = runner.getDoubleArgumentValue("sensible_eff_at_75_heating",user_arguments)	
	latent_eff_at_75_heating = runner.getDoubleArgumentValue("latent_eff_at_75_heating",user_arguments)
		
	sensible_eff_at_100_cooling = runner.getDoubleArgumentValue("sensible_eff_at_100_cooling",user_arguments)	
	latent_eff_at_100_cooling = runner.getDoubleArgumentValue("latent_eff_at_100_cooling",user_arguments)	
	sensible_eff_at_75_cooling = runner.getDoubleArgumentValue("sensible_eff_at_75_cooling",user_arguments)	
	latent_eff_at_75_cooling = runner.getDoubleArgumentValue("latent_eff_at_75_cooling",user_arguments)	
	
	if isOutOfRange(sensible_eff_at_100_heating, "sensible_eff_at_100_heating", runner)
		return false
	end	
	if isOutOfRange(latent_eff_at_100_heating, "latent_eff_at_100_heating", runner)
		return false
	end
	if isOutOfRange(sensible_eff_at_75_heating, "sensible_eff_at_75_heating", runner)
		return false
	end
	if isOutOfRange(latent_eff_at_75_heating, "latent_eff_at_75_heating", runner)
		return false
	end	
	if isOutOfRange(sensible_eff_at_100_cooling, "sensible_eff_at_100_cooling", runner)
		return false
	end	
	if isOutOfRange(latent_eff_at_100_cooling, "latent_eff_at_100_cooling", runner)
		return false
	end
	if isOutOfRange(sensible_eff_at_75_cooling, "sensible_eff_at_75_cooling", runner)
		return false
	end
	if isOutOfRange(latent_eff_at_75_cooling, "latent_eff_at_75_cooling", runner)
		return false
	end		
	
	heat_exchanger_type_widget = runner.getOptionalWorkspaceObjectChoiceValue("heat_exchanger_type_widget",user_arguments,model)
    handle = runner.getStringArgumentValue("heat_exchanger_type_widget",user_arguments)
	heat_exchanger_type_index = handle.to_i
	
	heat_exchanger_type_list = ["Rotary"]
	heat_type = heat_exchanger_type_list[heat_exchanger_type_index]
	
	nominal_electric_power = runner.getOptionalDoubleArgumentValue("nominal_electric_power",user_arguments)
	if nominal_electric_power.empty?
		nominal_electric_power = nil
	else
		nominal_electric_power = runner.getDoubleArgumentValue("nominal_electric_power",user_arguments)
	end
		
	# loop through all air loops
	i_air_loop = 0
	model.getAirLoopHVACs.each do |air_loop|
		#check if the airloop already has an ERV either on a specified air loop or all air loops
		i_air_loop = i_air_loop + 1
		if air_loop_index != 0 and (air_loop_index != i_air_loop)
			next
		end	
			
		has_ERV = false		
		air_loop.supplyComponents.each do |supply_component|
			#check if the supply component is an ERV
			if not supply_component.to_HeatExchangerAirToAirSensibleAndLatent.empty?
				has_ERV = true
				erv = supply_component.to_HeatExchangerAirToAirSensibleAndLatent.get
				erv.setHeatExchangerType(heat_type)
				setSensibleEffectiveness100Cooling(erv, sensible_eff_at_100_cooling, air_loop.name, runner)
				setSensibleEffectiveness75Cooling(erv, sensible_eff_at_75_cooling, air_loop.name, runner)				
				setLatentEffectiveness100Cooling(erv, latent_eff_at_100_cooling, air_loop.name, runner)
				setLatentEffectiveness75Cooling(erv, latent_eff_at_75_cooling, air_loop.name, runner)
				
				setSensibleEffectiveness100Heating(erv, sensible_eff_at_100_heating, air_loop.name, runner)
				setSensibleEffectiveness75Heating(erv, sensible_eff_at_75_heating, air_loop.name, runner)				
				setLatentEffectiveness100Heating(erv, latent_eff_at_100_heating, air_loop.name, runner)
				setLatentEffectiveness75Heating(erv, latent_eff_at_75_heating, air_loop.name, runner)
				
				#erv.setEconomizerLockout('Yes')
				#erv.setEconomizerLockout(true)
				erv.setString(23, "Yes")
				
				#erv.setSupplyAirOutletTemperatureControl ('No')
				#erv.setSupplyAirOutletTemperatureControl (false)
				erv.setString(17, "No") 
				if not nominal_electric_power.nil?
					setNominalElectricPower(erv, nominal_electric_power, air_loop.name, runner)
				end
			end 
		end
		air_loop.supplyComponents.each do |supply_component|
			#if no ERV was found, see if the air loop has an outdoor air system
			if has_ERV == false
				if not supply_component.to_AirLoopHVACOutdoorAirSystem.empty?
					#get the outdoor air system
					oa_system = supply_component.to_AirLoopHVACOutdoorAirSystem.get 
					#create a new heat exchanger and add it to the outdoor air system
					erv = OpenStudio::Model::HeatExchangerAirToAirSensibleAndLatent.new(model)  
					oa_node = oa_system.outboardOANode	
					if not oa_node.empty?
						#set node connection
						erv.addToNode(oa_node.get)	
						#set required fields to a single default value
						erv.setHeatExchangerType(heat_type)
						setSensibleEffectiveness100Cooling(erv, sensible_eff_at_100_cooling, air_loop.name, runner)
						setSensibleEffectiveness75Cooling(erv, sensible_eff_at_75_cooling, air_loop.name, runner)				
						setLatentEffectiveness100Cooling(erv, latent_eff_at_100_cooling, air_loop.name, runner)
						setLatentEffectiveness75Cooling(erv, latent_eff_at_75_cooling, air_loop.name, runner)
						
						setSensibleEffectiveness100Heating(erv, sensible_eff_at_100_heating, air_loop.name, runner)
						setSensibleEffectiveness75Heating(erv, sensible_eff_at_75_heating, air_loop.name, runner)				
						setLatentEffectiveness100Heating(erv, latent_eff_at_100_heating, air_loop.name, runner)
						setLatentEffectiveness75Heating(erv, latent_eff_at_75_heating, air_loop.name, runner)
						
						# Temporary solution, may need to fix later. 12/22/2013 Da
						#erv.setEconomizerLockout('Yes')
						#erv.setEconomizerLockout(true)
						erv.setString(23, "Yes")
						
						#erv.setSupplyAirOutletTemperatureControl ('No')
						#erv.setSupplyAirOutletTemperatureControl (false)
						erv.setString(17, "No") 
						
						if not nominal_electric_power.nil?
							setNominalElectricPower(erv, nominal_electric_power, air_loop.name, runner)
						end						
					end
				end	
			end
		end
	end		
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddEnergyRecoveryVentilator.new.registerWithApplication