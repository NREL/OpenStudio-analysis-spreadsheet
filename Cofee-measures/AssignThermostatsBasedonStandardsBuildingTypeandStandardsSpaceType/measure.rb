#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/OsLib_HelperMethods"

#start the measure
class AssignThermostatsBasedonStandardsBuildingTypeandStandardsSpaceType < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AssignThermostatsBasedonStandardsBuildingTypeandStandardsSpaceType"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #reporting initial condition of model
    thermalZones = model.getThermalZones
    counter = 0
    thermalZones.each do |zone|
      # if zone had thermostat add to counter
      if not zone.thermostatSetpointDualSetpoint.empty?
        counter += 1
      end
    end
    runner.registerInitialCondition("The building started with #{counter} thermostats assigned.")

    # create hash of existing thermostat
    thermostatHash = {}
    thermostats = model.getThermostatSetpointDualSetpoints
    thermostats.each do |thermostat|
      thermostatHash[thermostat.name.get] = thermostat
    end

    # loop through thermal zones
    thermalZones = model.getThermalZones
    thermalZones.each do |zone|

      # get space type
      spaceType = zone.spaces[0].spaceType.get

      # get standards space type
      standardsInfo = OsLib_HelperMethods.getSpaceTypeStandardsInformation([spaceType])

      # assign thermostat if it exists
      thermostatHash.each do |name,thermostat|
        if name.include? standardsInfo[0].to_s and name.include? standardsInfo[1].to_s
          zone.setThermostatSetpointDualSetpoint(thermostat)
        end
      end

      # todo - add more logic to look at all spaces in zone vs. just first one
      # todo - also confirm that zone has spaces in it
      # todo - confirm that space has a space type and that it has standards information
    end

    #reporting final condition of model
    counter = 0
    thermalZones.each do |zone|
      # if zone had thermostat add to counter
      if not zone.thermostatSetpointDualSetpoint.empty?
        counter += 1
      end
    end
    runner.registerFinalCondition("The building finished with #{counter} thermostats assigned.")


    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AssignThermostatsBasedonStandardsBuildingTypeandStandardsSpaceType.new.registerWithApplication