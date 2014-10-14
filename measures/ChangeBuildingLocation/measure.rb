#see the URL below for information on how to write OpenStudio measures
# TODO: Remove this link and replace with the wiki
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# Author: Nicholas Long
# Simple measure to load the EPW file and DDY file
require "#{File.dirname(__FILE__)}/resources/stat_file"

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

    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument('weather_directory', true)
    arg.setDisplayName("Weather Directory")
    #arg.setDescription("Relative directory to weather files from analysis directory")
    #arg.setUnits(nil)
    args << arg

    arg2 = OpenStudio::Ruleset::OSArgument.makeStringArgument('weather_file_name', true)
    arg2.setDisplayName("Weather File Name")
    #arg.setDescription("Name of the weather file to change to. This is the filename with the extension (e.g. NewWeather.epw)")
    args << arg2

    args
  end

  # Define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # report initial condition
    site = model.getSite
    initial_design_days = model.getDesignDays
    if site.weatherFile.is_initialized
      weather = site.weatherFile.get
      runner.registerInitialCondition("The initial weather file path was '#{weather.path.get}' and the model had #{initial_design_days.size} design days.")
    else
      runner.registerInitialCondition("The initial weather file has not been set and the model had #{initial_design_days.size} design days.")
    end

    # grab the initial weather file
    @weather_directory = runner.getStringArgumentValue("weather_directory", user_arguments)
    weather_file_name = runner.getStringArgumentValue("weather_file_name", user_arguments)

    #Add Weather File
    unless (Pathname.new @weather_directory).absolute?
      @weather_directory = File.expand_path(File.join(File.dirname(__FILE__), @weather_directory))
    end
    weather_file = File.join(@weather_directory, weather_file_name)
    if File.exists?(weather_file) and weather_file_name.downcase.include? ".epw"
        epw_file = OpenStudio::EpwFile.new(weather_file)
    else
      runner.registerError("'#{weather_file}' does not exist or is not an .epw file.")
      return false
    end

    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get
    runner.registerInfo("Setting weather file.")

    weather_name = "#{epw_file.city}_#{epw_file.stateProvinceRegion}_#{epw_file.country}"
    weather_lat = epw_file.latitude
    weather_lon = epw_file.longitude
    weather_time = epw_file.timeZone
    weather_elev = epw_file.elevation

    # Add or update site data
    site = model.getSite
    site.setName(weather_name)
    site.setLatitude(weather_lat)
    site.setLongitude(weather_lon)
    site.setTimeZone(weather_time)
    site.setElevation(weather_elev)
    runner.registerInfo("Setting site data.")

    # TODO: Add or update ground temperature data

    # Add SiteWaterMainsTemperature -- via parsing of STAT file.
    stat_filename = "#{File.join(File.dirname(weather_file), File.basename(weather_file, '.*'))}.stat"
    if File.exist? stat_filename
      stat_file = EnergyPlus::StatFile.new(stat_filename)
      water_temp = model.getSiteWaterMainsTemperature
      water_temp.setAnnualAverageOutdoorAirTemperature(stat_file.mean_dry_bulb)
      water_temp.setMaximumDifferenceInMonthlyAverageOutdoorAirTemperatures(stat_file.delta_dry_bulb)
      runner.registerInfo("Setting water main temperatures.")
      puts "mean dry bulb is #{stat_file.mean_dry_bulb}"
      puts "delta dry bulb is #{stat_file.delta_dry_bulb}"
      puts water_temp
    else
      runner.registerWarning("Can't access STAT file to set water main temperatures.")
    end

    # Remove all the Design Day objects that are in the file
    model.getObjectsByType("OS:SizingPeriod:DesignDay".to_IddObjectType).each { |d| d.remove }

    # Load in the ddy file based on convention that it is in the same directory and has the same basename as the weather
    ddy_file = "#{File.join(File.dirname(weather_file), File.basename(weather_file, '.*'))}.ddy"
    if File.exist? ddy_file
      ddy_model = OpenStudio::EnergyPlus.loadAndTranslateIdf(ddy_file).get
      ddy_model.getObjectsByType("OS:SizingPeriod:DesignDay".to_IddObjectType).each do |d|
        # grab only the ones that matter
        ddy_list = /(Htg 99.6. Condns DB)|(Clg .4. Condns WB=>MDB)|(Clg .4% Condns DB=>MWB)/
        if d.name.get =~ ddy_list
          puts "Adding object #{d.name}"
          runner.registerInfo("Adding design day '#{d.name}'.")

          # add the object to the existing model
          #model << d.clone
          model.addObject(d.clone)
          #model.addObject(d.clone.get)
          #model.addObjects(d.clone)
          #d.clone(model)
          #d.to_ModelObject.get.clone(model)
        end
      end
    else
      runner.registerError("Could not find DDY file for #{ddy_file}.")
      return false
    end

    # report final condition
    final_design_days = model.getDesignDays
    if site.weatherFile.is_initialized
      weather = site.weatherFile.get
      runner.registerFinalCondition("The final weather file path was '#{weather.path.get}' and the model has #{final_design_days.size} design days.")
    else
      runner.registerFinalCondition("The final weather file has not been set and the model has #{final_design_days.size} design days.")
    end

    true
  end
end

# This allows the measure to be use by the application
ChangeBuildingLocation.new.registerWithApplication