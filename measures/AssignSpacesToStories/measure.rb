#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AssignSpacesToStories < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AssignSpacesToStories"
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

    #assign the user inputs to variables

    # find the first story with z coordinate, create one if needed
    def getStoryForNominalZCoordinate(model, minz)

      model.getBuildingStorys.each do |story|
        z = story.nominalZCoordinate
        if not z.empty?
          if minz == z.get
            return story
          end
        end
      end

      story = OpenStudio::Model::BuildingStory.new(model)
      story.setNominalZCoordinate(minz)
      return story
    end

    #reporting initial condition of model
    starting_stories = model.getBuildingStorys
    runner.registerInitialCondition("The building started with #{starting_stories.size} stories.")

    # get all spaces
    spaces = model.getSpaces

    # make has of spaces and minz values
    sorted_spaces = Hash.new
    spaces.each do |space|
      # loop through space surfaces to find min z value
      z_points = []
      space.surfaces.each do |surface|
        surface.vertices.each do |vertex|
          z_points << vertex.z
        end
      end
      minz = z_points.min + space.zOrigin
      sorted_spaces[space] = minz
    end

    # pre-sort spaces
    sorted_spaces = sorted_spaces.sort{|a,b| a[1]<=>b[1]}

    # this should take the sorted list and make and assign stories
    sorted_spaces.each do |space|
      space_obj = space[0]
      space_minz = space[1]
      if space_obj.buildingStory.empty?

        story = getStoryForNominalZCoordinate(model, space_minz)
        space_obj.setBuildingStory(story)

      end
    end

    #reporting final condition of model
    finishing_stories = model.getBuildingStorys
    runner.registerFinalCondition("The building finished with #{finishing_stories.size} stories.")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AssignSpacesToStories.new.registerWithApplication