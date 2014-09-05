#start the measure
class XcelEDAReportingandQAQC < OpenStudio::Ruleset::ReportingUserScript
def create_results()  
    
    #create an attribute vector to hold results
    result_elems = OpenStudio::AttributeVector.new
    
    #floor_area
    floor_area_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName='Building Area' AND RowName='Net Conditioned Building Area' AND ColumnName='Area' AND Units='m2'" 
    floor_area = @sql.execAndReturnFirstDouble(floor_area_query)
    if floor_area.is_initialized
      result_elems << OpenStudio::Attribute.new("floor_area", floor_area.get, "m^2")
    else
      @runner.registerWarning("Building floor area not found")
      return false
    end
    
    #inflation approach
    inf_appr_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Life-Cycle Cost Parameters' AND RowName='Inflation Approach' AND ColumnName='Value'" 
    inf_appr = @sql.execAndReturnFirstString(inf_appr_query)
    if inf_appr.is_initialized
      if inf_appr.get == "ConstantDollar"
        inf_appr = "Constant Dollar"
      elsif inf_appr.get == "CurrentDollar"
        inf_appr = "Current Dollar"
      else
        @runner.registerError("Inflation approach: #{inf_appr.get} not recognized")
        return OpenStudio::Attribute.new("report", result_elems)
      end
      @runner.registerInfo("Inflation approach = #{inf_appr}")
    else
      @runner.registerError("Could not determine inflation approach used")
      return OpenStudio::Attribute.new("report", result_elems)
    end
    
    #base year
    base_yr_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Life-Cycle Cost Parameters' AND RowName='Base Date' AND ColumnName='Value'"
    base_yr = @sql.execAndReturnFirstString(base_yr_query)
    if base_yr.is_initialized
      if base_yr.get.match(/\d\d\d\d/)
        base_yr = base_yr.get.match(/\d\d\d\d/)[0].to_f
      else
        @runner.registerError("Could not determine the analysis start year from #{base_yr.get}")
        return OpenStudio::Attribute.new("report", result_elems)
      end
    else
      @runner.registerError("Could not determine analysis start year")
      return OpenStudio::Attribute.new("report", result_elems)      
    end
    
    #analysis length
    length_yrs_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Life-Cycle Cost Parameters' AND RowName='Length of Study Period in Years' AND ColumnName='Value'" 
    length_yrs = @sql.execAndReturnFirstInt(length_yrs_query)
    if length_yrs.is_initialized
      @runner.registerInfo"Analysis length = #{length_yrs.get} yrs"
      length_yrs = length_yrs.get
    else
      @runner.registerError("Could not determine analysis length")
      return OpenStudio::Attribute.new("report", result_elems)      
    end    
    
    #cash flows
    cash_flow_elems = OpenStudio::AttributeVector.new

    #setup a vector for each type of cash flow
    cap_cash_flow_elems = OpenStudio::AttributeVector.new
    om_cash_flow_elems = OpenStudio::AttributeVector.new
    energy_cash_flow_elems = OpenStudio::AttributeVector.new
    water_cash_flow_elems = OpenStudio::AttributeVector.new
    tot_cash_flow_elems = OpenStudio::AttributeVector.new
    
    #add the type to the element
    cap_cash_flow_elems << OpenStudio::Attribute.new("type", "#{inf_appr} Capital Costs")
    om_cash_flow_elems << OpenStudio::Attribute.new("type", "#{inf_appr} Operating Costs")
    energy_cash_flow_elems << OpenStudio::Attribute.new("type", "#{inf_appr} Energy Costs")
    water_cash_flow_elems << OpenStudio::Attribute.new("type", "#{inf_appr} Water Costs")
    tot_cash_flow_elems << OpenStudio::Attribute.new("type", "#{inf_appr} Total Costs")   
    
    #record the cash flow in these hashes
    cap_cash_flow = {}
    om_cash_flow = {}
    energy_cash_flow = {}
    water_cash_flow = {}
    tot_cash_flow = {}
    
    #loop through each year and record the cash flow
    for i in 0..(length_yrs - 1) do
      new_yr = base_yr + i
      yr = "January           #{new_yr.round}"
      ann_cap_cash = 0.0
      ann_om_cash = 0.0
      ann_energy_cash = 0.0
      ann_water_cash = 0.0
      ann_tot_cash = 0.0
    
      #capital cash flow
      cap_cash_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Capital Cash Flow by Category (Without Escalation)' AND RowName='#{yr}' AND ColumnName='Total'"
      cap_cash = @sql.execAndReturnFirstDouble(cap_cash_query)
      if cap_cash.is_initialized
        ann_cap_cash += cap_cash.get
        ann_tot_cash += cap_cash.get
      end
  
      #o&m cash flow (excluding utility costs)
      om_types = ["Maintenance", "Repair","Operation", "Replacement", "MinorOverhaul", "MajorOverhaul", "OtherOperational"] 
      om_types.each do |om_type|
        om_cash_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Operating Cash Flow by Category (Without Escalation)' AND RowName='#{yr}' AND ColumnName='#{om_type}'"
        om_cash = @sql.execAndReturnFirstDouble(om_cash_query)
        if om_cash.is_initialized
          ann_om_cash += om_cash.get
          ann_tot_cash += om_cash.get
        end
      end
  
      #energy cash flow
      energy_cash_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Operating Cash Flow by Category (Without Escalation)' AND RowName='#{yr}' AND ColumnName='Energy'"
      energy_cash = @sql.execAndReturnFirstDouble(energy_cash_query)
      if energy_cash.is_initialized
        ann_energy_cash += energy_cash.get
        ann_tot_cash += energy_cash.get
      end  
  
      #water cash flow
      water_cash_query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='Life-Cycle Cost Report' AND ReportForString='Entire Facility' AND TableName='Operating Cash Flow by Category (Without Escalation)' AND RowName='#{yr}' AND ColumnName='Water'"
      water_cash = @sql.execAndReturnFirstDouble(water_cash_query)
      if water_cash.is_initialized
        ann_water_cash += water_cash.get
        ann_tot_cash += water_cash.get
      end 

      #log the values for this year
      cap_cash_flow[yr] = ann_cap_cash
      om_cash_flow[yr] = ann_om_cash
      energy_cash_flow[yr] = ann_energy_cash
      water_cash_flow[yr] = ann_water_cash
      tot_cash_flow[yr] = ann_tot_cash      
   
      cap_cash_flow_elems << OpenStudio::Attribute.new("year", ann_cap_cash, "dollars")
      om_cash_flow_elems << OpenStudio::Attribute.new("year", ann_om_cash, "dollars")
      energy_cash_flow_elems << OpenStudio::Attribute.new("year", ann_energy_cash, "dollars")
      water_cash_flow_elems << OpenStudio::Attribute.new("year", ann_water_cash, "dollars")
      tot_cash_flow_elems << OpenStudio::Attribute.new("year", ann_tot_cash, "dollars")
   
    end #next year
    
    #end cash flows
    cash_flow_elems << OpenStudio::Attribute.new("cash_flow", cap_cash_flow_elems)
    cash_flow_elems << OpenStudio::Attribute.new("cash_flow", om_cash_flow_elems)
    cash_flow_elems << OpenStudio::Attribute.new("cash_flow", energy_cash_flow_elems)
    cash_flow_elems << OpenStudio::Attribute.new("cash_flow", water_cash_flow_elems)
    cash_flow_elems << OpenStudio::Attribute.new("cash_flow", tot_cash_flow_elems)
    result_elems << OpenStudio::Attribute.new("cash_flows", cash_flow_elems)
    
    #list of all end uses in OpenStudio
    end_use_cat_types = []
    OpenStudio::EndUseCategoryType::getValues.each do |end_use_val|
      end_use_cat_types << OpenStudio::EndUseCategoryType.new(end_use_val)
    end

    #list of all end use fule types in OpenStudio
    end_use_fuel_types = []
    OpenStudio::EndUseFuelType::getValues.each do |end_use_fuel_type_val|
      end_use_fuel_types << OpenStudio::EndUseFuelType.new(end_use_fuel_type_val)
    end  
      
    #list of the 12 months of the year in OpenStudio
    months = []
    OpenStudio::MonthOfYear::getValues.each do |month_of_year_val|
      if month_of_year_val >= 1 and month_of_year_val <= 12
        months << OpenStudio::MonthOfYear.new(month_of_year_val)
      end
    end
    
    #map each end use category type to the name that will be used in the xml 
    end_use_map = {
      OpenStudio::EndUseCategoryType.new("Heating").value => "heating",
      OpenStudio::EndUseCategoryType.new("Cooling").value => "cooling",
      OpenStudio::EndUseCategoryType.new("InteriorLights").value => "lighting_interior",
      OpenStudio::EndUseCategoryType.new("ExteriorLights").value => "lighting_exterior",
      OpenStudio::EndUseCategoryType.new("InteriorEquipment").value => "equipment_interior",
      OpenStudio::EndUseCategoryType.new("ExteriorEquipment").value => "equipment_exterior",
      OpenStudio::EndUseCategoryType.new("Fans").value => "fans",
      OpenStudio::EndUseCategoryType.new("Pumps").value => "pumps",
      OpenStudio::EndUseCategoryType.new("HeatRejection").value => "heat_rejection",
      OpenStudio::EndUseCategoryType.new("Humidifier").value => "humidification",
      OpenStudio::EndUseCategoryType.new("HeatRecovery").value => "heat_recovery",
      OpenStudio::EndUseCategoryType.new("WaterSystems").value => "water_systems",
      OpenStudio::EndUseCategoryType.new("Refrigeration").value => "refrigeration",
      OpenStudio::EndUseCategoryType.new("Generators").value => "generators"
    }
      
    #map each fuel type in EndUseFuelTypes to a specific FuelTypes
    fuel_type_map = {  
      OpenStudio::EndUseFuelType.new("Electricity").value => OpenStudio::FuelType.new("Electricity"),
      OpenStudio::EndUseFuelType.new("Gas").value => OpenStudio::FuelType.new("Gas"),
      OpenStudio::EndUseFuelType.new("AdditionalFuel").value => OpenStudio::FuelType.new("Diesel"), #TODO add other fuel types
      OpenStudio::EndUseFuelType.new("DistrictCooling").value => OpenStudio::FuelType.new("DistrictCooling"),
      OpenStudio::EndUseFuelType.new("DistrictHeating").value => OpenStudio::FuelType.new("DistrictHeating"),
      OpenStudio::EndUseFuelType.new("Water").value => OpenStudio::FuelType.new("Water")
    }  

    #map each fuel type in EndUseFuelTypes to a specific FuelTypes
    fuel_type_alias_map = {  
      OpenStudio::EndUseFuelType.new("Electricity").value => "electricity",
      OpenStudio::EndUseFuelType.new("Gas").value => "gas",
      OpenStudio::EndUseFuelType.new("AdditionalFuel").value => "other_energy",
      OpenStudio::EndUseFuelType.new("DistrictCooling").value => "district_cooling",
      OpenStudio::EndUseFuelType.new("DistrictHeating").value => "district_heating",
      OpenStudio::EndUseFuelType.new("Water").value => "water"
    }

    #annual "annual"
    annual_elems = OpenStudio::AttributeVector.new
    
      #consumption "consumption"
      cons_elems = OpenStudio::AttributeVector.new

        #electricity
        electricity = @sql.electricityTotalEndUses
        if electricity.is_initialized
          cons_elems << OpenStudio::Attribute.new("electricity", electricity.get, "GJ")
        else
          cons_elems << OpenStudio::Attribute.new("electricity", 0.0, "GJ")
        end      
      
        #gas
        gas = @sql.naturalGasTotalEndUses
        if gas.is_initialized
          cons_elems << OpenStudio::Attribute.new("gas", gas.get, "GJ")
        else
          cons_elems << OpenStudio::Attribute.new("gas", 0.0, "GJ")
        end       

        #other_energy
        other_energy = @sql.otherFuelTotalEndUses
        if other_energy.is_initialized
          cons_elems << OpenStudio::Attribute.new("other_energy", other_energy.get, "GJ")
        else
          cons_elems << OpenStudio::Attribute.new("other_energy", 0.0, "GJ")
        end

        #district_cooling
        district_cooling = @sql.districtCoolingTotalEndUses
        if district_cooling.is_initialized
          cons_elems << OpenStudio::Attribute.new("district_cooling", district_cooling.get, "GJ")
        else
          cons_elems << OpenStudio::Attribute.new("district_cooling", 0.0, "GJ")
        end
        
        #district_heating
        district_heating = @sql.districtHeatingTotalEndUses
        if district_heating.is_initialized
          cons_elems << OpenStudio::Attribute.new("district_heating", district_heating.get, "GJ")
        else
          cons_elems << OpenStudio::Attribute.new("district_heating", 0.0, "GJ")
        end
        
        #water
        water = @sql.waterTotalEndUses
        if water.is_initialized
          cons_elems << OpenStudio::Attribute.new("water", water.get, "m^3")
        else
          cons_elems << OpenStudio::Attribute.new("water", 0.0, "m^3")
        end
        
      #end consumption
      annual_elems << OpenStudio::Attribute.new("consumption", cons_elems)
      
      #demand "demand"
      demand_elems = OpenStudio::AttributeVector.new
      
        #get the weather file run period (as opposed to design day run period)
        ann_env_pd = nil
        @sql.availableEnvPeriods.each do |env_pd|
          env_type = @sql.environmentType(env_pd)
          if env_type.is_initialized
            if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
              ann_env_pd = env_pd
            end
          end
        end
      
        #only try to get the annual peak demand if an annual simulation was run
        if ann_env_pd
        
          #create some units to use
          joule_unit = OpenStudio::createUnit("J").get
          gigajoule_unit = OpenStudio::createUnit("GJ").get
          hrs_unit = OpenStudio::createUnit("h").get
          kilowatt_unit = OpenStudio::createUnit("kW").get
      
          #get the annual hours simulated
          hrs_sim = "(0 - no partial annual simulation)"
          if @sql.hoursSimulated.is_initialized
            hrs_sim = @sql.hoursSimulated.get
            if hrs_sim != 8760
              @runner.registerError("Simulation was only #{hrs_sim} hrs; EDA requires an annual simulation (8760 hrs)")
              return OpenStudio::Attribute.new("report", result_elems)
            end
          end
      
          #electricity_peak_demand
          electricity_peak_demand = 0.0
          elec = @sql.timeSeries(ann_env_pd, "Zone Timestep", "Electricity:Facility", "")
          #deduce the timestep based on the hours simulated and the number of datapoints in the timeseries
          if elec.is_initialized
            elec_peak_demand_timestep_J = OpenStudio::Quantity.new(OpenStudio::maximum(elec.get.values), joule_unit)
            num_int = elec.get.values.size
            int_len_hrs = OpenStudio::Quantity.new(hrs_sim/num_int, hrs_unit)
            elec_peak_demand_hourly_J_per_hr = elec_peak_demand_timestep_J/int_len_hrs
            electricity_peak_demand = OpenStudio::convert(elec_peak_demand_hourly_J_per_hr, kilowatt_unit).get.value
            demand_elems << OpenStudio::Attribute.new("electricity_peak_demand", electricity_peak_demand, "kW")
          else
            demand_elems << OpenStudio::Attribute.new("electricity_peak_demand", 0.0, "kW")
          end
          
          #electricity_annual_avg_peak_demand
          val = @sql.electricityTotalEndUses
          if val.is_initialized
            ann_elec_gj = OpenStudio::Quantity.new(val.get, gigajoule_unit)
            ann_hrs = OpenStudio::Quantity.new(hrs_sim, hrs_unit)
            elec_ann_avg_peak_demand_hourly_GJ_per_hr = ann_elec_gj/ann_hrs
            electricity_annual_avg_peak_demand = OpenStudio::convert(elec_ann_avg_peak_demand_hourly_GJ_per_hr, kilowatt_unit).get.value
            demand_elems << OpenStudio::Attribute.new("electricity_annual_avg_peak_demand", electricity_annual_avg_peak_demand, "kW")
          else
            demand_elems << OpenStudio::Attribute.new("electricity_annual_avg_peak_demand", 0.0, "kW")
          end
        
          #district_cooling_peak_demand
          district_cooling_peak_demand = 0.0
          dist_clg = @sql.timeSeries(ann_env_pd, "Zone Timestep", "DistrictCooling:Facility", "")
          #deduce the timestep based on the hours simulated and the number of datapoints in the timeseries
          if dist_clg.is_initialized
            dist_clg_peak_demand_timestep_J = OpenStudio::Quantity.new(OpenStudio::maximum(dist_clg.get.values), joule_unit)
            num_int = dist_clg.get.values.size
            int_len_hrs = OpenStudio::Quantity.new( hrs_sim/num_int, hrs_unit)
            dist_clg_peak_demand_hourly_J_per_hr = dist_clg_peak_demand_timestep_J/int_len_hrs
            district_cooling_peak_demand = OpenStudio::convert(dist_clg_peak_demand_hourly_J_per_hr, kilowatt_unit).get.value
            demand_elems << OpenStudio::Attribute.new("district_cooling_peak_demand", district_cooling_peak_demand, "kW")
          else
            demand_elems << OpenStudio::Attribute.new("district_cooling_peak_demand", 0.0, "kW")
          end
          
        else
          @runner.registerError("Could not find an annual run period")
          return OpenStudio::Attribute.new("report", result_elems)
        end

      #end demand
      annual_elems << OpenStudio::Attribute.new("demand", demand_elems)
        
      #utility_cost
      utility_cost_elems = OpenStudio::AttributeVector.new
              
        #electricity
        electricity = @sql.annualTotalCost(OpenStudio::FuelType.new("Electricity"))
        if electricity.is_initialized
          utility_cost_elems << OpenStudio::Attribute.new("electricity", electricity.get, "dollars")
        else
          utility_cost_elems << OpenStudio::Attribute.new("electricity", 0.0, "dollars")
        end

        #electricity_consumption_charge and electricity_demand_charge
        electric_consumption_charge = 0.0
        electric_demand_charge = 0.0
        
        electric_rate_query = "SELECT value FROM tabulardatawithstrings WHERE ReportName='LEEDsummary' AND ReportForString='Entire Facility' AND TableName='EAp2-3. Energy Type Summary' AND RowName='Electricity' AND ColumnName='Utility Rate'"
        electric_rate_name = @sql.execAndReturnFirstString(electric_rate_query)
        if electric_rate_name.is_initialized
          electric_rate_name = electric_rate_name.get.strip
        
          #electricity_consumption_charge
          electric_consumption_charge_query = "SELECT value FROM tabulardatawithstrings WHERE ReportName='Tariff Report' AND ReportForString='#{electric_rate_name}' AND TableName='Categories' AND RowName='EnergyCharges (~~$~~)' AND ColumnName='Sum'"
          val = @sql.execAndReturnFirstDouble(electric_consumption_charge_query)
          if val.is_initialized
            electric_consumption_charge = val.get
          end 
  
          #electricity_demand_charge
          electric_demand_charge_query = "SELECT value FROM tabulardatawithstrings WHERE ReportName='Tariff Report' AND ReportForString='#{electric_rate_name}' AND TableName='Categories' AND RowName='DemandCharges (~~$~~)' AND ColumnName='Sum'"
          val = @sql.execAndReturnFirstDouble(electric_demand_charge_query)
          if val.is_initialized
            electric_demand_charge = val.get
          end 
          
        end
        utility_cost_elems << OpenStudio::Attribute.new("electricity_consumption_charge", electric_consumption_charge, "dollars")
        utility_cost_elems << OpenStudio::Attribute.new("electricity_demand_charge", electric_demand_charge, "dollars")

        #gas
        gas = @sql.annualTotalCost(OpenStudio::FuelType.new("Gas"))
        if gas.is_initialized
          utility_cost_elems << OpenStudio::Attribute.new("gas", gas.get, "dollars")
        else
          utility_cost_elems << OpenStudio::Attribute.new("gas", 0.0, "dollars")
        end
        
        #other_energy
        other_energy = @sql.annualTotalCost(OpenStudio::FuelType.new("Diesel")) #TODO all other fuel types
        if other_energy.is_initialized
          utility_cost_elems << OpenStudio::Attribute.new("other_energy", other_energy.get, "dollars")
        else
          utility_cost_elems << OpenStudio::Attribute.new("other_energy", 0.0, "dollars")
        end
        
        #district_cooling
        district_cooling = @sql.annualTotalCost(OpenStudio::FuelType.new("DistrictCooling"))
        if district_cooling.is_initialized
          utility_cost_elems << OpenStudio::Attribute.new("district_cooling", district_cooling.get, "dollars")
        else
          utility_cost_elems << OpenStudio::Attribute.new("district_cooling", 0.0, "dollars")
        end
        
        #district_heating
        district_heating = @sql.annualTotalCost(OpenStudio::FuelType.new("DistrictHeating"))
        if district_heating.is_initialized
          utility_cost_elems << OpenStudio::Attribute.new("district_heating", district_heating.get, "dollars")
        else
          utility_cost_elems << OpenStudio::Attribute.new("district_heating", 0.0, "dollars")
        end
        
        #water
        water = @sql.annualTotalCost(OpenStudio::FuelType.new("Water"))
        if water.is_initialized
          utility_cost_elems << OpenStudio::Attribute.new("water", water.get, "dollars")
        else
          utility_cost_elems << OpenStudio::Attribute.new("water", 0.0, "dollars")
        end
        
        #total
        total = @sql.annualTotalUtilityCost
        if total.is_initialized
          utility_cost_elems << OpenStudio::Attribute.new("total", total.get, "dollars")
        else
          utility_cost_elems << OpenStudio::Attribute.new("total", 0.0, "dollars")
        end
    
        #end_uses - utility costs by end use using average blended cost  
        end_uses_elems = OpenStudio::AttributeVector.new
          #map to store the costs by end use
          cost_by_end_use = {}
        
          #fill the map with 0.0's to start
          end_use_cat_types.each do |end_use_cat_type|
            cost_by_end_use[end_use_cat_type] = 0.0
          end
        
          #only attempt to get monthly data if enduses table is available
          if @sql.endUses.is_initialized
            end_uses_table = @sql.endUses.get
            #loop through all the fuel types
            end_use_fuel_types.each do |end_use_fuel_type|
              #get the annual total cost for this fuel type
              ann_cost = @sql.annualTotalCost(fuel_type_map[end_use_fuel_type.value]); 
              #get the total annual usage for this fuel type in all end use categories
              #loop through all end uses, adding the annual usage value to the aggregator
              ann_usg = 0.0
              end_use_cat_types.each do |end_use_cat_type|
                ann_usg += end_uses_table.getEndUse(end_use_fuel_type,end_use_cat_type)
              end
              #figure out the annual blended rate for this fuel type
              avg_ann_rate = 0.0
              if ann_cost.is_initialized and ann_usg > 0
                avg_ann_rate = ann_cost.get/ann_usg
              end
              #for each end use category, figure out the cost if using
              #the avg ann rate; add this cost to the map
              end_use_cat_types.each do |end_use_cat_type|
                cost_by_end_use[end_use_cat_type] += end_uses_table.getEndUse(end_use_fuel_type,end_use_cat_type) * avg_ann_rate
              end
            end
            #loop through the end uses and record the annual total cost based on the avg annual rate
            end_use_cat_types.each do |end_use_cat_type|
              #record the value
              end_uses_elems << OpenStudio::Attribute.new(end_use_map[end_use_cat_type.value], cost_by_end_use[end_use_cat_type], "dollars") 
            end
          else
            @runner.registerError("End-Use table not available in results; could not retrieve monthly costs by end use")
            return OpenStudio::Attribute.new("report", result_elems)
          end
          
        #end end_uses
        utility_cost_elems << OpenStudio::Attribute.new("end_uses", end_uses_elems)

      #end utility_costs
      annual_elems << OpenStudio::Attribute.new("utility_cost", utility_cost_elems)

    #end annual
    result_elems << OpenStudio::Attribute.new("annual", annual_elems)
    
    #monthly
    monthly_elems = OpenStudio::AttributeVector.new
    
      #consumption
      cons_elems = OpenStudio::AttributeVector.new 
        #loop through all end uses
        end_use_cat_types.each do |end_use_cat|   
          end_use_elems = OpenStudio::AttributeVector.new
          #in each end use, loop through all fuel types
          end_use_fuel_types.each do |end_use_fuel_type|  
            fuel_type_elems = OpenStudio::AttributeVector.new
            ann_energy_cons = 0.0
            #in each end use, loop through months and get monthly enedy consumption
            months.each do |month|
              mon_energy_cons = 0.0
              val = @sql.energyConsumptionByMonth(end_use_fuel_type, end_use_cat, month)
              if val.is_initialized
                monthly_consumption_J = OpenStudio::Quantity.new(val.get, joule_unit)
                monthly_consumption_GJ = OpenStudio::convert(monthly_consumption_J, gigajoule_unit).get.value
                mon_energy_cons = monthly_consumption_GJ
                ann_energy_cons += monthly_consumption_GJ
              end
              #record the monthly value
              if end_use_fuel_type == OpenStudio::EndUseFuelType.new("Water")
                fuel_type_elems << OpenStudio::Attribute.new("month", mon_energy_cons, "m^3")
              else
                fuel_type_elems << OpenStudio::Attribute.new("month", mon_energy_cons, "GJ")
              end
                
            end
            #record the annual total
            fuel_type_elems << OpenStudio::Attribute.new("year", ann_energy_cons, "GJ")
            #add this fuel type
            end_use_elems << OpenStudio::Attribute.new(fuel_type_alias_map[end_use_fuel_type.value], fuel_type_elems) 
          end
        #add this end use
        cons_elems << OpenStudio::Attribute.new(end_use_map[end_use_cat.value], end_use_elems) 
        end
      #end consumption
      monthly_elems << OpenStudio::Attribute.new("consumption", cons_elems) 

      #create a unit to use
      watt_unit = OpenStudio::createUnit("W").get
      kilowatt_unit = OpenStudio::createUnit("kW").get  
      
      #demand
      demand_elems = OpenStudio::AttributeVector.new 
        #loop through all end uses
        end_use_cat_types.each do |end_use_cat|   
          end_use_elems = OpenStudio::AttributeVector.new
          #in each end use, loop through all fuel types
          end_use_fuel_types.each do |end_use_fuel_type|  
            fuel_type_elems = OpenStudio::AttributeVector.new
            ann_peak_demand = 0.0
            #in each end use, loop through months and get monthly enedy consumption
            months.each do |month|
              mon_peak_demand = 0.0
              val = @sql.peakEnergyDemandByMonth(end_use_fuel_type, end_use_cat, month)
              if val.is_initialized
                mon_peak_demand_W = OpenStudio::Quantity.new(val.get, watt_unit)
                mon_peak_demand = OpenStudio::convert(mon_peak_demand_W, kilowatt_unit).get.value
              end
              #record the monthly value
              fuel_type_elems << OpenStudio::Attribute.new("month", mon_peak_demand, "kW")
              #if month peak demand > ann peak demand make this new ann peak demand
              if mon_peak_demand > ann_peak_demand
                ann_peak_demand = mon_peak_demand
              end
            end
            #record the annual peak demand
            fuel_type_elems << OpenStudio::Attribute.new("year", ann_peak_demand, "kW")
            #add this fuel type
            end_use_elems << OpenStudio::Attribute.new(fuel_type_alias_map[end_use_fuel_type.value], fuel_type_elems) 
          end
        #add this end use
        demand_elems << OpenStudio::Attribute.new(end_use_map[end_use_cat.value], end_use_elems) 
        end
      #end demand
      monthly_elems << OpenStudio::Attribute.new("demand", demand_elems) 
      
    #end monthly
    result_elems << OpenStudio::Attribute.new("monthly", monthly_elems)
    
    result_elem = OpenStudio::Attribute.new("results", result_elems)
    return result_elem
    
  end #end create_results  
    
end    
    