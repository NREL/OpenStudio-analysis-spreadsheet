require 'erb'
#update
#start the measure
class UnmetLoadHoursTroubleshooting < OpenStudio::Ruleset::ReportingUserScript

  def name
    return "Unmet Load Hours Troubleshooting"
  end
  
  def energyPlusOutputRequests(runner, user_arguments)
	super(runner, user_arguments)
	
	requested_args = OpenStudio::IdfObjectVector.new
	
	if !runner.validateUserArguments(arguments(), user_arguments)
		return requested_args
	end
	
	requested_args << OpenStudio::IdfObject.load("Output:Variable,,Zone Mean Air Temperature,Hourly;").get
	requested_args << OpenStudio::IdfObject.load("Output:Variable,,Zone Thermostat Heating Setpoint Temperature,Hourly;").get
	requested_args << OpenStudio::IdfObject.load("Output:Variable,,Zone Thermostat Cooling Setpoint Temperature,Hourly;").get
	requested_args << OpenStudio::IdfObject.load("Output:Variable,,Zone People Occupant Count,Hourly;").get

	return requested_args
  end
  
  
  def arguments()
  
    ruleset = OpenStudio::Ruleset
    osargument = ruleset::OSArgument

    args = OpenStudio::Ruleset::OSArgumentVector.new

    # Future functionality
    #zone_titles = []
    #model.getThermalZones.each do |thermalZone|
    #	zone_name = thermalZone.name.empty? ? thermalZone.name.get : ''
    #	zone_titles.push( zone_name )
    #end

    #  Choice list of measure_zones
    measure_zones = [ "All Zones" ]
    measure_zone = osargument::makeChoiceArgument("measure_zone", measure_zones, measure_zones, true)
    measure_zone.setDefaultValue("All Zones")
    measure_zone.setDisplayName("Pick a Zone (or all Zones)")
    args << measure_zone
    
    return args
  end #end the arguments method

  def get_unmet_hours_matrix(zoneMetrics)

    @metrics[:toleranceTimeHeatSetUnmet] = 0.2
    @metrics[:toleranceTimeCoolSetUnmet] = 0.2
    @model.getObjectsByType("OS:OutputControl:ReportingTolerances".to_IddObjectType).each { |d|
      @metrics[:toleranceTimeHeatSetUnmet] = d.getDouble(1).empty? ? 0.2 : d.getDouble(1).get
      @metrics[:toleranceTimeCoolSetUnmet] = d.getDouble(2).empty? ? 0.2 : d.getDouble(2).get
    }
	# We must use Kelvin -> Rankine conversion instead of Celsius -> Farenheit because the latter conversion adds the 32 degree offset
    @metrics[:toleranceTimeHeatSetUnmetF] = OpenStudio::convert(@metrics[:toleranceTimeHeatSetUnmet], "K", "R").get
    @metrics[:toleranceTimeCoolSetUnmetF] = OpenStudio::convert(@metrics[:toleranceTimeCoolSetUnmet], "K", "R").get

    for i in 0..(zoneMetrics[:zone_mean_air_temp_vals].size - 1)

      if zoneMetrics[:zone_heat_setpoint_vals][i] > zoneMetrics[:zone_mean_air_temp_vals][i] + @metrics[:toleranceTimeHeatSetUnmetF]
        zoneMetrics[:TimeSetpointNotMet][:dur_heating] += 1
        zoneMetrics[:unmet_heating_hrs] += 1
        if zoneMetrics[:zone_occupant_vals][i] > 0
          zoneMetrics[:TimeSetpointNotMet][:dur_heating_occ] += 1
        end
      end
      if zoneMetrics[:zone_cool_setpoint_vals][i] < zoneMetrics[:zone_mean_air_temp_vals][i] - @metrics[:toleranceTimeCoolSetUnmetF]
        zoneMetrics[:TimeSetpointNotMet][:dur_cooling] += 1
        zoneMetrics[:unmet_cooling_hrs] += 1
        if zoneMetrics[:zone_occupant_vals][i] > 0
          zoneMetrics[:TimeSetpointNotMet][:dur_cooling_occ] += 1
        end
      end
    end
  end

  def compare_weather_to_dsn_days()

    # design day name vs run period weather file

    #lastEpwFile = @runner.lastEpwFilePath.empty? ? "" : @runner.lastEpwFilePath.get.to_s
     # Get the city name from the weather file
    epw_city_name = ""
    weather_file_name = @model.getWeatherFile.url
    if weather_file_name.is_initialized
      weather_file_name = weather_file_name.get
      weather_file_name = File.basename(weather_file_name, '.*')
      match = weather_file_name.match(/.*_.*_(\w*)\W/i)
      if match
        puts "Weather File City Initial = #{match}"
        if match[1]
          epw_city_name = match[1]
          puts "Weather File City = #{epw_city_name}"
        end
      end
    end

    # Get the city names from each design day
    dsn_day_city_names = []
    @model.getDesignDays.each do |dsn_day|
      dsn_day_name = dsn_day.name.get
      match = dsn_day_name.match(/(\w*) /i)
      if match
        if match[1]
          dsn_day_city_name = match[1]
          puts "Design Day City = #{dsn_day_city_name}"
          dsn_day_city_names << dsn_day_city_name
        end
      end
    end
    
    # Compare the weather file city against the dsn day city
    all_match = true
    dsn_day_city_names.each do |dsn_day_city_name|
      unless dsn_day_city_name.casecmp(epw_city_name)
        all_match = false
      end
    end

    if dsn_day_city_names.size == 0
      @metrics[:fileMatch] = :no_design_days
    elsif epw_city_name == ""
      @metrics[:fileMatch] = :no_weather_file
    elsif all_match == true
      @metrics[:fileMatch] = :matching_design_day_file
    else 
      @metrics[:fileMatch] = :unmatched_design_day_file
    end

  end

  def unmet_hrs_from_slave_zones(thermalZone, zoneMetrics)
    airloop = nil
    @model.getAirLoopHVACs.sort.each do |loop|
      airloop = loop
      break if airloop.thermalZones.include? thermalZone
    end

    zoneMetrics[:test_four_state] = nil

    if airloop.nil?

      zoneMetrics[:test_four_state] = :no_airloops

    else

      loopName = airloop.name.to_s
      supplyOutletNode = airloop.supplyOutletNode
      setPointManagers = supplyOutletNode.setpointManagers
      type = setPointManagers[0].iddObjectType.valueDescription

      if type == "OS:SetpointManager:SingleZone:Reheat"

        manager = setPointManagers[0].to_SetpointManagerSingleZoneReheat.get
        managerControlledZoneName = !manager.controlZone.empty? ? manager.controlZone.get.name.to_s : ""

        if (zoneMetrics[:name] != managerControlledZoneName)

          if zoneMetrics[:unmet_heating_hrs] > 50 || zoneMetrics[:unmet_cooling_hrs] > 50
            zoneMetrics[:test_four_state] = :failed
            zoneMetrics[:loopName] = loopName
            zoneMetrics[:managerControlledZoneName] = managerControlledZoneName
          end

        end

        else
          zoneMetrics[:test_four_state] = :not_single_zone_reheat
      end

    end
  end

  def thermostat_setpoints_for_underperforming(thermalZone, zoneMetrics)
    zoneMetrics[:test_five_state] = nil

    setpoint = thermalZone.thermostatSetpointDualSetpoint.empty? ? nil : thermalZone.thermostatSetpointDualSetpoint.get

    if !setpoint.nil?

      # will have to correlate schedules by overlapping period

      zoneMetrics[:thermostat_setpoints_for_underperforming] = {}

      if zoneMetrics[:unmet_heating_hrs] > 50
        heatingSchedule = setpoint.getHeatingSchedule.get
        abruptHeat = getAbruptScheduleChanges(heatingSchedule)

        if (!abruptHeat.empty?)
          zoneMetrics[:test_five_state] = :failed
          zoneMetrics[:heating_schedule_name] = heatingSchedule.name.get.to_s
          zoneMetrics[:thermostat_setpoints_for_underperforming][:heatChanges] = abruptHeat
        end

      end
      if zoneMetrics[:unmet_cooling_hrs] > 50
        coolingSchedule = setpoint.getCoolingSchedule.get
        abruptCool = getAbruptScheduleChanges(coolingSchedule)

        if (!abruptCool.empty?)
          zoneMetrics[:test_five_state] = :failed
          zoneMetrics[:cooling_schedule_name] = coolingSchedule.name.get.to_s
          zoneMetrics[:thermostat_setpoints_for_underperforming][:coolChanges] = abruptCool
        end

      end

    else
      zoneMetrics[:test_five_state] = :no_setpoint
    end

  end

  def plant_loop_temp_vs_setpoints(zoneMetrics)
    zoneMetrics[:test_six_state] = nil

    if @model.getPlantLoops.count == 0
      zoneMetrics[:test_six_state] = :no_plant_loops
    else

      zoneMetrics[:plant_loop_temp_vs_setpoints] = {}

      @model.getPlantLoops.sort.each do |plantloop|

        loop_name = plantloop.name.to_s
        loop_type = plantloop.sizingPlant.loopType

        zoneMetrics[:plant_loop_temp_vs_setpoints][loop_name] = {}
        zoneMetrics[:plant_loop_temp_vs_setpoints][loop_name][:loop_type] = loop_type

        supplyOutletNode = plantloop.supplyOutletNode
        setPointManagers = supplyOutletNode.setpointManagers
        managerType = setPointManagers[0].iddObjectType.valueDescription

        if managerType == "OS:SetpointManager:Scheduled"

          schedule = setPointManagers[0].to_SetpointManagerScheduled.get.schedule

          rawMin, rawMax = getMinMaxForSchedule(schedule)

          exit_temp = plantloop.sizingPlant.getDesignLoopExitTemperature.value
          exit_temp = OpenStudio::convert(exit_temp, "C", "F").get

          maxSetpointValue = OpenStudio::convert(rawMax, "C", "F").get
          minSetpointValue = OpenStudio::convert(rawMin, "C", "F").get

          zoneMetrics[:plant_loop_temp_vs_setpoints][loop_name][:schedule_name] = schedule.name.get.to_s
          zoneMetrics[:plant_loop_temp_vs_setpoints][loop_name][:set_min] = minSetpointValue
          zoneMetrics[:plant_loop_temp_vs_setpoints][loop_name][:set_max] = maxSetpointValue
          zoneMetrics[:plant_loop_temp_vs_setpoints][loop_name][:exit_temp] = exit_temp


          if loop_type == "Heating"
            if exit_temp < (maxSetpointValue - 5) || exit_temp > (maxSetpointValue + 5)
              zoneMetrics[:plant_loop_temp_vs_setpoints][loop_name][:state] = :failed
            else
              zoneMetrics[:plant_loop_temp_vs_setpoints][loop_name][:state] = :passed
            end
          end

          if loop_type == "Cooling"
            if exit_temp > (minSetpointValue + 2) || exit_temp < (minSetpointValue - 2)
              zoneMetrics[:plant_loop_temp_vs_setpoints][loop_name][:state] = :failed
            else
              zoneMetrics[:plant_loop_temp_vs_setpoints][loop_name][:state] = :passed
            end
          end

        else
          zoneMetrics[:plant_loop_temp_vs_setpoints][loop_name][:state] = :no_scheduled_manager
        end

      end

    end
  end

  def airloop_reasonable_setting(measureMetrics)
    measureMetrics[:test_seven_state] = nil
    if @model.getAirLoopHVACs.count == 0
      measureMetrics[:test_seven_state] = :no_airloops
    else

      measureMetrics[:airloop_reasonable_setting] = {}

      @model.getAirLoopHVACs.sort.each do |airloop|

        loop_name = airloop.name.to_s
        measureMetrics[:airloop_reasonable_setting][loop_name] = {}

        sizingSystem = airloop.sizingSystem
        centralHeatingTempF = OpenStudio::convert(sizingSystem.centralHeatingDesignSupplyAirTemperature, "C", "F").get
        centralCoolingTempF = OpenStudio::convert(sizingSystem.centralCoolingDesignSupplyAirTemperature, "C", "F").get

        measureMetrics[:airloop_reasonable_setting][loop_name][:centralHeatingTempF] = centralHeatingTempF
        measureMetrics[:airloop_reasonable_setting][loop_name][:centralCoolingTempF] = centralCoolingTempF
        
        # Determine whether the system is a reheat system or not
        if airloop.demandComponents("OS:AirTerminal:SingleDuct:ConstantVolume:Reheat".to_IddObjectType).size > 0 ||
        airloop.demandComponents("OS:AirTerminal:SingleDuct:ParallelPIU:Reheat".to_IddObjectType).size > 0 ||
        airloop.demandComponents("OS:AirTerminal:SingleDuct:SeriesPIU:Reheat".to_IddObjectType).size > 0 ||
        airloop.demandComponents("OS:AirTerminal:SingleDuct:VAV:HeatAndCool:Reheat".to_IddObjectType).size > 0 ||
        airloop.demandComponents("OS:AirTerminal:SingleDuct:VAV:Reheat".to_IddObjectType).size > 0
          measureMetrics[:airloop_reasonable_setting][loop_name][:reheat] = true
        else
          measureMetrics[:airloop_reasonable_setting][loop_name][:reheat] = false
        end
          
      end

    end
  end

  def air_loop_vs_schedule_temp(zoneMetrics)
    zoneMetrics[:test_eight_state] = nil

    if @model.getAirLoopHVACs.count == 0
      zoneMetrics[:test_eight_state] = :no_airloops
    else

      zoneMetrics[:air_loop_vs_schedule_temp] = {}

      @model.getAirLoopHVACs.sort.each do |airloop|

        loop_name = airloop.name.to_s
        zoneMetrics[:air_loop_vs_schedule_temp][loop_name] = {}

        supplyOutletNode = airloop.supplyOutletNode
        setPointManagers = supplyOutletNode.setpointManagers
        type = setPointManagers[0].iddObjectType.valueDescription

        if type == "OS:SetpointManager:Scheduled"

          schedule = setPointManagers[0].to_SetpointManagerScheduled.get.schedule

          #get schedule name for the setPointManager
          scheduleName = schedule.name.get.to_s

          sizingSystem = airloop.sizingSystem
          centralHeatingTemp = OpenStudio::convert(sizingSystem.centralHeatingDesignSupplyAirTemperature, "C", "F").get
          centralCoolingTemp = OpenStudio::convert(sizingSystem.centralCoolingDesignSupplyAirTemperature, "C", "F").get

          rawMin, rawMax = getMinMaxForSchedule( schedule )

          maxSetpointValue = OpenStudio::convert(rawMax, "C", "F").get
          minSetpointValue = OpenStudio::convert(rawMin, "C", "F").get

          zoneMetrics[:air_loop_vs_schedule_temp][loop_name][:centralHeatingTemp] = centralHeatingTemp
          zoneMetrics[:air_loop_vs_schedule_temp][loop_name][:centralCoolingTemp] = centralCoolingTemp

          zoneMetrics[:air_loop_vs_schedule_temp][loop_name][:maxSetpointValue] = maxSetpointValue
          zoneMetrics[:air_loop_vs_schedule_temp][loop_name][:minSetpointValue] = minSetpointValue

          zoneMetrics[:air_loop_vs_schedule_temp][loop_name][:scheduleName] = scheduleName
		  
          if centralHeatingTemp < (maxSetpointValue - 1) || centralHeatingTemp > (maxSetpointValue + 1)
            zoneMetrics[:air_loop_vs_schedule_temp][loop_name][:heating_status] = :failed
          else
            zoneMetrics[:air_loop_vs_schedule_temp][loop_name][:heating_status] = :passed
          end

          if centralCoolingTemp < (minSetpointValue - 1) || centralCoolingTemp > (minSetpointValue + 1)
            zoneMetrics[:air_loop_vs_schedule_temp][loop_name][:cooling_status] = :failed
          else
            zoneMetrics[:air_loop_vs_schedule_temp][loop_name][:cooling_status] = :passed
          end

        else
          zoneMetrics[:air_loop_vs_schedule_temp][loop_name][:status] = :no_scheduled_manager
        end
      end

    end
  end

  def time_series_setpoint_vs_temp( zoneMetrics )

    heating_setpoint_tolerance = @metrics[:toleranceTimeHeatSetUnmet]
    cooling_setpoint_tolerance = @metrics[:toleranceTimeCoolSetUnmet]

    missed_heat = zoneMetrics[:zone_mean_air_temp_vals].map.with_index { |val, i|
      diff = zoneMetrics[:zone_heat_setpoint_vals][i] - val
      if diff > heating_setpoint_tolerance
        diff - heating_setpoint_tolerance
      else
        0
      end
    }

    missed_cool = zoneMetrics[:zone_mean_air_temp_vals].map.with_index { |val, i|
      diff = val - zoneMetrics[:zone_cool_setpoint_vals][i]
      if diff > cooling_setpoint_tolerance
        diff + cooling_setpoint_tolerance
      else
        0
      end
    }

    js_date_times = @times.map{ |t| to_JSTime( t ) }

    hourly_vals = js_date_times.zip(zoneMetrics[:zone_mean_air_temp_vals], zoneMetrics[:zone_heat_setpoint_vals], zoneMetrics[:zone_cool_setpoint_vals], missed_heat, missed_cool )

    # Add the hourly load data to JSON for the report.html
    graph = {}
    graph["title"] = "#{zoneMetrics[:name]}"
    graph["xaxislabel"] = "Time"
    graph["yaxislabel"] = "Temp F"
    graph["yaxis2label"] = "Temp Difference"
    graph["labels"] = ["Date", "Air Temp", "Heat Setpoint", "Cool Setpoint", "Missed Heat", "Missed Cool"]
    graph["colors"] = ["#888888", "#FF8833", "#3388FF","#FF8833", "#3388FF"]
    graph["timeseries"] = hourly_vals

    # This measure requires ruby 2.0.0 to create the JSON for the report graph
    if RUBY_VERSION >= "2.0.0"
      @test_nine_data << graph
    end

  end


  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    @runner = runner

    #use the built-in error checking 
    if not @runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # get the last model and sql file
    
    @model = @runner.lastOpenStudioModel
    if @model.empty?
      @runner.registerError("Cannot find last model.")
      return false
    end
    @model = @model.get
	
	if @model.getThermalZones.empty?
		@runner.registerAsNotApplicable("This model has no thermal zones. This measure will not be run.")
		return true
    end
	
    @sqlFile = @runner.lastEnergyPlusSqlFile
    if @sqlFile.empty?
      @runner.registerError("Cannot find last sql file.")
      return false
    end
    @sqlFile = @sqlFile.get
    @model.setSqlFile(@sqlFile)


    # Get the weather file (as opposed to design day) run period
    @annEnvPd = nil
    @sqlFile.availableEnvPeriods.each do |envPd|
      envType = @sqlFile.environmentType(envPd)
      if not envType.empty?
        if envType.get == "WeatherRunPeriod".to_EnvironmentType
          @annEnvPd = envPd
        end
      else
        puts("Could not get weather file info")
      end
    end

    @test_nine_data = []

    puts("Unmet Load Hours QAQC")

    # put data into variables, these are available in the local scope binding

    zone_collection = []

    @metrics = {}

    # this is run once for the entire measure
    compare_weather_to_dsn_days()

    @measureMetrics = { :plant_loop_temp_vs_setpoints => {}, :airloop_reasonable_setting => {}, :air_loop_vs_schedule_temp => {}}

      # Test 2 see report markup

      # Test 3 see above


    @model.getThermalZones.sort.each do |thermalZone|

      zoneMetrics = initZoneMetrics( thermalZone )

      get_unmet_hours_matrix(zoneMetrics)

      unmet_hrs_from_slave_zones(thermalZone, zoneMetrics)

      thermostat_setpoints_for_underperforming(thermalZone, zoneMetrics)

      time_series_setpoint_vs_temp(zoneMetrics)

      zone_collection.push( zoneMetrics )

    end

    @measureMetrics[:zone_collection] = zone_collection

    plant_loop_temp_vs_setpoints(@measureMetrics)

    airloop_reasonable_setting(@measureMetrics)

    air_loop_vs_schedule_temp(@measureMetrics)

    #OUTPUT

    output = ""

    # Convert the graph data to JSON
    # This measure requires ruby 2.0.0 to create the JSON for the report graph
    if RUBY_VERSION >= "2.0.0"
      require 'json'
      @test_nine_data = @test_nine_data.to_json
    else
      runner.registerInfo("This Measure needs Ruby 2.0.0 to generate timeseries graphs on the report.  You have Ruby #{RUBY_VERSION}.  OpenStudio 1.4.2 and higher user Ruby 2.0.0.")
    end

    web_asset_path = OpenStudio::getSharedResourcesPath() / OpenStudio::Path.new("web_assets")

    html_in = getResourceFileData( "report.html.in" )

    # configure template with variable values
    renderer = ERB.new(html_in)
    html_out = renderer.result(binding)

    writeResourceFileData( "report.html", html_out )
    
    #closing the sql file
    @sqlFile.close()

    #reporting final condition
    @runner.registerFinalCondition("Goodbye.")
    
    return true
 
  end #end the run method


  def initZoneMetrics( thermalZone )

    zoneMetrics = {}

    zone_name = !thermalZone.name.empty? ? thermalZone.name.get : ''
    puts("Zone:#{zone_name}")

    zoneMetrics[:name] = zone_name

    zoneMetrics[:TimeSetpointNotMet] = {}
    zoneMetrics[:TimeSetpointNotMet][:dur_heating] = 0        # is this occupied only, or both occupied and unoccupied?
    zoneMetrics[:TimeSetpointNotMet][:dur_cooling] = 0
    zoneMetrics[:TimeSetpointNotMet][:dur_heating_occ] = 0
    zoneMetrics[:TimeSetpointNotMet][:dur_cooling_occ] = 0

    zoneMetrics[:singleZoneHeatWarningLoop] = nil
    zoneMetrics[:singleZoneCoolWarningLoop] = nil

    zoneMetrics[:singleZoneHeatControlZoneName] = ""
    zoneMetrics[:singleZoneCoolControlZoneName] = ""

    zoneMetrics[:unmet_heating_hrs] = 0   # is this the same as dur_heating?
    zoneMetrics[:unmet_cooling_hrs] = 0

    puts("Getting mean air temps")
    zoneMetrics[:zone_mean_air_temp_vals] = getTimeSeries( "Zone Mean Air Temperature", zone_name.upcase, @annEnvPd, "Hourly")
    zoneMetrics[:zone_mean_air_temp_vals].map! { |v| OpenStudio::convert(v, "C", "F").get }

    @times = getTimesForSeries("Zone Mean Air Temperature", zone_name.upcase, @annEnvPd, "Hourly")

    puts("Getting heating setpoints")
    zoneMetrics[:zone_heat_setpoint_vals] = getTimeSeries( "Zone Thermostat Heating Setpoint Temperature", zone_name.upcase, @annEnvPd, "Hourly")
    zoneMetrics[:zone_heat_setpoint_vals].map! { |v| OpenStudio::convert(v, "C", "F").get }


    puts("Getting cooling setpoints")
    zoneMetrics[:zone_cool_setpoint_vals] = getTimeSeries( "Zone Thermostat Cooling Setpoint Temperature", zone_name.upcase, @annEnvPd, "Hourly")
    zoneMetrics[:zone_cool_setpoint_vals].map! { |v| OpenStudio::convert(v, "C", "F").get }

    puts("Getting occupancy")
    zoneMetrics[:zone_occupant_vals] = getTimeSeries( "Zone People Occupant Count", zone_name.upcase, @annEnvPd, "Hourly")
    zoneMetrics[:zone_occupant_max] = !zoneMetrics[:zone_occupant_vals].nil? ? zoneMetrics[:zone_occupant_vals].max : 0

    if zoneMetrics[:zone_occupant_vals].nil? then
      zoneMetrics[:zone_occupant_vals] = Array.new(8760, 0)
    end

    return zoneMetrics
  end

  def getMinMaxForSchedule( schedule )

    profiles = []
    defaultProfile = schedule.to_ScheduleRuleset.get.defaultDaySchedule
    profiles << defaultProfile

    rules = schedule.to_ScheduleRuleset.get.scheduleRules

    rules.each do |rule|
      profiles << rule.daySchedule
    end

    # test profiles
    min = nil
    max = nil
    profiles.each do |profile|
      profile.values.each do |value|
        if min.nil?
          min = value
        else
          if value < min then min = value end
        end
        if max.nil?
          max = value
        else
          if value > max then max = value end
        end
      end
    end

    return min, max
  end

  def getAbruptScheduleChanges( schedule )

    profiles = []
    defaultProfile = schedule.to_ScheduleRuleset.get.defaultDaySchedule
    profiles << defaultProfile

    rules = schedule.to_ScheduleRuleset.get.scheduleRules

    rules.each do |rule|
      profiles << rule.daySchedule
    end

    changesOut = {}

    profiles.each do |profile|

      name = profile.name.get.to_s

      last_val = -1
      for s in 0..profile.values.count - 1 do

        if s == 0
          curr = s
          last = profile.values.count - 1
        else
          curr = s
          last = s-1
        end

        currVal = OpenStudio::convert(profile.values[curr], "C", "F").get
        lastVal = OpenStudio::convert(profile.values[last], "C", "F").get
        change = (currVal - lastVal).abs

        if change > 3
          changesOut[name] = changesOut[name].nil? ? 0 : changesOut[name] + 1
        end

      end
    end

    return changesOut
  end

  def getTimeSeries( name, index, envperiod, rate )

      series = @sqlFile.timeSeries( envperiod, rate, name, index)
      if series.empty?
        @runner.registerWarning("No data found for '#{name}' '#{index}'")
        return nil
      else
        series = series.get
      end

      series_collection = series.values
      series_vals = []
      for i in 0..(series_collection.size - 1)
        series_vals << series_collection[i]
      end

      series_vals
  end

  def getTimesForSeries( name, index, envperiod, rate )

    series = @sqlFile.timeSeries( envperiod, rate, name, index)
    if series.empty?
      @runner.registerWarning("No data found for '#{name}' '#{index}'")
      return nil
    else
      series = series.get
    end

    series.dateTimes

  end

  # Method to translate from OpenStudio's time formatting
  # to Javascript time formatting
  # OpenStudio time
  # 2009-May-14 00:10:00   Raw string
  # Javascript time
  # 2009/07/12 12:34:56
  def to_JSTime( os_time )
    js_time = os_time.to_s
    # Replace the '-' with '/'
    js_time = js_time.gsub('-','/')
    # Replace month abbreviations with numbers
    js_time = js_time.gsub('Jan','01')
    js_time = js_time.gsub('Feb','02')
    js_time = js_time.gsub('Mar','03')
    js_time = js_time.gsub('Apr','04')
    js_time = js_time.gsub('May','05')
    js_time = js_time.gsub('Jun','06')
    js_time = js_time.gsub('Jul','07')
    js_time = js_time.gsub('Aug','08')
    js_time = js_time.gsub('Sep','09')
    js_time = js_time.gsub('Oct','10')
    js_time = js_time.gsub('Nov','11')
    js_time = js_time.gsub('Dec','12')

    return js_time
  end

  def getResourceFileData( fileName )
    data_in_path = "#{File.dirname(__FILE__)}/resources/#{fileName}"
    if !File.exist?(data_in_path)
        data_in_path = "#{File.dirname(__FILE__)}/#{fileName}"
    end

    html_in = ""
    File.open(data_in_path, 'r') do |file|
      html_in = file.read
    end

    html_in
  end

  def writeResourceFileData( fileName, data )
    File.open("./#{fileName}", 'w') do |file|
      file << data
      # make sure data is written to the disk one way or the other
      begin
        file.fsync
      rescue
        file.flush
      end
    end
  end  
  
end #end the measure

#this allows the measure to be use by the application
UnmetLoadHoursTroubleshooting.new.registerWithApplication
