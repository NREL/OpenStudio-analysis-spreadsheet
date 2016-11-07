module OsLib_QAQC

  # include any general notes about QAQC method here

  #checks the number of unmet hours in the model
  def check_mech_sys_capacity(category,options)

    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "Mechanical System Capacity")
    check_elems << OpenStudio::Attribute.new("category", category)
    check_elems << OpenStudio::Attribute.new("description", "Check HVAC capacity against ASHRAE rules of thumb for chiller max flow rate, air loop max flow rate, air loop cooling capciaty, and zone heating capcaity. Zone heating check will skip thermal zones without any exterior exposure, and thermal zones that are not conditioned.")

    begin

      # check max flow rate of chillers in model
      @model.getPlantLoops.sort.each do |plant_loop|

        # next if no chiller on plant loop
        chillers = []
        plant_loop.supplyComponents.each do |sc|
          if sc.to_ChillerElectricEIR.is_initialized
            chillers << sc.to_ChillerElectricEIR.get
          end
        end
        next if chillers.size == 0

        # gather targets for chiller capacity
        chiller_max_flow_rate_target = options['chiller_max_flow_rate']['target']
        chiller_max_flow_rate_fraction_min = options['chiller_max_flow_rate']['min']
        chiller_max_flow_rate_fraction_max = options['chiller_max_flow_rate']['max']
        chiller_max_flow_rate_units_ip = options['chiller_max_flow_rate']['units'] # gal/ton*min
        # string above or display only, for converstion 12000 Btu/h per ton

        # get capacity of loop (not individual chiller but entire loop)
        total_cooling_capacity_w = plant_loop.total_cooling_capacity
        total_cooling_capacity_ton = OpenStudio.convert(total_cooling_capacity_w,'W','Btu/h').get/12000.0

        # get the max flow rate (through plant, not specific chiller)
        maximum_loop_flow_rate = plant_loop.find_maximum_loop_flow_rate
        maximum_loop_flow_rate_ip = OpenStudio.convert(maximum_loop_flow_rate,'m^3/s','gal/min').get

        # calculate the flow per tons of cooling
        model_flow_rate_per_ton_cooling_ip = maximum_loop_flow_rate_ip/total_cooling_capacity_ton

        # check flow rate per capacity
        if model_flow_rate_per_ton_cooling_ip < chiller_max_flow_rate_target*(1.0 - chiller_max_flow_rate_fraction_min)
          check_elems <<  OpenStudio::Attribute.new("flag", "Flow Rate of #{model_flow_rate_per_ton_cooling_ip.round(2)} #{chiller_max_flow_rate_units_ip} for #{plant_loop.name.get} is more than #{chiller_max_flow_rate_fraction_min*100} % below the typical value of #{chiller_max_flow_rate_target.round(2)} #{chiller_max_flow_rate_units_ip}.")
        elsif model_flow_rate_per_ton_cooling_ip > chiller_max_flow_rate_target*(1.0 + chiller_max_flow_rate_fraction_max)
          check_elems <<  OpenStudio::Attribute.new("flag", "Flow Rate of #{model_flow_rate_per_ton_cooling_ip.round(2)} #{chiller_max_flow_rate_units_ip} for #{plant_loop.name.get} is more than #{chiller_max_flow_rate_fraction_max*100} % above the typical value of #{chiller_max_flow_rate_target.round(2)} #{chiller_max_flow_rate_units_ip}.")
        end
      end

      # loop through air loops to get max flor rate and cooling capacity.
      @model.getAirLoopHVACs.sort.each do |air_loop|

        # todo - check if DOAS, don't check airflow or cooling capacity if it is (why not check OA for DOAS? would it be different target)

        # gather argument options for air_loop_max_flow_rate checks
        air_loop_max_flow_rate_target = options['air_loop_max_flow_rate']['target']
        air_loop_max_flow_rate_fraction_min = options['air_loop_max_flow_rate']['min']
        air_loop_max_flow_rate_fraction_max = options['air_loop_max_flow_rate']['max']
        air_loop_max_flow_rate_units_ip = options['air_loop_max_flow_rate']['units']
        air_loop_max_flow_rate_units_si= 'm^3/m^2*s'

        # get values from model for air loop checks
        floor_area_served = air_loop.floor_area_served # m^2
        design_supply_air_flow_rate = air_loop.find_design_supply_air_flow_rate # m^3/s

        # check max flow rate of air loops in the model
        model_normalized_flow_rate_si = design_supply_air_flow_rate/floor_area_served
        model_normalized_flow_rate_ip = OpenStudio.convert(model_normalized_flow_rate_si,air_loop_max_flow_rate_units_si,air_loop_max_flow_rate_units_ip).get
        if model_normalized_flow_rate_ip < air_loop_max_flow_rate_target*(1.0 - air_loop_max_flow_rate_fraction_min)
          check_elems <<  OpenStudio::Attribute.new("flag", "Flow Rate of #{model_normalized_flow_rate_ip.round(2)} #{air_loop_max_flow_rate_units_ip} for #{air_loop.name.get} is more than #{air_loop_max_flow_rate_fraction_min*100} % below the typical value of #{air_loop_max_flow_rate_target.round(2)} #{air_loop_max_flow_rate_units_ip}.")
        elsif model_normalized_flow_rate_ip > air_loop_max_flow_rate_target*(1.0 + air_loop_max_flow_rate_fraction_max)
          check_elems <<  OpenStudio::Attribute.new("flag", "Flow Rate of #{model_normalized_flow_rate_ip.round(2)} #{air_loop_max_flow_rate_units_ip} for #{air_loop.name.get} is more than #{air_loop_max_flow_rate_fraction_max*100} % above the typical value of #{air_loop_max_flow_rate_target.round(2)} #{air_loop_max_flow_rate_units_ip}.")
        end
      end

      # loop through air loops to get max flor rate and cooling capacity.
      @model.getAirLoopHVACs.sort.each do |air_loop|

        # check if DOAS, don't check airflow or cooling capacity if it is
        sizing_system = air_loop.sizingSystem
        next if sizing_system.typeofLoadtoSizeOn.to_s == "VentilationRequirement"

        # gather argument options for air_loop_cooling_capacity checks
        air_loop_cooling_capacity_target = options['air_loop_cooling_capacity']['target']
        air_loop_cooling_capacity_fraction_min = options['air_loop_cooling_capacity']['min']
        air_loop_cooling_capacity_fraction_max = options['air_loop_cooling_capacity']['max']
        air_loop_cooling_capacity_units_ip = options['air_loop_cooling_capacity']['units'] #tons/ft^2
        # string above or display only, for converstion 12000 Btu/h per ton
        air_loop_cooling_capacity_units_si= 'W/m^2'

        # get values from model for air loop checks
        floor_area_served = air_loop.floor_area_served # m^2
        capacity = air_loop.total_cooling_capacity # W

        # check cooling capacity of air loops in the model
        model_normalized_capacity_si = capacity/floor_area_served
        model_normalized_capacity_ip = OpenStudio.convert(model_normalized_capacity_si,air_loop_cooling_capacity_units_si,'Btu/ft^2*h').get/12000.0 # hard coded to get tons from Btu/h

        # want to display in tons/ft^2 so invert number and display for checks
        model_tons_per_area_ip = 1.0/model_normalized_capacity_ip
        target_tons_per_area_ip = 1.0/air_loop_cooling_capacity_target
        inverted_units = 'ft^2/ton'

        if model_tons_per_area_ip < target_tons_per_area_ip*(1.0 - air_loop_cooling_capacity_fraction_max)
          check_elems <<  OpenStudio::Attribute.new("flag", "Cooling Capacity of #{model_tons_per_area_ip.round} #{inverted_units} for #{air_loop.name.get} is more than #{air_loop_cooling_capacity_fraction_max*100} % below the typical value of #{target_tons_per_area_ip.round} #{inverted_units}.")
        elsif model_tons_per_area_ip > target_tons_per_area_ip*(1.0 + air_loop_cooling_capacity_fraction_min)
          check_elems <<  OpenStudio::Attribute.new("flag", "Cooling Capacity of #{model_tons_per_area_ip.round} #{inverted_units} for #{air_loop.name.get} is more than #{air_loop_cooling_capacity_fraction_min*100} % above the typical value of #{target_tons_per_area_ip.round} #{inverted_units}.")
        end
      end

      # check heating capacity of thermal zones in the model with exterior exposure
      report_name = 'HVACSizingSummary'
      table_name = 'Zone Sensible Heating'
      column_name = 'User Design Load per Area'
      target = options['zone_heating_capacity']['target']
      fraction_min = options['zone_heating_capacity']['min']
      fraction_max = options['zone_heating_capacity']['max']
      units_ip = options['zone_heating_capacity']['units']
      units_si= 'W/m^2'
      @model.getThermalZones.sort.each do |thermal_zone|
        next if thermal_zone.canBePlenum
        next if thermal_zone.exteriorSurfaceArea == 0.0
        query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='#{report_name}' and TableName='#{table_name}' and RowName= '#{thermal_zone.name.get.upcase}' and ColumnName= '#{column_name}'"
        results = @sql.execAndReturnFirstDouble(query) # W/m^2
        model_zone_heating_capacity_ip = OpenStudio.convert(results.to_f,units_si,units_ip).get
        # check actual against target
        if model_zone_heating_capacity_ip < target*(1.0 - fraction_min)
          check_elems <<  OpenStudio::Attribute.new("flag", "Capacity of #{model_zone_heating_capacity_ip.round(2)} Btu/ft^2*h for #{thermal_zone.name.get} is more than #{fraction_min*100} % below the typical value of #{target.round(2)} Btu/ft^2*h.")
        elsif model_zone_heating_capacity_ip > target*(1.0 + fraction_max)
          check_elems <<  OpenStudio::Attribute.new("flag", "Capacity of #{model_zone_heating_capacity_ip.round(2)} Btu/ft^2*h for #{thermal_zone.name.get} is more than #{fraction_max*100} % above the typical value of #{target.round(2)} Btu/ft^2*h.")
        end
      end

    rescue => e
      # brief description of ruby error
      check_elems << OpenStudio::Attribute.new("flag", "Error prevented QAQC check from running (#{e}).")

      # backtrace of ruby error for diagnostic use
      #check_elems << OpenStudio::Attribute.new("flag", "#{e.backtrace.join("\n")}")
    end

    # add check_elms to new attribute
    check_elem = OpenStudio::Attribute.new("check", check_elems)

    return check_elem
    # note: registerWarning and registerValue will be added for checks downstream using os_lib_reporting_qaqc.rb

  end

end  