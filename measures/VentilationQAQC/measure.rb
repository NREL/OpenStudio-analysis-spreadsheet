require 'erb'

#start the measure
class VentilationQAQC < OpenStudio::Ruleset::ReportingUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Ventilation Report"
  end

  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    result = OpenStudio::IdfObjectVector.new

    if !runner.validateUserArguments(arguments(), user_arguments)
      return result
    end

    ventilation = OpenStudio::IdfObject.load("Output:Variable,,Zone Mechanical Ventilation Current Density Volume Flow Rate,Hourly;").get
    result << ventilation

    ach = OpenStudio::IdfObject.load("Output:Variable,,Zone Infiltration Air Change Rate,Hourly;").get
    result << ach

    people = OpenStudio::IdfObject.load("Output:Variable,,Zone People Occupant Count,Hourly;").get
    result << people

    return result
  end
  
  #define the arguments that the user will input

  #
  #   note - there is no 'model' argument provided here.  This may cause an issue.
  #

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

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # get the last model and sql file

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get


    @sqlFile = runner.lastEnergyPlusSqlFile
    if @sqlFile.empty?
     runner.registerError("Cannot find last sql file.")
     return false
    end
    @sqlFile = @sqlFile.get
    model.setSqlFile(@sqlFile)


    # Get the weather file (as opposed to design day) run period
    annEnvPd = nil
    @sqlFile.availableEnvPeriods.each do |envPd|
      envType = @sqlFile.environmentType(envPd)
      if not envType.empty?
        if envType.get == "WeatherRunPeriod".to_EnvironmentType
          annEnvPd = envPd
        end
      else
        puts("Could not get weather file info")
      end
    end

    #binding.pry

    # put data into variables, these are available in the local scope binding

    zoneCollection = []
    spaceCollection = []
    annualGraphData = []
    warnings = []

    model.getThermalZones.sort.each do |thermalZone|

      zone_name = !thermalZone.name.empty? ? thermalZone.name.get : ''

      puts("Zone:#{zone_name}")

      # Get the hourly ventilation in cfm
      puts("Get Ventilation")

      zone_mechanical_ventilation_vals = getTimeSeries( "Zone Mechanical Ventilation Current Density Volume Flow Rate", zone_name.upcase, annEnvPd, "Hourly", runner)
      if zone_mechanical_ventilation_vals

        zone_mechanical_ventilation_vals.map! { |v| v * 2118.882 }
        max_ventilation = zone_mechanical_ventilation_vals.max || 0 # max of an empty array is nil, so use 0 for max ventilation in this case
      else
        max_ventilation = 0
      end

      puts("Get Infiltration")

      zone_infiltration_vals = getTimeSeries( "Zone Infiltration Air Change Rate", zone_name.upcase, annEnvPd, "Hourly", runner)

      puts("Get Occupant")

      zone_occupant_vals = getTimeSeries( "Zone People Occupant Count", zone_name.upcase, annEnvPd, "Hourly", runner)
      zone_occupant_max = !zone_occupant_vals.nil? ? zone_occupant_vals.max : 0

      zone_occupant_normalized = zone_occupant_vals.map { |v| v / zone_occupant_max }

      unoccupied = 0
      lightly_occupied = 0

      coordinated = zone_occupant_normalized.zip( zone_mechanical_ventilation_vals )

      coordinated.each do | vals |
        normalized_occupancy = vals[0]
        zone_mech_vent = vals[1]

        if normalized_occupancy == 0 && zone_mech_vent > 0
          unoccupied = unoccupied + 1
        end

        if normalized_occupancy < 0.05 && zone_mech_vent > 20
          lightly_occupied = lightly_occupied + 1
        end

      end

	  puts "Unoccupied: #{unoccupied}, Lightly Occupied: #{lightly_occupied}"
	  
      if unoccupied > 10
        warnings.push("Thermal Zone <strong>#{zone_name}</strong> appears to have mechanical ventilation during periods when the zone is unoccupied, resulting in potentially unnecessary ventilation energy. This occurs <strong>#{unoccupied}</strong> hours per run period. Please ensure this is a correct representation of the modeling scenario. Minimum fraction OA schedules may need adjusting.")
      end

      if lightly_occupied > 1500
        warnings.push("Thermal Zone <strong>#{zone_name}</strong> appears to have mechanical ventilation during periods when the zone is lightly occupied, resulting in potentially unnecessary ventilation energy. This occurs <strong>#{lightly_occupied}</strong> hours per run period. Please ensure this is a correct representation of the modeling scenario.")
      end

      times = getTimesForSeries("Zone People Occupant Count", zone_name.upcase, annEnvPd, "Hourly", runner)
      js_date_times = times.map{ |t| to_JSTime( t ) }

      # Create an array of arrays [timestamp, zone_mechanical_ventilation_vals, zone_infiltration_vals]
      hourly_vals = js_date_times.zip(zone_infiltration_vals)

      # Add the hourly load data to JSON for the report.html
      graph = {}
      graph["title"] = "#{zone_name} - Hourly Infiltration"
      graph["xaxislabel"] = "Time"
      graph["yaxislabel"] = "Infiltration (ACH)"
      graph["labels"] = ["Date", "Infiltration (ACH)"]
      graph["colors"] = ["#FF5050", "#0066FF"]
      graph["timeseries"] = hourly_vals

      # This measure requires ruby 2.0.0 to create the JSON for the report graph
      if RUBY_VERSION >= "2.0.0"
        annualGraphData << graph
      end

      zoneMetrics = {}
      zoneMetrics[:zoneWeightedCFM] = 0

      thermalZone.spaces.each do |space|

        spaceMetrics = {}

        spaceMetrics[:name] = !space.name.empty? ? space.name.get : ''
        spaceMetrics[:isPartOfTotalFloorArea] = space.partofTotalFloorArea
        spaceMetrics[:floorAreaM2] = space.floorArea
        spaceMetrics[:volumeM3] = space.volume
        spaceMetrics[:peoplePerFloorArea] = space.peoplePerFloorArea
        #spaceMetrics[:exteriorAreaM2] = space.exteriorArea
        spaceMetrics[:calculatedPeople] =  space.floorArea * space.peoplePerFloorArea

        if ( !space.designSpecificationOutdoorAir.empty? )
          spec = space.designSpecificationOutdoorAir.get

          #spaceMetrics[:specMethod] = spec.outdoorAirMethod
          spaceMetrics[:specOutdoorAirFlowperPerson] = spec.getOutdoorAirFlowperPerson.value
          spaceMetrics[:specOutdoorAirFlowperFloorArea] = spec.getOutdoorAirFlowperFloorArea.value
          spaceMetrics[:specOutdoorAirFlowRate] = spec.outdoorAirFlowRate
          spaceMetrics[:specOutdoorAirFlowAirChangesperHour] = spec.getOutdoorAirFlowAirChangesperHour.value

          #Outdoor Air Method
          #Outdoor Air Flow per Person {m3/s-person}
          #Outdoor Air Flow per Floor Area {m3/s-m2}
          #Outdoor Air Flow Rate {m3/s}
          #Outdoor Air Flow Air Changes per Hour {1/hr}
          #Outdoor Air Flow Rate Fraction Schedule Name
		  
          outdoorAirFlow = calculateOutdoorAirFlow( spaceMetrics, spec)
          if spaceMetrics[:calculatedPeople] > 0
            spaceMetrics[:outsideAirPerPerson] = OpenStudio::convert(outdoorAirFlow, "m^3/s", "cfm").get / spaceMetrics[:calculatedPeople]
          else
            spaceMetrics[:outsideAirPerPerson] = 0
          end
            
        else
          spaceMetrics[:outsideAirPerPerson] = 0
        end
        

        i = 0
        spaceMetrics[:designFlowRates] = {}
        space.spaceInfiltrationDesignFlowRates.each do |designFlowRate|
          spaceMetrics[:designFlowRates][i] = {}
          spaceMetrics[:designFlowRates][i][:calcMethod] = designFlowRate.designFlowRateCalculationMethod
          spaceMetrics[:designFlowRates][i][:designFlowRate] = !designFlowRate.designFlowRate.empty? ? designFlowRate.designFlowRate.get : nil
          spaceMetrics[:designFlowRates][i][:flowPerSpaceFloorArea] = !designFlowRate.flowperSpaceFloorArea.empty? ? designFlowRate.flowperSpaceFloorArea.get : nil
          spaceMetrics[:designFlowRates][i][:flowPerExteriorSurfaceArea] = !designFlowRate.flowperExteriorSurfaceArea.empty? ? designFlowRate.flowperExteriorSurfaceArea.get : nil
          spaceMetrics[:designFlowRates][i][:airChangesperHour] = !designFlowRate.airChangesperHour.empty? ? designFlowRate.airChangesperHour.get : nil
          i = i + 1
        end
		spaceMetrics[:airChangesPerHour] = space.infiltrationDesignAirChangesPerHour

        i = 0
        spaceMetrics[:effectiveLeakageAreas] = {}
        space.spaceInfiltrationEffectiveLeakageAreas.each do |effectiveLeakageArea|
          spaceMetrics[:effectiveLeakageAreas][i] = {}
          spaceMetrics[:effectiveLeakageAreas][i][:leakageArea] = effectiveLeakageArea.effectiveAirLeakageArea
          i = i + 1
        end

        designFlow = if spaceMetrics[:outsideAirPerPerson] then spaceMetrics[:outsideAirPerPerson] * spaceMetrics[:calculatedPeople] else 0 end
        spaceWeight = spaceMetrics[:floorAreaM2] /  thermalZone.floorArea
        spaceMetrics[:spaceWeightedCFM] = spaceWeight * designFlow

        spaceCollection.push(spaceMetrics)

        zoneMetrics[:zoneWeightedCFM] = zoneMetrics[:zoneWeightedCFM] + spaceMetrics[:spaceWeightedCFM]
      end


      if zoneMetrics[:zoneWeightedCFM] / 2 > max_ventilation
        warnings.push("Thermal Zone <strong>#{zone_name}</strong> appears to have excessive outside air assignments. Check the number of Design Specification Outdoor Air Objects associated with this zone.")
      end

      zoneCollection.push(zoneMetrics)

    end

    spaceCollection.sort! { |a,b| a[:name].downcase <=> b[:name].downcase }

    output =  "Measure Name = #{name}"

    # Convert the graph data to JSON
    # This measure requires ruby 2.0.0 to create the JSON for the report graph
    if RUBY_VERSION >= "2.0.0"
      require 'json'
      annualGraphData = annualGraphData.to_json
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
    runner.registerFinalCondition("Goodbye.")


    @outData = { :spaceCollection => spaceCollection, :zoneCollection => zoneCollection, :warnings => warnings }

    return true

  end #end the run method


  def outData
    @outData
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

  def getTimeSeries( name, index, envperiod, rate, runner )

      series = @sqlFile.timeSeries( envperiod, rate, name, index)
      if series.empty?
        runner.registerWarning("No data found for '#{name}' '#{index}'")
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

  def getTimesForSeries( name, index, envperiod, rate, runner )

    series = @sqlFile.timeSeries( envperiod, rate, name, index)
    if series.empty?
      runner.registerWarning("No data found for '#{name}' '#{index}'")
      return nil
    else
      series = series.get
    end

    series.dateTimes

  end
  
  def calculateOutdoorAirFlow(spaceMetrics, spec)
	# Calculate airflows for all methods.  Airflows are in native units (m3/s)
	flows = [
		spec.outdoorAirFlowperPerson * spaceMetrics[:calculatedPeople],
		spec.outdoorAirFlowperFloorArea * spaceMetrics[:floorAreaM2],
		spec.outdoorAirFlowAirChangesperHour * spaceMetrics[:volumeM3] / 3600,
		spec.outdoorAirFlowRate
	]
  
	# Depending on the outdoorAirMethod chosen, we return either the sum or maximum of the above flows
	if spec.outdoorAirMethod == "Sum"
		return flows.inject(0) { |sum, i| sum + i }
	end
	if spec.outdoorAirMethod == "Maximum"
		return flows.max
	end
  end

  def getFlowPerPerson( spaceMetrics )

    out = 0
    if !spaceMetrics[:specOutdoorAirFlowperPerson].nil?
      out = spaceMetrics[:specOutdoorAirFlowperPerson]

    elsif !spaceMetrics[:specOutdoorAirFlowperFloorArea].nil?
      if spaceMetrics[:peoplePerFloorArea] != 0
        out = spec.getOutdoorAirFlowperFloorArea.value * ( 1 / spaceMetrics[:peoplePerFloorArea] )
      end

    elsif !spaceMetrics[:specOutdoorAirFlowRate].nil?
      if spaceMetrics[:calculatedPeople] != 0
        out = spec.outdoorAirFlowRate / spaceMetrics[:calculatedPeople]
      end

    elsif !spaceMetrics[:specOutdoorAirFlowAirChangesperHour].nil?
      if spaceMetrics[:calculatedPeople] != 0
        out = spec.getOutdoorAirFlowAirChangesperHour.value / 60 * spaceMetrics[:volumeM3] / spaceMetrics[:calculatedPeople]
      end

    end

  end

  def getAirChangesPerHour( spaceMetrics )
    out = 0
    i = 0
    # translate existing metrics into airChangesPerHour and sum for all designFlowRate structures

    secondsPerHourPerVolume = 3600 / spaceMetrics[:volumeM3]

    spaceMetrics[:designFlowRates].each do |flowRate|
      curr = 0

      if !spaceMetrics[:designFlowRates][i][:designFlowRate].nil?
        curr = spaceMetrics[:designFlowRates][i][:designFlowRate] * secondsPerHourPerVolume

      elsif !spaceMetrics[:designFlowRates][i][:flowPerSpaceFloorArea].nil?
        curr = spaceMetrics[:designFlowRates][i][:flowPerSpaceFloorArea] * spaceMetrics[:floorAreaM2] * secondsPerHourPerVolume

      elsif !spaceMetrics[:designFlowRates][i][:flowPerExteriorSurfaceArea].nil?
        curr = spaceMetrics[:designFlowRates][i][:flowPerExteriorSurfaceArea] * spaceMetrics[:exteriorAreaM2] * secondsPerHourPerVolume

      elsif !spaceMetrics[:designFlowRates][i][:airChangesperHour].nil?
        curr = spaceMetrics[:designFlowRates][i][:airChangesperHour]

      end

      out += curr
      i = i + 1
    end

    return out
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

end #end the measure

#this allows the measure to be use by the application
VentilationQAQC.new.registerWithApplication
