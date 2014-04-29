class XcelEDAReportingandQAQC < OpenStudio::Ruleset::ReportingUserScript

  #add electric heat rejection to electric cooling
  #add fans and lights? compare fans and cooling - greater than 5x different during peak cooling month - helps identify bad chiller curves
  
  #energy use for cooling and heating as percentage of total energy
  def enduse_pcts_check
    
    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "Energy Enduses Check")
    check_elems << OpenStudio::Attribute.new("category", "Xcel EDA")
    check_elems << OpenStudio::Attribute.new("description", "Check that heating and cooling energy make up the expected percentage of total energy consumption")
     
    #aggregators to hold the values
    electricity_cooling = 0
    natural_gas_cooling = 0
    other_fuel_cooling = 0
    total_site_energy = 0
    electricity_heating = 0
    natural_gas_heating = 0
    other_fuel_heating = 0
     
    #make sure all required data are available
    if @sql.electricityCooling.is_initialized
      electricity_cooling = @sql.electricityCooling.get
    end
    if @sql.naturalGasCooling.is_initialized
      natural_gas_cooling = @sql.naturalGasCooling.get
    end    
    if @sql.otherFuelCooling.is_initialized
      other_fuel_cooling = @sql.otherFuelCooling.get
    end
    if @sql.totalSiteEnergy.is_initialized 
      total_site_energy = @sql.totalSiteEnergy.get
    end    
    if @sql.electricityHeating.is_initialized 
      electricity_heating = @sql.electricityHeating.get
    end    
    if @sql.naturalGasHeating.is_initialized
      natural_gas_heating = @sql.naturalGasHeating.get
    end    
    if @sql.otherFuelHeating.is_initialized
      other_fuel_heating = @sql.otherFuelHeating.get
    end
    
    pct_cooling = (electricity_cooling + natural_gas_cooling + other_fuel_cooling) / total_site_energy
    pct_heating = (electricity_heating + natural_gas_heating + other_fuel_heating) / total_site_energy
    
    #flag if 0% < pct_cooling < 20%
    if pct_cooling < 0.0 or pct_cooling > 0.2
      check_elems << OpenStudio::Attribute.new("flag", "Cooling energy = #{pct_cooling} of total energy use;  outside of 0%-20% range expected by Xcel EDA")
      @runner.registerWarning("Cooling energy = #{pct_cooling} of total energy use;  outside of 0%-20% range expected by Xcel EDA")
    end
    
    #flag if 30% < pct_heating < 50%
    if pct_heating < 0.30 or pct_heating > 0.50
      check_elems << OpenStudio::Attribute.new("flag", "Heating energy = #{pct_heating} of total energy use; outside the 30%-50% range expected by Xcel EDA")
      @runner.registerWarning("Heating energy = #{pct_heating} of total energy use; outside the 30%-50% range expected by Xcel EDA")
    end
    
    check_elem = OpenStudio::Attribute.new("check", check_elems)
 
    return check_elem
    
  end

end