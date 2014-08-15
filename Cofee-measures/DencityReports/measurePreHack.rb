# DencityReports generates data that are required for the DEnCity API.

# Author: Henry Horsey (github: henryhorsey)
# Creation Date: 6/27/2014

class DencityReports < OpenStudio::Ruleset::ReportingUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Dencity Reports"
  end

  #define the arguments that the user will input
  def arguments
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make choice argument for facade
    choices = OpenStudio::StringVector.new
    choices << "JSON"
    choices << "CSV"
    choices << "Both"
    output_format = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("output_format", choices)
    output_format.setDisplayName("Output Format")
    output_format.setDefaultValue("JSON")
    args << output_format

    return args
  end


  #sql_query method
  def sql_query(runner, sql, report_name, query)
    val = nil
    result = sql.execAndReturnFirstDouble("SELECT Value FROM TabularDataWithStrings WHERE ReportName='#{report_name}' AND #{query}")
    if result.empty?
      runner.registerWarning("Query failed for #{report_name} and #{query}")
    else
      begin
        val = result.get
      rescue Exception => e
        val = nil
        runner.registerWarning("Query result.get failed")
      end
    end

    val
  end

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    require 'ruby-prof'

    begin
      RubyProf.start

      output_format = runner.getStringArgumentValue("output_format",user_arguments)
      os_version = OpenStudio::VersionString.new(OpenStudio::openStudioVersion())
      min_version_feature1 = OpenStudio::VersionString.new("1.2.3")
      require 'time'

      # determine how to format time series output
      json_flag = FALSE
      csv_flag = FALSE
      if output_format == "JSON" || output_format == "Both"
        json_flag = TRUE
      end
      if output_format == "CSV" || output_format == "Both"
        csv_flag = TRUE
      end

      # get the last model and sql file
      model = runner.lastOpenStudioModel
      if model.empty?
        runner.registerError("Cannot find last model.")
        return false
      end
      model = model.get

      runner.registerInfo("Model loaded")

      sqlFile = runner.lastEnergyPlusSqlFile
      if sqlFile.empty?
        runner.registerError("Cannot find last sql file.")
        return false
      end
      sqlFile = sqlFile.get
      model.setSqlFile(sqlFile)

      runner.registerInfo("Sql loaded")

      # put data into variables, these are available in the local scope binding
      #building_name = model.getBuilding.name.get

      #get end use totals for fuels
      site_energy_use = 0.0
      OpenStudio::EndUseFuelType.getValues.each do |fuel_type|
        fuel_type = OpenStudio::EndUseFuelType.new(fuel_type).valueDescription
        fuel_type_aggregation = 0.0
        OpenStudio::EndUseCategoryType.getValues.each do |category_type|
          category_str = OpenStudio::EndUseCategoryType.new(category_type).valueDescription
          temp_val = sql_query(runner, sqlFile, 'AnnualBuildingUtilityPerformanceSummary', "TableName='End Uses' AND RowName='#{category_type}' AND ColumnName='#{fuel_type}'")
          if temp_val
            if (os_version >= min_version_feature1)
              unless fuel_type == 'Water'
                fuel_flag = 0
              else
                fuel_flag = 1
              end

              #raise "temp_val is #{temp_val} of class #{temp_val.class}"

              prefix_str = OpenStudio::toUnderscoreCase("#{fuel_type}_#{category_str}")
              if fuel_flag == 0
                runner.registerValue("#{prefix_str}", temp_val, "GJ")
              else
                runner.registerValue("#{prefix_str}", temp_val, "m3")
              end
            end
            fuel_type_aggregation += temp_val
          end
        end

        if (os_version >= min_version_feature1)
          unless fuel_type == 'Water'
            fuel_flag = 0
          else
            fuel_flag = 1
          end
          if fuel_flag == 0
            runner.registerValue(OpenStudio::toUnderscoreCase("total_#{fuel_type}_end_use"), fuel_type_aggregation, "GJ")
          else
            runner.registerValue(OpenStudio::toUnderscoreCase("total_#{fuel_type}_end_use"), fuel_type_aggregation, "m3")
          end
        end
        site_energy_use += fuel_type_aggregation
      end

      #get monthly fuel aggregates
      OpenStudio::EndUseFuelType.getValues.each do |fuel_type|
        fuel_type = OpenStudio::EndUseFuelType.new(fuel_type).valueDescription
        OpenStudio::MonthOfYear.getValues.each do |month|
          if month >= 1 and month <= 12
            fuel_and_month_aggregation = 0.0
            OpenStudio::EndUseCategoryType::getValues.each do |category_type|
              if not sqlFile.energyConsumptionByMonth(OpenStudio::EndUseFuelType.new(fuel_type),
                                                      OpenStudio::EndUseCategoryType.new(category_type),
                                                      OpenStudio::MonthOfYear.new(month)).empty?
                valInJ = sqlFile.energyConsumptionByMonth(OpenStudio::EndUseFuelType.new(fuel_type),
                                                          OpenStudio::EndUseCategoryType.new(category_type),
                                                          OpenStudio::MonthOfYear.new(month)).get
                fuel_and_month_aggregation += valInJ
              end
            end
            if (os_version >= min_version_feature1)
              month_str = OpenStudio::MonthOfYear.new(month).valueDescription
              unless fuel_type == 'Water'
                fuel_flag = 0
              else
                fuel_flag = 1
              end
              prefix_str = OpenStudio::toUnderscoreCase("#{month_str}_end_use_#{fuel_type}")
              if fuel_flag == 0
                runner.registerValue("#{prefix_str}", OpenStudio::convert(fuel_and_month_aggregation, "J", "GJ").get, "GJ")
              else
                runner.registerValue("#{prefix_str}", fuel_and_month_aggregation, "m3")
              end
            end
          end
        end
      end

      #Run several one-off sql queries
      if (os_version >= min_version_feature1)
        runner.registerValue("site_energy_use", site_energy_use, "GJ")

        # queries that don't have API methods yet
        total_building_area = sql_query(runner, sqlFile, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Building Area' AND RowName='Total Building Area' AND ColumnName='Area'")
        runner.registerValue("total_building_area", total_building_area, "m2") if total_building_area

        net_conditioned_building_area = sql_query(runner, sqlFile, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Building Area' AND RowName='Net Conditioned Building Area' AND ColumnName='Area'")
        runner.registerValue("net_conditioned_building_area", net_conditioned_building_area, "m2") if net_conditioned_building_area

        unconditioned_building_area = sql_query(runner, sqlFile, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Building Area' AND RowName='Unconditioned Building Area' AND ColumnName='Area'")
        runner.registerValue("unconditioned_building_area", unconditioned_building_area, "m2") if unconditioned_building_area

        total_site_energy_eui = sql_query(runner, sqlFile, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Site and Source Energy' AND RowName='Total Site Energy' AND ColumnName='Energy Per Conditioned Building Area'")
        runner.registerValue("total_site_energy_eui", total_site_energy_eui, "MJ/m2") if total_site_energy_eui

        total_source_energy_eui = sql_query(runner, sqlFile, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Site and Source Energy' AND RowName='Total Source Energy' AND ColumnName='Energy Per Conditioned Building Area'")
        runner.registerValue("total_source_energy_eui", total_source_energy_eui, "MJ/m2") if total_source_energy_eui

        time_setpoint_not_met_during_occupied_heating = sql_query(runner, sqlFile, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Comfort and Setpoint Not Met Summary' AND RowName='Time Setpoint Not Met During Occupied Heating' AND ColumnName='Facility'")
        runner.registerValue("time_setpoint_not_met_during_occupied_heating", time_setpoint_not_met_during_occupied_heating, "hr") if time_setpoint_not_met_during_occupied_heating

        time_setpoint_not_met_during_occupied_cooling = sql_query(runner, sqlFile, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Comfort and Setpoint Not Met Summary' AND RowName='Time Setpoint Not Met During Occupied Cooling' AND ColumnName='Facility'")
        runner.registerValue("time_setpoint_not_met_during_occupied_cooling", time_setpoint_not_met_during_occupied_cooling, "hr") if time_setpoint_not_met_during_occupied_cooling

        time_setpoint_not_met_during_occupied_hours = time_setpoint_not_met_during_occupied_heating + time_setpoint_not_met_during_occupied_cooling
        runner.registerValue("time_setpoint_not_met_during_occupied_hours", time_setpoint_not_met_during_occupied_hours, "hr") if time_setpoint_not_met_during_occupied_hours
      end

      #get exterior wall area
      exterior_wall_area = 0.0
      surfaces = model.getSurfaces
      surfaces.each do |surface|
        if surface.outsideBoundaryCondition == "Outdoors" and surface.surfaceType == "Wall"
          exterior_wall_area += surface.netArea
        end
      end
      if (os_version >= min_version_feature1)
        runner.registerValue("exterior_wall_area", exterior_wall_area, "m2")
      end

      #get exterior roof area
      exterior_roof_area = 0.0
      surfaces = model.getSurfaces
      surfaces.each do |surface|
        if surface.outsideBoundaryCondition == "Outdoors" and surface.surfaceType == "RoofCeiling"
          exterior_roof_area += surface.netArea
        end
      end
      if (os_version >= min_version_feature1)
        runner.registerValue("exterior_roof_area", exterior_roof_area, "m2")
      end

      #get ground plate area
      ground_plate_area = 0.0
      surfaces = model.getSurfaces
      surfaces.each do |surface|
        if surface.outsideBoundaryCondition == "Ground" and surface.surfaceType == "Floor"
          ground_plate_area += surface.netArea
        end
      end
      if (os_version >= min_version_feature1)
        runner.registerValue("ground_plate_area", ground_plate_area, "m2")
      end

      #get exterior fenestration area
      exterior_fenestration_area = 0.0
      subsurfaces = model.getSubSurfaces
      subsurfaces.each do |subsurface|
        if subsurface.outsideBoundaryCondition == "Outdoors"
          if subsurface.subSurfaceType == "FixedWindow" or subsurface.subSurfaceType == "OperableWindow"
            exterior_fenestration_area += subsurface.netArea
          end
        end
      end
      if (os_version >= min_version_feature1)
        runner.registerValue("exterior_fenestration_area", exterior_fenestration_area, "m2")
      end

      # #get density of economizers in airloops
      # num_airloops = 0
      # num_economizers = 0
      # model.getAirLoopHVACs.each do |air_loop|
      # num_airloops += 1
      # if not air_loop.airLoopHVACOutdoorAirSystem.empty?
      # if not air_loop.airLoopHVACOutdoorAirSystem.empty?
      # air_loop_oa = air_loop.airLoopHVACOutdoorAirSystem
      # if not air_loop_oa.getControllerOutdoorAir.empty?
      # air_loop_oa_controller = air_loop_oa.getControllerOutdoorAir
      # if air_loop_oa_controller.getEconomizerControlType != "NoEconomizer"
      # num_economizers += 1
      # end
      # end
      # end
      # end
      # end
      # economizer_density = num_economizers / num_airloops
      # if (os_version >= min_version_feature1)
      # runner.registerValue("economizer_density",economizer_density,"")
      # end

      #get average lighting power density, occupancy, rotation, infiltration, and floor to floor height
      building = model.getBuilding
      building_rotation = building.northAxis
      floor_to_floor_height = building.nominalFloortoFloorHeight
      total_occupancy = building.numberOfPeople
      occupancy_density = building.peoplePerFloorArea
      total_lighting_power = building.lightingPower
      lighting_power_density = building.lightingPowerPerFloorArea
      infiltration_rate = building.infiltrationDesignFlowRate
      if (os_version >= min_version_feature1)
        runner.registerValue("building_rotation", building_rotation, "deg")
        runner.registerValue("floor_to_floor_height", floor_to_floor_height, "m")
        runner.registerValue("total_occupancy", total_occupancy, "people")
        runner.registerValue("occupant_density", occupancy_density, "people/m2")
        runner.registerValue("total_lighting_power", total_lighting_power, "W")
        runner.registerValue("lighting_power_density", lighting_power_density, "W/m2")
        runner.registerValue("infiltration_rate", infiltration_rate, "m3/s")
      end

      #get conditioned, unconditioned, and total air volumes
      total_building_volume = total_building_area * floor_to_floor_height
      if (os_version >= min_version_feature1)
        runner.registerValue("total_building_volume", total_building_volume, "m3")
      end

      #get window to wall ratios
      window_to_wall_ratio_north = sql_query(runner, sqlFile, 'InputVerificationandResultsSummary', "TableName='Window-Wall Ratio' AND RowName='Gross Window-Wall Ratio' AND ColumnName='North (315 to 45 deg)'")
      window_to_wall_ratio_south = sql_query(runner, sqlFile, 'InputVerificationandResultsSummary', "TableName='Window-Wall Ratio' AND RowName='Gross Window-Wall Ratio' AND ColumnName='South (135 to 225 deg)'")
      window_to_wall_ratio_east = sql_query(runner, sqlFile, 'InputVerificationandResultsSummary', "TableName='Window-Wall Ratio' AND RowName='Gross Window-Wall Ratio' AND ColumnName='East (45 to 135 deg)'")
      window_to_wall_ratio_west = sql_query(runner, sqlFile, 'InputVerificationandResultsSummary', "TableName='Window-Wall Ratio' AND RowName='Gross Window-Wall Ratio' AND ColumnName='West (225 to 315 deg)'")
      if (os_version >= min_version_feature1)
        runner.registerValue("window_to_wall_ratio_north", window_to_wall_ratio_north, "%") if window_to_wall_ratio_north
        runner.registerValue("window_to_wall_ratio_south", window_to_wall_ratio_south, "%") if window_to_wall_ratio_south
        runner.registerValue("window_to_wall_ratio_east", window_to_wall_ratio_east, "%") if window_to_wall_ratio_east
        runner.registerValue("window_to_wall_ratio_west", window_to_wall_ratio_west, "%") if window_to_wall_ratio_west
      end

      #get aspect ratios
      north_wall_area = sql_query(runner, sqlFile, 'InputVerificationandResultsSummary', "TableName='Window-Wall Ratio' AND RowName='Gross Wall Area' AND ColumnName='North (315 to 45 deg)'")
      east_wall_area = sql_query(runner, sqlFile, 'InputVerificationandResultsSummary', "TableName='Window-Wall Ratio' AND RowName='Gross Wall Area' AND ColumnName='East (45 to 135 deg)'")
      if north_wall_area && east_wall_area
        aspect_ratio = north_wall_area / east_wall_area
        if (os_version >= min_version_feature1)
          runner.registerValue("aspect_ratio", aspect_ratio, "")
        end
      end

      #get meter timeseries data and output as a json
      #todo: find a way for the sql call to not rely on RUN PERIOD 1
      available_meters = sqlFile.execAndReturnVectorOfString("SELECT VariableName FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND ReportingFrequency='Zone Timestep'")
      get_timeseries_flag = 1
      if available_meters.empty?
        runner.registerWarning("No meters found with Zone Timestep reporting frequency to extract timeseries data from")
      else
        begin
          meter_strings = available_meters.get
          runner.registerInfo("The following meters were found: #{meter_strings}")
        rescue Exception => e
          get_timeseries_flag = 0
          runner.registerWarning("Unable to retrieve timeseries strings")
        end
      end
      if get_timeseries_flag == 1
        if json_flag
          out_array = []
          meter_strings.each do |meter_string|
            runner.registerInfo("Getting timeseries data for #{meter_string}")
            unless sqlFile.timeSeries("RUN PERIOD 1", "Zone Timestep", meter_string, "").empty?
              sql_ts = sqlFile.timeSeries("RUN PERIOD 1", "Zone Timestep", meter_string, "").get
              ts_values = sql_ts.values
              ts_times = sql_ts.dateTimes
              if ts_values.size == ts_times.size
                timeseries_out = {}
                for i in 0..ts_times.size - 1
                  timeseries_out[Time.parse(ts_times[i].toString()).to_i*1000] = ts_values[i]
                end
                meter_hash = { timeseries: {}}
                meter_hash[:timeseries][:fuel] = meter_string.split(':')[0]
                meter_hash[:timeseries][:interval] = Time.parse(ts_times[1].toString()).to_i - Time.parse(ts_times[0].toString()).to_i
                meter_hash[:timeseries][:interval_units] = 'seconds'
                meter_hash[:timeseries][:data] = timeseries_out
                out_array << meter_hash
              else
                register.warning("Timeseries values for #{meter_string} did not match the length of the dateTimes")
              end
            else
               register.warning("Timeseries #{meter_string} was empty.")
            end
          end

          File.open("dencity_timeseries.json", "w") do |file|
            file << JSON.pretty_generate({data: out_array})
            runner.registerInfo("Saved timeseries data as dencity_timeseries.json")
          end
        end

        if csv_flag
          runner.registerInfo("Populating ISO8601 data for csv output")
          unless sqlFile.timeSeries("RUN PERIOD 1", "Zone Timestep", meter_strings[0], "").empty?
            sql_ts = sqlFile.timeSeries("RUN PERIOD 1", "Zone Timestep", meter_strings[0], "").get
            ts_times = sql_ts.dateTimes
            csv_holder = Array.new
            temp = Array.new
            temp[0] = "Timestamp (ISO8601)"
            for i in 1..ts_times.length
              temp[i] = Time.parse(ts_times[i-1].toString()).utc.iso8601(0)
            end
            csv_holder[0] = temp
            check_length = ts_times.length
            timeseries_from = meter_strings[0].split(':')[0]
            for i in 0..meter_strings.size - 1
              temp = Array.new
              meter_string = meter_strings[i]
              runner.registerInfo("Getting timeseries data for #{meter_string}")
              unless sqlFile.timeSeries("RUN PERIOD 1", "Zone Timestep", meter_string, "").empty?
                sql_ts = sqlFile.timeSeries("RUN PERIOD 1", "Zone Timestep", meter_string, "").get
                ts_values = sql_ts.values
                ts_times = sql_ts.dateTimes
                if ts_times.length == check_length
                  temp[0] =  meter_string.split(':')[0]
                  for j in 1..ts_times.length
                    temp[j] = ts_values[j - 1]
                  end
                  csv_holder[csv_holder.length] = temp
                else
                  register.warning("Timeseries values for #{meter_string} did not match the length of the dateTimes found in #{timeseries_from}")
                end
              else
                register.warning("Timeseries #{meter_string} was empty.")
              end
            end
            csv_holder = csv_holder.transpose
            CSV.open("dencity_timeseries.csv", "wb") do |csv|
              csv_holder.each do |elem|
                csv << elem
              end
            end
            runner.registerInfo("Saved timeseries data as dencity_timeseries.csv")
          else
            runner.registerWarning("Unable to populate ISO8601 data as #{meter_strings[0]} was empty")
          end
        end
      end

      #closing the sql file
      sqlFile.close

      #reporting final condition
      runner.registerFinalCondition("Dencity Report generated successfully.")

    ensure

      profile_results = RubyProf.stop
      FileUtils.mkdir_p 'results'
      File.open("results/profile-graph.html", 'w') { |f| RubyProf::GraphHtmlPrinter.new(profile_results).print(f) }
      File.open("results/profile-flat.txt", 'w') { |f| RubyProf::FlatPrinter.new(profile_results).print(f) }
      File.open("results/profile-tree.prof", 'w') { |f| RubyProf::CallTreePrinter.new(profile_results).print(f) }


    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
DencityReports.new.registerWithApplication