# DencityReports generates data that are required for the DEnCity API.

# Author: Henry Horsey (github: henryhorsey)
# Creation Date: 6/27/2014

class DencityReports < OpenStudio::Ruleset::ReportingUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    'Dencity Reports'
  end

  #define the arguments that the user will input
  def arguments
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make choice argument for facade
    choices = OpenStudio::StringVector.new
    choices << 'MSGPACK'
    choices << 'CSV'
    choices << 'Both'
    output_format = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('output_format', choices)
    output_format.setDisplayName('Output Format')
    output_format.setDefaultValue('Both')
    args << output_format

    args
  end

  #short_os_fuel method
  def short_os_fuel(fuel_string)
    val = nil
    fuel_vec = fuel_string.split(' ')
    if fuel_vec[0] == 'Electricity'
      val = 'Elec'
    elsif fuel_vec[0] == 'District'
      if fuel_vec[1] == 'Heating'
        val = 'DistHeat'
      elsif fuel_vec[1] == 'Cooling'
        val = 'DistCool'
      end
    elsif fuel_vec[0] == 'Natural'
      val = 'NatGas'
    elsif fuel_vec[0] == 'Additional'
      val = 'Other'
    elsif fuel_vec[0] == 'Water'
      val = 'Water'
    else
      val = 'Unknown'
    end

    val

  end

  #short_os_cat method
  def short_os_cat(category_string)
    val = nil
    cat_vec = category_string.split(' ')
    if cat_vec[0] == 'Heating'
        val = 'Heat'
    elsif cat_vec[0] == 'Cooling'
      val = 'Cool'
    elsif cat_vec[0] == 'Humidification'
      val = 'Humid'
    elsif cat_vec[0] == 'Interior'
      if cat_vec[1] == 'Lighting'
        val = 'IntLht'
      elsif cat_vec[1] == 'Equipment'
        val = 'IntEqu'
      end
    elsif cat_vec[0] == 'Exterior'
      if cat_vec[1] == 'Lighting'
        val = 'ExtLht'
      elsif cat_vec[1] == 'Equipment'
        val = 'ExtEqu'
      end
    elsif cat_vec[0] == 'Heat'
      if cat_vec[1] == 'Recovery'
        val = 'HeatRec'
      elsif cat_vec[1] == 'Rejection'
        val = 'HeatRej'
      end
    elsif cat_vec[0] == 'Pumps'
      val = 'Pumps'
    elsif cat_vec[0] == 'Fans'
      val = 'Fans'
    elsif cat_vec[0] == 'Refrigeration'
      val = 'Rfg'
    elsif cat_vec[0] == 'Generators'
      val = 'Gen'
    elsif cat_vec[0] == 'Water'
      val = 'WtrSys'
    else
      val = 'Unknown'
    end

    val

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
      rescue
        val = nil
        runner.registerWarning('Query result.get failed')
      end
    end

    val
  end

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    #use the built-in error checking
    unless runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    # require 'ruby-prof'

    begin
      # RubyProf.start

      output_format = runner.getStringArgumentValue('output_format',user_arguments)
      os_version = OpenStudio::VersionString.new(OpenStudio::openStudioVersion())
      min_version_feature1 = OpenStudio::VersionString.new('1.2.3')
      require 'time'

      unless os_version >= min_version_feature1
        runner.registerError('Dencity Reports requires a version of OpenStudio greater than 1.2.3.')
        return false
      end

      # determine how to format time series output
      msgpack_flag = FALSE
      csv_flag = FALSE
      if output_format == 'MSGPACK' || output_format == 'Both'
        msgpack_flag = TRUE
      end
      if output_format == 'CSV' || output_format == 'Both'
        csv_flag = TRUE
      end

      # get the last model and sql file
      model = runner.lastOpenStudioModel
      if model.empty?
        runner.registerError('Cannot find last model.')
        return false
      end
      model = model.get
      building = model.getBuilding

      runner.registerInfo('Model loaded')

      sql_file = runner.lastEnergyPlusSqlFile
      if sql_file.empty?
        runner.registerError('Cannot find last sql file.')
        return false
      end
      sql_file = sql_file.get
      model.setSqlFile(sql_file)

      runner.registerInfo('Sql loaded')

      #Initalize array that will be used to construct the DEnCity metadata csv
      metadata = Array.new
      metadata[0] = ['name','display_name','short_name','description','unit','datatype','user_defined']

      #get end use totals for fuels
      site_energy_use = 0.0
      OpenStudio::EndUseFuelType.getValues.each do |fuel_type|
        fuel_str = OpenStudio::EndUseFuelType.new(fuel_type).valueDescription
        fuel_type_aggregation = 0.0
        if fuel_str != 'Water'
          runner_units = 'GJ'
          metadata_units = 'gigajoule'
        else
          runner_units = 'm3'
          metadata_units = 'cubic_meter'
        end
        OpenStudio::EndUseCategoryType.getValues.each do |category_type|
          category_str = OpenStudio::EndUseCategoryType.new(category_type).valueDescription
          temp_val = sql_query(runner, sql_file, 'AnnualBuildingUtilityPerformanceSummary', "TableName='End Uses' AND RowName='#{category_str}' AND ColumnName='#{fuel_str}'")
          if temp_val and temp_val !=0
            prefix_str = OpenStudio::toUnderscoreCase("#{fuel_str}_#{category_str}")
            runner.registerValue("#{prefix_str}", temp_val, "#{runner_units}")
            short_name = "#{short_os_fuel(fuel_str)}_#{short_os_cat(category_str)}"
            metadata[metadata.length] = [prefix_str, "#{category_str} #{fuel_str}", short_name, "Total #{fuel_str} used for #{category_str}", metadata_units, 'double', 'FALSE']
            fuel_type_aggregation += temp_val
          end
        end
        if fuel_type_aggregation != 0
          prefix_str = OpenStudio::toUnderscoreCase("total_#{fuel_str}_end_use")
          runner.registerValue(prefix_str, fuel_type_aggregation, 'm3')
          short_name = "Tot_#{short_os_fuel(fuel_str)}_EndUse"
          metadata[metadata.length] = [prefix_str, "Total #{fuel_str} End Use", short_name, "Total #{fuel_str} End Use", metadata_units, 'double', 'FALSE']
          site_energy_use += fuel_type_aggregation if fuel_str != 'Water'
        end
      end

      runner.registerValue('site_energy_use', site_energy_use, 'GJ')
      metadata[metadata.length] = ['site_energy_use', 'Total Site Energy Use', 'Tot Site Energy', 'Total Site End Use Energy', 'gigajoule', 'double', 'FALSE']

      #get monthly fuel aggregates
      OpenStudio::EndUseFuelType.getValues.each do |fuel_type|
        fuel_str = OpenStudio::EndUseFuelType.new(fuel_type).valueDescription
        if fuel_str != 'Water'
          runner_units = 'GJ'
          metadata_units = 'gigajoule'
        else
          runner_units = 'm3'
          metadata_units = 'cubic_meter'
        end
        OpenStudio::MonthOfYear.getValues.each do |month|
          if month >= 1 and month <= 12
            fuel_and_month_aggregation = 0.0
            OpenStudio::EndUseCategoryType::getValues.each do |category_type|
              if sql_file.energyConsumptionByMonth(OpenStudio::EndUseFuelType.new(fuel_str), OpenStudio::EndUseCategoryType.new(category_type),OpenStudio::MonthOfYear.new(month)).is_initialized
                val_in_j = sql_file.energyConsumptionByMonth(OpenStudio::EndUseFuelType.new(fuel_str),OpenStudio::EndUseCategoryType.new(category_type),OpenStudio::MonthOfYear.new(month)).get
                fuel_and_month_aggregation += val_in_j
              end
            end
            if fuel_and_month_aggregation != 0
              month_str = OpenStudio::MonthOfYear.new(month).valueDescription
              prefix_str = OpenStudio::toUnderscoreCase("#{month_str}_end_use_#{fuel_str}")
              runner.registerValue("#{prefix_str}", OpenStudio::convert(fuel_and_month_aggregation, 'J', 'GJ').get, "#{runner_units}")
              short_name = "#{month_str[0..2]} #{short_os_fuel(fuel_str)} EndUse"
              metadata[metadata.length] = ["#{prefix_str}", "#{month_str} #{fuel_str} End Use", short_name, "Total #{fuel_str} End Use in #{month_str}", metadata_units, 'double', 'FALSE']
            end
          end
        end
      end

      # queries that don't have API methods yet

      building_footprint = sql_query(runner, sql_file, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Building Area' AND RowName='Total Building Area' AND ColumnName='Area'")
      runner.registerValue('building_footprint', building_footprint, 'm2') if building_footprint
      metadata[metadata.length] = ['building_footprint', 'Total Building Footprint', 'Bld Ftpnt', 'Total building area as calculated by E+', 'square_meter', 'double', 'FALSE'] if building_footprint

      conditioned_footprint = sql_query(runner, sql_file, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Building Area' AND RowName='Net Conditioned Building Area' AND ColumnName='Area'")
      runner.registerValue('conditioned_footprint', conditioned_footprint, 'm2') if conditioned_footprint
      metadata[metadata.length] = ['conditioned_footprint', 'Total Conditioned Footprint', 'Cond Bld Ftpnt', 'Total conditioned building area as calculated by E+', 'square_meter', 'double', 'FALSE'] if conditioned_footprint

      unconditioned_footprint = sql_query(runner, sql_file, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Building Area' AND RowName='Unconditioned Building Area' AND ColumnName='Area'")
      runner.registerValue('unconditioned_footprint', unconditioned_footprint, 'm2') if unconditioned_footprint
      metadata[metadata.length] = ['unconditioned_footprint', 'Total Unconditioned Footprint', 'Uncond Bld Ftpnt', 'Total unconditioned building area as calculated by E+', 'square_meter', 'double', 'FALSE'] if unconditioned_footprint

      total_site_eui = sql_query(runner, sql_file, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Site and Source Energy' AND RowName='Total Site Energy' AND ColumnName='Energy Per Conditioned Building Area'")
      runner.registerValue('total_site_eui', total_site_eui, 'MJ/m2') if total_site_eui
      metadata[metadata.length] = ['total_site_eui', 'Total Site Energy Use Intensity', 'Site EUI', 'Total site energy use intensity per conditioned building area as calculated by E+', 'megajoules_per_square_meter', 'double', 'FALSE'] if total_site_eui

      total_source_eui = sql_query(runner, sql_file, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Site and Source Energy' AND RowName='Total Source Energy' AND ColumnName='Energy Per Conditioned Building Area'")
      runner.registerValue('total_source_eui', total_source_eui, 'MJ/m2') if total_source_eui
      metadata[metadata.length] = ['total_source_eui', 'Total Source Energy Use Intensity', 'Source EUI', 'Total site energy use intensity per conditioned building area as calculated by E+', 'megajoules_per_square_meter', 'double', 'FALSE'] if total_source_eui

      time_setpoint_not_met_during_occupied_heating = sql_query(runner, sql_file, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Comfort and Setpoint Not Met Summary' AND RowName='Time Setpoint Not Met During Occupied Heating' AND ColumnName='Facility'")
      runner.registerValue('time_setpoint_not_met_during_occupied_heating', time_setpoint_not_met_during_occupied_heating, 'hr') if time_setpoint_not_met_during_occupied_heating
      metadata[metadata.length] = ['time_setpoint_not_met_during_occupied_heating', 'Occupied Time During Which Heating Setpoint Not Met', 'SetpointMissedHeat', 'Hours during which the building was occupied but the heating setpoint temperature was not met', 'hour', 'double', 'FALSE'] if time_setpoint_not_met_during_occupied_heating

      time_setpoint_not_met_during_occupied_cooling = sql_query(runner, sql_file, 'AnnualBuildingUtilityPerformanceSummary', "TableName='Comfort and Setpoint Not Met Summary' AND RowName='Time Setpoint Not Met During Occupied Cooling' AND ColumnName='Facility'")
      runner.registerValue('time_setpoint_not_met_during_occupied_cooling', time_setpoint_not_met_during_occupied_cooling, 'hr') if time_setpoint_not_met_during_occupied_cooling
      metadata[metadata.length] = ['time_setpoint_not_met_during_occupied_cooling', 'Occupied Time During Which Cooling Setpoint Not Met', 'SetpointMissedCool', 'Hours during which the building was occupied but the cooling setpoint temperature was not met', 'hour', 'double', 'FALSE'] if time_setpoint_not_met_during_occupied_cooling

      time_setpoint_not_met_during_occupied_hours = time_setpoint_not_met_during_occupied_heating + time_setpoint_not_met_during_occupied_cooling
      runner.registerValue('time_setpoint_not_met_during_occupied_hours', time_setpoint_not_met_during_occupied_hours, 'hr') if time_setpoint_not_met_during_occupied_hours
      metadata[metadata.length] = ['time_setpoint_not_met_during_occupied_hours', 'Occupied Time During Which Temperature Setpoint Not Met', 'TotalSetpointMissed', 'Hours during which the building was occupied but the setpoint temperatures were not met', 'hour', 'double', 'FALSE'] if time_setpoint_not_met_during_occupied_hours

      window_to_wall_ratio_north = sql_query(runner, sql_file, 'InputVerificationandResultsSummary', "TableName='Window-Wall Ratio' AND RowName='Gross Window-Wall Ratio' AND ColumnName='North (315 to 45 deg)'")
      runner.registerValue('window_to_wall_ratio_north', window_to_wall_ratio_north, '%') if window_to_wall_ratio_north
      metadata[metadata.length] = ['window_to_wall_ratio_north', 'North Window to Wall Ratio', 'WWR North', 'Window to wall ratio of wall objects facing between 315 and 45 degrees', 'percent', 'double', 'FALSE'] if window_to_wall_ratio_north

      window_to_wall_ratio_south = sql_query(runner, sql_file, 'InputVerificationandResultsSummary', "TableName='Window-Wall Ratio' AND RowName='Gross Window-Wall Ratio' AND ColumnName='South (135 to 225 deg)'")
      runner.registerValue('window_to_wall_ratio_south', window_to_wall_ratio_south, '%') if window_to_wall_ratio_south
      metadata[metadata.length] = ['window_to_wall_ratio_south', 'South Window to Wall Ratio', 'WWR South', 'Window to wall ratio of wall objects facing between 135 and 225 degrees', 'percent', 'double', 'FALSE'] if window_to_wall_ratio_south

      window_to_wall_ratio_east = sql_query(runner, sql_file, 'InputVerificationandResultsSummary', "TableName='Window-Wall Ratio' AND RowName='Gross Window-Wall Ratio' AND ColumnName='East (45 to 135 deg)'")
      runner.registerValue('window_to_wall_ratio_east', window_to_wall_ratio_east, '%') if window_to_wall_ratio_east
      metadata[metadata.length] = ['window_to_wall_ratio_east', 'East Window to Wall Ratio', 'WWR East', 'Window to wall ratio of wall objects facing between 45 and 135 degrees', 'percent', 'double', 'FALSE'] if window_to_wall_ratio_east

      window_to_wall_ratio_west = sql_query(runner, sql_file, 'InputVerificationandResultsSummary', "TableName='Window-Wall Ratio' AND RowName='Gross Window-Wall Ratio' AND ColumnName='West (225 to 315 deg)'")
      runner.registerValue('window_to_wall_ratio_west', window_to_wall_ratio_west, '%') if window_to_wall_ratio_west
      metadata[metadata.length] = ['window_to_wall_ratio_west', 'West Window to Wall Ratio', 'WWR West', 'Window to wall ratio of wall objects facing between 225 and 315 degrees', 'percent', 'double', 'FALSE'] if window_to_wall_ratio_west

      # queries with one-line API methods
      building_rotation = building.northAxis
      runner.registerValue('building_rotation', building_rotation, 'deg') if building_rotation
      metadata[metadata.length] = ['building_rotation', 'Building Rotation', 'Bld Rot', 'Degrees of building north axis off of true north', 'degrees_angular', 'double', 'FALSE'] if building_rotation

      floor_to_floor_height = building.nominalFloortoFloorHeight
      runner.registerValue('floor_to_floor_height', floor_to_floor_height, 'm') if floor_to_floor_height
      metadata[metadata.length] = ['floor_to_floor_height', 'Floor to Floor Height', 'Flr2Flr Hght', 'Nominal floor to floor height of building', 'meter', 'double', 'FALSE'] if floor_to_floor_height

      total_occupancy = building.numberOfPeople
      runner.registerValue('total_occupancy', total_occupancy, 'people') if total_occupancy
      metadata[metadata.length] = ['total_occupancy', 'Total Building Occupancy', 'Bld Occ', 'Number of people in the buildinga as calculated by E+', 'none', 'double', 'FALSE'] if total_occupancy

      occupancy_density = building.peoplePerFloorArea
      runner.registerValue('occupant_density', occupancy_density, 'people/m2') if occupancy_density
      metadata[metadata.length] = ['occupancy_density', 'Building Occupancy Dencity', 'Occ Dens', 'Number of people per floor area as calculated by E+', 'none', 'double', 'FALSE'] if occupancy_density

      lighting_power = building.lightingPower
      runner.registerValue('lighting_power', lighting_power, 'W') if lighting_power
      metadata[metadata.length] = ['lighting_power', 'Lighting Power', 'Lght Pwr', 'Lighting power as calculated by E+', 'watt', 'double', 'FALSE'] if lighting_power

      lighting_power_density = building.lightingPowerPerFloorArea
      runner.registerValue('lighting_power_density', lighting_power_density, 'W/m2') if lighting_power_density
      metadata[metadata.length] = ['lighting_power_density', 'Lighting Power Density', 'Lght Pwr Dens', 'Lighting power density as calculated by E+', 'watts_per_square_meter', 'double', 'FALSE'] if lighting_power_density

      infiltration_rate = building.infiltrationDesignFlowRate
      runner.registerValue('infiltration_rate', infiltration_rate, 'm3/s') if infiltration_rate
      metadata[metadata.length] = ['infiltration_rate', 'Infiltration Rate', 'Infilt Rate', 'Infiltration rate of air into the building', 'cubic_meters_per_second', 'double', 'FALSE'] if infiltration_rate

      total_building_volume = building_footprint * floor_to_floor_height
      runner.registerValue('total_building_volume', total_building_volume, 'm3') if total_building_volume
      metadata[metadata.length] = ['total_building_volume', 'Total Building Volume', 'Bldg Vol', 'Building volume calculated by multiplying floor to floor height and footprint', 'cubic_meter', 'double', 'FALSE'] if total_building_volume

      #get building type name if it has been set
      if building.standardsBuildingType.is_initialized
        building_type = building.standardsBuildingType
        runner.registerValue('building_type', building_type, '') if building_type
        metadata[metadata.length] = ['building_type', 'Building Type', 'Bldg Type', 'Building type as defined by the user', 'none', 'string', 'FALSE'] if building_type
      end

      #get exterior wall, exterior roof, and ground plate areas
      exterior_wall_area = 0.0
      exterior_roof_area = 0.0
      ground_plate_area = 0.0
      surfaces = model.getSurfaces
      surfaces.each do |surface|
        if surface.outsideBoundaryCondition == 'Outdoors' and surface.surfaceType == 'Wall'
          exterior_wall_area += surface.netArea
        end
        if surface.outsideBoundaryCondition == 'Outdoors' and surface.surfaceType == 'RoofCeiling'
          exterior_roof_area += surface.netArea
        end
        if surface.outsideBoundaryCondition == 'Ground' and surface.surfaceType == 'Floor'
          ground_plate_area += surface.netArea
        end
      end

      runner.registerValue('exterior_wall_area', exterior_wall_area, 'm2') if exterior_wall_area
      metadata[metadata.length] = ['exterior_wall_area', 'Exterior Wall Area', 'Ext Wall Area', "Total area of all surfaces with the conditions of 'Outdoors' and 'Wall'", 'square_meter', 'double', 'FALSE'] if exterior_wall_area

      runner.registerValue('exterior_roof_area', exterior_roof_area, 'm2') if exterior_roof_area
      metadata[metadata.length] = ['exterior_roof_area', 'Exterior Roof Area', 'Ext Roof Area', "Total area of all surfaces with the conditions of 'Outdoors' and 'Roof'", 'square_meter', 'double', 'FALSE'] if exterior_roof_area

      runner.registerValue('ground_plate_area', ground_plate_area, 'm2') if ground_plate_area
      metadata[metadata.length] = ['ground_plate_area', 'Ground Plate Area', 'Gnd Plt Area', "Total area of all surfaces with the conditions of 'Ground' and 'Floor'", 'square_meter', 'double', 'FALSE'] if ground_plate_area

      #get exterior fenestration area
      exterior_fenestration_area = 0.0
      subsurfaces = model.getSubSurfaces
      subsurfaces.each do |subsurface|
        if subsurface.outsideBoundaryCondition == 'Outdoors'
          if subsurface.subSurfaceType == 'FixedWindow' or subsurface.subSurfaceType == 'OperableWindow'
            exterior_fenestration_area += subsurface.netArea
          end
        end
      end

      runner.registerValue('exterior_fenestration_area', exterior_fenestration_area, 'm2') if exterior_fenestration_area
      metadata[metadata.length] = ['exterior_fenestration_area', 'Exterior Fenestration Area', 'Ext Fen Area', "Total area of all subsurfaces with the conditions of 'Outdoors' and 'FixedWindow' or 'OperableWindow'", 'square_meter', 'double', 'FALSE'] if exterior_fenestration_area

      #get density of economizers in airloops
      num_airloops = 0
      num_economizers = 0
      model.getAirLoopHVACs.each do |air_loop|
        num_airloops += 1
        if air_loop.airLoopHVACOutdoorAirSystem.is_initialized
          air_loop_oa = air_loop.airLoopHVACOutdoorAirSystem.get
          air_loop_oa_controller = air_loop_oa.getControllerOutdoorAir
          if air_loop_oa_controller.getEconomizerControlType != 'NoEconomizer'
            num_economizers += 1
          end
        end
      end
      economizer_density = num_economizers / num_airloops if  num_airloops != 0

      runner.registerValue('economizer_density',economizer_density,'') if economizer_density
      metadata[metadata.length] = ['economizer_density', 'Economizer Density', 'Econom Dens', 'Proportion of air loops with economizers to air loops without', 'percent', 'double', 'FALSE'] if economizer_density

      #get aspect ratios
      north_wall_area = sql_query(runner, sql_file, 'InputVerificationandResultsSummary', "TableName='Window-Wall Ratio' AND RowName='Gross Wall Area' AND ColumnName='North (315 to 45 deg)'")
      east_wall_area = sql_query(runner, sql_file, 'InputVerificationandResultsSummary', "TableName='Window-Wall Ratio' AND RowName='Gross Wall Area' AND ColumnName='East (45 to 135 deg)'")
      if north_wall_area != 0 and east_wall_area != 0
        aspect_ratio = north_wall_area / east_wall_area
        runner.registerValue('aspect_ratio', aspect_ratio, '')
        metadata[metadata.length] = ['aspect_ratio', 'Aspect Ratio', 'Aspc Rto', 'Proportion of north wall area to east wall area', 'percent', 'double', 'FALSE']
      end

      #write metadata CSV
      runner.registerInfo('Saving Dencity metadata csv file')
      CSV.open('dencity_metadata.csv', 'wb') do |csv|
        metadata.each do |elem|
          csv << elem
        end
      end
      runner.registerInfo('Saved Dencity metadata as dencity_metadata.csv')

      #get meter timeseries data and output as a msgpack or csv or both
      #todo: find a way for the sql call to not rely on RUN PERIOD 1
      timeseries_start = Time.now.to_i
      available_meters = sql_file.execAndReturnVectorOfString("SELECT VariableName FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND ReportingFrequency='Zone Timestep'")
      get_timeseries_flag = 1
      if available_meters.empty?
        runner.registerWarning('No meters found with Zone Timestep reporting frequency to extract timeseries data from')
      else
        begin
          meter_strings = available_meters.get
          runner.registerInfo("The following meters were found: #{meter_strings}")
        rescue
          get_timeseries_flag = 0
          runner.registerWarning('Unable to retrieve timeseries strings')
        end
      end

      if get_timeseries_flag == 1
        if msgpack_flag and csv_flag
          require 'parallel'
          require 'msgpack'
          msgpack_array = []
          csv_array = []
          mark0 = Time.now.to_i
          Parallel.each_with_index(meter_strings, :in_threads => 4) do |meter_string, meter_index|
            runner.registerInfo("Getting timeseries data for #{meter_string}")
            if sql_file.timeSeries('RUN PERIOD 1', 'Zone Timestep', meter_string, '').is_initialized
              sql_ts = sql_file.timeSeries('RUN PERIOD 1', 'Zone Timestep', meter_string, '').get
              ts_values = sql_ts.values
              ts_times = sql_ts.dateTimes
              timeseries_out = {}
              initial_epoch_time = Time.parse(ts_times[0].toString).to_i*1000
              timestep_in_epoch = (Time.parse(ts_times[1].toString).to_i - Time.parse(ts_times[0].toString).to_i)*1000
              timeseries_out[initial_epoch_time] = ts_values[0]
              next_epoch_time = initial_epoch_time
              for i in 1..ts_times.size - 1
                next_epoch_time += timestep_in_epoch
                timeseries_out[next_epoch_time] = ts_values[i]
              end
              csv_array << (['epoch_time'] + timeseries_out.to_a.transpose[0]) if meter_index == 0
              csv_array << ([meter_string.gsub(':','_')] + timeseries_out.to_a.transpose[1])
              meter_hash = { timeseries: {}}
              meter_hash[:timeseries][:fuel] = meter_string.gsub(':','_')
              meter_hash[:timeseries][:interval] = Time.parse(ts_times[1].toString).to_i - Time.parse(ts_times[0].toString).to_i
              meter_hash[:timeseries][:interval_units] = 'seconds'
              meter_hash[:timeseries][:data] = timeseries_out
              msgpack_array << meter_hash
            else
              runner.registerWarning("Timeseries #{meter_string} was empty.")
            end
          end
          mark1 = Time.now.to_i
          runner.registerInfo("DeltaMake=#{mark1-mark0}")
          File.open('dencity_timeseries.msgpack', 'w') do |file|
            file << {data: msgpack_array}.to_msgpack
          end
          runner.registerInfo('Saved timeseries data as dencity_timeseries.msgpack')
          csv_array = csv_array.transpose
          CSV.open('dencity_timeseries.csv', 'w') do |csv|
            csv_array.each do |elem|
              csv << elem
            end
          end
          runner.registerInfo('Saved timeseries data as dencity_timeseries.csv')
          mark2 = Time.now.to_i
          runner.registerInfo("DeltaWrite=#{mark2-mark1}")

        elsif msgpack_flag
          require 'parallel'
          require 'msgpack'
          msgpack_array = []
          mark0 = Time.now.to_i
          meter_strings.each(meter_strings, :in_threads => 4) do |meter_string|
            runner.registerInfo("Getting timeseries data for #{meter_string}")
            if sql_file.timeSeries('RUN PERIOD 1', 'Zone Timestep', meter_string, '').is_initialized
              sql_ts = sql_file.timeSeries('RUN PERIOD 1', 'Zone Timestep', meter_string, '').get
              ts_values = sql_ts.values
              ts_times = sql_ts.dateTimes
              timeseries_out = {}
              initial_epoch_time = Time.parse(ts_times[0].toString).to_i*1000
              timestep_in_epoch = (Time.parse(ts_times[1].toString).to_i - Time.parse(ts_times[0].toString).to_i)*1000
              timeseries_out[initial_epoch_time] = ts_values[0]
              next_epoch_time = initial_epoch_time
              for i in 1..ts_times.size - 1
                next_epoch_time += timestep_in_epoch
                timeseries_out[next_epoch_time] = ts_values[i]
              end
              meter_hash = { timeseries: {}}
              meter_hash[:timeseries][:fuel] = meter_string.gsub(':','_')
              meter_hash[:timeseries][:interval] = Time.parse(ts_times[1].toString).to_i - Time.parse(ts_times[0].toString).to_i
              meter_hash[:timeseries][:interval_units] = 'seconds'
              meter_hash[:timeseries][:data] = timeseries_out
              msgpack_array << meter_hash
            else
               runner.registerWarning("Timeseries #{meter_string} was empty.")
            end
          end
          mark1 = Time.now.to_i
          runner.registerInfo("DeltaMake=#{mark1-mark0}")
          File.open('dencity_timeseries_msgpack.msgpack', 'w') do |file|
            file << {data: msgpack_array}.to_msgpack
            runner.registerInfo('Saved timeseries data as dencity_timeseries_msgpack.msgpack')
          end
          mark2 = Time.now.to_i
          runner.registerInfo("DeltaWrite=#{mark2-mark1}")

        elsif csv_flag
          require 'parallel'
          csv_array = []
          mark0 = Time.now.to_i
          Parallel.each_with_index(meter_strings, :in_threads => 4) do |meter_string, meter_index|
            runner.registerInfo("Getting timeseries data for #{meter_string}")
            if sql_file.timeSeries('RUN PERIOD 1', 'Zone Timestep', meter_string, '').is_initialized
              sql_ts = sql_file.timeSeries('RUN PERIOD 1', 'Zone Timestep', meter_string, '').get
              ts_values = sql_ts.values
              ts_times = sql_ts.dateTimes
              timeseries_out = {}
              initial_epoch_time = Time.parse(ts_times[0].toString).to_i*1000
              timestep_in_epoch = (Time.parse(ts_times[1].toString).to_i - Time.parse(ts_times[0].toString).to_i)*1000
              timeseries_out[initial_epoch_time] = ts_values[0]
              next_epoch_time = initial_epoch_time
              for i in 1..ts_times.size - 1
                next_epoch_time += timestep_in_epoch
                timeseries_out[next_epoch_time] = ts_values[i]
              end
              csv_array << (['epoch_time'] + timeseries_out.to_a.transpose[0]) if meter_index == 0
              csv_array << ([meter_string.gsub(':','_')] + timeseries_out.to_a.transpose[1])
            else
              runner.registerWarning("Timeseries #{meter_string} was empty.")
            end
          end
          mark1 = Time.now.to_i
          runner.registerInfo("DeltaMake=#{mark1-mark0}")
          csv_array = csv_array.transpose
          CSV.open('dencity_timeseries.csv', 'w') do |csv|
            csv_array.each do |elem|
              csv << elem
            end
          end
          runner.registerInfo('Saved timeseries data as dencity_timeseries.csv')
          mark2 = Time.now.to_i
          runner.registerInfo("DeltaWrite=#{mark2-mark1}")
        end
      end
      timeseries_end = Time.now.to_i
      runner.registerInfo("Total Timeseries Time: #{timeseries_end-timeseries_start}")

      #closing the sql file
      sql_file.close

      #reporting final condition
      runner.registerFinalCondition('Dencity Report generated successfully.')

    ensure

      # profile_results = RubyProf.stop
      # FileUtils.mkdir_p 'results'
      # File.open("results/profile-graph.html", 'w') { |f| RubyProf::GraphHtmlPrinter.new(profile_results).print(f) }
      # File.open("results/profile-flat.txt", 'w') { |f| RubyProf::FlatPrinter.new(profile_results).print(f) }
      # File.open("results/profile-tree.prof", 'w') { |f| RubyProf::CallTreePrinter.new(profile_results).print(f) }


    end

    true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
DencityReports.new.registerWithApplication