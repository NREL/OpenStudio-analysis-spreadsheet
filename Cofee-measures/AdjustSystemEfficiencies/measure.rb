#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AdjustSystemEfficiencies < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AdjustSystemEfficiencies"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    # Heating efficiency multiplier
    heating_efficiency_multiplier = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("heating_efficiency_multiplier",true)
    heating_efficiency_multiplier.setDisplayName("Heating Efficiency Multiplier")
    heating_efficiency_multiplier.setDefaultValue(1.0)
    args << heating_efficiency_multiplier

    # Cooling cop multiplier
    cooling_cop_multiplier = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cooling_cop_multiplier",true)
    cooling_cop_multiplier.setDisplayName("Cooling COP Multiplier")
    cooling_cop_multiplier.setDefaultValue(1.0)
    args << cooling_cop_multiplier

    
    return args
  end #end the arguments method
  
  def modify_coil_cooling_dx_single_speed(component, cooling_cop_multiplier)

    rated_cop = component.ratedCOP
    if rated_cop.empty?
      return false
    end
    
    temp = OpenStudio::OptionalDouble.new(cooling_cop_multiplier*rated_cop.get)
    component.setRatedCOP(temp)
    return true
  end
  
  def modify_coil_cooling_dx_two_speed(component, cooling_cop_multiplier)

    rated_low_speed_cop = component.ratedLowSpeedCOP
    rated_high_speed_cop = component.ratedHighSpeedCOP
    if rated_low_speed_cop.empty? or rated_high_speed_cop.empty?
      return false
    end
    
    component.setRatedLowSpeedCOP(cooling_cop_multiplier*rated_low_speed_cop.get)
    component.setRatedHighSpeedCOP(cooling_cop_multiplier*rated_high_speed_cop.get)
    return true
  end
  
  def modify_boiler_hot_water(component, heating_efficiency_multiplier)
    nominal_thermal_efficiency = component.nominalThermalEfficiency
    new_efficiency = heating_efficiency_multiplier*nominal_thermal_efficiency
    if new_efficiency > 1
      return false
    end
    return component.setNominalThermalEfficiency(new_efficiency)
  end
  
  def modify_chiller_electric_eir(component, cooling_cop_multiplier)
    referenceCOP = component.referenceCOP
    return component.setReferenceCOP(cooling_cop_multiplier*referenceCOP)
  end
  
  def modify_coil_heating_gas(component, heating_efficiency_multiplier)
    gas_burner_efficiency = component.gasBurnerEfficiency
    new_efficiency = heating_efficiency_multiplier*gas_burner_efficiency
    if new_efficiency > 1
      return false
    end
    component.setGasBurnerEfficiency(new_efficiency)
    return true
  end
  
  def modify_coil_heating_electric(component, heating_efficiency_multiplier)
    efficiency = component.efficiency
    new_efficiency = heating_efficiency_multiplier*efficiency
    if new_efficiency > 1
      return false
    end
    return component.setEfficiency(new_efficiency)
  end
  
  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    heating_efficiency_multiplier = runner.getDoubleArgumentValue("heating_efficiency_multiplier",user_arguments)
    cooling_cop_multiplier = runner.getDoubleArgumentValue("cooling_cop_multiplier",user_arguments)
    
    if heating_efficiency_multiplier <= 0
      runner.registerError("Heating efficiency multiplier must be greater than 0")
      return false
    end
    
    if cooling_cop_multiplier <= 0
      runner.registerError("Cooling COP multiplier must be greater than 0")
      return false
    end
    
    num_heating_objects_modified = 0
    num_cooling_objects_modified = 0

    # loop over all air loops
    model.getAirLoopHVACs.each do |air_loop|
      modified = false
      air_loop.supplyComponents.each do |component|
      
        # CoilHeatingGas
        if not component.to_CoilHeatingGas.empty?
          component = component.to_CoilHeatingGas.get
          if not modify_coil_heating_gas(component, heating_efficiency_multiplier)
            runner.registerError("Cannot modify heating efficiency for #{component.name.get} by multiplier #{heating_efficiency_multiplier}")
            return false
          else
            num_heating_objects_modified += 1
            modified = true
          end
          
        # CoilHeatingElectric
        elsif not component.to_CoilHeatingElectric.empty?
          component = component.to_CoilHeatingElectric.get
          if not modify_coil_heating_electric(component, heating_efficiency_multiplier)
            runner.registerError("Cannot modify heating efficiency for #{component.name.get} by multiplier #{heating_efficiency_multiplier}")
            return false
          else
            num_heating_objects_modified += 1
            modified = true
          end
            
        # CoilCoolingDXSingleSpeed
        elsif not component.to_CoilCoolingDXSingleSpeed.empty?
          component = component.to_CoilCoolingDXSingleSpeed.get
          if not modify_coil_cooling_dx_single_speed(component, cooling_cop_multiplier)
            runner.registerError("Cannot modify COP for #{component.name.get} by multiplier #{cooling_cop_multiplier}")
            return false
          else
            num_cooling_objects_modified += 1
            modified = true
          end
          
        # CoilCoolingDXTwoSpeed
        elsif not component.to_CoilCoolingDXTwoSpeed.empty?
          component = component.to_CoilCoolingDXTwoSpeed.get
          if not modify_coil_cooling_dx_two_speed(component, cooling_cop_multiplier)
            runner.registerError("Cannot modify COP for #{component.name.get} by multiplier #{cooling_cop_multiplier}")
            return false
          else
            num_cooling_objects_modified += 1
            modified = true
          end
        end
      end
      
      if not modified
        runner.registerWarning("No heating or cooling elements found for air loop #{air_loop.name.get}")
      end
    end
    
    # loop over all plant loops
    model.getPlantLoops.each do |plant_loop|
      modified = false
      plant_loop.supplyComponents.each do |component|
        #BoilerHotWater
        if not component.to_BoilerHotWater.empty?
          component = component.to_BoilerHotWater.get
          if not modify_boiler_hot_water(component, heating_efficiency_multiplier)
            runner.registerError("Cannot modify heating efficiency for #{component.name.get} by multiplier #{heating_efficiency_multiplier}")
            return false
          else
            num_heating_objects_modified += 1
            modified = true
          end
          
        # ChillerElectricEIR
        elsif not component.to_ChillerElectricEIR.empty?
          component = component.to_ChillerElectricEIR.get
          if not modify_chiller_electric_eir(component, cooling_cop_multiplier)
            runner.registerError("Cannot modify COP for #{component.name.get} by multiplier #{cooling_cop_multiplier}")
            return false
          else
            num_cooling_objects_modified += 1
            modified = true
          end
        end
      end
      
      if not modified
        runner.registerWarning("No heating or cooling elements found for plant loop #{plant_loop.name.get}")
      end
    end
    
    # loop over all thermal zones
    model.getThermalZones.each do |thermal_zone|
      modified = false
      equipment = thermal_zone.equipment
      equipment.each do |component|
        if not component.to_ZoneHVACPackagedTerminalAirConditioner.empty?
          component = component.to_ZoneHVACPackagedTerminalAirConditioner.get
          
          heating_coil = component.heatingCoil
          # CoilHeatingGas
          if not heating_coil.to_CoilHeatingGas.empty?
            component = heating_coil.to_CoilHeatingGas.get
            if not modify_coil_heating_gas(component, heating_efficiency_multiplier)
              runner.registerError("Cannot modify heating efficiency for #{component.name.get} by multiplier #{heating_efficiency_multiplier}")
              return false
            else
              num_heating_objects_modified += 1
              modified = true
            end
            
          # CoilHeatingElectric
          elsif not heating_coil.to_CoilHeatingElectric.empty?
            component = heating_coil.to_CoilHeatingElectric.get
            if not modify_coil_heating_electric(component, heating_efficiency_multiplier)
              runner.registerError("Cannot modify heating efficiency for #{component.name.get} by multiplier #{heating_efficiency_multiplier}")
              return false
            else
              num_heating_objects_modified += 1
              modified = true
            end
            
          else
            runner.registerError("Unknown heating coil type for #{heating_coil.name.get}")
            return false
          end
          
          cooling_coil = component.coolingCoil
          # CoilCoolingDXSingleSpeed
          if not cooling_coil.to_CoilCoolingDXSingleSpeed.empty?
            component = cooling_coil.to_CoilCoolingDXSingleSpeed.get
            if not modify_coil_cooling_dx_single_speed(component, cooling_cop_multiplier)
              runner.registerError("Cannot modify COP for #{component.name.get} by multiplier #{cooling_cop_multiplier}")
              return false
            else
              num_cooling_objects_modified += 1
              modified = true
            end
            
          # CoilCoolingDXTwoSpeed
          elsif not cooling_coil.to_CoilCoolingDXTwoSpeed.empty?
            component = cooling_coil.to_CoilCoolingDXTwoSpeed.get
            if not modify_coil_cooling_dx_two_speed(component, cooling_cop_multiplier)
              runner.registerError("Cannot modify COP for #{component.name.get} by multiplier #{cooling_cop_multiplier}")
              return false
            else
              num_cooling_objects_modified += 1
              modified = true
            end
            
          else
            runner.registerError("Unknown cooling coil type for #{cooling_coil.name.get}")
            return false
          end

        end
      end
      
      # DLM: todo check if any zone equipment that is not a terminal
      #if equipment.size > 0 and not modified
      #  runner.registerWarning("No heating or cooling elements found for thermal zone #{thermal_zone.name.get}")
      #end
    end
    
    #reporting final condition of model
    runner.registerFinalCondition("Modified efficiencies for #{num_heating_objects_modified} heating objects and #{num_cooling_objects_modified} cooling objects.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AdjustSystemEfficiencies.new.registerWithApplication