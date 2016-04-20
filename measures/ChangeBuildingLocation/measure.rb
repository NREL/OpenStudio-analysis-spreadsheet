#see the URL below for information on how to write OpenStudio measures
# TODO: Remove this link and replace with the wiki
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# Author: Nicholas Long
# Simple measure to load the EPW file and DDY file
require_relative 'resources/stat_file'
require_relative 'resources/epw'

class ChangeBuildingLocation < OpenStudio::Ruleset::ModelUserScript

  attr_reader :weather_directory

  def initialize
    super

    # Hard code the weather directory for now. This assumes that you are running
    # the analysis on the OpenStudio distributed analysis server
    @weather_directory = File.expand_path(File.join(File.dirname(__FILE__), "../../weather"))
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    'ChangeBuildingLocation'
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    weather_directory = OpenStudio::Ruleset::OSArgument.makeStringArgument('weather_directory', true)
    weather_directory.setDisplayName("Weather Directory")
    weather_directory.setDescription("Relative directory to weather files from analysis directory")
    #arg.setUnits(nil)
    args << weather_directory

    weather_file_name = OpenStudio::Ruleset::OSArgument.makeStringArgument('weather_file_name', true)
    weather_file_name.setDisplayName("Weather File Name")
    weather_file_name.setDescription("Name of the weather file to change to. This is the filename with the extension (e.g. NewWeather.epw).")
    args << weather_file_name

    #make choice argument for facade
    choices = OpenStudio::StringVector.new
    choices << "1A"
    choices << "1B"
    choices << "2A"
    choices << "2B"
    choices << "3A"
    choices << "3B"
    choices << "3C"
    choices << "4A"
    choices << "4B"
    choices << "4C"
    choices << "5A"
    choices << "5B"
    choices << "5C"
    choices << "6A"
    choices << "6B"
    choices << "7"
    choices << "8"
    climate_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("climate_zone", choices,true)
    climate_zone.setDisplayName("Climate Zone.")
    args << climate_zone

    args
  end

  # Define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # todo - create initial condition
    if not model.getWeatherFile.city == ''
      runner.registerInitialCondition("The initial weather file is #{model.getWeatherFile.city} and the model has #{model.getDesignDays.size} design day objects")
    else
      runner.registerInitialCondition("No weather file is set. The model has #{model.getDesignDays.size} design day objects")
    end

    # grab the initial weather file
    @weather_directory = runner.getStringArgumentValue("weather_directory", user_arguments)
    weather_file_name = runner.getStringArgumentValue("weather_file_name", user_arguments)
    climate_zone = runner.getStringArgumentValue("climate_zone",user_arguments)

    #Add Weather File
    unless (Pathname.new @weather_directory).absolute?
      @weather_directory = File.expand_path(File.join(File.dirname(__FILE__), @weather_directory))
    end

    # todo - add error checking if epw not found

    # Check if the weather file is a ZIP, if so, then unzip and read the EPW file.
    weather_file = File.join(@weather_directory, weather_file_name)

    # Parse the EPW manually because OpenStudio can't handle multiyear weather files (or DATA PERIODS with YEARS)
    epw_file = OpenStudio::Weather::Epw.load(weather_file)

    weather_file = model.getWeatherFile
    weather_file.setCity(epw_file.city)
    weather_file.setStateProvinceRegion(epw_file.state)
    weather_file.setCountry(epw_file.country)
    weather_file.setDataSource(epw_file.data_type)
    weather_file.setWMONumber(epw_file.wmo.to_s)
    weather_file.setLatitude(epw_file.lat)
    weather_file.setLongitude(epw_file.lon)
    weather_file.setTimeZone(epw_file.gmt)
    weather_file.setElevation(epw_file.elevation)
    weather_file.setString(10, "file:///#{epw_file.filename}")

    weather_name = "#{epw_file.city}_#{epw_file.state}_#{epw_file.country}"
    weather_lat = epw_file.lat
    weather_lon = epw_file.lon
    weather_time = epw_file.gmt
    weather_elev = epw_file.elevation

    # Add or update site data
    site = model.getSite
    site.setName(weather_name)
    site.setLatitude(weather_lat)
    site.setLongitude(weather_lon)
    site.setTimeZone(weather_time)
    site.setElevation(weather_elev)

    # Set climate zone
    climateZones = model.getClimateZones
    climateZones.setClimateZone("ASHRAE",climate_zone)

    # Add SiteWaterMainsTemperature -- via parsing of STAT file.
    stat_file = "#{File.join(File.dirname(epw_file.filename), File.basename(epw_file.filename, '.*'))}.stat"
    unless File.exist? stat_file
      runner.registerInfo "Could not find STAT file by filename, looking in the directory"
      stat_files = Dir["#{File.dirname(epw_file.filename)}/*.stat"]
      if stat_files.size > 1
        runner.registerError("More than one stat file in the EPW directory")
        return false
      end
      if stat_files.size == 0
        runner.registerError("Cound not find the stat file in the EPW directory")
        return false
      end

      runner.registerInfo "Using STAT file: #{stat_files.first}"
      stat_file = stat_files.first
    end
    unless stat_file
      runner.registerError "Could not find stat file"
      return false
    end

    stat_file = EnergyPlus::StatFile.new(stat_file)
    water_temp = model.getSiteWaterMainsTemperature
    water_temp.setAnnualAverageOutdoorAirTemperature(stat_file.mean_dry_bulb)
    water_temp.setMaximumDifferenceInMonthlyAverageOutdoorAirTemperatures(stat_file.delta_dry_bulb)
    runner.registerInfo("mean dry bulb is #{stat_file.mean_dry_bulb}")
    runner.registerInfo("delta dry bulb is #{stat_file.delta_dry_bulb}")

    # Remove all the Design Day objects that are in the file
    model.getObjectsByType("OS:SizingPeriod:DesignDay".to_IddObjectType).each { |d| d.remove }

    # find the ddy files
    ddy_file = "#{File.join(File.dirname(epw_file.filename), File.basename(epw_file.filename, '.*'))}.ddy"
    unless File.exist? ddy_file
      ddy_files = Dir["#{File.dirname(epw_file.filename)}/*.ddy"]
      if ddy_files.size > 1
        runner.registerError("More than one stat file in the EPW directory")
        return false
      end
      if ddy_files.size == 0
        runner.registerError("could not find the stat file in the EPW directory")
        return false
      end

      ddy_file = ddy_files.first
    end

    unless ddy_file
      runner.registerError "Could not find DDY file for #{ddy_file}"
      return error
    end

    ddy_model = OpenStudio::EnergyPlus.loadAndTranslateIdf(ddy_file).get
    ddy_model.getObjectsByType("OS:SizingPeriod:DesignDay".to_IddObjectType).each do |d|
      # grab only the ones that matter
      ddy_list = /(Htg 99.6. Condns DB)|(Clg .4. Condns WB=>MDB)|(Clg .4% Condns DB=>MWB)/
      if d.name.get =~ ddy_list
        runner.registerInfo("Adding object #{d.name}")

        # add the object to the existing model
        model.addObject(d.clone)
      end
    end

    # todo - add final condition
    runner.registerFinalCondition("The final weather file is #{model.getWeatherFile.city} and the model has #{model.getDesignDays.size} design day objects")

    true
  end
end

# This allows the measure to be use by the application
ChangeBuildingLocation.new.registerWithApplication