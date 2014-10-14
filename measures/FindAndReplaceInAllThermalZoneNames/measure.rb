#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class FindAndReplaceInAllThermalZoneNames < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Find And Replace In All Thermal Zone Names"
  end
  
  #define the arguments that the user will input
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for your name
    orig_string = OpenStudio::Ruleset::OSArgument::makeStringArgument("orig_string",true)
    orig_string.setDisplayName("Type the text you want search for in thermal zone names")
    orig_string.setDefaultValue(" Thermal Zone")
    args << orig_string

    #make an argument to add new space true/false
    new_string = OpenStudio::Ruleset::OSArgument::makeStringArgument("new_string",true)
    new_string.setDisplayName("Type the text you want to add in place of the found text")
    new_string.setDefaultValue("")
    args << new_string

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    orig_string = runner.getStringArgumentValue("orig_string",user_arguments)
    new_string = runner.getStringArgumentValue("new_string",user_arguments)

    #check the orig_string for reasonableness
    puts orig_string
    if orig_string == ""
      runner.registerError("No search string was entered.")
      return false
    end

    #reporting initial condition of model
    thermal_zones = model.getThermalZones
    runner.registerInitialCondition("The model has #{thermal_zones.size} thermal zones.")

    #array for objects with names
    named_objects = []

    #loop through model objects and rename if the object has a name
    thermal_zones.each do |thermal_zone|
      if thermal_zone.name.is_initialized
        old_name = thermal_zone.name.get
        requested_name = old_name.gsub(orig_string,new_string)
        new_name = thermal_zone.setName(requested_name)
        if old_name != new_name
          named_objects << new_name
        elsif old_name != requested_name
          runner.registerWarning("Could not change name of '#{old_name}' to '#{requested_name}'.")
        end
      end
    end

    #reporting final condition of model
    runner.registerFinalCondition("#{named_objects.size} thermal zones were renamed.")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
FindAndReplaceInAllThermalZoneNames.new.registerWithApplication