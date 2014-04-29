#see the URL below for information on how to write OpenStuido measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#start the measure
class SetThermostatSchedules < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Thermostat Schedules"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #populate choice argument for thermal zones in the model
    zone_handles = OpenStudio::StringVector.new
    zone_display_names = OpenStudio::StringVector.new

    #putting zone names into hash
    zone_hash = {}
    model.getThermalZones.each do |zone|
      zone_hash[zone.name.to_s] = zone
    end

    #looping through sorted hash of zones
    zone_hash.sort.map do |zone_name, zone|
      if zone.thermostatSetpointDualSetpoint.is_initialized
        zone_handles << zone.handle.to_s
        zone_display_names << zone_name
      end
    end

    #add building to string vector with zones
    building = model.getBuilding
    zone_handles << building.handle.to_s
    zone_display_names << "*All Thermal Zones*"
    
    #make an argument for zones
    zones = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("zones", zone_handles, zone_display_names, true)
    zones.setDisplayName("Choose Thermal Zones to change thermostat schedules on.")
    zones.setDefaultValue("*All Thermal Zones*") #if no zone is chosen this will run on all zones
    args << zones

    #populate choice argument for schedules in the model
    sch_handles = OpenStudio::StringVector.new
    sch_display_names = OpenStudio::StringVector.new

    #putting schedule names into hash
    sch_hash = {}
    model.getSchedules.each do |sch|
      sch_hash[sch.name.to_s] = sch
    end

    #looping through sorted hash of schedules
    sch_hash.sort.map do |sch_name, sch|
      if not sch.scheduleTypeLimits.empty?
        unitType = sch.scheduleTypeLimits.get.unitType
        #puts "#{sch.name}, #{unitType}"
        if unitType == "Temperature"
          sch_handles << sch.handle.to_s
          sch_display_names << sch_name
        end
      end
    end

    #add empty handle to string vector with schedules
    sch_handles << OpenStudio::toUUID("").to_s
    sch_display_names << "*No Change*"
    
    #make an argument for cooling schedule
    cooling_sch = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("cooling_sch", sch_handles, sch_display_names, true)
    cooling_sch.setDisplayName("Choose Cooling Schedule.")
    cooling_sch.setDefaultValue("*No Change*") #if no change is chosen then cooling schedules will not be changed
    args << cooling_sch    

    #make an argument for heating schedule
    heating_sch = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("heating_sch", sch_handles, sch_display_names, true)
    heating_sch.setDisplayName("Choose Heating Schedule.")
    heating_sch.setDefaultValue("*No Change*") #if no change is chosen then heating schedules will not be changed
    args << heating_sch
    
    #make an argument for material and installation cost
    material_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost",true)
    material_cost.setDisplayName("Material and Installation Costs per Thermal Zone ($/thermal zone).")
    material_cost.setDefaultValue(0.0)
    args << material_cost
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    zones = runner.getOptionalWorkspaceObjectChoiceValue("zones",user_arguments,model) #model is passed in because of argument type
    cooling_sch = runner.getOptionalWorkspaceObjectChoiceValue("cooling_sch",user_arguments,model) #model is passed in because of argument type
    heating_sch = runner.getOptionalWorkspaceObjectChoiceValue("heating_sch",user_arguments,model) #model is passed in because of argument type
    material_cost = runner.getDoubleArgumentValue("material_cost",user_arguments)
    
    #check the zone selection for reasonableness
    apply_to_all_zones = false
    selected_zone = nil
    if zones.empty?
      handle = runner.getStringArgumentValue("zones",user_arguments)
      if handle.empty?
        runner.registerError("No thermal zone was chosen.")
        return false
      else
        runner.registerError("The selected thermal zone with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
        return false
      end
    else
      if not zones.get.to_ThermalZone.empty?
        selected_zone = zones.get.to_ThermalZone.get
      elsif not zones.get.to_Building.empty?
        apply_to_all_zones = true
      else
        runner.registerError("Script Error - argument not showing up as thermal zone.")
        return false
      end
    end  #end of if zones.empty?
    
    #depending on user input, add selected zones to an array
    selected_zones = [] 
    if apply_to_all_zones == true
      selected_zones = model.getThermalZones
    else
      selected_zones << selected_zone
    end

    #check the cooling_sch for reasonableness
    if cooling_sch.empty?
      handle = runner.getStringArgumentValue("cooling_sch",user_arguments)
      if handle == OpenStudio::toUUID("").to_s
        # no change
        cooling_sch = nil
      else
        runner.registerError("The selected schedule with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
        return false
      end
    else
      if not cooling_sch.get.to_Schedule.empty?
        cooling_sch = cooling_sch.get.to_Schedule.get
      else
        runner.registerError("Script Error - argument not showing up as schedule.")
        return false
      end
    end  #end of if cooling_sch.empty?

    #check the heating_sch for reasonableness
    if heating_sch.empty?
      handle = runner.getStringArgumentValue("heating_sch",user_arguments)
      if handle == OpenStudio::toUUID("").to_s
        # no change
        heating_sch = nil
      else
        runner.registerError("The selected schedule with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
        return false
      end
    else
      if not heating_sch.get.to_Schedule.empty?
        heating_sch = heating_sch.get.to_Schedule.get
      else
        runner.registerError("Script Error - argument not showing up as schedule.")
        return false
      end
    end  #end of if heating_sch.empty?
      
    number_zones_modified = 0
    total_cost = 0
    if heating_sch or cooling_sch
    
      selected_zones.each do |zone|
        
        thermostatSetpointDualSetpoint = zone.thermostatSetpointDualSetpoint
        if thermostatSetpointDualSetpoint.empty?
          runner.registerInfo("Creating thermostat for thermal zone '#{zone.name}'.")
          
          thermostatSetpointDualSetpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
          zone.setThermostatSetpointDualSetpoint(thermostatSetpointDualSetpoint)
        else
          thermostatSetpointDualSetpoint = thermostatSetpointDualSetpoint.get
          
          # make sure this thermostat is unique to this zone
          if thermostatSetpointDualSetpoint.getSources("OS_ThermalZone".to_IddObjectType).size > 1
            # if not create a new copy
            runner.registerInfo("Copying thermostat for thermal zone '#{zone.name}'.")
            
            oldThermostat = thermostatSetpointDualSetpoint
            thermostatSetpointDualSetpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
            if not oldThermostat.heatingSetpointTemperatureSchedule.empty?
              thermostatSetpointDualSetpoint.setHeatingSetpointTemperatureSchedule(oldThermostat.heatingSetpointTemperatureSchedule.get)
            end
            if not oldThermostat.coolingSetpointTemperatureSchedule.empty?
              thermostatSetpointDualSetpoint.setCoolingSetpointTemperatureSchedule(oldThermostat.coolingSetpointTemperatureSchedule.get)
            end
            zone.setThermostatSetpointDualSetpoint(thermostatSetpointDualSetpoint)
          end
        end
        
        if heating_sch
          if not thermostatSetpointDualSetpoint.setHeatingSetpointTemperatureSchedule(heating_sch)
            runner.registerError("Script Error - cannot set heating schedule for thermal zone '#{zone.name}'.")
            return false
          end
        end
        
        if cooling_sch
          if not thermostatSetpointDualSetpoint.setCoolingSetpointTemperatureSchedule(cooling_sch)
            runner.registerError("Script Error - cannot set cooling schedule for thermal zone '#{zone.name}'.")
            return false
          end
        end
        
        if material_cost.abs != 0
          total_cost += material_cost
          OpenStudio::Model::LifeCycleCost::createLifeCycleCost("LCC_Mat - #{zone.name} Thermostats", zone, material_cost, "CostPerEach", "Construction")
        end
        
        number_zones_modified += 1
      end
    end
    
    runner.registerFinalCondition("Replaced thermostats for #{number_zones_modified} thermal zones, capital cost #{total_cost}")                   

    if number_zones_modified == 0
      runner.registerAsNotApplicable("No thermostats altered")
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetThermostatSchedules.new.registerWithApplication









