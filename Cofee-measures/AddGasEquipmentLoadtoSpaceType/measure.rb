#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddGasEquipmentLoadtoSpaceType < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddGasEquipmentLoadtoSpaceType"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

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
      #only include if space type is used in the model
      if value.spaces.size > 0
        space_type_handles << value.handle.to_s
        space_type_display_names << key
      end
    end

    #add building to string vector with space type
    building = model.getBuilding
    space_type_handles << building.handle.to_s
    space_type_display_names << "*Entire Building*"

    #make a choice argument for space type
    object = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("object", space_type_handles, space_type_display_names)
    object.setDisplayName("Apply the Measure to a Specific Space Type or to the Entire Model.")
    object.setDefaultValue("*Entire Building*") #if no space type is chosen this will run on the entire building
    args << object

    #make an argument for reduction percentage
    gas_per_space_floor_area = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gas_per_space_floor_area",true)
    gas_per_space_floor_area.setDisplayName("Gas Energy Per Space Floor Area (Btu/ft^2*h).")
    gas_per_space_floor_area.setDefaultValue(0)
    args << gas_per_space_floor_area

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
    object = runner.getOptionalWorkspaceObjectChoiceValue("object",user_arguments,model)
    gas_per_space_floor_area = runner.getDoubleArgumentValue("gas_per_space_floor_area",user_arguments)

    #check the space_type for reasonableness and see if measure should run on space type or on the entire building
    apply_to_building = false
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
        apply_to_building = true
      else
        runner.registerError("Script Error - argument not showing up as space type or building.")
        return false
      end
    end

    #check the user_name for reasonableness
    if gas_per_space_floor_area < 0.0
      runner.registerError("Please enter a non negative number for gas per space floor area.")
      return false
    end
    
    watts_per_space_floor_area = OpenStudio::convert(gas_per_space_floor_area, "Btu/ft^2*h", "W/m^2").get

    #reporting initial condition of model
    building = model.getBuilding
    building_equip_power = building.gasEquipmentPower
    runner.registerInitialCondition("The model's initial building gas equipment power was #{building_equip_power} (W).")
    
    space_types = []
    if apply_to_building
      space_types = model.getSpaceTypes
    else
      space_types << space_type
    end

    # add new gas definition
    gas_definition = OpenStudio::Model::GasEquipmentDefinition.new(model)
    gas_definition.setWattsperSpaceFloorArea(watts_per_space_floor_area)
    
    space_types.each do |space_type|

      # skip if space type is not used
      next if space_type.spaces.size == 0
      
      floor_area = space_type.floorArea
      number_of_people = space_type.getNumberOfPeople(floor_area)

      # find largest electric load in space type
      biggest_electric_load = nil
      biggest_design_level = 0
      space_type.electricEquipment.each do |electric_equipment|
        design_level = electric_equipment.getDesignLevel(floor_area, number_of_people)
        if design_level > biggest_design_level
          biggest_design_level = design_level
          biggest_electric_load = electric_equipment
        end
      end
      
      if not biggest_electric_load
        runner.registerWarning("Space type #{space_type.name.get} does not have any electric loads, will not add gas load to this space type.")
        next
      end
      
      if biggest_electric_load.schedule.empty?
        runner.registerWarning("Space type #{space_type.name.get}'s largest electric load does not have a schedule, will not add gas load to this space type.")
        next
      end

      # add instance of new gas definition and link to added definition
      gas_instance = OpenStudio::Model::GasEquipment.new(gas_definition)
      gas_instance.setSchedule(biggest_electric_load.schedule.get)
      gas_instance.setSpaceType(space_type)
    end

    #reporting final condition of model
    building_equip_power = building.gasEquipmentPower
    runner.registerFinalCondition("The model's final building gas equipment power is #{building_equip_power} (W).")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddGasEquipmentLoadtoSpaceType.new.registerWithApplication