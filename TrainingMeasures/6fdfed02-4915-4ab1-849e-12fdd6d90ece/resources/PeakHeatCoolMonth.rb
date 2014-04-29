class XcelEDAReportingandQAQC < OpenStudio::Ruleset::ReportingUserScript
  
  #for cooling electricity, include heat rejection electricity
  #should normalize by # days/month - Drew -> yes

  #peak heating and cooling months
  def peak_heat_cool_mo_check
  
    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "Peak Heating and Cooling Month Check")
    check_elems << OpenStudio::Attribute.new("category", "Xcel EDA")
    check_elems << OpenStudio::Attribute.new("description", "Check that the heating and cooling energy peak during the expected time of year")
         
    #heating
    heating_electricity_peak_energy = 0
    heating_gas_peak_energy = 0
    heating_other_fuel_peak_energy = 0
    heating_district_cooling_peak_energy = 0
    heating_district_heating_peak_energy = 0
    #cooling
    cooling_electricity_peak_energy = 0
    cooling_gas_peak_energy = 0
    cooling_other_fuel_peak_energy = 0
    cooling_district_cooling_peak_energy = 0
    cooling_district_heating_peak_energy = 0

    #heating
    heating_electricity_peak_mo = "NotAMonth".to_MonthOfYear
    heating_gas_peak_mo = "NotAMonth".to_MonthOfYear
    heating_other_fuel_peak_mo = "NotAMonth".to_MonthOfYear
    heating_district_cooling_peak_mo = "NotAMonth".to_MonthOfYear
    heating_district_heating_peak_mo = "NotAMonth".to_MonthOfYear
    #cooling
    cooling_electricity_peak_mo = "NotAMonth".to_MonthOfYear
    cooling_gas_peak_mo = "NotAMonth".to_MonthOfYear
    cooling_other_fuel_peak_mo = "NotAMonth".to_MonthOfYear
    cooling_district_cooling_peak_mo = "NotAMonth".to_MonthOfYear
    cooling_district_heating_peak_mo = "NotAMonth".to_MonthOfYear

    #loop through all of the months, finding the peak month for 
    #heating and cooling for each fuel type
    (1..12).each do |month|
      month = OpenStudio::MonthOfYear.new(month)
      heating = "Heating".to_EndUseCategoryType
      cooling = "Cooling".to_EndUseCategoryType
      electricity = "Electricity".to_EndUseFuelType
      gas = "Gas".to_EndUseFuelType
      other_fuel = "AdditionalFuel".to_EndUseFuelType
      district_cooling = "DistrictCooling".to_EndUseFuelType
      district_heating = "DistrictHeating".to_EndUseFuelType
      
      #heating
      if @sql.energyConsumptionByMonth(electricity,heating, month).is_initialized
        if @sql.energyConsumptionByMonth(electricity,heating, month).get > heating_electricity_peak_energy
          heating_electricity_peak_energy = @sql.energyConsumptionByMonth(electricity,heating, month).get
          heating_electricity_peak_mo = month
        end
      end
      
      if @sql.energyConsumptionByMonth(gas,heating, month).is_initialized
        if @sql.energyConsumptionByMonth(gas,heating, month).get > heating_gas_peak_energy
          heating_gas_peak_energy = @sql.energyConsumptionByMonth(gas,heating, month).get
          heating_gas_peak_mo = month
        end
      end
      
      if @sql.energyConsumptionByMonth(other_fuel,heating, month).is_initialized
        if @sql.energyConsumptionByMonth(other_fuel,heating, month).get > heating_other_fuel_peak_energy
          heating_other_fuel_peak_energy = @sql.energyConsumptionByMonth(other_fuel,heating, month).get
          heating_other_fuel_peak_mo = month
        end
      end
        
      if @sql.energyConsumptionByMonth(district_cooling,heating, month).is_initialized
        if @sql.energyConsumptionByMonth(district_cooling,heating, month).get > heating_district_cooling_peak_energy
          heating_district_cooling_peak_energy = @sql.energyConsumptionByMonth(district_cooling,heating, month).get
          heating_district_cooling_peak_mo = month
        end
      end
      
      if @sql.energyConsumptionByMonth(district_heating,heating, month).is_initialized
        if @sql.energyConsumptionByMonth(district_heating,heating, month).get > heating_district_heating_peak_energy
          heating_district_heating_peak_energy = @sql.energyConsumptionByMonth(district_heating,heating, month).get
          heating_district_heating_peak_mo = month
        end  
      end
      
      #cooling
      if @sql.energyConsumptionByMonth(electricity,cooling, month).is_initialized
        if @sql.energyConsumptionByMonth(electricity,cooling, month).get > cooling_electricity_peak_energy
          cooling_electricity_peak_energy = @sql.energyConsumptionByMonth(electricity,cooling, month).get
          cooling_electricity_peak_mo = month
        end
      end
      
      if @sql.energyConsumptionByMonth(gas,cooling, month).is_initialized
        if @sql.energyConsumptionByMonth(gas,cooling, month).get > cooling_gas_peak_energy
          cooling_gas_peak_energy = @sql.energyConsumptionByMonth(gas,cooling, month).get
          cooling_gas_peak_mo = month
        end
      end
      
      if @sql.energyConsumptionByMonth(other_fuel,cooling, month).is_initialized
        if @sql.energyConsumptionByMonth(other_fuel,cooling, month).get > cooling_other_fuel_peak_energy
          cooling_other_fuel_peak_energy = @sql.energyConsumptionByMonth(other_fuel,cooling, month).get
          cooling_other_fuel_peak_mo = month
        end
      end
      
      if @sql.energyConsumptionByMonth(district_cooling,cooling, month).is_initialized
        if @sql.energyConsumptionByMonth(district_cooling,cooling, month).get > cooling_district_cooling_peak_energy
          cooling_district_cooling_peak_energy = @sql.energyConsumptionByMonth(district_cooling,cooling, month).get
          cooling_district_cooling_peak_mo = month
        end
      end
      
      if @sql.energyConsumptionByMonth(district_heating,cooling, month).is_initialized
        if @sql.energyConsumptionByMonth(district_heating,cooling, month).get > cooling_district_heating_peak_energy
          cooling_district_heating_peak_energy = @sql.energyConsumptionByMonth(district_heating,cooling, month).get
          cooling_district_heating_peak_mo = month
        end  
      end
      
    end

    #define winter
    winter = ["Dec","Jan","Feb","Mar","NotAMonth"]

    #define summer
    summer = ["Jun","Jul","Aug","NotAMonth"]

    #peak heating should occur during winter for all fuel types
    unless winter.include?(heating_electricity_peak_mo.valueName) 
      check_elems << OpenStudio::Attribute.new("flag", "Peak electricity consumption for heating does not occur in winter as expected; it occurs in #{heating_electricity_peak_mo.valueName}")
      @runner.registerWarning("Peak electricity consumption for heating does not occur in winter as expected; it occurs in #{heating_electricity_peak_mo.valueName}") 
    end

    unless winter.include?(heating_gas_peak_mo.valueName)
      check_elems << OpenStudio::Attribute.new("flag", "Peak gas consumption for heating does not occur in winter as expected; it occurs in #{heating_gas_peak_mo.valueName}")
      @runner.registerWarning("Peak gas consumption for heating does not occur in winter as expected; it occurs in #{heating_gas_peak_mo.valueName}")
    end

    unless winter.include?(heating_other_fuel_peak_mo.valueName)
      check_elems << OpenStudio::Attribute.new("flag", "Peak other fuel consumption for heating does not occur in winter as expected; it occurs in #{heating_other_fuel_peak_mo.valueName}")
      @runner.registerWarning("Peak other fuel consumption for heating does not occur in winter as expected; it occurs in #{heating_other_fuel_peak_mo.valueName}")
    end

    unless winter.include?(heating_district_cooling_peak_mo.valueName)
      check_elems << OpenStudio::Attribute.new("flag", "Peak district cooling consumption for heating does not occur in winter as expected; it occurs in #{heating_district_cooling_peak_mo.valueName}")
      @runner.registerWarning("Peak district cooling consumption for heating does not occur in winter as expected; it occurs in #{heating_district_cooling_peak_mo.valueName}")      
    end

    unless winter.include?(heating_district_heating_peak_mo.valueName)
      check_elems << OpenStudio::Attribute.new("flag", "Peak district heating consumption for heating does not occur in winter as expected; it occurs in #{heating_district_heating_peak_mo.valueName}")
      @runner.registerWarning("Peak district heating consumption for heating does not occur in winter as expected; it occurs in #{heating_district_heating_peak_mo.valueName}")      
    end

    #peak cooling should occur during summer for all fuel types
    unless summer.include?(cooling_electricity_peak_mo.valueName)
      check_elems << OpenStudio::Attribute.new("flag", "Peak electricity consumption for cooling does not occur in summer as expected; it occurs in #{cooling_electricity_peak_mo.valueName}")
      @runner.registerWarning("Peak electricity consumption for cooling does not occur in summer as expected; it occurs in #{cooling_electricity_peak_mo.valueName}")      
    end

    unless summer.include?(cooling_gas_peak_mo.valueName)
      check_elems << OpenStudio::Attribute.new("flag", "Peak gas consumption for cooling does not occur in summer as expected; it occurs in #{cooling_gas_peak_mo.valueName}")
      @runner.registerWarning("Peak gas consumption for cooling does not occur in summer as expected; it occurs in #{cooling_gas_peak_mo.valueName}")      
    end

    unless summer.include?(cooling_other_fuel_peak_mo.valueName)
      check_elems << OpenStudio::Attribute.new("flag", "Peak other fuel consumption for cooling does not occur in summer as expected; it occurs in #{cooling_other_fuel_peak_mo.valueName}")
      @runner.registerWarning("Peak other fuel consumption for cooling does not occur in summer as expected; it occurs in #{cooling_other_fuel_peak_mo.valueName}")      
    end

    unless summer.include?(cooling_district_cooling_peak_mo.valueName)
      check_elems << OpenStudio::Attribute.new("flag", "Peak district cooling consumption for cooling does not occur in summer as expected; it occurs in #{cooling_district_cooling_peak_mo.valueName}")
      @runner.registerWarning("Peak district cooling consumption for cooling does not occur in summer as expected; it occurs in #{cooling_district_cooling_peak_mo.valueName}")      
    end

    unless summer.include?(cooling_district_heating_peak_mo.valueName)
      check_elems << OpenStudio::Attribute.new("flag", "Peak district heating consumption for cooling does not occur in summer as expected; it occurs in #{cooling_district_heating_peak_mo.valueName}")
      @runner.registerWarning("Peak district heating consumption for cooling does not occur in summer as expected; it occurs in #{cooling_district_heating_peak_mo.valueName}")      
    end
    
    check_elem = OpenStudio::Attribute.new("check", check_elems)
 
    return check_elem
    
  end

end  