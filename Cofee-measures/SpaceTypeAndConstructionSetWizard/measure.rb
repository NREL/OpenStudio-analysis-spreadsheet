#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/SpaceTypeGenerator"
require "#{File.dirname(__FILE__)}/resources/ConstructionSetGenerator"

#start the measure
class SpaceTypeAndConstructionSetWizard < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SpaceTypeAndConstructionSetWizard"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for building type
    buildingType = OpenStudio::Ruleset::OSArgument::makeStringArgument("buildingType",true)
    buildingType.setDisplayName("Building Type.")
    args << buildingType

    #make an argument for vintage
    template = OpenStudio::Ruleset::OSArgument::makeStringArgument("template",true) # vintage or standard for building
    template.setDisplayName("Template.")
    args << template

    #make an argument for climate zone
    climateZone = OpenStudio::Ruleset::OSArgument::makeStringArgument("climateZone",true)
    climateZone.setDisplayName("ASHRAE Climate Zone.")
    args << climateZone

    #make an argument to add new space types
    createSpaceTypes = OpenStudio::Ruleset::OSArgument::makeBoolArgument("createSpaceTypes",true)
    createSpaceTypes.setDisplayName("Create Space Types?")
    createSpaceTypes.setDefaultValue(true)
    args << createSpaceTypes

    #make an argument to add new construction set
    createConstructionSet = OpenStudio::Ruleset::OSArgument::makeBoolArgument("createConstructionSet",true)
    createConstructionSet.setDisplayName("Create Construction Set?")
    createConstructionSet.setDefaultValue(true)
    args << createConstructionSet

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
    building_type = runner.getStringArgumentValue("buildingType",user_arguments)
    template = runner.getStringArgumentValue("template",user_arguments)
    climate = runner.getStringArgumentValue("climateZone",user_arguments)
    createSpaceTypes = runner.getBoolArgumentValue("createSpaceTypes",user_arguments)
    createConstructionSet = runner.getBoolArgumentValue("createConstructionSet",user_arguments)

    #todo - check arguments for reasonableness

    #reporting initial condition of model
    starting_spaceTypes = model.getSpaceTypes
    starting_constructionSets = model.getDefaultConstructionSets
    runner.registerInitialCondition("The building started with #{starting_spaceTypes.size} space types and #{starting_constructionSets.size} construction sets.")

    path_to_standards_json = "#{File.dirname(__FILE__)}/resources/OpenStudio_Standards.json"
    path_to_master_schedules_library = "#{File.dirname(__FILE__)}/resources/Master_Schedules.osm"

    #create generators
    space_type_generator = SpaceTypeGenerator.new(path_to_standards_json, path_to_master_schedules_library)
    construction_set_generator = ConstructionSetGenerator.new(path_to_standards_json)

    #load the data from the JSON file into a ruby hash
    standards = {}
    temp = File.read(path_to_standards_json)
    standards = JSON.parse(temp)
    space_types = standards["space_types"]
    construction_sets = standards["construction_sets"]

    # add space types
    puts "Creating Space Types"
    for t in space_types.keys.sort
      next if not t == template
      puts "#{t}"

      for c in space_types[template].keys.sort
        next if not space_type_generator.is_climate_zone_in_climate_zone_set(climate, c)

        for b in space_types[template][c].keys.sort
          next if not b == building_type
          puts "****#{building_type}"

          for space_type in space_types[template][c][building_type].keys.sort
            #generate space type
            result = space_type_generator.generate_space_type(template, c, building_type, space_type, model)

          end #next space type
        end #next building type
      end #next climate
    end #next template

    # get climate zone set from specific climate zone for construction set
    climateConst = construction_set_generator.find_climate_zone_set(template, climate, building_type, "")

    # add construction set
    puts "Creating Construction Sets"
    for t in construction_sets.keys.sort
      next if not t == template
      puts "#{t}"
      for c in construction_sets[template].keys.sort
        next if not c == climateConst
        puts "**#{c}"
        for b in construction_sets[template][climateConst].keys.sort
          next if not b == building_type
          puts "****#{b}"

          for space_type in construction_sets[template][climateConst][building_type].keys.sort
            #generate construction set
            result = construction_set_generator.generate_construction_set(template, climateConst, building_type, space_type, model)

            # set default construction set
            model.getBuilding.setDefaultConstructionSet(result[0])

          end #next space type
        end #next building type
      end #next climate
    end #next template

    # thermostat schedules are brought in but cant be assigned until later on when there is a model.

    #reporting final condition of model
    finishing_spaceTypes = model.getSpaceTypes
    finishing_constructionSets = model.getDefaultConstructionSets
    runner.registerFinalCondition("The building finished with #{finishing_spaceTypes.size} space types and #{finishing_constructionSets.size} construction sets.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SpaceTypeAndConstructionSetWizard.new.registerWithApplication