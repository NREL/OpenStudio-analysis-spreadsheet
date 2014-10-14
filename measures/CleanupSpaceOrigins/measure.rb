#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class CleanupSpaceOrigins < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "CleanupSpaceOrigins"
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

    def cleanup_group(group)
      boundingBox = group.transformation*group.boundingBox

      if boundingBox.isEmpty
        return
      end

      matrix = OpenStudio::Matrix.new(4,4,0)
      matrix[0,0] = 1
      matrix[1,1] = 1
      matrix[2,2] = 1
      matrix[3,3] = 1
      matrix[0,3] = boundingBox.minX.get
      matrix[1,3] = boundingBox.minY.get
      matrix[2,3] = boundingBox.minZ.get
      translation = OpenStudio::Transformation.new(matrix)
      group.changeTransformation(translation)
    end

    #reporting initial condition of model
    planarSurfaceGroups = model.getPlanarSurfaceGroups
    runner.registerInitialCondition("The building has #{planarSurfaceGroups.size} planar surface groups.")

    # do spaces first as these may contain other groups
    model.getSpaces.each do |space|
      next if not runner.inSelection(space)
      cleanup_group(space)

      space.shadingSurfaceGroups.each do |group|
        cleanup_group(group)
      end

      space.interiorPartitionSurfaceGroups.each do |group|
        cleanup_group(group)
      end
    end

    # now do shading surfaces
    model.getShadingSurfaceGroups.each do |group|
      next if not runner.inSelection(group)
      cleanup_group(group)
    end

    # now do interior partition surface groups
    model.getInteriorPartitionSurfaceGroups.each do |group|
      next if not runner.inSelection(group)
      cleanup_group(group)
    end

    #reporting final condition of model
    runner.registerFinalCondition("All planar surface group origins have been inspected, and adjusted as necessary.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
CleanupSpaceOrigins.new.registerWithApplication