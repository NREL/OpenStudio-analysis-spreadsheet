#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ImportEnvelopeAndInternalLoadsFromIdf < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ImportEnvelopeAndInternalLoadsFromIdf"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for your name
    source_idf_path = OpenStudio::Ruleset::OSArgument::makeStringArgument("source_idf_path",true)
    source_idf_path.setDisplayName("Path to Source IDF File to Use.")
    args << source_idf_path

    #make an argument for importing site objects
    import_site_objects = OpenStudio::Ruleset::OSArgument::makeBoolArgument("import_site_objects",true)
    import_site_objects.setDisplayName("Import Site Shading.")
    # import_site_objects.setDisplayName("Import Site objects (site shading and exterior lights).")  # todo - use this once exterior lights are supported
    import_site_objects.setDefaultValue(true)
    args << import_site_objects
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #assign the user inputs to variables
    import_site_objects = runner.getBoolArgumentValue("import_site_objects",user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    source_idf_path = runner.getStringArgumentValue("source_idf_path",user_arguments)

    #check the source_idf_path for reasonableness
    if source_idf_path == ""
      runner.registerError("No Source IDF File Path was Entered.")
      return false
    end

    #reporting initial condition of model
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("The building started with #{starting_spaces.size} spaces.")

    # translate IDF file to OSM
    workspace = OpenStudio::Workspace::load(OpenStudio::Path.new(source_idf_path))
    rt = OpenStudio::EnergyPlus::ReverseTranslator.new
    model2 = rt.translateWorkspace(workspace.get)

    # remove original building
    building = model.getBuilding
    building.remove

    # clone in building from IDF
    building2 = model2.getBuilding
    building2.clone(model)

    # hash of old and new thermostats
    thermostatOldNewHash = {}

    # cloning thermostats
    thermostats = model2.getThermostatSetpointDualSetpoints
    thermostats.each do |thermostat|
      newThermostat = thermostat.clone(model)
      # populate hash
      thermostatOldNewHash[thermostat] = newThermostat
    end

    # loop through thermal zone to match old to new and assign thermostat
    thermalZonesOld = model2.getThermalZones
    thermalZonesNew = model.getThermalZones
    thermalZonesOld.each do |thermalZoneOld|
      thermalZonesNew.each do |thermalZoneNew|
        if thermalZoneOld.name.to_s == thermalZoneNew.name.to_s
          # wire thermal zone to thermostat
          if not thermalZoneOld.thermostatSetpointDualSetpoint.empty?
            thermostatOld = thermalZoneOld.thermostatSetpointDualSetpoint.get
            thermalZoneNew.setThermostatSetpointDualSetpoint(thermostatOldNewHash[thermostatOld].to_ThermostatSetpointDualSetpoint.get)
          end
          next
        end
      end
    end # end of thermalZonesOld.each do

    # fix for space type and thermal zone connections
    spaces = model.getSpaces
    spaces.each do |space|
      thermalZonesNew.each do |zone|
        # since I know the names here I can look for match, but this work around only works with imported IDF's where names are known
        if zone.name.to_s == "#{space.name} Thermal Zone"
          space.setThermalZone(zone)
        end
      end
    end

    # todo - surface matching is also messed up, but I'll add a stand alone measure for that vs. adding it here.

    # import site objects if requested
    if import_site_objects

      # todo - this doesn't do anything because exterior lights don't make it through reverse translation
      # get exterior lights
      facility = model2.getFacility
      exteriorLights = facility.exteriorLights
      exteriorLights.each do |exteriorLight|
        exteriorLight.clone(model)
        runner.registerInfo("Cloning exterior light #{exteriorLight.name} into model.")
      end

      # get site shading
      shadingSurfaceGroups = model2.getShadingSurfaceGroups
      shadingSurfaceGroups.each do |group|
        if group.shadingSurfaceType == "Site"
          group.clone(model)
          runner.registerInfo("Cloning shading group #{group.name} into model.")
        end
      end

    end # end of if import_site_objects

    #reporting final condition of model
    finishing_spaces = model.getSpaces
    runner.registerFinalCondition("The building finished with #{finishing_spaces.size} spaces.")

    # todo - see if SHW comes in, if not think of solution

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ImportEnvelopeAndInternalLoadsFromIdf.new.registerWithApplication