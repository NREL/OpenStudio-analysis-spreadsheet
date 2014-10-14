#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AssignSpaceTypeBySpaceName < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AssignSpaceTypeBySpaceName"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for your name
    search_string = OpenStudio::Ruleset::OSArgument::makeStringArgument("search_string",true)
    search_string.setDisplayName("String ot search for in space names.")
    args << search_string

    #make a choice argument for model objects
    space_type_handles = OpenStudio::StringVector.new
    space_type_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    space_type_args = model.getSpaceTypes
    space_type_args_hash = {}
    space_type_args.each do |space_type_arg|
      space_type_args_hash[space_type_arg.name.to_s] = space_type_arg
    end

    #looping through sorted hash of model objects
    space_type_args_hash.sort.map do |key,value|
      space_type_handles << value.handle.to_s
      space_type_display_names << key
    end

    #add building to string vector with space type
    building = model.getBuilding
    space_type_handles << building.handle.to_s
    space_type_display_names << "<clear field>"

    #make a choice argument for space type
    space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space_type", space_type_handles, space_type_display_names)
    space_type.setDisplayName("Space type to assign to affected spaces.")
    space_type.setDefaultValue("<clear field>") #if no space type is chosen this field will be cleared out
    args << space_type

    #make an argument for deleting all existing space shading in the model
    skip_already_assigned = OpenStudio::Ruleset::OSArgument::makeBoolArgument("skip_already_assigned",true)
    skip_already_assigned.setDisplayName("Skip spaces that already have hard assigned space types.")
    skip_already_assigned.setDefaultValue(false)
    args << skip_already_assigned
    
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
    search_string = runner.getStringArgumentValue("search_string",user_arguments)
    object = runner.getOptionalWorkspaceObjectChoiceValue("space_type",user_arguments,model)
    skip_already_assigned = runner.getBoolArgumentValue("skip_already_assigned",user_arguments)

    #check the search_string for reasonableness
    puts search_string
    if search_string == ""
      runner.registerError("No search string was entered.")
      return false
    end

    # check space type for reasonableness
    clear_field = false
    space_type = nil
    if object.empty?
      handle = runner.getStringArgumentValue("space_type",user_arguments)
      if handle.empty?
        runner.registerError("No space type was chosen.")
      else
        runner.registerError("The selected space type with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not object.get.to_SpaceType.empty?
        space_type = object.get.to_SpaceType.get
      elsif not object.get.to_Building.empty?
        clear_field = true
      else
        runner.registerError("Script Error - argument not showing up as space type or building.")
        return false
      end
    end

    # counters
    stringMatch = 0
    spacesChanged = 0

    spaces = model.getSpaces
    spaces.each do |space|
      # get current space type
      startingSpaceType = space.spaceType

      # test string
      if space.name.to_s.include? search_string
        stringMatch += 1

        # check starting space type and user bool
        if not (skip_already_assigned and not startingSpaceType.empty?)
          spacesChanged += 1
          space.setSpaceType(space_type)
        end
      end

    end # end of spaces.each do

    #reporting initial condition of model
    runner.registerInitialCondition("#{stringMatch} space names contained the requested string.")

    #reporting final condition of model
    runner.registerFinalCondition("Changed space type assignment for #{spacesChanged} spaces.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AssignSpaceTypeBySpaceName.new.registerWithApplication