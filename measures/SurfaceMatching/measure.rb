#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SurfaceMatching < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SurfaceMatching"
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

    # matched surface counter
    initialMatchedSurfaceCounter = 0
    surfaces = model.getSurfaces
    surfaces.each do |surface|
      if surface.outsideBoundaryCondition == "Surface"
        next if not surface.adjacentSurface.is_initialized # don't count as matched if boundary condition is right but no matched object
        initialMatchedSurfaceCounter += 1
      end
    end

    #reporting initial condition of model
    runner.registerInitialCondition("The initial model has #{initialMatchedSurfaceCounter} matched surfaces.")

    #put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end

    #match surfaces for each space in the vector
    OpenStudio::Model.matchSurfaces(spaces)

    # matched surface counter
    finalMatchedSurfaceCounter = 0
    surfaces.each do |surface|
      if surface.outsideBoundaryCondition == "Surface"
        finalMatchedSurfaceCounter += 1
      end
    end

    #reporting final condition of model
    runner.registerFinalCondition("The final model has #{finalMatchedSurfaceCounter} matched surfaces.")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SurfaceMatching.new.registerWithApplication