module OsLib_QAQC

  # include any general notes about QAQC method here

  #checks the number of unmet hours in the model
  def check_simultaneous_heating_and_cooling(category,max_pass)

    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "Simultaneous Heating and Cooling")
    check_elems << OpenStudio::Attribute.new("category", category)
    check_elems << OpenStudio::Attribute.new("description", "Check for simultaneous heating and cooling by looping through all Single Duct VAV Reheat Air Terminals and analyzing hourly data when there is a cooling load. ")

    begin

      # get the weather file run period (as opposed to design day run period)
      ann_env_pd = nil
      @sql.availableEnvPeriods.each do |env_pd|
        env_type = @sql.environmentType(env_pd)
        if env_type.is_initialized
          if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
            ann_env_pd = env_pd
            break
          end
        end
      end

      # only try to get the annual timeseries if an annual simulation was run
      if ann_env_pd.nil?
        check_elems << OpenStudio::Attribute.new("flag","Cannot find the annual simulation run period, cannot determine simultaneous heating and cooling.")
        return check_elem
      end

      # For each VAV reheat terminal, calculate
      # the annual total % reheat hours.
      @model.getAirTerminalSingleDuctVAVReheats.each do |term|

        # Reheat coil heating rate
        rht_coil = term.reheatCoil
        key_value =  rht_coil.name.get.to_s.upcase # must be in all caps.
        time_step = "Hourly" # "Zone Timestep", "Hourly", "HVAC System Timestep"
        variable_name = "Heating Coil Heating Rate"
        variable_name_alt = "Heating Coil Air Heating Rate"
        rht_rate_ts = @sql.timeSeries(ann_env_pd, time_step, variable_name, key_value) # key value would go at the end if we used it.

        # try and alternate variable name
        if rht_rate_ts.empty?
          rht_rate_ts = @sql.timeSeries(ann_env_pd, time_step, variable_name_alt, key_value) # key value would go at the end if we used it.
        end

        if rht_rate_ts.empty?
          check_elems << OpenStudio::Attribute.new("flag","Heating Coil (Air) Heating Rate Timeseries not found for #{key_value}.")
        else

          rht_rate_ts = rht_rate_ts.get.values
          # Put timeseries into array
          rht_rate_vals = []
          for i in 0..(rht_rate_ts.size - 1)
            rht_rate_vals << rht_rate_ts[i]
          end

          # Zone Air Terminal Sensible Heating Rate
          key_value =  "ADU #{term.name.get.to_s.upcase}" # must be in all caps.
          time_step = "Hourly" # "Zone Timestep", "Hourly", "HVAC System Timestep"
          variable_name = "Zone Air Terminal Sensible Cooling Rate"
          clg_rate_ts = @sql.timeSeries(ann_env_pd, time_step, variable_name, key_value) # key value would go at the end if we used it.
          if clg_rate_ts.empty?
            check_elems << OpenStudio::Attribute.new("flag","Zone Air Terminal Sensible Cooling Rate Timeseries not found for #{key_value}.")
          else

            clg_rate_ts = clg_rate_ts.get.values
            # Put timeseries into array
            clg_rate_vals = []
            for i in 0..(clg_rate_ts.size - 1)
              clg_rate_vals << clg_rate_ts[i]
            end

            # Loop through each timestep and calculate the hourly
            # % reheat value.
            ann_rht_hrs = 0
            ann_clg_hrs = 0
            ann_pcts = []
            rht_rate_vals.zip(clg_rate_vals).each do |rht_w, clg_w|
              # Skip hours with no cooling (in heating mode)
              next if clg_w == 0
              pct_overcool_rht = rht_w / (rht_w + clg_w)
              ann_rht_hrs += pct_overcool_rht # implied * 1hr b/c hrly results
              ann_clg_hrs += 1
              ann_pcts << pct_overcool_rht.round(3)
            end

            # Calculate annual % reheat hours
            ann_pct_reheat = ((ann_rht_hrs / ann_clg_hrs)*100).round(1)

            # Compare to limit
            if ann_pct_reheat > max_pass * 100.0
              check_elems << OpenStudio::Attribute.new("flag", "#{term.name} has #{ann_pct_reheat}% overcool-reheat, which is greater than the limit of #{max_pass * 100.0}%. This terminal is in cooling mode for #{ann_clg_hrs} hours of the year.")
            end

          end

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